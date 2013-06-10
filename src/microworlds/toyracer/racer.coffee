#
# racer.coffee (c) 2012 HT de Beer
#
# race simulator
#
window.CoffeeGrounds = CoffeeGrounds ? {}
CoffeeGrounds.Racer = class
  
  initialize_properties: (properties) ->
    # Initialize properties with properties or default values
    p = {}
    p.speed = properties?.speed ? 5
    p.buttons = properties?.buttons ? ['restart', 'pause', 'race', 'finish']
    p.runnable = properties?.runnable ? true
    if not p.runnable
      p.buttons = []
    p.icon_path = properties?.icon_path ? 'lib/icons'
    p

  constructor: (@paper, @x, @y, @track, @graph, properties) ->
   
    @PADDING = 5
    @LABEL_SEP = 10
    @TRACK_SEP = 25
    @spec = @initialize_properties properties

    @BUTTON_WIDTH = 34
    @BUTTON_SEP = 5
    @GROUP_SEP = 15
    CoffeeGrounds.Button.set_width @BUTTON_WIDTH
    CoffeeGrounds.Button.set_base_path @spec.icon_path

    @actions = {
      restart:
        button:
          type: 'group'
          value: 'restart'
          option_group: 'simulation'
          group: 'simulation'
          icon: 'media-skip-backward'
          tooltip: 'Terug naar de start'
          on_select: =>
            @change_mode 'restart'
            @restart()
          enabled: true
          default: true
      pause:
        button:
          type: 'group'
          value: 'pause'
          option_group: 'simulation'
          group: 'simulation'
          icon: 'media-playback-pause'
          tooltip: 'Pauzeer de race'
          on_select: =>
            @change_mode 'pause'
            @pause()
          enabled: true
      race:
        button:
          type: 'group'
          value: 'race'
          option_group: 'simulation'
          group: 'simulation'
          icon: 'media-playback-start'
          tooltip: 'Start de race / ga verder met racen'
          on_select: =>
            @change_mode 'race'
            @start()
          enabled: true
    }

    @acceleration = @parse_accelerationpath(@track?.accelerationpath ? '0.1|10')

    @mode = 'start'
    @time = 0
    @distance = 0
    @id = -1
    @time_step = 50
    @speed = 0
    @current_acceleration_spectification = 0
    @draw()
    @update_labels()
    @compute_maximum()
    @length = 0
    @racing = false
    @graphpath = ""
    @max_length = Raphael.getTotalLength @trackpath

  set_graph: (graph) ->
    @graph = graph

  get_graph: ->
    @graph


  update_labels: ->
    # update time and distance labels
    @time_label.attr
      text: @time.toFixed 2
    @distance_label.attr
      text: @distance.toFixed 2

  change_mode: (mode) ->
    @mode = mode


  # simulation methods
  restart: =>
    @time = 0
    @distance = 0
    @racing = false
    @length = 0
    @graphpath = ""
    @speed = 0
    @current_acceleration_spectification = 0
    clearInterval @id
    point = Raphael.getPointAtLength @trackpath, @length
    @place_car point.x, point.y, point.alpha
    @update_labels()

  pause: =>
    clearInterval @id
    @racing = false

  start: =>
    clearInterval @id
    @racing = true
    @id = setInterval @race, @time_step


  update_graph: (dtime, ddistance) ->
    # compute the number of pixels per tenth of mm
    line = @graph.computer_line
    x = line.min.x
    y = line.max.y
    if @graphpath is ""
      @graphpath = "M#{x},#{y}"
      @graphpath += "l#{dtime/line.x_unit.per_pixel},-#{ddistance/line.y_unit.per_pixel}"
    else
      @graphpath += "l#{dtime/line.x_unit.per_pixel},-#{ddistance/line.y_unit.per_pixel}"
      
    @graph.computer_graph.attr
      path: @graphpath
    line.add_point x, y, @graph
    p = line.find_point_at x
    line.add_freehand_line p, @graphpath

  race: =>
    if @racing and @length < @max_length  - 10
      if @distance < @acceleration[@current_acceleration_spectification].distance
        # still in this interval: accelerate
        acceleration = @acceleration[@current_acceleration_spectification].acceleration
      else
        # get new interval end, if any
        @current_acceleration_spectification = @current_acceleration_spectification + 1 if (@current_acceleration_spectification < @acceleration.length - 1)
        acceleration = @acceleration[@current_acceleration_spectification].acceleration
      
      @speed += acceleration


      @time += @time_step / 1000
      ddistance = @time_step * (@speed/1000)
      @distance +=  ddistance
      @length += ddistance / @track.meter_per_pixel

      point = Raphael.getPointAtLength @trackpath, @length
      @place_car point.x, point.y, point.alpha
      @update_labels()
      @update_graph @time_step/1000, ddistance
    else
      @racing = false
      clearInterval @id
      @simulation.deselect 'race'
      point = Raphael.getPointAtLength @trackpath, @max_length
      @place_car point.x, point.y, 135


  compute_maximum: ->
    @maximum_distance = Raphael.getTotalLength(@trackpath)  * @track.meter_per_pixel
    # compute later when speed-section has been added. Until then: use 9.8
    time = 0
    distance = 0
    curr_accl = 0
    speed = 0
    acc = 0
    while distance < @maximum_distance
      if distance < @acceleration[curr_accl].distance
        acc = @acceleration[curr_accl].acceleration
      else
        curr_accl = curr_accl + 1 if (curr_accl < @acceleration.length - 1)
        acc = @acceleration[curr_accl].acceleration

      speed += acc
      time += @time_step / 1000
      ddistance = @time_step * (speed / 1000)
      distance += ddistance


      
    @maximum_time = time

  # utility methods

  draw: ->
    @draw_buttons()
    y = @y + @PADDING + @BUTTON_WIDTH + @TRACK_SEP

    label_format =
      'font-family': 'sans-serif'
      'font-size': '16pt'
      'text-anchor': 'end'
    label_label_format =
      'font-family': 'sans-serif'
      'font-size': '16pt'
      'text-anchor': 'start'

    time_label_label = @paper.text @x + @PADDING, y, "tijd :"
    time_label_label.attr label_label_format
    tllbb = time_label_label.getBBox()
    distance_label_y = y + tllbb.height + @LABEL_SEP
    distance_label_label = @paper.text @x + @PADDING, distance_label_y, "afstand :"
    distance_label_label.attr label_label_format
    dllbb = distance_label_label.getBBox()

    @time_label = @paper.text @x, y, "8888,88"
    @time_label.attr label_format
    tlbb = @time_label.getBBox()
    time_label_x = @x + @PADDING + dllbb.width + @LABEL_SEP + tlbb.width
    @time_label.attr
      x: time_label_x
    @distance_label = @paper.text time_label_x, distance_label_y, "3300"
    @distance_label.attr label_format

    unit_x = time_label_x + @LABEL_SEP
    time_unit_label = @paper.text unit_x, y, "sec"
    time_unit_label.attr label_label_format
    distance_unit_label = @paper.text unit_x, distance_label_y, "m"
    distance_unit_label.attr label_label_format

    seperator_y = distance_label_y + dllbb.height + @LABEL_SEP

    track_y = seperator_y + @TRACK_SEP
    track_x = @x + @PADDING

    @trackpath = "M#{track_x + @track.move_x},#{track_y}" + @track.path

    # Add markers to the track
    SMALL_TICK = 10
    LARGE_TICK = 14
    START_TICK = 20

    ticks = @parse_tickspath @track.ticks

    length = 0
    max_length = Raphael.getTotalLength @trackpath
    # step in meters expressed in pixels
    step = ticks.distance / @track.meter_per_pixel
    i = 0
    

    while length < max_length + step
      point = Raphael.getPointAtLength @trackpath, length
      if ticks[i].size is 'large'
        tick = @paper.path "M#{point.x},#{point.y}v#{LARGE_TICK}v-#{2*LARGE_TICK}"
        tick.attr
          'stroke-width': 2
          stroke: 'orange'
      else
        # ticks size is small
        tick = @paper.path "M#{point.x},#{point.y}v#{SMALL_TICK}v-#{2*SMALL_TICK}"
      tick.attr
        transform: "r#{point.alpha}"

      length += step
      i = (i + 1) % ticks.length

    # start tick
    point = Raphael.getPointAtLength @trackpath, length
    tick = @paper.path "M#{point.x},#{point.y}v#{START_TICK}v-#{2*START_TICK}"
    tick.attr
      'stroke-width': 4
      stroke: 'red'


    racetrack = @paper.path @trackpath
    racetrack.attr
      stroke: '#222'
      'stroke-width': 16
    midmarking = @paper.path @trackpath
    midmarking.attr
      stroke: '#eee'
      'stroke-width': 3

    rtbb = racetrack.getBBox()
    seperator = @paper.path "M#{@x},#{seperator_y}h#{rtbb.width + @PADDING + 32}"
    seperator.attr
      'stroke-width': 2

    legend_size = (ticks.length * ticks.distance) / @track.meter_per_pixel
    legend_x = rtbb.x2 - legend_size + 2 * @PADDING
    legend_y = rtbb.y2 + 2*@TRACK_SEP

    legendpath = "M#{legend_x},#{legend_y}h#{legend_size}"
    legendtrack = @paper.path legendpath
    legendtrack.attr
      stroke: '#222'
      'stroke-width': 16
    legendmarking = @paper.path legendpath
    legendmarking.attr
      stroke: '#eee'
      'stroke-width': 3

    i = 0
    length = 0
    point = Raphael.getPointAtLength legendpath, length
    tick = @paper.path "M#{point.x},#{point.y}v#{LARGE_TICK}v-#{2*LARGE_TICK}"
    tick.attr
      'stroke-width': 2
      stroke: 'orange'
    length += step
    while length < legend_size
      point = Raphael.getPointAtLength legendpath, length
      if ticks[i].size is 'large'
        tick = @paper.path "M#{point.x},#{point.y}v#{LARGE_TICK}v-#{2*LARGE_TICK}"
        tick.attr
          'stroke-width': 2
          stroke: 'orange'
      else
        # ticks size is small
        tick = @paper.path "M#{point.x},#{point.y}v#{SMALL_TICK}v-#{2*SMALL_TICK}"
      tick.attr
        transform: "r#{point.alpha}"
      length += step
      i++

    point = Raphael.getPointAtLength legendpath, length
    tick = @paper.path "M#{point.x},#{point.y}v#{LARGE_TICK}v-#{2*LARGE_TICK}"
    tick.attr
      'stroke-width': 2
      stroke: 'orange'

    ltbb = legendtrack.getBBox()
    legend_y += ltbb.height + 3*@LABEL_SEP

    legend_label = @paper.text legend_x, legend_y, "= #{ticks.length * ticks.distance} meter"
    legend_label.attr label_label_format


    point = Raphael.getPointAtLength @trackpath, 0
    @CAR_WIDTH = 26
    @CAR_HEIGHT = 13
    @car = @paper.image '../raceauto_geel.png', 0, 0, @CAR_WIDTH, @CAR_HEIGHT
    @car.attr
      fill: 'yellow'
      stroke: 'black'
    @place_car point.x, point.y, 180

    @width = @PADDING*2 + rtbb.width


  place_car: (x, y, angle = 0) ->
    @car.attr
      x: x - @CAR_WIDTH/2
      y: y - @CAR_HEIGHT/2
      transform: "R#{angle}"
    


  draw_buttons: ->
    x = @x
    y = @y
    @mode = ""

    group = ''
    optiongroups = {}
    sep = 0
    @buttons = {}
    for name, action of @actions
      if name in @spec.buttons
        # only those buttons set are put on the graph
        button = action.button

        if group isnt ''
          if button.group is group
            x += @BUTTON_WIDTH + @BUTTON_SEP
          else
            x += @BUTTON_WIDTH + @GROUP_SEP
        group = button.group



        switch button.type
          when 'action'
            @buttons.name = new CoffeeGrounds.ActionButton @paper,
              x: x
              y: y
              icon: button.icon
              tooltip: button.tooltip
              action: button.action
          when 'switch'
            @buttons.name = new CoffeeGrounds.SwitchButton @paper,
              x: x
              y: y
              icon: button.icon
              tooltip: button.tooltip
              switched_on: button?.switched_on ? false
              on_switch_on: button.on_switch_on
              on_switch_off: button.on_switch_off
          when 'group'
            optiongroups[button.option_group] = optiongroups[button.option_group] ? []
            optiongroups[button.option_group].push {
              x: x
              y: y
              icon: button.icon
              tooltip: button.tooltip
              value: name
              on_select: button.on_select
              chosen: button.default ? false
            }


    # Add and create buttongroups
    for name, optiongroup of optiongroups
      buttongroup = new CoffeeGrounds.ButtonGroup @paper, optiongroup
      @simulation = buttongroup
      for button in buttongroup.buttons
        @buttons[button.value] = button



    if @spec.buttons.length is 0
      @BUTTONS_GROUP_WIDTH = 3 * (@BUTTON_WIDTH + @BUTTON_SEP) - @BUTTON_SEP
    else if 'time' in @spec.buttons
      @BUTTONS_GROUP_WIDTH = x - @GROUP_SEP - @x
    else
      @BUTTONS_GROUP_WIDTH = x - @BUTTON_SEP - @x

  parse_tickspath: (s) ->
    # tickspath ::= <number> ( t|T|l|L )+
    # with:
    #   ∙ number: the distance in units between ticks. Ticks are all
    #             equally spaced
    #   ∙ subseqent ticks specified by:
    #     ∙ t: small tick, no label
    #     ∙ T: large tick, no label
    #     ∙ l: small tick, with label
    #     ∙ L: large tick, with label
    #
    # the pattern will be repeated until the end of the axis
    #
    # return: array of subsequent ticks (without repetition)
    #
    pattern = /(\d+(?:\.\d+)?)((?:t|T|l|L)+)/
    match = pattern.exec s
    ticklength = parseFloat match[1]
    tickpattern = match[2]
    ticks = []
    ticks.distance = ticklength
    for c in tickpattern
      tick = {}
      switch c
        when 't'
          tick.label = false
          tick.size = 'small'
        when 'T'
          tick.label = false
          tick.size = 'large'
        when 'l'
          tick.label = true
          tick.size = 'small'
        when 'L'
          tick.label = true
          tick.size = 'large'
      ticks.push tick

    ticks

  parse_accelerationpath: (s) ->
    # accelerationpath:
    #
    # ((<number> | r <number>)[<number>],)+
    #
    # accelerate for number or random*number until distance number
    #
    pattern = /((?:-)?\d+(?:\.\d+)?)\|(\d+(?:\.\d+)?)/
    accel_parts = s.split(',')
    accel_arr = []
    for part in accel_parts
      match =pattern.exec part
      acceleration_spec =
        acceleration: parseFloat match[1]
        distance: parseFloat match[2]
      accel_arr.push acceleration_spec
    accel_arr


