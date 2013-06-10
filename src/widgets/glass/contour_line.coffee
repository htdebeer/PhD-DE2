#
# contour_line.coffee (c) 2012 HT de Beer
#
# A contour line models the right-hand side of a glass. A contour line is a
# list of points. A point has the following properties:
#
#   ∙ x, the x coordinate
#   ∙ y, the y coordinate
#   ∙ border, border ∈ {none, foot, stem, bowl, edge}
#   ∙ segment, the line segment starting from this point to the next, if
#              there is a next point. A segment has the following
#              properties:
#     ∙ type, type ∈ {straight, curve}
#     ∙ c1, control point for this point, only when type = curve
#       ∙ x, the x coordinate of the control point
#       ∙ y, the y coordinate of the control point
#     ∙ c2, control point for the next point, only when type = curve
#       ∙ x, the x coordinate of the control point
#       ∙ y, the y coordinate of the control point
#
# For a contour line the followin holds:
#
#   min.y ≤ edge.y ≤ bowl.y ≤ stem.y ≤ foot.y = max.y
# ∧
#   (∀p: 0 ≤ p < |points| - 1: points[p].y < points[p+1].y)
# ∧
#   (∀p: 0 ≤ p < |points|: mid.x ≤ points[p].x ≤ max.x)
#   
ContourLine = class

  constructor: (left, top, width, height, @mm_per_pixel, @record = false) ->
    @mid =
      x: left
      y: Math.floor(top + height/2)
    @min =
      x: left - width
      y: top
      width: 25
    @max =
      x: left + width
      y: top + height

    # initial borders
    FOOTHEIGHT = 20
    STEMWIDTH = 10
    STEMHEIGHT = 20
    @foot =
      x: Math.floor(@mid.x + width/3)
      y: @max.y
      border: 'foot'
      segment:
        type: 'straight'
        c1:
          x: 0
          y: 0
        c2:
          x: 0
          y: 0
    @stem =
      x: Math.floor(@mid.x + width/3)
      y: Math.floor(@max.y - FOOTHEIGHT)
      border: 'stem'
      segment:
        type: 'straight'
        c1:
          x: 0
          y: 0
        c2:
          x: 0
          y: 0
    @bowl =
      x: Math.floor(@mid.x + width/3)
      y: Math.floor(@max.y - (FOOTHEIGHT + STEMHEIGHT))
      border: 'bowl'
      segment:
        type: 'straight'
        c1:
          x: 0
          y: 0
        c2:
          x: 0
          y: 0
    @edge =
      x: Math.floor(@mid.x + width/3)
      y: Math.floor(@max.y - (height/2))
      border: 'edge'
      segment:
        type: 'straight'
        c1:
          x: 0
          y: 0
          line: null
          representation: null
        c2:
          x: 0
          y: 0
          line: null
          representation: null
    @points = [@edge, @bowl, @stem, @foot]




  # queries
  get_point: (p) ->
    @points[p]

  get_point_above_height: (h) ->
    p = 0
    while p < @points.length and @points[p].y < h
      p++
    p - 1


  can_add_point: (x, y) ->
    # if x, y on the line: true
    #
    result = false
    p = @get_point_above_height y
    if p isnt -1
      point = @points[p]
      if point.y is y
        # point already exists
        result = false
      else
        # Not already a point
        result = true
    result
    


  can_remove_point: (p) ->
    @points[p].border is 'none'

  can_move_point: (p, x, y, r = 1) ->
    result = false
    if @mid.x + r <= x <= @max.x and @min.y <= y <= @max.y
      if 0 < p < @points.length - 1
        # there is a previous and next point
        if @points[p-1].y + r < y < @points[p+1].y - r
          result = true
      else
        if p is 0
          result = y < @points[p+1].y and x >= (@mid.x + @min.width)
        else
          # p = |points| - 1
          result = @points[p-1].y < y
    result
    
  can_move_control_point: (p, x, y) ->
    if p < @points.length - 1
      above = @points[p]
      below = @points[p+1]
      return @mid.x <= x <= @max.x and above.y <= y <= below.y
    else
      return false


  can_move_border: (border, x, y) ->

  find_point_at: (y, r = 1) ->
    p = 0
    while p < @points.length and not((y - r) <= @points[p].y <= (y + r))
      p++
    p = if p is @points.length then -1 else p

  find_point_near: (x, y, r = 1) ->
    # Find a point, if any, in the circle with origin x, y and radius r

    found = -1
    ar = 0
    while found is -1 and ar < r
      found = Math.max(@find_point_at(y + ar), @find_point_at(y - ar))
      if found isnt -1 and x - ar <= @points[found].x  <= x + ar
        break
      else
        found = -1
      ar++
    found
      
  # actions
  add_point: (x, y, representation) ->
    p = @get_point_above_height y
    # it never is the first or last point
    head = []
    head = @points[0..p] unless p < 0

    tail = @points[p+1..]
    above = @points[p]
    below = @points[p+1]
    point =
      x: x
      y: y
      border: 'none'
      segment:
        type: 'straight'
        c1:
          x: 0
          y: 0
          line: null
          representation: null
        c2:
          x: 0
          y: 0
          line: null
          representation: null
      representation: representation
    above.segment.c2.y = y - Math.abs(above.segment.c2.y - below.y)

    @points = head.concat point, tail
    point


  remove_point: (p) ->
    head = @points[0...p]
    tail = if p is @points.length - 1 then [] else @points[p+1..]
    @points = head.concat tail

  move_point: (p, x, y) ->
    @points[p].x = x
    @points[p].y = y
    if @points[p].segment.type is 'curve'
      @set_control_points p
    if p isnt 0 and @points[p-1].segment.type is 'curve'
      @set_control_points (p-1)

  set_control_points: (p) ->
    if p isnt @points.length - 1
      above = @points[p]
      below = @points[p+1]
      dxc1 = Math.abs(@mid.x - above.x)/2
      dxc2 = Math.abs(@mid.x - below.x)/2
      dy = Math.abs(above.y - below.y)/4
      above.segment.c1.x = above.x - dxc1
      above.segment.c1.y = above.y + dy
      above.segment.c2.x = below.x - dxc2
      above.segment.c2.y = below.y - dy


  make_curve: (p) ->
    point_segment = @points[p].segment
    point_segment.type = 'curve'
    @set_control_points p


  make_straight: (p) ->
    @points[p].segment.type = 'straight'
    @points[p].segment.c1.representation.remove()
    @points[p].segment.c1.line.remove()
    @points[p].segment.c2.line.remove()
    @points[p].segment.c2.representation.remove()
    @points[p].segment.c1.representation = null
    @points[p].segment.c1.line = null
    @points[p].segment.c2.line = null
    @points[p].segment.c2.representation = null


  move_control_point: (p, cp, x, y) ->
    
    if cp is 1
      point = @points[p].segment.c1
    else
      point = @points[p].segment.c2

    point.x = x
    point.y = y


  move_border: (border, x, y) ->

  # line actions
  to_path: ->
    # There are at least four points
    p = @points[0]
    path = "M#{p.x},#{p.y}"
    i = 0
    while i < @points.length - 1
      p = @points[i]
      q = @points[i+1]
      switch p.segment.type
        when 'straight'
          path += "L#{q.x},#{q.y}"
        when 'curve'
          path += "C#{p.segment.c1.x},#{p.segment.c1.y},#{p.segment.c2.x},#{p.segment.c2.y},#{q.x},#{q.y}"
      i++

    path
    

  to_glass_path: (part = 'full') ->
    
    i = 0
    switch part
      when 'full'
        i = 0
      when 'base'
        while @points[i].border isnt 'bowl'
          i++

    p = @points[i]
    path = "M#{p.x},#{p.y}"
    while i < @points.length - 1
      p = @points[i]
      q = @points[i+1]
      switch p.segment.type
        when 'straight'
          path += "L#{q.x},#{q.y}"
        when 'curve'
          path += "C#{p.segment.c1.x},#{p.segment.c1.y},#{p.segment.c2.x},#{p.segment.c2.y},#{q.x},#{q.y}"
      i++

    # mirror
    mid = @mid
    mirror = (x) ->
      x - 2*(x-mid.x)
    p = @points[i]
    path += "H#{mirror(p.x)}"
    while i > 0
      p = @points[i]
      q = @points[i-1]
      if part is 'base' and p.border is 'bowl'
        path += "H#{p.x}H#{mirror(p.x)}"
        break

      switch q.segment.type
        when 'straight'
          path += "L#{mirror(q.x)},#{q.y}"
        when 'curve'
          path += "C#{mirror(q.segment.c2.x)},#{q.segment.c2.y},#{mirror(q.segment.c1.x)},#{q.segment.c1.y},#{mirror(q.x)},#{q.y}"
      i--

    path
    
  to_glass: (spec) ->
    height_in_mm = Math.floor((@foot.y - @edge.y) * @mm_per_pixel)
    path = @to_relative_path()
    midfoot =
      x: @mid.x
      y: @foot.y
    midstem =
      x: @mid.x
      y: @stem.y
    midbowl =
      x: @mid.x
      y: @bowl.y
    midedge =
      x: @mid.x
      y: @edge.y
    glass = new Glass path, midfoot, midstem, midbowl, midedge, height_in_mm, spec
    glass

  from_glass: (glass)->
    # put glass as relative path in path
    # Computer glass's mm_per_pixel
    mm_per_pixel = glass.height_in_mm / (glass.foot.y - glass.edge.y)
    factor = @mm_per_pixel / mm_per_pixel
    # now compute 


    
  to_relative_path: ->
    path = @to_path()
    relsegs = Raphael.pathToRelative path
    relpath = ""
    for seg in relsegs
      for elt in seg
        relpath += "#{elt} "

    relpath.replace /\s$/, ''

module.exports = ContourLine
