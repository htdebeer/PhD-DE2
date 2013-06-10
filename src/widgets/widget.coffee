###

(c) 2012, Huub de Beer, H.T.de.Beer@gmail.com

###
class Widget

  constructor: (@canvas, @x, @y, @spec = {}) ->
    @widgets = @canvas.set()
    @dx = @dy = 0
    
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
