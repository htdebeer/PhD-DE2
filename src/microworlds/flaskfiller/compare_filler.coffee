# 
# compare_filler.coffee (c) 2012 HT de Beer
#
# simulation of filling a glasses while comparing them
#
window.CompareFiller = class
  
  initialize_properties: (properties) ->
    # Initialize properties with properties or default values
    p = {}
    p.dimension = properties?.dimension ? '2d'
    p.time = properties?.time ? false
    p.icon_path = properties?.icon_path ? 'lib/icons'
    p.fillable = properties?.fillable ? true
    p

  get_glass: ->
    @glass

  start: ->
    for glass in @glasses
      glass.tap.start()
      glass.tap.simulation.select 'play'

  empty: ->
    for glass in @glasses
      glass.tap.empty()
      glass.tap.simulation.select 'start'

  pause: ->
    for glass in @glasses
      glass.tap.pause()
      glass.tap.simulation.select 'pause'
  
  full: ->
    for glass in @glasses
      glass.tap.full()
      glass.tap.simulation.select 'end'

  fit_point: (x, y) ->
    point =
      x: x - @paper.canvas.parentNode.offsetLeft
      y: y - @paper.canvas.parentNode.offsetTop
    point

  constructor: (@paper, @x, @y, @glasses, @width, @height, properties) ->
    @spec = @initialize_properties(properties)

    @PADDING = 2
    
    @TAP_SEP = 10
    @TAP_HEIGHT = 150

    @RULER_WIDTH = 50
    @RULER_SEP = 25
    @RULER_X = @x + @PADDING
    @RULER_Y = @y + @PADDING + @TAP_HEIGHT + @RULER_SEP


    @GLASS_SEP = 50
    @GLASS_X = @x + @PADDING + @RULER_SEP + @RULER_WIDTH
    @GLASS_Y = @y + @PADDING + @TAP_HEIGHT + @GLASS_SEP

    @COMPARE_SEP = 75

    @draw()
    
  draw: ->
    x = @x + @PADDING
    y = @y + @PADDING + @TAP_HEIGHT + @GLASS_SEP

    # Find largest glass (height)
    max_height = 0 # in mm
    max_glass_height = 0 # in px
    for glass in @glasses
      max_height = Math.max max_height, glass.model.height_in_mm
      glass.glass_height = glass.model.foot.y - glass.model.edge.y
      max_glass_height = Math.max max_glass_height, glass.glass_height

    # draw all glasses; compute total width
    total_width = 0
    for glass in @glasses
      glass_x = x + @RULER_WIDTH + @RULER_SEP
      glass_y = y + (max_glass_height - glass.glass_height)

      glass_representation = new WContourGlass @paper, glass_x, glass_y, glass.model
      glass_height = glass_representation.geometry.height
      glass_width = glass_representation.geometry.width

      
      MID_MOVE = 10
      stream_extra = Math.abs(glass.glass_height-max_glass_height) + @GLASS_SEP - 7
      tap = new CoffeeGrounds.Tap @paper,
        glass_x + glass_width/2 - MID_MOVE,
        @y + @PADDING,
        glass.model,
        null,
          speed: glass.speed
          glass_to_fill: glass_representation
          time: glass.time
          runnable: glass.runnable
          icon_path: @spec.icon_path
          stream_extra: stream_extra
     
      x += glass_width + @COMPARE_SEP
      total_width += glass_width + @COMPARE_SEP

      glass.tap = tap


    # Put in one ruler to rule them all
    ruler_extra = (@GLASS_SEP - @RULER_SEP) * (max_height/max_glass_height)
    ruler = new WVerticalRuler @paper,
      @RULER_X,
      @RULER_Y,
      @RULER_WIDTH,
      max_glass_height + @RULER_SEP,
      max_height + ruler_extra,
        'measure_line_width': total_width + @RULER_SEP*2 + @RULER_WIDTH
