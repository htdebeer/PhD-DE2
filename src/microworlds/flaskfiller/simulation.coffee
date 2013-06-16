
Glass = require '../../widgets/glass/glass'
WGlass = require '../../widgets/glass/wglass'
WVerticalRuler = require '../../widgets/ruler/wvertical_ruler'
WHorizontalRuler = require '../../widgets/ruler/whorizontal_ruler'

class Simulation

  constructor: (@flaskfiller, container, @config) ->

    @selected = {selected: null}

    WIDTH = 750
    HEIGHT = 650
    RULER_WIDTH = 30
    RULER_LENGTH = HEIGHT - RULER_WIDTH
    MM_RULER = 190

    @simulation_container = container.append('figure')
      .attr('id', 'simulation')

    @canvas = Raphael 'simulation', WIDTH, HEIGHT
    console.log "sdsdf"

    
    @glasses = []
    for glass in @config.glasses
      @add_glass glass

    vruler = new WVerticalRuler @canvas,
      0,
      0,
      RULER_WIDTH,
      RULER_LENGTH,
      MM_RULER
    hruler = new WHorizontalRuler @canvas,
      RULER_WIDTH,
      RULER_LENGTH,
      RULER_LENGTH,
      RULER_WIDTH,
      MM_RULER


  add_glass: (glass) ->
    wglass = new WGlass @canvas, 0, 0, glass.glass,
      fill: glass.color
    wglass.start_selectable( @selected )
    glass.representation = wglass
    @glasses.push glass

  remove_glass: (glass) ->
    glass.representation.remove()
    @glasses.splice @glasses.indexOf(glass), 1
    
    
    

module.exports = Simulation
