###
 (c) 2012, Huub de Beer, H.T.de.Beer@gmail.com
###
class MeasureLine

  # error range
  @EPSILON = 0.01

  to_json: ->
    export_object =
      volume: @volume
      height: @height
      initial_position: @initial_position
      position:
        x: @position.x
        y: @position.y
      side: @side
      movable: @movable
      visible: @visible
    JSON.stringify export_object

  from_json: (mljson) ->
    @volume = mljson.volume
    @height = mljson.height
    @initial_position = mljson.initial_position
    @position = mljson.position
    @side = mljson.side
    @movable = mljson.movable
    @visible = mljson.visible


  constructor: (@volume, @height, @glass, @initial_position = {x: -1, y: -1}, @side = 'right', @visible = false, @movable = true) ->
    @set_position @initial_position

  reset: () ->
    ###
    ###
    @set_position @initial_position

  hide: ->
    @visible = false

  show: ->
    @visible = true

  set_position: (position) ->
    ###
    Set the position of this measure line. Position is a point (x, y). Subsequently the height in mm can be computed.
    ###
    @position = position
    @height = (@glass.foot.y - @position.y) / @glass.unit

  is_correct: ->
    ###
    Is this measure line on the correct height on the glass? That is: is the error smaller than epsilon?
    ###
    Math.abs(@error) <= MeasureLine.EPSILON

  error: ->
    ###
    The distance of this measure line to the correct position in mm. A negative error means it is too hight, a positive distance that it is too low
    ###
    (@glass.height_at_volume @volume) - @height

module.exports = MeasureLine
