
Button = require './button'

ActionButton = class extends Button

  constructor: (@paper, button) ->
    super @paper, button
    @action = button?.action ? ->
      # nothing
    @elements.click @activate

  activate: =>
    @action()

  disable: ->
    @back.attr @prop.disabled
    @elements.unclick @activate

  enable: ->
    @back.attr @prop.normal
    @elements.click @activate
    
module.exports = ActionButton
