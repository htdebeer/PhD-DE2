Button = require './button'

SwitchButton = class extends Button

  constructor: (@paper, button) ->
    super @paper, button
    @switched_on = button?.switched_on ? false
    @on_switch_on = button?.on_switch_on ? ->
      # nothing
    @on_switch_off = button?.on_switch_off ? ->
      # nothing

    if @switched_on
      @back.attr @prop.switched_on
      @on_switch_on()
    else
      @on_switch_off()
    @elements.click @switch

  switch: =>
    if @switched_on
      @switched_on = false
      @back.attr @prop.normal
      @on_switch_off()
    else
      @switched_on = true
      @back.attr @prop.switched_on
      @on_switch_on()
  
  disable: ->
    @back.attr @prop.disabled
    @elements.unclick @switch

  enable: ->
    @back.attr @prop.normal
    @elements.click @switch


module.exports = SwitchButton
