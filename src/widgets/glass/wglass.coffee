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



  start_filling: ->
    # place tap on richt place
    # SEP = 30
    # tapbb = @tap.getBBox(true)

    # @_compute_geometry()
    # 
    # 

    # tapx = @geometry.center.x - (tapbb.width)/2
    # tapy = @geometry.top - SEP
    # @tap.transform "...T#{tapx},#{tapy}"
    # @tap.show()
    


  stop_filling: ->
    #@tap.hide()

    

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
      fill: @spec?.fill ? '#abf'
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

    @glasspane = @canvas.path "#{@paths.bowl} #{@paths.base}"
    @glasspane.attr
      fill: 'white'
      'fill-opacity': 0
      'stroke-width': 5
      'stroke-opacity': 0
      'stroke': 'gray'

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
    @geometry.height = base.y2 + bowl.y1
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
