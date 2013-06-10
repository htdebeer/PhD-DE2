###
(c) 2012, Huub de Beer, H.T.de.Beer@gmail.com
###

class WMeasureLine extends Widget
  
  constructor: (@canvas, @x, @y, @ml, @foot, @spec = {}) ->
    super @canvas, @x, @y, @spec
    @_draw()

    if @ml.movable
      @widgets.mouseover (e) =>
        @border.attr
          fill: 'gold'
          'fill-opacity': 0.25
          'stroke-opacity': 0.75
          cursor: 'move'
      @widgets.mouseout (e) =>
        @border.attr
          'stroke-opacity': 0
          cursor: 'default'
          fill: 'white'
          'fill-opacity': 0
      @widgets.drag @drag, @start, @end

  drag: (dx, dy, x, y, e) =>
    tx = Math.floor(dx - @dpo.x)
    ty = Math.floor(dy - @dpo.y)
    
    @x += tx
    @y += ty
    @widgets.transform "...t#{tx},#{ty}"
    @dpo =
      x: dx
      y: dy
    @_compute_geometry()
    @ml.position.x = @x
    @ml.position.y = @y
    @ml.glass.change_measure_line @ml.volume, (@foot - @y) / @ml.glass.unit

  show: ->
    @widgets.show()

  hide: ->
    @widgets.hide()


  start: =>
    @dpo = @dpo ? {}
    @dpo =
      x: 0
      y: 0
    @border.attr
      'fill': 'gold'
      'fill-opacity': 0.05
      
  end: =>
    @border.attr
      'fill': 'white'
      'fill-opacity': 0

  _draw: () ->
    TICKWIDTH = @spec['thickwidth'] ? 10
    LABELSKIP = @spec['labelskip'] ? 5
    BENDINESS = 6

    @bend = @spec.bend ? false
    switch @ml.side
      when 'right'
        if @bend
          tickpath = "M#{@ml.position.x},#{@ml.position.y}c0,#{2},-#{BENDINESS},#{BENDINESS},-#{TICKWIDTH},#{BENDINESS}"
        else
          tickpath = "M#{@ml.position.x},#{@ml.position.y}h-#{TICKWIDTH}"
        tick = @canvas.path tickpath
        label = @canvas.text 0, 0, "#{@ml.volume} ml"
        # determine the position of the label
        label.attr
          'font-family': @spec['font-family'] ? 'sans-serif'
          'font-size': @spec['font-size'] ? 12
          'text-anchor': 'start'
        bbox = label.getBBox()
        labelleft = @ml.position.x - LABELSKIP - bbox.width - TICKWIDTH
        if @bend
          # if the mls are bended (3d), place the labels somewhat lower
          label.attr
            x: labelleft
            y: @ml.position.y + BENDINESS
        else
          label.attr
            x: labelleft
            y: @ml.position.y
        bbox = label.getBBox()
        @border = @canvas.rect bbox.x, bbox.y, bbox.width + TICKWIDTH, bbox.height
        @border.attr
          stroke: 'black'
          fill: 'white'
          'fill-opacity': 0
          'stroke-opacity': 0
          'stroke-dasharray': '. '
      when 'left'
        tickpath = "M#{@ml.position.x},#{@ml.position.y}h#{TICKWIDTH}"
        

    

    @widgets.push tick, label, @border
    bbox = @widgets.getBBox()
    @width = bbox.width
    @height = bbox.height
    #@widgets.hide() unless @ml.visible


# export WMeasureLine
window.WMeasureLine = WMeasureLine
