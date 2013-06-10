
OptionButton = require './option_button'

ButtonGroup = class

  constructor: (@paper, buttonlist) ->
    @buttons = []
    @value = ""
    for button in buttonlist
      @buttons.push new OptionButton @paper, button, @
    

  disable: ->
    for button in @buttons
      button.disable()

  enable: ->
    for button in @buttons
      button.enable()

  select: (button) ->
    for i in @buttons
      if i.value is button
        i.select()

  deselect: (button) ->
    for i in @buttons
      if i.value is button
        i.deselect()

module.exports = ButtonGroup
