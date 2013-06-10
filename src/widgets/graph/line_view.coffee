#
# line is a double linked list of line segments. Line segments are either
# straight, a curve, or an "empty" line denoting a point or movement
#
Line = class

  defineProperties = (inp) ->
    outp = {}

    outp.background_color = inp.background ? 'white'
    outp.background_opacity = inp.background_opacity ? 0

    outp.line = {}
    outp.line.width = inp.line_width ? 1
    outp.line.color = inp.line_color ? 'black'
    outp.line.color_selected = inp.line_color_selected ? 'orange'
    outp.line.color_highlighted = inp.line_color_highlighted ? 'red'
    outp.line.dash = inp.line_dash ? ''

    outp.point = {}
    outp.point.size = inp.point_size ? 5
    outp.point.shape = inp.point_shape ? 'circle'
    outp.point.color = inp.point_color ? 'black'
    outp.point.color_selected = inp.point_color_selected ? 'orange'
    outp.point.color_highlighted = inp.point_color_highlighted ? 'red'

    outp.control = {}
    outp.control.size = inp.control_size ? 5
    outp.control.shape = inp.control_shape ? 'rect'
    outp.control.color = inp.control_color ? 'green'
    outp.control.color_selected = inp.control_color_selected ? 'green'
    outp.control.color_highlighted = inp.control_color_highlighted ? 'blue'

    outp

  constructor: (@canvas, @x, @y, @width, @height, properties = {}) ->
    @prop = defineProperties properties
    @points = []
    @segments = []
    @container = @canvas.set()
    @draw()

    @temp_line = @canvas.path "M0,0"

    @container.mousedown @add_start_point

  add_start_point: (e, x, y) =>
    @new_point = new CoffeeGrounds.Point @canvas, x - @canvas.offset.left, y - @canvas.offset.top, @prop.point
    @points.push @new_point
    @container.mousemove @draw_line
    @container.unmousedown @add_start_point
    @container.mouseup @add_end_point

  draw_line: (e, dx, dy, x, y) =>
    sx = @new_point.x
    sy = @new_point.y
    @temp_line.attr
      path: "M#{sx},#{sy}L#{dx - @canvas.offset.left},#{dy - @canvas.offset.top}"
      stroke: @prop.line.color
    @temp_line.show()
  
  add_end_point: (e, x, y) =>
    @container.unmousemove @draw_line
    @container.unmouseup @add_end_point
    @temp_line.hide()
    @new_end_point = new CoffeeGrounds.Point @canvas, x - @canvas.offset.left, y - @canvas.offset.top, @prop.point
    @points.push @new_end_point
    @container.mousedown @add_start_point


  set_constraints: (@constraints) ->

  add_segment: (start, end, kind) ->
    if not (start and end)
      @start = start
      @end = end

  draw: ->
    @background = @canvas.rect @x, @y, @width, @height
    @background.attr
      'fill': @prop.background_color
      'fill-opacity': @prop.background_opacity
      'stroke': 'black'
      'cursor': 'crosshair'
    @container.push @background

module.exports = Line
