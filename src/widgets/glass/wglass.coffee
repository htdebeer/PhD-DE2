###
###

Widget = require '../widget'
Glass = require './glass'
MeasureLine = require './measure_line'
WMeasureLine = require './wmeasure_line'

class WGlass extends Widget

  constructor: (@canvas, @x, @y, @glass, @spec = {}) ->
    super(@canvas, @x, @y, @spec)
    @points = @_compute_points( @glass )
    @lengths = @_compute_lengths_at_heigth()
    @_draw()
    @place_at @x, @y
    @move_handler = null
    @graph = null
  
  start_manual_diff: =>
    @glasspane.mouseover @show_longdrink
    @glasspane.mouseout @hide_longdrink

  show_longdrink: =>
    @longdrink.show()
    @lml.show()
    @lbl.show()
    @ll.show()
    @lf.show()
    @llp.show()
    @lrp.show()
    @move_handler = @move_handler ? @move_longdrink @
    @glasspane.mousemove @move_handler

  hide_longdrink: =>
    @longdrink.hide()
    @lml.hide()
    @lbl.hide()
    @ll.hide()
    @lf.hide()
    @llp.hide()
    @lrp.hide()
    @lgl.hide()
    @gp.hide()
  
  fit_point: (x, y) ->
    point =
      x: x - @canvas.canvas.parentNode.offsetLeft
      y: y - @canvas.canvas.parentNode.offsetTop
    point

  set_graph: (graph) ->
    @graph = graph

  del_graph: ->
    @graph = null

  move_longdrink: (glassrep) ->
    (e, x, y) =>
      # First fix the point on the page
      p = glassrep.fit_point x, y
      # Then remove the translate of the glass representation to put it the
      # same coordinate system as the original path
      py = p.y - @dy
      # compute the height from the foot and convert it into tenth of mm
      ph = glassrep.points.foot.right.y - py
      h = Math.ceil((ph / glassrep.glass.unit) * Glass.TENTH_OF_MM)
      # find corresponding point on the glass contour
      length = glassrep.lengths[h]
      right = Raphael.getPointAtLength glassrep.glass.path, length
      # compute the left hand point
      left = right.x - 2*(right.x - glassrep.glass.edge.x)
      # compute a nice volume for the longdrink glas with height >= 100
      # pixels
      # radius
      r = (right.x - left)/2
      rmm = r / glassrep.glass.unit
      # start around about 2 cm
      hi = Math.floor(20 * glassrep.glass.unit)

      compute_vol = (rmm, h) ->
        hmm = h / glassrep.glass.unit
        Math.floor(Math.PI * Math.pow(rmm, 2) * hmm/1000)

      while ((compute_vol(rmm, hi) % 2) isnt 0 and (compute_vol(rmm, hi) % 10) isnt 5)
        hi++

      # hi is a nice volume
      vol = compute_vol(rmm, hi)
      BELOW = 10 * glassrep.glass.unit
      # set the max and bottom lines
      # start the longdrink glass about a cm below this point
      if @spec.diff_graph and @graph
        # draw the manual diff over the graph
        OVER_GRAPH_LENGTH = 1000
        # draw and set the longdrnk graph line lgl and set point on graph gp
        gheight = Math.ceil((ph / glassrep.glass.unit) )
        gvol = @glass.volume_at_height gheight
        line = @graph.computer_line
        gpx = line.min.x + gvol / line.x_unit.per_pixel
        gpy = line.max.y - (gheight/10) / line.y_unit.per_pixel
        halfvol = vol / 2
        halfvolpx = halfvol / line.x_unit.per_pixel
        lglpath = "M#{gpx},#{gpy}l#{halfvolpx},#{-hi+BELOW}M#{gpx},#{gpy}l-#{halfvolpx},#{BELOW}"
        @lgl.attr
          path: lglpath
        @lgl.show().toFront()
        @gp.attr
          cx: gpx
          cy: gpy
        @gp.show().toFront()
      else
        @lgl.hide()
        @gp.hide()
        OVER_GRAPH_LENGTH = 0


      @lf.attr
        x: left + @dx
        y: right.y + @dy
        width: right.x - left
        height: BELOW

      path = "M#{right.x},#{right.y-hi+BELOW}H#{-@dx+10}"
      path += "M#{right.x},#{right.y-hi+BELOW}h#{OVER_GRAPH_LENGTH}"
      @lml.attr
        path: path
        transform: "t#{@dx},#{@dy}"
      @lml.toFront()
      
      path = "M#{right.x},#{right.y+BELOW}H#{-@dx+10}"
      path += "M#{right.x},#{right.y+BELOW}h#{OVER_GRAPH_LENGTH}"
      @lbl.attr
        path: path
        transform: "t#{@dx},#{@dy}"
      @lbl.toFront()

      # generate the longdrink glass
      path = "M#{right.x},#{right.y+BELOW}v-#{hi+10}M#{right.x},#{right.y+BELOW}L#{left},#{right.y+BELOW}v-#{hi+10}"
      # and display it after translating it as the glass is translated
      @longdrink.attr
        path: path
        transform: "t#{@dx},#{@dy}"
      # display the points
      @llp.attr
        cx: left + @dx
        cy: right.y + @dy
      @lrp.attr
        cx: right.x + @dx
        cy: right.y + @dy
      # and place label just above the max line
      #
      @ll.attr
        text: "#{vol} ml"
        transform: "t#{left+@dx+10},#{right.y-hi+@dy-10+BELOW}"

  stop_manual_diff: =>
    @longdrink.hide()
    @lgl.hide()
    @gp.hide()
    @glasspane.unmousemove @move_handler
    @glasspane.unmouseover @show_longdrink
    @glasspane.unmouseout @hide_longdrink

  fill_to_height: (height_in_mm) ->
    ###
    Update the fill-part to correspond to a water level equal to the height_in_mm.
    ###
    diameter = (length, glass) ->
      Math.abs(Raphael.getPointAtLength(glass.path, length).x - glass.foot.x) * 2

    height = @glass.foot.y - (height_in_mm * @glass.unit)
    if height < @glass.bowl.y
      # if the height is larger than the base, there is something to fill
      @points.water_level = {}
      @points.water_level.length = length = @lengths[height_in_mm*Glass.TENTH_OF_MM]
      @points.water_level.right = right = Raphael.getPointAtLength @glass.path, length
      @points.water_level.left =
          x: right.x - diameter(length, @glass)
          y: right.y

      # Base part 
      right = Raphael.path2curve Raphael.getSubpath(@glass.path,
        @points.water_level.length, @points.bowl.length)
      left = @_mirror_path_vertically right, @glass.bowl.x

      @water_level.attr
        path: right + "H#{@points.bowl.left.x}"+ left

  _draw: ->
    @paths = @_create_paths()
    base = @canvas.path @paths.base
    base.attr
      fill: '#aaa'
      stroke: 'black'
      'stroke-width': 2
    @widgets.push base

    @water_level = @canvas.path "M0,0"
    @water_level.attr
      fill: '#abf'
      'fill-opacity': 0.4
      stroke: 'none'
    @widgets.push @water_level

    bowl = @canvas.path @paths.bowl
    bowl.attr
      stroke: 'black'
      'stroke-width': 2
    @widgets.push bowl

    
    # add maximum measure line
    maxpoint = Raphael.getPointAtLength(@glass.path, @lengths[@glass.maximum_height * Glass.TENTH_OF_MM])

    max_x = maxpoint.x
    max_y = maxpoint.y
    @max_ml = new MeasureLine @glass.maximum_volume,
      @glass.maximum_height,
      @glass,
      {x: max_x, y: max_y},
      'right',
      true,
      false
    max_ml_representation = new WMeasureLine @canvas, max_x, max_y, @max_ml

    @widgets.push max_ml_representation.widgets

    # max longdrink line
    # "fill"
    @lf = @canvas.rect 0, 0, 0, 0
    @lf.attr
      fill: 'orange'
      'fill-opacity': 0.5
      'stroke': 'none'
    @lf.hide()
    @lml = @canvas.path "M0,0"
    @lml.attr
      stroke: 'orange'
      'stroke-opacity': 0.5
      'stroke-dasharray': '-'
    @lml.hide()
    # bottom longdrink line
    @lbl = @canvas.path "M0,0"
    @lbl.attr
      stroke: 'orange'
      'stroke-opacity': 0.5
      'stroke-dasharray': '-'
    @lbl.hide()
    # longdrink glass for differentiation
    @longdrink = @canvas.path "M0,0"
    @longdrink.attr
      stroke: 'orange'
      'stroke-width': 3
      'stroke-opacity': 0.9
    @longdrink.hide()
    # Longdrink graph on graph
    @lgl = @canvas.path "M0,0"
    @lgl.attr
      stroke: 'orange'
      'stroke-width': 3
      'stroke-opacity': 0.9
    @lgl.hide()
    #longdrink point on graph
    @gp = @canvas.circle 0, 0, 2
    @gp.attr
      fill: 'gray'
    @gp.hide()
    # volume label londrink
    @ll = @canvas.text 0,0, "250 ml"
    @ll.attr
      'font-family': 'sans-serif'
      'font-size': '12pt'
      'text-anchor': 'start'
      fill: 'gray'
    @ll.hide()

    @llp = @canvas.circle 0, 0, 2
    @llp.attr
      fill: 'gray'
    @llp.hide()
    @lrp = @canvas.circle 0, 0, 2
    @lrp.attr
      fill: 'gray'
    @lrp.hide()
    
    @glasspane = @canvas.path @paths.bowl
    @glasspane.attr
      fill: 'white'
      'fill-opacity': 0
      'stroke-width': 5
      'stroke-opacity': 0

    @widgets.push @glasspane
      
  _create_paths: ->
    ###
    Create the path of the part of this glass
    ###
    paths = {}
    # Base part 
    right = Raphael.path2curve Raphael.getSubpath(@glass.path,
      @points.bowl.length, @points.foot.length)
    left = @_mirror_path_vertically right, @glass.foot.x
    paths.base = right + "H#{@points.foot.left.x}"+ left
    # Bowl part
    right = Raphael.path2curve Raphael.getSubpath(@glass.path,
      @points.edge.length, @points.bowl.length)
    left = @_mirror_path_vertically right, @glass.foot.x
    paths.bowl = right + "H#{@points.bowl.left.x}" + left
    paths

  _compute_geometry: () ->
    
    base = Raphael.pathBBox @paths.base
    bowl = Raphael.pathBBox @paths.bowl
    @geometry = {}
    @geometry.top = bowl.y
    @geometry.left = Math.min base.x, bowl.x
    @geometry.bottom = base.y2
    @geometry.right = Math.max base.x2, bowl.b2
    @geometry.width = Math.max base.width, bowl.width
    @geometry.height = base.height + bowl.height
    @geometry.center =
      x: (@geometry.right - @geometry.left) / 2 + @geometry.left
      y: (@geometry.bottom - @geometry.top) / 2 + @geometry.top

  _compute_points: (glass) ->
    ###
    Compute points, lengths, and paths between points for the edge, foot, stem, and bowl
    ###
    diameter = (length) ->
      Math.abs(Raphael.getPointAtLength(glass.path, length).x - glass.foot.x) * 2

    points = {}
    # Length 0 on the path is the edge of the glass
    length = 0

    # from the edge working downward to the foot
    for line in ['edge', 'bowl', 'stem', 'foot']
      points[line] = {}
      points[line].length = length = @_length_at_y glass.path, glass[line].y, length
      points[line].right = right = Raphael.getPointAtLength glass.path, length
      points[line].left =
        x: right.x - diameter(length)
        y: right.y

    points


  _compute_lengths_at_heigth: ->
    lengths = []
    length = 0
    max_length = Raphael.getTotalLength @glass.path
    height = @glass.height_in_mm*Glass.TENTH_OF_MM
    
    while height > 0
      height_in_pixels = @glass.foot.y - ((height * @glass.unit) / Glass.TENTH_OF_MM)
      while length < max_length and Raphael.getPointAtLength(@glass.path, length).y < height_in_pixels
        length++

      lengths[height] = length
      height--

    lengths[0] = @points.foot.length
    lengths



  _length_at_y: (path, y, start = 0) ->
    ###
      Find the length on the path the path hat intersects the horizontal line at y
    ###
    length = start
    max_length = Raphael.getTotalLength path

    while length < max_length and Raphael.getPointAtLength(path, length).y < y
      length++
      
    length


  _mirror_path_vertically: (path, x_line) ->
    ###
    ###
    mirror_x = (x) ->
      x_line - Math.abs(x_line - x)

    # By translating a path to a curve, all path commands are C commands.
    # That makes for easier translation as there is only one command to
    # mirror.
    cpath = Raphael.path2curve path

    cpathsegs = Raphael.parsePathString cpath
    mirror = ""
    mirrorlist = []
    
    # First element is always a M command, first part is 'M', second and
    # third the x and y coordinate, respectively
    [x,y] = cpathsegs[0][1..2]
    
    # For all other elements, which are C commands of the form C, cp1x, cp1y,
    # cp2x, cp2y, x, y, mirror the coordinates
    for segment in cpathsegs[1..cpathsegs.length]
      [cp1x,cp1y,cp2x,cp2y] = segment[1..4]
      mirrorlist.push [mirror_x(cp2x), cp2y, mirror_x(cp1x), cp1y, mirror_x(x), y]
      [x, y] = segment[5..6]

    # Now string the mirrored segments in reversed order together"
    mirror = ('C'+ segment.join(",") for segment in mirrorlist.reverse()).join("")
    mirror


module.exports = WGlass
