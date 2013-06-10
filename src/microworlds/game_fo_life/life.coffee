#
# life.coffee (c) 2012 HT de Beer
#
# Conway's game of life implementation
#
window.CoffeeGrounds = CoffeeGrounds ? {}
CoffeeGrounds.Life = class
  
  initialize_properties: (properties) ->
    # Initialize properties with properties or default values
    p = {}
    p.buttons = properties?.buttons ? ['restart', 'pause', 'step']
    p.runnable = properties?.runnable ? true
    if not p.runnable
      p.buttons = []
    p.icon_path = properties?.icon_path ? 'lib/icons'
    p

  constructor: (@paper, @x, @y, @config, @graph, properties) ->
   
    @PADDING = 5
    @LABEL_SEP = 10
    @SIM_SEP = 25
    @spec = @initialize_properties properties
    @ALIVE_COLOR = 'black'
    @DEAD_COLOR = 'white'

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
          tooltip: 'Terug naar het begin'
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
          tooltip: 'Pauzeer de simulation'
          on_select: =>
            @change_mode 'pause'
            @pause()
          enabled: true
      step:
        button:
          type: 'group'
          value: 'step'
          option_group: 'simulation'
          group: 'simulation'
          icon: 'media-playback-start'
          tooltip: 'Start de simulation / ga verder met de simulation'
          on_select: =>
            @change_mode 'step'
            @start()
          enabled: true
    }

    @mode = 'start'
    @population = @config.initial_configuration.length
    @generation = 0
    @id = -1
    @time_step = 1000/@config.speed
    @simulating = false
    @maximum_generation = @config.maximum_generation
    # absolute maximum, most possible the population will not grow over just
    # a small part
    @maximum_population = @config.width * @config.height
    @current = @generate_configuration @config.width, @config.height, @config.initial_configuration
    @next = @generate_configuration @config.width, @config.height
    @draw()
    @update_labels()
    @length = 0
    @graphpath = ""


  generate_configuration: (width, height, init = []) ->
    config = []
    for row in [0...height]
      config[row] = []
      for col in [0...width]
        config[row].push(if "#{row};#{col}" in init then 1 else 0)
    config

  neighbor_count: (row, col) ->
    count = 0
    rowprev = if row is 0 then @config.height - 1 else row - 1
    rownext = if row is @config.height - 1 then 0 else row + 1
    colprev = if col is 0 then @config.width - 1 else col - 1
    colnext = if col is @config.width - 1 then 0 else col + 1

    if @current[rownext][col] is 1
      count++
    if @current[rownext][colnext] is 1
      count++
    if @current[row][colnext] is 1
      count++
    if @current[row][colprev] is 1
      count++
    if @current[rownext][colprev] is 1
      count++
    if @current[rowprev][col] is 1
      count++
    if @current[rowprev][colprev] is 1
      count++
    if @current[rowprev][colnext] is 1
      count++
    count


  next_configuration: ->
    population = 0
    for row in [0...@config.height]
      for col in [0...@config.width]
        neighbors  = @neighbor_count row, col
        if @config.highlife
          alive = (@current[row][col] is 1) and neighbors is 2 or neighbors is 3 or neighbors is 6
        else
          alive = (@current[row][col] is 1) and neighbors is 2 or neighbors is 3
        @next[row][col] = if alive then 1 else 0
        if alive
          population++

    @current = @next
    population


  set_graph: (graph) ->
    @graph = graph

  get_graph: ->
    @graph

  update_configuration: ->
    # update configuration with current configuration
    for row in [0...@config.height]
      for col in [0...@config.width]
        alive = if @current[row][col] is 1 then @ALIVE_COLOR else @DEAD_COLOR
        @configuration_view[row][col].attr
          fill: alive

  update_labels: ->
    # update time and distance labels
    @generation_label.attr
      text: @generation
    @population_label.attr
      text: @population

  change_mode: (mode) ->
    @mode = mode


  # simulation methods
  restart: =>
    @time = 0
    @generation = 0
    @population = @config.initial_configuration.length
    @simulating = false
    @length = 0
    @graphpath = ""
    @current = @generate_configuration @config.width, @config.height, @config.initial_configuration
    @next = @generate_configuration @config.width, @config.height
    @update_configuration()
    clearInterval @id
    @update_labels()
    @update_graph()

  pause: =>
    clearInterval @id
    @simulating = false

  start: =>
    clearInterval @id
    @simulating = true
    @id = setInterval @step, @time_step


  update_graph: (dgen, dpop) ->
    # compute the number of pixels per tenth of mm
    dpop = -1 * dpop
    line = @graph.computer_line
    x = line.min.x
    y = line.max.y
    if @graphpath is ""
      @graphpath = "M#{x},#{y}"
      @graphpath += "m0,#{(-1*@population)/line.y_unit.per_pixel}"
      @graphpath += "l#{dgen/line.x_unit.per_pixel},#{dpop/line.y_unit.per_pixel}"
    else
      @graphpath += "l#{dgen/line.x_unit.per_pixel},#{dpop/line.y_unit.per_pixel}"
      
    @graph.computer_graph.attr
      path: @graphpath
    line.add_point x, y, @graph
    p = line.find_point_at x
    line.add_freehand_line p, @graphpath

  step: =>
    if @simulating and @generation < @maximum_generation
      @generation++
      newpop = @next_configuration()
      dpop = newpop - @population
      @population = newpop
      @update_configuration()
      @update_graph 1, dpop

      @update_labels()
    else
      @simulating = false
      clearInterval @id
      @simulation.deselect 'step'



  # utility methods

  draw: ->
    @draw_buttons()
    y = @y + @PADDING + @BUTTON_WIDTH + @SIM_SEP

    label_format =
      'font-family': 'sans-serif'
      'font-size': '16pt'
      'text-anchor': 'end'
    label_label_format =
      'font-family': 'sans-serif'
      'font-size': '16pt'
      'text-anchor': 'start'

    generation_label_label = @paper.text @x + @PADDING, y, "generatie :"
    generation_label_label.attr label_label_format
    tllbb = generation_label_label.getBBox()
    population_label_y = y + tllbb.height + @LABEL_SEP
    population_label_label = @paper.text @x + @PADDING, population_label_y, "populatie :"
    population_label_label.attr label_label_format
    dllbb = population_label_label.getBBox()

    @generation_label = @paper.text @x, y, "88888"
    @generation_label.attr label_format
    tlbb = @generation_label.getBBox()
    generation_label_x = @x + @PADDING + dllbb.width + @LABEL_SEP + tlbb.width
    @generation_label.attr
      x: generation_label_x
    @population_label = @paper.text generation_label_x, population_label_y, "330000"
    @population_label.attr label_format

    unit_x = generation_label_x + @LABEL_SEP
    generation_unit_label = @paper.text unit_x, y, ""
    generation_unit_label.attr label_label_format
    population_unit_label = @paper.text unit_x, population_label_y, "bacteriën"
    population_unit_label.attr label_label_format



    @configuration_view = @generate_configuration @config.width, @config.height
    y = dllbb.y2 + @SIM_SEP
    x = @PADDING
    @CELL_WIDTH = 10
    @CELL_SEP = 0.5
    for row in [0...@config.height]
      x = @PADDING
      for col in [0...@config.width]
        cell = @paper.rect x, y, @CELL_WIDTH, @CELL_WIDTH
        cell.attr
          fill: 'white'
          stroke: 'silver'
        @configuration_view[row][col] = cell
        x += @CELL_WIDTH + @CELL_SEP
      y += @CELL_WIDTH + @CELL_SEP

    @width = x - @x + 2*@PADDING

    @update_configuration()




  draw_buttons: ->
    x = @x + @PADDING
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


