
Button = require './button'

OptionButton = class extends Button

  constructor: (@paper, button, @group) ->
    super @paper, button
    @value = button.value ? "no value given"
    @on_select = button?.on_select ? ->
      ""
    if button.chosen
      @back.attr @prop.activated
      @group.value = @value

    @elements.click @select

  select: =>
    for button in @group.buttons
      button.deselect()
    @back.attr @prop.activated
    @group.value = @value
    @on_select()

  deselect: ->
    @back.attr @prop.normal

  disable: ->
    @back.attr @prop.disabled
    @elements.unclick @select

  enable: ->
    @back.attr @prop.normal
    @elements.click @select


module.exports = OptionButton
