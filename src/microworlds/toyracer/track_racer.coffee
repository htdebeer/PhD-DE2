# 
# filler.coffee (c) 2012 HT de Beer
#
# simulation of filling a glass and creating a measuring cup
#
window.TrackRacer = class
  
  initialize_properties: (properties) ->
    # Initialize properties with properties or default values
    p = {}
    p.components = properties?.components ? ['racer', 'graph']
    p.editable = properties?.editable ? true
    p.icon_path = properties?.icon_path ? 'lib/icons'
    p.speed = properties?.speed ? 15
    p.graph_buttons = properties?.graph_buttons ? ['normal', 'point', 'straight', 'curve', 'remove', 'raster', 'delta']
    p.computer_graph = properties?.computer_graph ? true
    p

  constructor: (@paper, @x, @y, @track, @width, @height, properties) ->
    @spec = @initialize_properties(properties)

    @PADDING = 2
    @RACER_SEP = 50
    @RACER_X = @x + @PADDING
    @RACER_Y = @y + @PADDING

    

    @draw()

  draw: ->
    @racer = new CoffeeGrounds.Racer @paper,
      @RACER_X,
      @RACER_Y,
      @track,
      {},
        icon_path: @spec.icon_path

    @GRAPH_X = @RACER_X + @racer.width + @RACER_SEP
    @GRAPH_Y = @y + @PADDING
  

    if 'graph' in @spec.components
      @GRAPH_SEP = 50
      @GRAPH_GRAPH_SEP = 15
      @GRAPH_PADDING = 2
      @GRAPH_AXIS_WIDTH = 40
      @GRAPH_BUTTON_WIDTH = 34

      @GRAPHER_HEIGHT = @height - @PADDING
      @GRAPHER_WIDTH = @width - @racer.width - @RACER_SEP - @PADDING

      # determine the axes
      time = @racer.maximum_time*1.1
      distance = @racer.maximum_distance*1.4

      @GRAPH_WIDTH = @GRAPHER_WIDTH - 2*@GRAPH_PADDING - @GRAPH_AXIS_WIDTH
      @GRAPH_HEIGHT = @GRAPHER_HEIGHT - @GRAPH_BUTTON_WIDTH - @GRAPH_AXIS_WIDTH - @GRAPH_GRAPH_SEP - 2*@GRAPH_PADDING


      time_per_pixel = time / @GRAPH_WIDTH
      pixels_per_meter = @GRAPH_HEIGHT / distance
      meter_per_pixel = distance / @GRAPH_HEIGHT

      distancestep_candidate =  distance / 15
      distanceticks = [0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000]
      distancestep_i = 0
      while distancestep_i < distanceticks.length and distanceticks[distancestep_i] <= distancestep_candidate
        distancestep_i++

      distancestep = distanceticks[distancestep_i - 1]
      distancetickspath = "#{distancestep}tL"


      timestep_candidate = time / (@GRAPH_WIDTH / (pixels_per_meter*distancestep))

      timeticks = [0.05, 0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000]
      timestep_i = 0
      while timestep_i < timeticks.length and timeticks[timestep_i] <= timestep_candidate
        timestep_i++
      
      timetickspath = "#{timeticks[timestep_i - 1]}tL"



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
          label: "afstand (m)"
          raster: true
          unit:
            per_pixel: 1/pixels_per_meter
            symbol: "m"
            quantity: "afstand"
          max: distance
          tickspath: distancetickspath
          orientation: 'vertical'
        buttons: @spec.graph_buttons
        computer_graph: @spec.computer_graph
        editable: @spec.editable
        icon_path: @spec.icon_path

      @racer.set_graph @graph
    # The tap wants a computergraph representation, so, if there is no
    # graphing component give it an empty path.
    #@computer_graph = @graph?.computer_graph ? null
    
