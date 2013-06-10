###
(c) 2012, Huub de Beer (H.T.de.Beer@gmail.com)
###

Widget = require '../widget'

class Ruler extends Widget

  constructor: (@canvas, @x, @y, @width, @height, @height_in_mm, @spec = {
    orientation: "vertical"
    rounded_corners: 5
  }) ->
    super(@canvas, @x, @y, @spec)

module.exports = Ruler
