# 
# life_simulator.coffee (c) 2012 HT de Beer
#
# simulation of the game of life with graph of population and generation
#
window.LifeSimulator = class
  
  initialize_properties: (properties) ->
    # Initialize properties with properties or default values
    p = {}
    p.components = properties?.components ? ['life', 'graph']
    p.editable = properties?.editable ? true
    p.icon_path = properties?.icon_path ? 'lib/icons'
    p.speed = properties?.speed ? 25
    p.graph_buttons = properties?.graph_buttons ? ['normal', 'point', 'straight', 'curve', 'remove', 'raster', 'delta']
    p.computer_graph = properties?.computer_graph ? true
    p

  constructor: (@paper, @x, @y, @config, @width, @height, properties) ->
    @spec = @initialize_properties(properties)

    @PADDING = 2
    @LIFE_SEP = 50
    @LIFE_X = @x + @PADDING
    @LIFE_Y = @y + @PADDING

    

    @draw()

  draw: ->
    @life = new CoffeeGrounds.Life @paper,
      @LIFE_X,
      @LIFE_Y,
      @config,
      {},
        icon_path: @spec.icon_path

    @GRAPH_X = @LIFE_X + @life.width + @LIFE_SEP
    @GRAPH_Y = @y + @PADDING
  

    if 'graph' in @spec.components
      @GRAPH_SEP = 50
      @GRAPH_GRAPH_SEP = 15
      @GRAPH_PADDING = 2
      @GRAPH_AXIS_WIDTH = 40
      @GRAPH_BUTTON_WIDTH = 34

      @GRAPHER_HEIGHT = @height - @PADDING
      @GRAPHER_WIDTH = @width - @life.width - @LIFE_SEP - @PADDING

      # determine the axes
      generation = Math.floor(@life.maximum_generation*1.15)
      population = Math.floor(@life.maximum_population*0.7)

      @GRAPH_WIDTH = @GRAPHER_WIDTH - 2*@GRAPH_PADDING - @GRAPH_AXIS_WIDTH
      @GRAPH_HEIGHT = @GRAPHER_HEIGHT - @GRAPH_BUTTON_WIDTH - @GRAPH_AXIS_WIDTH - @GRAPH_GRAPH_SEP - 2*@GRAPH_PADDING


      generation_per_pixel = generation / @GRAPH_WIDTH
      pixels_per_aantal = @GRAPH_HEIGHT / population
      aantal_per_pixel = population / @GRAPH_HEIGHT

      populationstep_candidate =  population / 15
      populationticks = [1, 5, 10, 20, 50, 100, 200, 500, 1000]
      populationstep_i = 0
      while populationstep_i < populationticks.length and populationticks[populationstep_i] <= populationstep_candidate
        populationstep_i++

      populationstep = populationticks[populationstep_i - 1]
      populationtickspath = "#{populationstep}tL"


      generationstep_candidate = generation / (@GRAPH_WIDTH / (pixels_per_aantal*populationstep*2))

      generationticks = [1, 5, 10, 20, 50, 100, 200, 500, 1000]
      generationstep_i = 0
      while generationstep_i < generationticks.length and generationticks[generationstep_i] <= generationstep_candidate
        generationstep_i++
      
      generationtickspath = "#{generationticks[generationstep_i - 1]}tL"




      @graph = new Graph @paper, @GRAPH_X, @GRAPH_Y, @GRAPHER_WIDTH, @GRAPH_HEIGHT,
        x_axis:
          label: "generaties (aantal)"
          raster: true
          unit:
            per_pixel: generation_per_pixel
            symbol: "aantal"
            quantity: "generatie"
          max: generation
          tickspath: generationtickspath
          orientation: 'horizontal'
        y_axis:
          label: "populatie (aantal bacteriën)"
          raster: true
          unit:
            per_pixel: 1/pixels_per_aantal
            symbol: "aantal"
            quantity: "populatie"
          max: population
          tickspath: populationtickspath
          orientation: 'vertical'
        buttons: @spec.graph_buttons
        computer_graph: @spec.computer_graph
        editable: @spec.editable
        icon_path: @spec.icon_path

      @life.set_graph @graph
    # The tap wants a computergraph representation, so, if there is no
    # graphing component give it an empty path.
    #@computer_graph = @graph?.computer_graph ? null
    
