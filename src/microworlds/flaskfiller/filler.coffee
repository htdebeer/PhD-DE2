# 
# filler.coffee (c) 2012 HT de Beer
#
# simulation of filling a glass and creating a measuring cup
#
window.Filler = class
  
  initialize_properties: (properties) ->
    # Initialize properties with properties or default values
    p = {}
    p.components = properties?.components ? ['tap', 'ruler', 'graph']
    p.time = properties?.time ? true
    p.buttons = properties?.buttons ? ['show_graph']
    p.editable = properties?.editable ? true
    p.icon_path = properties?.icon_path ? 'lib/icons'
    p.fillable = properties?.fillable ? true
    p.speed = properties?.speed ? 15
    p.graph_buttons = properties?.graph_buttons ? ['normal', 'point', 'straight', 'curve', 'remove', 'raster']
    p.computer_graph = properties?.computer_graph ? true
    p.time_graph = properties?.time_graph ? true
    p.speed_graph = properties?.speed_graph ? false
    p.diff_graph = properties?.diff_graph ? false
    p.hide_all_except_graph = properties?.hide_all_except_graph ? false
    p

  get_glass: ->
    @glass


  fit_point: (x, y) ->
    point =
      x: x - @paper.canvas.parentNode.offsetLeft
      y: y - @paper.canvas.parentNode.offsetTop
    point

  constructor: (@paper, @x, @y, @glass, @width, @height, properties) ->
    @spec = @initialize_properties(properties)

    @PADDING = 2
    @BUTTON_SEP = 5
    @BUTTON_WIDTH = 34
    CoffeeGrounds.Button.set_width @BUTTON_WIDTH
    @BUTTON_X = @x + @PADDING
    @BUTTON_Y = @y + @PADDING
    CoffeeGrounds.Button.set_base_path @spec.icon_path
    @GROUP_SEP = 15

    
    if 'tap' in @spec.components
      @TAP_SEP = 10
      @TAP_HEIGHT = 150
      @spec.buttons_orientation = 'vertical'
    else
      @TAP_SEP = @BUTTON_SEP
      @TAP_HEIGHT = @BUTTON_WIDTH
      @spec.buttons_orientation = 'horizontal'

    if 'ruler' in @spec.components
      @RULER_WIDTH = 50
      @RULER_SEP = 25
      @RULER_X = @x + @PADDING
      @RULER_Y = @y + @PADDING + @TAP_HEIGHT + @RULER_SEP
    else
      # no ruler
      @RULER_WIDTH = 0
      @RULER_SEP = 0
      @RULER_X = 0
      @RULER_Y = 0


    @GLASS_SEP = 50
    @GLASS_X = @x + @PADDING + @RULER_SEP + @RULER_WIDTH
    @GLASS_Y = @y + @PADDING + @TAP_HEIGHT + @GLASS_SEP


    @actions =
      manual_diff:
        button:
          type: 'switch'
          group: 'components'
          icon: 'draw-triangle'
          tooltip: 'Meet snelheid met een longdrink glas'
          switched_on: false
          on_switch_on: =>
            @differentiate_tool()
          on_switch_off: =>
            @differentiate_tool()

    @diff_tool = true
    @draw()

  differentiate_tool: =>
    if @diff_tool
      @glass_representation.stop_manual_diff()
      @diff_tool = false
    else
      @glass_representation.start_manual_diff()
      @diff_tool = true

  draw: ->
  
    @glass_representation = new WContourGlass @paper, @GLASS_X, @GLASS_Y, @glass,
      diff_graph: @spec.diff_graph
   
    @GLASS_HEIGHT = @glass_representation.geometry.height
    @GLASS_WIDTH = @glass_representation.geometry.width

    @RULER_EXTRA = (@GLASS_SEP - @RULER_SEP) * (@glass.height_in_mm/@GLASS_HEIGHT)
    if 'ruler' in @spec.components
      @ruler = new WVerticalRuler @paper, @RULER_X, @RULER_Y, @RULER_WIDTH,
        @GLASS_HEIGHT + @RULER_SEP,
        @glass.height_in_mm + @RULER_EXTRA,
          {'measure_line_width': @GLASS_WIDTH + @RULER_SEP*2 + @RULER_WIDTH}

    if 'graph' in @spec.components
      @GRAPH_SEP = 50
      @GRAPH_GRAPH_SEP = 15
      @GRAPH_PADDING = 2
      @GRAPH_AXIS_WIDTH = 40
      @GRAPH_BUTTON_WIDTH = 34
      @GRAPH_X = @GLASS_X + @GLASS_WIDTH + @GRAPH_SEP
      @GRAPH_Y = @RULER_Y - @BUTTON_WIDTH - @GRAPH_GRAPH_SEP - @GRAPH_PADDING
      @GRAPH_HEIGHT = @GLASS_HEIGHT + (@GLASS_SEP - @RULER_SEP) + @GRAPH_PADDING*2 + @GRAPH_BUTTON_WIDTH + @GRAPH_AXIS_WIDTH + @GRAPH_GRAPH_SEP

      if @spec.time_graph
        # determine the time axis
        time = (@glass.maximum_volume * 1.1)/ @spec.speed
        @GRAPHER_WIDTH = 450
        @GRAPH_WIDTH = @GRAPHER_WIDTH - 2*@GRAPH_PADDING - @GRAPH_AXIS_WIDTH
        time_per_pixel = time / @GRAPH_WIDTH
        pixels_per_cm = @glass.unit*Glass.TENTH_OF_MM
        timestep_candidate = time / (@GRAPH_WIDTH / pixels_per_cm)

        timeticks = [0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000]
        timestep_i = 0
        while timestep_i < timeticks.length and timeticks[timestep_i] <= timestep_candidate
          timestep_i++
        
