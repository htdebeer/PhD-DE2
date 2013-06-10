###
(c) 2012, Huub de Beer (H.T.de.Beer@gmail.com)
###

Ruler = require './ruler'
class VerticalRuler extends Ruler

  constructor: (@canvas, @x, @y, @width, @height, @height_in_mm, @spec = {
    orientation: "vertical"
    rounded_corners: 5
  }) ->
    super(@canvas, @x, @y, @width, @height, @height_in_mm, @spec)
    @_draw()
    @_compute_geometry()
    @widgets.mouseover (e) =>
      @measure_line.show()
    @widgets.mouseout (e) =>
      @measure_line.hide()
    @widgets.mousemove (e, x, y) =>
      p = @fit_point x, y
      #      y = e.pageY - @canvas.offset.top - @dy
      @_move_measure_line p.y
    @widgets.click (e, x, y) =>
      p = @fit_point x, y
      @_place_pointer p.y
  
  fit_point: (x, y) ->
    point =
      x: x - @canvas.canvas.parentNode.offsetLeft
      y: y - @canvas.canvas.parentNode.offsetTop
    point

  _place_pointer: (y) ->
    T_WIDTH = 10
    T_HEIGHT = 2
    triangle = "l#{T_WIDTH},#{T_HEIGHT}v-#{2 * T_HEIGHT}l-#{T_WIDTH},#{T_HEIGHT}m#{T_WIDTH},0"
    pointer = @canvas.path "M#{@x+@width},#{y}" + triangle + "h#{(@spec['measure_line_width'] ? 500) - @width - T_WIDTH - 2}"
    pointer.attr
        fill: '#222'
        stroke: '#222'
        'stroke-opacity': 0.5
        'stroke-width': 0.5
        'fill-opacity': 1
        'stroke-dasharray': '. '

    active = (elt) ->
        elt.attr
            fill: "red"
            stroke: "red"
            'stroke-opacity': 0.5
            'fill-opacity': 0.5
        
    unactive = (elt) ->
        elt.attr
            fill: "#222"
            stroke: '#222'
            'stroke-opacity': 0.5
            'stroke-width': 0.5
            'fill-opacity': 1
        
    remove = (elt) ->
        elt.unmouseover active
        elt.unmouseout unactive
        # Chrome gives error that attr is called of removed object, ie and
        # ff do not.
        elt.remove()


    pointer.mouseover ->
        active @
    pointer.mouseout ->
        unactive @
    pointer.click ->
        remove @
    pointer.touchstart ->
        active @
    pointer.touchcancel ->
        unactive @
    pointer.touchend ->
        remove @

    # Works only when whole group isn't translated
    #
    # pointer.transform(@transformstring)
    @pointers.push pointer

  _move_measure_line: (y) ->
    MEASURELINE_LENGTH = @spec['measure_line_width'] ? 500
    @measure_line.attr
      path: "M#{@x - @dx},#{y}h#{MEASURELINE_LENGTH}"
      stroke: 'red'
      'stroke-opacity': 0.5
      'stroke-width': 1

  _draw: () ->
    ###
    Draw a vertical ruler
    ###
    @unit = @height / @height_in_mm
    background = @canvas.rect @x, @y, @width, @height, @spec.rounded_corners ? 5
    background.attr
      fill: @spec.background ? "white"
      stroke: @spec.stroke ? "black"
      'stroke-width': @spec['stroke-width'] ? 2
    @widgets.push background

    ticks = @canvas.path @_ticks_path()
    ticks.attr
      stroke: @spec.stroke ? "black"
    @widgets.push ticks

    labels = @_ticks_labels()
    for label in labels
      label.attr
        'font-family': @spec['font-family'] ? 'sans-serif'
        'font-size': @spec['font-size'] ? 10
        'font-weight': 'bold'
      @widgets.push label

    cmlabel = @canvas.text @x + 11, @y + 11, "cm"
    cmlabel.attr
        'font-family': @spec['font-family'] ? 'sans-serif'
        'font-size': (@spec['font-size'] ? 10) + 2
        'font-weight': 'bold'
    @widgets.push cmlabel

    @pointers = @canvas.set()
    @widgets.push @pointers

    @measure_line = @canvas.path "M#{@x},#{@y}"
    @measure_line.hide()
    @widgets.push @measure_line

  _ticks_path: () ->
    ###
    Generate the ticks by moving from tick to tick and drawing a horizontal line
    for every tick.
    ###
    MM_WIDTH = @spec.mm_width ? 3
    HCM_WIDTH = @spec.hcm_width ? 7
    CM_WIDTH = @spec.cm_width ? 11
    x = @x + @width
    y = @y + @height - (@spec.border_width ? 2)
    d = ""
    for mm in [2...@height_in_mm - 1]
      y -= @unit
      d += "M#{x},#{y}"
      if mm % 10 is 0
        # a cm tick
        d += "h-#{CM_WIDTH}"
      else if mm % 5 is 0
        # a half a cm tick
        d += "h-#{HCM_WIDTH}"
      else
        # a mm tick
        d += "h-#{MM_WIDTH}"
    d

  _ticks_labels: () ->
    ###
    Draw the labels of the cm ticks
    ###
    X_DISTANCE = @spec.x_distance ? 18
    Y_DISTANCE = @spec.y_distance ? 3
    x = @x + @width - X_DISTANCE
    y = @y + @height - (@spec.border_width ? 2)
    cm = 0
    labels = []
    for mm in [2...@height_in_mm - 1]
      y -= @unit
      if mm % 10 is 0
        cm++
        labels.push(@canvas.text x, y + Y_DISTANCE, "#{cm}")
    labels

module.exports = VerticalRuler
