###

(c) 2012, Huub de Beer, H.T.de.Beer@gmail.com

###
class Widget

  constructor: (@canvas, @x, @y, @spec = {}) ->
    @widgets = @canvas.set()
    # at then end of drawing a widget, push a glasspane on top
    @dx = @dy = 0
    @selected = false

  remove: ->
    @widgets.remove()

  start_selectable: (@slot) =>
    @glasspane.mouseover @enable_selectable
    @glasspane.mouseout @disable_selectable

  stop_selectable: =>
    @glasspane.unmouseover @enable_selectable
    @glasspane.unmouseout @disable_selectable

  enable_selectable: =>
    @glasspane.dblclick @select

  disable_selectable: =>
    @glasspane.undblclick @select

  select: =>
    if @selected
      @selected = false
      @slot.selected = null
      @disable_draggable()
      @glasspane.attr 'stroke-opacity', 0
    else
      @selected = true
      if @slot?.selected
        @slot.selected.select()
      @slot.selected = @
      @widgets.toFront()
      @enable_draggable()
      @glasspane.attr 'stroke-opacity', 0.5

  start_draggable: =>
    @glasspane.mouseover @enable_draggable
    @glasspane.mouseout @disable_draggable

  stop_draggable: =>
    @glasspane.unmouseover @enable_draggable
    @glasspane.unmouseout @disable_draggable

  drag_start: =>
    @dpo = @dpo ? {}
    @dpo =
      x: 0
      y: 0

  drag_end: =>

  drag_move: (dx, dy, x, y, e) =>
    tx = Math.floor(dx - @dpo.x)
    ty = Math.floor(dy - @dpo.y)
    
    @x += tx
    @y += ty
    @widgets.transform "...t#{tx},#{ty}"
    @dpo =
      x: dx
      y: dy
  

  enable_draggable: =>
    @widgets.attr 'cursor', 'move'
    @widgets.drag @drag_move, @drag_start, @drag_end


  disable_draggable: =>
    @widgets.attr 'cursor', 'default'
    @widgets.undrag()

  hide: ->
    @widgets.hide()

  show: ->
    @widgets.show()
    
  place_at: (x, y) ->
    ###
    Place this widget at co-ordinates x an y
    ###
    @_compute_geometry()
    @dx = x - @geometry.left
    @dy = y - @geometry.top
    @widgets.transform "...t#{@dx},#{@dy}"
    @x = x
    @y = y
    @_compute_geometry()
    @
  

  fit_point: (x, y) ->
    point =
      x: x - @canvas.canvas.parentNode.offsetLeft
      y: y - @canvas.canvas.parentNode.offsetTop
    point

  _draw: () ->
    ###
    Draw this widget. Virtual method to be overloaded by all subclasses of 
    Widget. All shapes drawn are added to the list of widgets
    ###

  _compute_geometry: () ->
    ###
    Compute the left, top, bottom, right, width, height, and center of this 
    widget given its top-left corner (x, y). 
    
    This does not work with paths that do not start at (0,0)


    ###
    bbox = @widgets.getBBox()
    @geometry = {}
    @geometry.width = bbox.width
    @geometry.height = bbox.height
    @geometry.top = bbox.y
    @geometry.left = bbox.x
    @geometry.right = bbox.x2
    @geometry.bottom = bbox.y2
    @geometry.center =
      x: (@geometry.right - @geometry.left) / 2 + @geometry.left
      y: (@geometry.bottom - @geometry.top) / 2 + @geometry.top


module.exports = Widget