#      volstep = if volstep_i > 1 then (volticks[volstep_i - 1]/2).toFixed(1) else 0.5
#      ^^ nicer but not with a raster
        timetickspath = "#{timeticks[timestep_i - 1]}tL"
        
        #vol_per_pixel = 0.5

        @graph = new Graph @paper, @GRAPH_X, @GRAPH_Y, @GRAPHER_WIDTH, @GRAPH_HEIGHT,
          x_axis:
            label: "tijd (sec)"
            raster: true
            unit:
              per_pixel: time_per_pixel
              symbol: "sec"
              quantity: "tijd"
            max: time
            tickspath: timetickspath
            orientation: 'horizontal'
          y_axis:
            label: "hoogte (cm)"
            raster: true
            unit:
              per_pixel: (0.1/@glass.unit)
              symbol: "cm"
              quantity: "hoogte"
            max: @glass.height_in_mm + @RULER_EXTRA
            tickspath: "0.5tL"
            orientation: 'vertical'
          buttons: @spec.graph_buttons
          computer_graph: @spec.computer_graph
          editable: @spec.editable
          icon_path: @spec.icon_path

        @glass.create_graph(@paper, @graph.computer_graph, @graph.computer_line, 'time', @spec.speed)

      else if @spec.speed_graph

        # determine speed axis
        speed = @glass.maximum_speed * 1.10
        @GRAPHER_HEIGHT  = @GRAPH_HEIGHT - 2*@GRAPH_PADDING - @GRAPH_BUTTON_WIDTH - @GRAPH_AXIS_WIDTH - @GRAPH_GRAPH_SEP
        speed_per_pixel = speed / @GRAPHER_HEIGHT

        speedstep_candidate = speed / 10
        speedticks = [0.001, 0.002, 0.005, 0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1, 2, 5, 10]
        speedstep_i = 0
        while speedstep_i < speedticks.length and speedticks[speedstep_i] <= speedstep_candidate
          speedstep_i++
        
#      speedstep = if speedstep_i > 1 then (speedticks[speedstep_i - 1]/2).toFixed(1) else 0.5
#      ^^ nicer but not with a raster
        speedtickspath = "#{speedticks[speedstep_i - 1]}tL"

        # determine the volume axis
        vol = @glass.maximum_volume * 1.10
        @GRAPHER_WIDTH = 450
        @GRAPH_WIDTH = @GRAPHER_WIDTH - 2*@GRAPH_PADDING - @GRAPH_AXIS_WIDTH
        vol_per_pixel = vol / @GRAPH_WIDTH
        pixels_per_cm = @glass.unit*Glass.TENTH_OF_MM
        volstep_candidate = vol / 15

        volticks = [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000]
        volstep_i = 0
        while volstep_i < volticks.length and volticks[volstep_i] <= volstep_candidate
          volstep_i++
        
