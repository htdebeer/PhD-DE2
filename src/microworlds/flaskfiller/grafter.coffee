# 
# glass_grafter.coffee (c) 2012 HT de Beer
#
# version 0
#
# Tool to construct glasses (see glass.coffee) by drawing the right-hand
# contour of the glass. From that the whole glass, including the
# volume/height functions will be generated.
#
window.GlassGrafter = class
  
  initialize_properties: (properties) ->
    # Initialize properties with properties or default values
    p = {}
    p.buttons = properties?.buttons ? ['normal', 'add_point', 'remove_point', 'straight', 'curve']
    p.icon_path = properties?.icon_path ? 'lib/icons'
    p



  constructor: (@paper, @x, @y, @width, @height, mm_per_pixel, properties) ->
    @spec = @initialize_properties(properties)
    @PADDING = 3
    
    @POINT_WIDTH = 3
    
    @BUTTON_WIDTH = 32
    CoffeeGrounds.Button.set_width @BUTTON_WIDTH
    CoffeeGrounds.Button.set_base_path @spec.icon_path

    @AXIS_WIDTH = 40
    @BUTTON_SEP = 5
    @GROUP_SEP = 15
    @CANVAS_SEP = 10

    @CANVAS_TOP = @y + @PADDING + @BUTTON_WIDTH + @CANVAS_SEP
    @CANVAS_LEFT = @x + @PADDING
    @CANVAS_HEIGHT = @height - @PADDING*2 - @BUTTON_WIDTH - @CANVAS_SEP - @AXIS_WIDTH
    @CANVAS_WIDTH = @width - @PADDING*2 - @AXIS_WIDTH
    @CANVAS_BOTTOM = @CANVAS_TOP + @CANVAS_HEIGHT
    @CANVAS_RIGHT = @CANVAS_LEFT + @CANVAS_WIDTH
    @CANVAS_MID = @CANVAS_LEFT + @CANVAS_WIDTH/2

    @BORDER_WIDTH = @CANVAS_WIDTH/2

    @PIXELS_PER_MM = 1/mm_per_pixel unless mm_per_pixel is 0

    @contour = new CoffeeGrounds.ContourLine @CANVAS_MID, @CANVAS_TOP, @BORDER_WIDTH, @CANVAS_HEIGHT, mm_per_pixel

    @actions = {
      normal:
        button:
          type: 'group'
          option_group: 'mode'
          group: 'select'
          icon: 'edit-select'
          tooltip: 'Versleep witte en blauwe punten'
          on_select: =>
            @change_mode 'normal'
          enabled: true
          default: true
        cursor: 'default'
      add_point:
        button:
          type: 'group'
          option_group: 'mode'
          group: 'edit-point'
          icon: 'format-add-node'
          tooltip: 'Voeg een extra punt toe aan de lijn'
          on_select: =>
            @change_mode 'add_point'
          enabled: true
        cursor: 'crosshair'
      remove_point:
        button:
          type: 'group'
          option_group: 'mode'
          group: 'edit-point'
          icon: 'format-remove-node'
          tooltip: 'Verwijder het rood oplichtende extra punt'
          on_select: =>
            @change_mode 'remove_point'
          enabled: true
        cursor: 'default'
      straight:
        button:
          type: 'group'
          option_group: 'mode'
          group: 'edit-line'
          icon: 'straight-line'
          tooltip: 'Maak van de kromme lijn onder de cursor een rechte lijn'
          on_select: =>
            @change_mode 'straight'
        cursor: 'default'
      curve:
        button:
          type: 'group'
          option_group: 'mode'
          group: 'edit-line'
          icon: 'draw-bezier-curves'
          tooltip: 'Maak van de rechte lijn onder de cursor een kromme lijn'
          on_select: =>
            @change_mode 'curve'
        cursor: 'default'
      realistic:
        button:
          type: 'action'
          icon: 'games-hint'
          group: 'view'
          tooltip: 'Bekijk het glas er in 3D uitziet'
          action: =>
            #console.log "make 3d glass"
      export_png:
        button:
          type: 'action'
          icon: 'image-x-generic'
          group: 'export'
          tooltip: 'Download het glas als een PNG afbeelding'
          action: =>
            #console.log "save as png"
      export_svg:
        button:
          type: 'action'
          icon: 'image-svg+xml'
          group: 'export'
          tooltip: 'Download het glas als een SVG afbeelding'
          action: =>
            #console.log "save as svg"
    }
    @draw()
    @init()
    
  init: ->
    @mode = 'normal'
    @click = ''
    @points_draggable = false
    @cp_points_draggable = false
    @make_draggable()
    @canvas.mouseover @mouseover
    @canvas.mouseout @mouseout
   
  set_contour: (contour) ->
    @contour.from_glass contour.to_glass()
    @draw()
    @init()

  get_contour: ->
    @contour

  mouseover: (e, x, y) =>
    @canvas.mousemove @mousemove

  mouseout: (e, x, y) =>
    @canvas.unmousemove @mousemove

  fit_point: (x, y) ->
    point =
      x: Math.floor(x - @paper.canvas.parentNode.offsetLeft)
      y: Math.floor(y - @paper.canvas.parentNode.offsetTop)
    point

  reset_mouse: ->
    @click = ''
    @canvas.unclick @add_point
    @canvas.unclick @remove_point
    @canvas.unclick @line_changer
    @potential_point.hide()
    @potential_above.hide()
    @potential_below.hide()
    @remove_point_point.hide()
    @remove_point_line.hide()
    @change_line_area.hide()

  mousemove: (e, x, y) =>
    p = @fit_point x, y
    @canvas.attr
      cursor: @actions[@mode].cursor
    switch @mode
      when 'normal'
        1 is 1
      when 'add_point'
        if @contour.can_add_point p.x, p.y
          above = @contour.get_point_above_height p.y
          below = above + 1
          above = @contour.get_point above
          below = @contour.get_point below

          if @click isnt @mode
            @canvas.click @add_point
            @click = @mode
          @potential_above.attr
            path: "M#{above.x},#{above.y}L#{p.x},#{p.y-2}"
          @potential_above.show()
          @potential_below.attr
            path: "M#{below.x},#{below.y}L#{p.x},#{p.y+2}"
          @potential_below.show()

        else
          @potential_point.hide()
          @potential_above.hide()
          @potential_below.hide()
          @canvas.attr
            cursor: 'not-allowed'
      when 'remove_point'
        q = @contour.find_point_near p.x, p.y, @POINT_WIDTH*5
        if q isnt -1 and @contour.can_remove_point q
          if @click isnt @mode
            @canvas.click @remove_point
            @click = @mode
          point = @contour.get_point q
          above = q - 1
          below = q + 1
          above = @contour.get_point above
          below = @contour.get_point below
          @remove_point_point.attr
            cx: point.x
            cy: point.y
          @remove_point_point.show()
          @remove_point_line.attr
            path: "M#{above.x},#{above.y}L#{below.x},#{below.y}"
          @remove_point_line.show()
        else
          @reset_mouse()
          @canvas.attr
            cursor: 'not-allowed'

      when 'straight'
        q = @contour.get_point_above_height p.y
        if q isnt -1
          point = @contour.get_point q
          below = @contour.get_point q + 1
          
          if point.segment.type isnt 'straight'
            if @click isnt @mode
              @canvas.click @change_line(@, 'straight')
              @click = @mode
            @change_line_area.attr
              y: point.y
              height: below.y - point.y
            @change_line_area.show()
          else
            @change_line_area.hide()
            @canvas.attr
              cursor: 'not-allowed'
        else
          @change_line_area.hide()
          @canvas.attr
            cursor: 'not-allowed'

      when 'curve'
        q = @contour.get_point_above_height p.y
        if q isnt -1
          point = @contour.get_point q
          below = @contour.get_point q + 1
          
          if point.segment.type isnt 'curve'
            if @click isnt @mode
              @canvas.click @change_line(@, 'curve')
              @click = @mode
            @change_line_area.attr
              y: point.y
              height: below.y - point.y
            @change_line_area.show()
          else
            @change_line_area.hide()
            @canvas.attr
              cursor: 'not-allowed'
        else
          @change_line_area.hide()
          @canvas.attr
            cursor: 'not-allowed'

  add_point: (e, x, y) =>
    p = @fit_point x, y
    point = @paper.circle p.x, p.y, @POINT_WIDTH
    point.attr
      fill: 'black'
    q = @contour.add_point p.x, p.y, point
    point.drag @move_point(@, q), @move_point_start, @move_point_end(@, q)
    @draw_glass()

  make_draggable: ->
    @points_draggable = @points_draggable ? false
    if not @points_draggable
      for point in @contour.points
        point.representation.drag @move_point(@, point), @move_point_start(point), @move_point_end(@, point)
        if point.border is 'none'
          point.representation.attr
            fill: 'blue'
            stroke: 'blue'
            r: @POINT_WIDTH * 2
            'fill-opacity': 0.3
      @points_draggable = true

  move_point: (grafter, point) ->
    return (dx, dy, x, y, e) =>
      tx = Math.floor(dx - grafter.dpo.x)
      ty = Math.floor(dy - grafter.dpo.y)
      p = grafter.contour.find_point_at point.y
      if point.border is 'foot'
        # the foot can only move on x
        newp =
          x: point.x + tx
          y: point.y
      else
        # others can be moved everywhere within limits
        newp =
          x: point.x + tx
          y: point.y + ty
      if p isnt -1 and grafter.contour.can_move_point p, newp.x, newp.y
        grafter.contour.move_point p, newp.x, newp.y
        grafter.dpo =
          x: dx
          y: dy
        point.representation.attr
          cx: point.x
          cy: point.y
        switch point.border
          when 'edge'
            @edge.attr
              path: "M#{@CANVAS_MID},#{point.y}h#{@CANVAS_WIDTH/2}"
          when 'bowl'
            @bowl.attr
              path: "M#{@CANVAS_MID},#{point.y}h#{@CANVAS_WIDTH/2}"
          when 'stem'
            @stem.attr
              path: "M#{@CANVAS_MID},#{point.y}h#{@CANVAS_WIDTH/2}"
        @draw_glass()
      else
        # cannot move point: stay

  move_point_start: (point) ->
    return (x, y, e) =>
      if point.border isnt 'none'
        point.representation.attr
          fill: 'blue'
      @dpo = @dpo ? {}
      @dpo =
        x: 0
        y: 0


  move_point_end: (grafter, point) ->
    return (x, y, e) =>
      if point.border isnt 'none'
        point.representation.attr
          fill: 'white'
          'fill-opacity': 1
      grafter.draw_glass()
      point.representation.toFront()

  make_undraggable: ->
    @points_draggable = @points_draggable ? false
    if @points_draggable
      for point in @contour.points
        point.representation.undrag()
        if point.border is 'none'
          point.representation.attr
            fill: 'black'
            stroke: 'black'
            r: @POINT_WIDTH
            'fill-opacity': 1
      @points_draggable = false


  remove_point: (e, x, y) =>
    p = @fit_point x, y
    q = @contour.find_point_near p.x, p.y, @POINT_WIDTH*5
    if q isnt -1 and @contour.can_remove_point(q)
      r = @contour.get_point q
      r.representation.remove()
      @contour.remove_point q
      @draw_glass()
      @remove_point_point.hide()
      @remove_point_line.hide()
    
  change_line: (grafter, kind) ->

    grafter.canvas.unclick grafter.line_changer
    grafter.line_changer = null
    grafter.line_changer = (e, x, y) =>
      p = @fit_point x, y
      q = @contour.get_point_above_height p.y
      if kind is 'curve'
        if q isnt -1 and q isnt (@contour.points.length - 1)
          grafter.contour.make_curve q
          point = grafter.contour.get_point q
          below = grafter.contour.get_point(q+1)
          c1 = point.segment.c1
          c2 = point.segment.c2

          if not c1?.representation?
            c1.representation = @paper.circle c1.x, c1.y, @POINT_WIDTH * 2
            c1.line = @paper.path "M#{point.x},#{point.y}L#{c1.x},#{c1.y}"
          ctop = c1.representation
          ctop.attr
            cx: c1.x
            cy: c1.y
            fill: 'orange'
            stroke: 'orange'
            'fill-opacity': 0.3
          cltop = c1.line
          cltop.attr
            path: "M#{point.x},#{point.y}L#{c1.x},#{c1.y}"
            stroke: 'orange'
            'stroke-dasharray': '.'

          ctop.drag @move_control_point(@, point, ctop, cltop, 1), @control_point_start, @control_point_end(@, point, ctop)

          if not c2?.representation?
            c2.representation = @paper.circle c2.x, c2.y, @POINT_WIDTH * 2
            c2.line = @paper.path "M#{below.x},#{below.y}L#{c2.x},#{c2.y}"

          cbottom = c2.representation
          cbottom.attr
            cx: c2.x
            cy: c2.y
            fill: 'orange'
            stroke: 'orange'
            'fill-opacity': 0.3
          clbottom = c2.line
          clbottom.attr
            path: "M#{below.x},#{below.y}L#{c2.x},#{c2.y}"
            stroke: 'orange'
            'stroke-dasharray': '.'

          cbottom.drag @move_control_point(@, point, cbottom, clbottom, 2), @control_point_start, @control_point_end(@, c1, cbottom)
          
          grafter.draw_glass()
      else
        # is straight
        if q isnt -1
          grafter.contour.make_straight q
          grafter.draw_glass()
    grafter.line_changer




  move_control_point: (grafter, point, representation, line, cp) ->
    return (dx, dy, x, y, e) =>
      tx = dx - grafter.dpo.x
      ty = dy - grafter.dpo.y
      p = grafter.contour.find_point_at point.y
      below = grafter.contour.get_point (p+1)
      newp =
        x: representation.attr('cx') + tx
        y: representation.attr('cy') + ty
      if grafter.contour.can_move_control_point p, newp.x, newp.y
        grafter.contour.move_control_point p, cp, newp.x, newp.y
        representation.attr
          cx: newp.x
          cy: newp.y
        start = if cp is 1 then point else below
        line.attr
          path: "M#{start.x},#{start.y}L#{newp.x},#{newp.y}"
        grafter.dpo =
          x: dx
          y: dy

        grafter.draw_glass()
      

  control_point_start: =>
    @dpo = @dpo ? {}
    @dpo =
      x: 0
      y: 0

  control_point_end: (grafter, above, representation) ->
    return (x, y, e) =>
      grafter.draw_glass()

  draw_glass: ->
    @glass_base.attr
      path: @contour.to_glass_path 'base'
    @glass_bowl.attr
      path: @contour.to_glass_path()
    @glass_contour.attr
      path: @contour.to_path()

    place_label = (label, above, below) ->
      # place glass part labels if possible
      #console.log label, above, below
      bb = label.getBBox()
      bowlheight = below.y - above.y
      if bowlheight > bb.height
        # possible to put label
        rest = bowlheight - bb.height
        label.attr
          y: above.y + rest/2 + bb.height/2
        label.show()
      else
        label.hide()

    place_label @bowl_label, @contour.edge, @contour.bowl
    place_label @stem_label, @contour.bowl, @contour.stem
    place_label @foot_label, @contour.stem, @contour.foot

  change_mode: (mode) ->
    @reset_mouse()
    @make_undraggable()
    @mode = @mode ? {}
    @mode = mode
    if @mode is 'normal'
      @make_draggable()
    else
      @make_undraggable()
    if @mode is 'curve'
      @make_cp_draggable()
    else
      @make_cp_undraggable()

  make_cp_draggable: ->
    @cp_points_draggable = @cp_points_draggable ? false
    if not @cp_points_draggable
      for point in @contour.points
        s = point.segment
        if s.type is 'curve'
          point.segment.c1.representation.attr
            cx: point.segment.c1.x
            cy: point.segment.c1.y
          point.segment.c1.representation.show()
          point.segment.c2.representation.attr
            cx: point.segment.c2.x
            cy: point.segment.c2.y
          point.segment.c2.representation.show()
          point.segment.c1.line.attr
            path: "M#{point.x},#{point.y}L#{point.segment.c1.x},#{point.segment.c1.y}"
          point.segment.c1.line.show()
          next_point = @contour.get_point(@contour.find_point_at(point.y) + 1)
          point.segment.c2.line.attr
            path: "M#{next_point.x},#{next_point.y}L#{point.segment.c2.x},#{point.segment.c2.y}"
          point.segment.c2.line.show()
      @cp_points_draggable = true

  make_cp_undraggable: ->
    @cp_points_draggable = @cp_points_draggable ? false
    if @cp_points_draggable
      for point in @contour.points
        s = point.segment
        if s.type is 'curve'
          point.segment.c1.representation.hide()
          point.segment.c2.representation.hide()
          point.segment.c1.line.hide()
          point.segment.c2.line.hide()
      @cp_points_draggable = false

  draw: ->
    @elements = @paper.set()

    @foot_label = @paper.text (@CANVAS_MID + @CANVAS_WIDTH/4), 0, "voet"
    @foot_label.attr
      'font-family': 'sans-serif'
      'font-size': '14pt'
      'fill': 'silver'
    @stem_label = @paper.text (@CANVAS_MID + @CANVAS_WIDTH/4), 0, "steel"
    @stem_label.attr
      'font-family': 'sans-serif'
      'font-size': '14pt'
      'fill': 'silver'
    @bowl_label = @paper.text (@CANVAS_MID + @CANVAS_WIDTH/4), 0, "kelk"
    @bowl_label.attr
      'font-family': 'sans-serif'
      'font-size': '14pt'
      'fill': 'silver'

    @glass_base = @paper.path @contour.to_glass_path 'base'
    @glass_base.attr
      fill: 'black'
      'fill-opacity': 0.3
      stroke: 'gray'
      'stroke-width': 2
      'stroke-dasharray': ''
    @glass_bowl = @paper.path @contour.to_glass_path()
    @glass_bowl.attr
      stroke: 'black'
      'stroke-width': 2
      'stroke-dasharray': ''


    @draw_axis 'radius'
    @draw_axis 'height'

    @potential_point = @paper.circle 0, 0, @POINT_WIDTH*2
    @potential_point.attr
      fill: 'green'
      opacity: 0.5
    @potential_point.hide()
    @potential_above = @paper.path "M0,0"
    @potential_above.attr
      stroke: 'green'
      opacity: 0.5
      'stroke-dasharray': '-'
    @potential_above.hide()
    @potential_below = @paper.path "M0,0"
    @potential_below.attr
      stroke: 'green'
      opacity: 0.5
      'stroke-dasharray': '-'
    @potential_below.hide()

    @remove_point_point = @paper.circle 0, 0, @POINT_WIDTH*4
    @remove_point_point.attr
      fill: 'red'
      stroke: 'red'
      opacity: 0.5
    @remove_point_point.hide()
    @remove_point_line = @paper.path "M0,0"
    @remove_point_line.attr
      stroke: 'red'
      opacity: 0.5
      'stroke-dasharray': '-'
    @remove_point_line.hide()
    @change_line_area = @paper.rect @CANVAS_MID, @CANVAS_BOTTOM, @CANVAS_WIDTH/2, 0
    @change_line_area.attr
      fill: 'orange'
      opacity: 0.5
    @change_line_area.hide()
    
    @glass_contour = @paper.path @contour.to_path()
    @glass_contour.attr
      stroke: 'DarkGreen'
      'stroke-width': 3

    @canvas = @paper.rect @CANVAS_MID, @CANVAS_TOP, @CANVAS_WIDTH/2, @CANVAS_HEIGHT
    @canvas.attr
      fill: 'white'
      'fill-opacity': 0
      stroke: 'white'
      'stroke-width': 0

    mid_line = @paper.path "M#{@CANVAS_MID},#{@CANVAS_TOP}v#{@CANVAS_HEIGHT}"
    mid_line.attr
      stroke: 'Indigo'
      'stroke-width': 2
      'stroke-dasharray': '-.'
   
    @glass_contour.hide()

    
    @draw_buttons()



    @foot = @draw_border @contour.foot, ''
    @foot.attr
      stroke: 'black'
    @stem = @draw_border @contour.stem
    @bowl = @draw_border @contour.bowl
    @edge = @draw_border @contour.edge

    @foot_point = @draw_point @contour.foot
    @contour.foot.representation = @foot_point
    @stem_point = @draw_point @contour.stem
    @contour.stem.representation = @stem_point
    @bowl_point = @draw_point @contour.bowl
    @contour.bowl.representation = @bowl_point
    @edge_point = @draw_point @contour.edge
    @contour.edge.representation = @edge_point

    @draw_glass()
  
  draw_point: (p) ->
    if p.border isnt 'none'
      point = @paper.circle p.x, p.y, @POINT_WIDTH * 2
      point.attr
        fill: 'white'
        stroke: 'black'
        'stroke-width': 2
    else
      point = @paper.circle p.x, p.y, @POINT_WIDTH
      point.attr
        fill: 'black'
        stroke: 'black'
        'stroke-width': @POINT_WIDTH
        'stroke-opacity': 0
    p.representation = point
    
    point


  draw_border: (border, dashing = '. ') ->
    border_line = @paper.path "M#{@CANVAS_MID},#{border.y}h#{@BORDER_WIDTH}"
    border_line.attr
      stroke: 'Indigo'
      'stroke-dasharray': dashing
      'stroke-width': 0.5
    border_line
  
  draw_buttons:  ->
    x = @CANVAS_MID
    y = @CANVAS_TOP - @CANVAS_SEP - @BUTTON_WIDTH
    @mode = ""

    
    group = ''
    optiongroups = {}
    sep = 0
    @buttons = {}
    for name, action of @actions
      if name in @spec.buttons
        # only those buttons set are put on the graph
        button = action.button

        if group isnt ''
          if button.group is group
            x += @BUTTON_WIDTH + @BUTTON_SEP
          else
            x += @BUTTON_WIDTH + @GROUP_SEP
        group = button.group



        switch button.type
          when 'action'
            @buttons.name = new CoffeeGrounds.ActionButton @paper,
              x: x
              y: y
              icon: button.icon
              tooltip: button.tooltip
              action: button.action
          when 'switch'
            @buttons.name = new CoffeeGrounds.SwitchButton @paper,
              x: x
              y: y
              icon: button.icon
              tooltip: button.tooltip
              switched_on: button?.switched_on ? false
              on_switch_on: button.on_switch_on
              on_switch_off: button.on_switch_off
          when 'group'
            optiongroups[button.option_group] = optiongroups[button.option_group] ? []
            optiongroups[button.option_group].push {
              x: x
              y: y
              icon: button.icon
              tooltip: button.tooltip
              value: name
              on_select: button.on_select
              chosen: button.default ? false
            }


    # Add and create buttongroups
    for name, optiongroup of optiongroups
      buttongroup = new CoffeeGrounds.ButtonGroup @paper, optiongroup
      for button in buttongroup.buttons
        @buttons[button.value] = button



  draw_axis: (axis) ->
    TICKSLENGTH = 10
    HALFTICKSLENGTH = TICKSLENGTH/2
    LABELSEP = 5
    AXISLABELSEP = 30

    path = ''
    step = 5 * @PIXELS_PER_MM
    label = 0
    i = 0
    if axis is 'radius'
      movement = 'v'
      x = @CANVAS_MID
      end = @CANVAS_MID + @BORDER_WIDTH

      while x <= end
        path += "M#{x},#{@CANVAS_BOTTOM}"
        if (i % 10) is 0
          # one cm tick
          path += "#{movement}#{TICKSLENGTH}"
          label_text = @paper.text x, 0, label
          label_text.attr
            'font-family': 'sans-serif'
            'font-size': '12pt'
          ltbb = label_text.getBBox()
          label_text.attr
            y: @CANVAS_BOTTOM + LABELSEP + ltbb.height
          label += 1
        else
          path += "#{movement}#{HALFTICKSLENGTH}"
          # half cm tick

        # go to the next half cm tick
        x += step
        i +=5

      axis_label = @paper.text 0, 0, 'straal (cm)'
      axis_label.attr
        'font-family': 'sans-serif'
        'font-size': '14pt'
        'text-anchor': 'start'
      albb = axis_label.getBBox()
      axis_label.attr
        x: @CANVAS_RIGHT - albb.width
        y: @CANVAS_BOTTOM + LABELSEP + albb.height + TICKSLENGTH + LABELSEP

      axis_line = @paper.path "M#{@CANVAS_MID},#{@CANVAS_BOTTOM}h#{@CANVAS_WIDTH/2}"
      axis_line.attr
        stroke: 'black'
        'stroke-width': 2


    else
      movement = 'h'
      y = @CANVAS_BOTTOM
      end = @CANVAS_TOP

      while y >= end
        path += "M#{@CANVAS_RIGHT},#{y}"
        if (i % 10) is 0
          # one cm tick
          path += "#{movement}#{TICKSLENGTH}"
          label_text = @paper.text 0, y, 99
          label_text.attr
            'font-family': 'sans-serif'
            'font-size': '12pt'
          ltbb = label_text.getBBox()
          label_text.attr
            x: @CANVAS_RIGHT + LABELSEP + TICKSLENGTH + ltbb.width
            'text-anchor': 'end'
            text: label
          label += 1
        else
          path += "#{movement}#{HALFTICKSLENGTH}"
          # half cm tick

        # go to the next half cm tick
        y -= step
        i +=5
      
      axis_label = @paper.text 0, 0, 'hoogte (cm)'
      axis_label.attr
        'font-family': 'sans-serif'
        'font-size': '14pt'
        'text-anchor': 'start'
      albb = axis_label.getBBox()
      axis_label.attr
        x: @CANVAS_RIGHT - albb.width
        y: @CANVAS_BOTTOM + LABELSEP + albb.height + TICKSLENGTH + LABELSEP
      axis_label.transform "r-90,#{@CANVAS_RIGHT},#{@CANVAS_BOTTOM}t#{@CANVAS_HEIGHT},#{LABELSEP}"
      
      axis_line = @paper.path "M#{@CANVAS_RIGHT},#{@CANVAS_BOTTOM}v-#{@CANVAS_HEIGHT}"
      axis_line.attr
        stroke: 'black'
        'stroke-width': 2


    axis = @paper.path path
    axis.attr
      stroke: 'black'
      'stroke-width': 2

    axis
