###
(c) 2012, Huub de Beer (H.T.de.Beer@gmail.com)
###

Widget = require '../widget'

class WRuler extends Widget

  constructor: (@canvas, @x, @y, @width, @height, @height_in_mm, @spec = {}) ->
    super(@canvas, @x, @y, @spec)

module.exports = WRuler