#      volstep = if volstep_i > 1 then (volticks[volstep_i - 1]/2).toFixed(1) else 0.5
#      ^^ nicer but not with a raster
        voltickspath = "#{volticks[volstep_i - 1]}tL"
        
        #vol_per_pixel = 0.5

        @graph = new Graph @paper, @GRAPH_X, @GRAPH_Y, @GRAPHER_WIDTH, @GRAPH_HEIGHT,
          x_axis:
            label: "volume (ml)"
            raster: true
            unit:
              per_pixel: vol_per_pixel
              symbol: "ml"
              quantity: "volume"
            max: vol
            tickspath: voltickspath
            orientation: 'horizontal'
          y_axis:
            label: "stijgsnelheid (cm/ml)"
            raster: true
            unit:
              per_pixel: speed_per_pixel
              symbol: "cm/ml"
              quantity: "stijgsnelheid"
            max: speed
            tickspath: speedtickspath
            orientation: 'vertical'
          buttons: @spec.graph_buttons
          computer_graph: @spec.computer_graph
          editable: @spec.editable
          icon_path: @spec.icon_path

        @glass.create_graph(@paper, @graph.computer_graph, @graph.computer_line, 'vol', true)

      else
        # determine the volume axis
        vol = @glass.maximum_volume * 1.10
        @GRAPHER_WIDTH = 450
        @GRAPH_WIDTH = @GRAPHER_WIDTH - 2*@GRAPH_PADDING - @GRAPH_AXIS_WIDTH
        vol_per_pixel = vol / @GRAPH_WIDTH
        pixels_per_cm = @glass.unit*Glass.TENTH_OF_MM
        volstep_candidate = vol / (@GRAPH_WIDTH / pixels_per_cm)

        volticks = [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000]
        volstep_i = 0
        while volstep_i < volticks.length and volticks[volstep_i] <= volstep_candidate
          volstep_i++
        
#      volstep = if volstep_i > 1 then (volticks[volstep_i - 1]/2).toFixed(1) else 0.5
#      ^^ nicer but not with a raster
        voltickspath = "#{volticks[volstep_i - 1]}tL"
        
        #vol_per_pixel = 0.5

        @graph = new Graph @paper, @GRAPH_X, @GRAPH_Y, @GRAPHER_WIDTH, @GRAPH_HEIGHT,
          x_axis:
            label: "volume (ml)"
            raster: true
            unit:
              per_pixel: vol_per_pixel
              symbol: "ml"
              quantity: "volume"
            max: vol
            tickspath: voltickspath
            orientation: 'horizontal'
          y_axis:
            label: "hoogte (cm)"
            raster: true
            unit:
              per_pixel: (0.1/@glass.unit)
              symbol: "cm"
              quantity: "hoogte"
            max: @glass.height_in_mm + @RULER_EXTRA
            tickspath: "0.5tL"
            orientation: 'vertical'
          buttons: @spec.graph_buttons
          computer_graph: @spec.computer_graph
          editable: @spec.editable
          icon_path: @spec.icon_path

        @glass.create_graph(@paper, @graph.computer_graph, @graph.computer_line, 'vol')

    # The tap wants a computergraph representation, so, if there is no
    # graphing component give it an empty path.
    @computer_graph = @graph?.computer_graph ? null
    if @spec.diff_graph
      # add the graph to the glass representation as to allow for
      # differentation on glass and grpah at the same time
      @glass_representation.set_graph @graph
    
    if 'tap' in @spec.components
      stream_extra = @GLASS_SEP - 5
      MID_MOVE = 10
      @tap = new CoffeeGrounds.Tap  @paper, @GLASS_X + @GLASS_WIDTH/2 - MID_MOVE, @y, @glass, @computer_graph, {
        glass_to_fill: @glass_representation
        time: @spec.time
        runnable: @spec.fillable
        speed: @spec.speed
        stream_extra: stream_extra
        icon_path: @spec.icon_path
      }



    @draw_buttons()

    if @spec.hide_all_except_graph
      # hide all except the graph
      cover = @paper.rect @x - 5, @y - 5, @GRAPH_X - @x, @height
      cover.attr
        fill: 'white'
        stroke: 'white'

  draw_buttons:  ->
    x = @BUTTON_X
    y = @BUTTON_Y
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
          if @spec.buttons_orientation is 'horizontal'
            if button.group is group
              x += @BUTTON_WIDTH + @BUTTON_SEP
            else
              x += @BUTTON_WIDTH + @GROUP_SEP
          else
            if button.group is group
              y += @BUTTON_WIDTH + @BUTTON_SEP
            else
              y += @BUTTON_WIDTH + @GROUP_SEP
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
      for button in buttongroup.buttons
        @buttons[button.value] = button



