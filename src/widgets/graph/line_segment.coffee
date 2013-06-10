#
# line segment 
#
LineSegment = class
  
  defineProperties = (in_properties) ->
    out_properties = {}
    out_properties.straight = in_properties.straight ? false
    out_properties.color = in_properties.color ? 'black'
    out_properties.line_width = in_properties.line_width ? 1
    out_properties.highlight = in_properties.highlight ? 'red'
    out_properties.control_line_color = in_properties.control_line_color ? 'gray'
    out_properties.control_line_dash = '-'
    out_properties.background = in_properties.background ? 'yellow'
    out_properties.background_opacity = in_properties.background_opacity ? 0.7

    out_properties

  constructor: (@canvas, @start, @control_start, @end, @control_end, properties = {}) ->
    @properties = defineProperties properties
    @view = @canvas.set()
    @draw()
    @control_end.hide()
    @control_start.hide()

    @highlighted = false
    @back.mouseover @highlight
    @back.mouseout @highlight
    @selected = false
    @start.add_line @
    @end.add_line @
    @control_start.add_line @
    control_end.add_line @
    @update()


  update: ->
    path = @update_path(@start, @control_start, @end, @control_end)
    @line.attr
      path: path
    @back.attr
      path: path
    @start_control_line.attr
      path: @update_control_path @start, @control_start
    @end_control_line.attr
      path: @update_control_path @end, @control_end


  highlight: =>
    if @highlighted
      @back.unclick @select
      @highlighted = false
    else
      @back.click @select
      @highlighted = true

  select: =>
    if @selected
      @hide_controls()
      @line.attr
        'stroke-width': @properties.line_width
      @selected = false
    else
      if not @properties.straight
        @show_controls()
      @line.attr
        'stroke-width': @properties.line_width * 1.5
      @selected = true

  make_straight: ->
    @properties.straight = true

  make_curve: ->
    @properties.straight = false

  show_controls: ->
    @control_start.show()
    @control_end.show()
    @start_control_line.show()
    @end_control_line.show()

  hide_controls: ->
    @control_start.hide()
    @control_end.hide()
    @start_control_line.hide()
    @end_control_line.hide()

  draw: ->
    
    path = @update_path(@start, @control_start, @end, @control_end)
    @line = @canvas.path path
    @line.attr
      stroke: @properties.color
      'stroke-width': @properties.line_width


    @back = @canvas.path path
    @back.attr
      stroke: @properties.background
      'stroke-opacity': 0
      'stroke-width': @properties.line_width * 4
    @start_control_line = @canvas.path @update_control_path @start, @control_start
    @start_control_line.attr
      stroke: @properties.control_line_color
      'stroke-dasharray': @properties.control_line_dash
      'stroke-width': 0.5
    @start_control_line.hide()
    @end_control_line = @canvas.path @update_control_path @end, @control_end
    @end_control_line.attr
      stroke: @properties.control_line_color
      'stroke-dasharray': @properties.control_line_dash
      'stroke-width': 0.5
    @end_control_line.hide()

    @view.push @back, @line, @start_control_line, @end_control_line
    @line.toBack()
    @back.toBack()


  update_path: (s, cs, e, ce) ->
    if @properties.straight
      path = "M#{s.x},#{s.y}C#{s.x},#{s.y},#{e.x},#{e.y},#{e.x},#{e.y}"
    else
      path = "M#{s.x},#{s.y}C#{cs.x},#{cs.y},#{ce.x},#{ce.y},#{e.x},#{e.y}"

  update_control_path: (p, c) ->
    "M#{p.x},#{p.y}L#{c.x},#{c.y}"

module.exports = LineSegment
