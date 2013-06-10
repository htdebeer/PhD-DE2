#
# point -- a graphical representation of a point
#
#
Point = class

  constructor: (@canvas, @x, @y, properties = {}) ->
    @properties = defineProperties properties
    @view = {}
    @draw @properties.size
    @highlighted = false
    @view.mouseover @highlight
    @view.mouseout @highlight
    @line = {}

    @view.drag @move, @startdrag, @stopdrag

  defineProperties = (in_properties) ->
    out_properties = {}
    out_properties.shape = in_properties.shape ? 'circle'
    out_properties.color = in_properties.color ? 'black'
    out_properties.size = in_properties.size ? 5
    out_properties.highlight = in_properties.highlight ? 'red'
    out_properties


  set_line: (@line) ->

  remove_line: (line) ->
    @lines.delete line

  toFront: ->
    @view.toFront()

  make_draggable: ->
    @view.drag @move, @startdrag, @stopdrag

  make_undraggable: ->
    @highlighted = false
    @view.attr
      fill: @properties.color
    @view.undrag()

  show: ->
    @view.show()

  hide: ->
    @view.hide()

  highlight: =>
    #console.log "over"
    if @highlighted
      @view.attr
        fill: @properties.color
      @highlighted = false
    else
      @view.attr
        fill: @properties.highlight
      @highlighted = true
        

  move: (dx, dy, x, y, e) =>
    tx = dx - @ox
    ty = dy - @oy
    @ox = dx
    @oy = dy
    @x += tx
    @y += ty
    # use the ... before translate, otherwise it doesn't work ... (WTF?)
    # Apparently the ... prepends or appends transformations: adding to the
    # already existing ones.
    @view.transform "...T#{tx},#{ty}"
    @line.x += tx
    @line.y += ty

  startdrag: (x, y, e) =>
    @ox = 0
    @oy = 0
    @view.attr
      'fill-opacity': 0.5

  stopdrag: (x, y, e) =>
    @view.attr
      'fill-opacity': 1



  draw: (size)->
    radius = size / 2
    switch @properties.shape
      when 'circle'
        @view = @canvas.circle @x, @y, radius
      when 'rect'
        x = @x - radius
        y = @y - radius
        @view = @canvas.rect x, y, size, size

    @view.attr
      fill: @properties.color
      stroke: @properties.color
      'stroke-width': radius*2
      'stroke-opacity': 0
      

    
module.exports = Point
