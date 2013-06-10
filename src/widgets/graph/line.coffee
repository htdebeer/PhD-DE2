#
# line.coffee (c) 2012 HT de Beer
#
# version 0
#
# A line models a line in a Cartesian graph. A line is a list of points. A
# point has the following properties:
#
#   ∙ x, the x coordinate
#   ∙ y, the y coordinate
#   ∙ segment, the line segment from this point to the next if any. A 
#              segment has the following properties:
#
#     ∙ type, type ∈ {none, straight, curve, freehand}. 
#
#     - If this segment is a curve, it has also two control points:
#
#     ∙ c1, controlling the curve around this point:
#       ∙ x, the x coordinate
#       ∙ y, the y coordinate
#     ∙ c2, controlling the curve around the next point:
#       ∙ x, the x coordinate
#       ∙ y, the y coordinate
#           
#     - If this segment has type freehand, it has also a path:
#
#     ∙ path, an SVG path starting in this point and ending in the next 
#             point.
#
# For a line and its points, the following hold:
#   
#   (∀i: 0 ≤ i < |points| - 1: points[i].x < points[i+1].x)
# ∧ 
#   min.x ≤ points[0].x ∧ points[|points|-1] ≤ max.x
# ∧
#   (∀i: 0 ≤ i < |points|: min.y ≤ points[i].y ≤ max.y)
# ∧ 
#   point[|points|-1].line = none
#
# A line is initialized given the area of the Cartesian graph this line is
# part of:
#
#   ∙ x, the left x coordinate of the Cartesian graph; min.x = x
#   ∙ y, the top y coordinate of the Cartesian graph; min.y = y
#   ∙ width, the width of the Cartesian graph; max.x = min.x + width
#   ∙ height, the height of the Cartesian graph; min.y = min.y + height
#
#   ∙ unit:
#     ∙ x, the horizontal axis:
#       ∙ amount_per_pixel, the amount of this quantity represented by one
#                           pixel
#       ∙ quantity, the quantity represented by this unit
#       ∙ symbol, the symbol used for this quantity
#     ∙ y, the vertical axis:
#       ∙ amount_per_pixel, the amount of this quantity represented by one
#                           pixel
#       ∙ quantity, the quantity represented by this unit
#       ∙ symbol, the symbol used for this quantity
#
#   ∙ record, record ∈ {true, false}. The construction and manipulation of a
#             line can be recorded.  If a line is recorded, all operations 
#             are pushed onto the history. The history is a stack of 
#             operations performed on this line.
#
# One point or one line can be selected.
#
#   ( 0 ≤ selected.point < |points| ∧ selected.line = -1 )
# ∨
#   ( selected.point = -1 ∧ 0 ≤ selected.line < |points| - 1 ∧
#     points[selected.line].segment ≠ none )
# ∨
#   selected.point = -1 ∧ selected.line = -1
#
#
Line = class

  constructor: (left, top, width, height, @x_unit, @y_unit, @record = false) ->
    # x_unit in units per pixel
    # y_unit in units per pixel
    @min =
      x: left
      y: top
    @max =
      x: @min.x + width
      y: @min.y + height
    if @record
      @history = []
      @start_time = Date.now()
    @points = []
    @selected =
      point: -1
      line: -1

    @move_buffer =
      x: 0
      y: 0


  to_json: ->
    eo =
      x_unit: @x_unit
      y_unit: @y_unit
      min:
        x: @min.x
        y: @min.y
      max:
        x: @max.x
        y: @max.y
      record: @record
      points: []
    if @record
      eo.start_time = @start_time
      eo.history = @history.join(' ')

    for point, index in @points
      eopoint =
        index: index
        x: point.x
        y: point.y
      switch point.segment.type
        when 'none'
          eopoint.segment = 'none'
        when 'straight'
          eopoint.segment = 'straight'
        when 'curve'
          eopoint.segment = 'curve'
          eopoint.c1 =
            x: point.segment.c1.x
            y: point.segment.c1.y
          eopoint.c2 =
            x: point.segment.c2.x
            y: point.segment.c2.y
        when 'freehand'
          eopoint.segment = 'freehand'
          eopoint.path = point.segment.path
      eo.points[index] = eopoint

    JSON.stringify eo
    


  # queries

  get_point: (p) ->
    # Get point p from the list with points
    #
    # pre   : 0 ≤ p < |points|
    # post  : true
    # return: points[p]
    @points[p]

  find_point_at: (x) ->
    # Find and return the index of the point with x coordinate equal to x, -1
    # otherwise
    #
    # pre   : min.x ≤ x ≤ max.x
    # post  : true
    # return: p,  -1 ≤ p < |points|
    #           ∧ (
    #               p = -1 -> true
    #             ∨
    #               p > -1 -> points[p].x = x
    #             )
    # replace linear search with a more efficient one later
    p = 0
    while p < @points.length and @points[p].x isnt x
      p++
    p = if p is @points.length then -1 else p
  
  point_in_circle: (p, x, y, r) ->
    q = @points[p]
    result = (q.x - r < x < q.x + r) and (q.y - r < y < q.y + r)
    result

  find_point_near: (x, y, r = 1) ->
    # Find a point, if any, in the circle with origin x, y and radius r

    found = -1
    ar = 0
    while found is -1 and ar < r
      found = Math.max(@find_point_at(x + ar), @find_point_at(x - ar))
      if found isnt -1 and y - ar <= @points[found].y  <= y + ar
        break
      else
        found = -1
      ar++
    found
      

  find_point_around: (x, y, r = 10) ->
    # Find and return the index of the point in the circle around x, y with
    # radius r, if any. Return -1 otherwise
    #
    # pre   : min.x ≤ x ≤ max.x ∧ min.y ≤ y ≤ max.y
    # post  : true
    # return: p, -1 ≤ p < |points| 
    #       ∧
    #         points.p.x - r < x < points.p.x + r
    #       ∧
    #         points.p.y -r < y < points.p.y + r
    ax = x
    ay = y
    while p < @points.length and not @point_in_circle(p, x, y, r)
      p++
    
    p = if p isnt @points.length then p else -1

  find_point_to_the_left_of: (x) ->
    # Find and return the index of the point left of and closest to x, -1
    # otherwise
    #
    # pre   : min.x ≤ x ≤ max.x
    # post  : true
    # return: p,  -1 ≤ p < |points| 
    #           ∧  
    #             (∀i: 0 ≤ i < p: point[i].x < x)
    #           ∧
    #             (∀i: p < i < |points|: x ≤ points[i].x)
    #
    # replace linear search with a efficient one later
    p = 0
    while p < @points.length and @points[p].x < x
      p++
    # points[p].x ≥ x, one point too far
    p -= 1
    p

  can_add_point: (x, y) ->
    # Can the point (x, y) be added to this line?
    #
    # pre   : true
    # post  : true
    # return: min.x ≤ x ≤ max.x ∧ min.y ≤ y ≤ max.y ∧
    #         ( 
    #           (∃i,j: 0 ≤ i < j < |points|: 
    #             points[i].x < x < points[j].x ∧ points[i].line = none)
    #           ∨
    #             x < points[0].x 
    #           ∨ 
    #             points[|points|-1].x < x
    #         )
    result = false
    if (@min.x <= x <= @max.x) and (@min.y <= y <= @max.y)
      p = @find_point_to_the_left_of x
      if p is -1
        result = true
      else
        # there is a point to the left of x
        if p is @points.length - 1
          result = true
        else
          # x between the first and last point
          if @points[p+1].x isnt x and @points[p].segment.type is 'none'
            result = true
          else
            # if points[p+1].x = x ∨ points[p].segment.type ≠ none the point (x,y)
            # cannot be added              
            result = false
    else
      # x or y outside the boundaries: it cannot be added
      result = false

    result

  can_remove_point: (p) ->
    # Points that are not part of any line segment can be removed.
    #
    # pre   : 0 ≤ p < |points|
    # post  : true
    # return: p = 0 => points[p].segment.type = none 
    #       ∧ 
    #         p ≠ 0 => (points[p].segment.type = none ∧ points[p-1].segment.type = none)
    result = false

    if p is 0
      result = @points[0].segment.type is 'none'
    else
      if @points.length > 1
        # p > 0
        result = @points[p-1].segment.type is 'none' and @points[p].segment.type is 'none'

    result
  
  can_add_line: (x) ->
    # Can a line be drawn from the point left of x to the point right of x?
    #
    # pre   : min.x ≤ x ≤ max.x
    # post  : true
    # return: points[find_point_to_the_left_of(x)].segment.type = none 
    #       ∧ 
    #         find_point_to_the_left_of(x) < |points| - 1
    p = @find_point_to_the_left_of x
    -1 < p < @points.length - 1 and @points[p].segment.type is 'none'

  can_add_line_to_point: (p) ->
    # Can a line be drawn from p to the next point?
    #
    # pre   : 0 ≤ p < |points|
    # post  : true
    # return: points[p].segment.type = none ∧ p ≠ |points| - 1
    @points[p].segment.type is 'none' and p isnt @points.length

  can_remove_line_from_point: (p) ->
    # Can the line starting from point points[p] be removed?
    #
    # pre   : 0 ≤ p < |points| - 1
    # post  : true
    # return: points[p].segment.line ∈ {line,curve,freehand}
    (@points[p].segment.type isnt 'none')

  can_move_point: (p, x, y) ->
    # Can point p be moved to (x, y)?
    #
    # pre   : 0 ≤ p < |points|
    # post  : true
    # return: min.x ≤ x ≤ max.x
    #       ∧
    #         min.y ≤ y ≤ max.y
    #       ∧
    #         (∀i: 0 ≤ i < p: points[p].x < x)
    #       ∧
    #         (∀i: p < i < |points|: x < points[p].x)
    #
    result = false
    if @min.x <= x <= @max.x and @min.y <= y <= @max.y
      if 0 < p < @points.length - 1
        # there is a previous and next point
        if @points[p-1].x < x < @points[p+1].x
          result = true
      else
        # either a previous or next point or both aren't there
        if @points.length is 1
          # there is only one point
          result = true
        else
          # there is more than one point
          if p is 0
            result = x < @points[p+1].x
          else
            # p = |points| - 1
            result = @points[p-1].x < x
    result
  
  can_move_control_point: (p, x, y) ->
    # VVVV is not correct
    # Can point p be moved to (x, y)?
    #
    # pre   : 0 ≤ p < |points|
    # post  : true
    # return: min.x ≤ x ≤ max.x
    #       ∧
    #         min.y ≤ y ≤ max.y
    #
    result = false
    if @min.x <= x <= @.max.x and @min.y <= y <= @max.y
      result = true

      
    result

  # actions

  start_time: ->
    # start the history now, for example just before the graph becomes
    # visible
    @start_time = Date.now()

  add_point: (x, y, rep) ->
    # Add point (x,y) to this line
    #
    # pre   : can_add_point(x, y) ∧ p = find_point_to_the_left_of(x)
    # post  : (∀i: 0 ≤ i < p: points[i].x < point[p].x)
    #       ∧
    #         (∀i: p < i < |points|: point[p].x < points[i].x)
    # return: -
    p = @find_point_to_the_left_of x
    head = []
    head = @points[0..p] unless p < 0

    tail = if p is @points.length - 1 then [] else @points[p+1..]
    point =
      x: x
      y: y
      segment:
        type: 'none'
      representation: rep

    @points = head.concat point, tail

    if @record
      time = Date.now() - @start_time
      @history.push "AP#{p+1}:#{x},#{y}@#{time}"

    point

  remove_point: (p) ->
    # remove point points[p] from this line
    #
    # pre   : can_remove_point(p)
    # post  : (∀i: 0 ≤ i < |points|: points[p].x ≠ points[i].x)
    # return: -
    head = @points[0...p]
    tail = if p is @points.length - 1 then [] else @points[p+1..]
    @points = head.concat tail
    if @record
      time = Date.now() - @start_time
      @history.push "RP#{p}@#{time}"

  add_straight_line: (p) ->
    # add a straight line from points[p] to the next point
    #
    # pre   : can_add_line_to_point(p)
    # post  : points[p].segment.type = straight
    # return: -
    @points[p].segment.type = 'straight'
    if @record
      time = Date.now() - @start_time
      @history.push "AS#{p}@#{time}"


  add_curved_line: (p, d, left, right, lleft, lright) ->
    # add a curved line from points[p] to the next point
    #
    # pre   : can_add_line_to_point(p) 
    # post  : points[p].segment.type = straight 
    #       ∧ 
    #         points[p].segment.c1 = points[p].(x+d,y)
    #       ∧
    #         points[p].segment.c2 = points[p+1].(x-d,y)
    # return: -
    @points[p].segment.type = 'curve'
    @points[p].segment.c1 =
      x: @points[p].x + d
      y: @points[p].y
      representation: left
      line: lleft
    @points[p].segment.c2 =
      x: @points[p+1].x - d
      y: @points[p+1].y
      representation: right
      line: lright
    if @record
      time = Date.now() - @start_time
      @history.push "AC#{p}@#{time}"

  add_freehand_line: (p, path) ->
    # add a freehand line from points[p] to the next point
    #
    # pre   : can_add_line_to_point(p) 
    # post  : points[p].segment.type = freehand
    #       ∧
    #         points[p].segment.path = path
    # return: -
    @points[p].segment.type = 'freehand'
    @points[p].segment.path = path
    if @record
      time = Date.now() - @start_time
      @history.push "AF#{p}:#{path}@#{time}"

  remove_line: (p) ->
    # remove line between points[p] and the next point, if any
    #
    # pre   : can_remove_line_from_point(p)
    # post  : points[p].segment.type = none
    @points[p].segment.type = 'none'
    if @record
      time = Date.now() - @start_time
      @history.push "RL#{p}@#{time}"

  move_point: (p, x, y, do_record = false) ->
    # Move point p to position (x, y)
    #
    # pre   : can_move_point(p)
    # post  : points[p].x = x ∧ points[p].y = y
    # return: -
    if not do_record
      @points[p].x = x
      @points[p].y = y
    if @record
      if do_record
        time = Date.now() - @start_time
        @history.push "MP#{p}:#{@move_buffer.x},#{@move_buffer.y}@#{time}"
      else
        @move_buffer =
          x: x
          y: y
    
  move_control_point1: (p, x, y, do_record = false) ->
    # Move control point of the line starting at p
    #
    # pre   : 0 ≤ p < |points| 
    #       ∧ 
    #         points[p].segment.type = curve
    #       ∧
    #         min.x ≤ x ≤ max.x
    #       ∧
    #         min.y ≤ y ≤ max.y
    # post  : p.segment.c1 = (x,y)
    # return: -
    if @min.x <= x <= @max.x and @min.y <= y <= @max.y
      if not do_record
        @points[p].segment.c1.x = x
        @points[p].segment.c1.y = y
    if @record
      if do_record
        time = Date.now() - @start_time
        @history.push "M1C#{p}:#{@move_buffer.x},#{@move_buffer.y}@#{time}"
      else
        @move_buffer =
          x: x
          y: y

  move_control_point2: (p, x, y, do_record = false) ->
    # Move control point of the line ending at p + 1
    #
    # pre   : 0 ≤ p < |points| - 1 
    #       ∧ 
    #         points[p].segment.type = curve
    #       ∧
    #         min.x ≤ x ≤ max.x
    #       ∧
    #         min.y ≤ y ≤ max.y
    # post  : p.segment.c2 = (x,y)
    # return: -
    if @min.x <= x <= @max.x and @min.y <= y <= @max.y
      if not do_record
        @points[p].segment.c2.x = x
        @points[p].segment.c2.y = y
    if @record
      if do_record
        time = Date.now() - @start_time
        @history.push "M2C#{p}:#{@move_buffer.x},#{@move_buffer.y}@#{time}"
      else
        @move_buffer =
          x: x
          y: y

  select_line: (p) ->
    # Select the line starting at p, assuming there is a line
    #
    # pre   : 0 ≤ p < |points| ∧ points[p].segment.type ≠ none 
    # post  : selected.line = p ∧ selected.point = -1
    # return: -
    @selected.line = p
    @selected.point = -1

  select_point: (p) ->
    # Select the point at p
    #
    # pre   : 0 ≤ p < |points|
    # post  : selected.point = p ∧ selected.line = -1
    # return: -
    @selected.point = p
    @selected.line = -1

  deselect: ->
    # Deselect the selected line or point, if any
    #
    # pre   : true
    # post  : selected.point = -1 ∧ selected.line = -1
    # return: -
    @selected.point = -1
    @selected.line = -1

  # Whole line functionality; fill in later

  to_path: ->
    # 
    #
    path = ''
    i = 0
    while i < @points.length
      p = @points[i]
      q = @points[i+1]
      switch p.segment.type
        when 'none'
          path += "M#{p.x},#{p.y}"
        when 'straight'
          path += "M#{p.x},#{p.y}L#{q.x},#{q.y}"
        when 'curve'
          path += "M#{p.x},#{p.y}C#{p.segment.c1.x},#{p.segment.c1.y},#{p.segment.c2.x},#{p.segment.c2.y},#{q.x},#{q.y}"
        when 'freehand'
          path += p.segment.path
      i++

    path

module.exports = Line
