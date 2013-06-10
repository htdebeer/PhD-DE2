#
# wtap.coffee (c) 2012 HT de Beer
#
# tab and filling simulator
#

Button = require '../buttons/button'
ActionButton = require '../buttons/action_button'
SwitchButton = require '../buttons/switch_button'
OptionButton = require '../buttons/option_button'
ButtonGroup = require '../buttons/button_group'

Tap = class

  constructor: (@x, @y, properties) ->
    @spec = @initialize_properties properties
    @BUTTON_WIDTH = 26
    Button.set_width @BUTTON_WIDTH
    @BUTTON_SEP = 5
    @TIME_LABEL_SEP = 5
    @TAB_SEP = 5
    @GROUP_SEP = 15

    Button.set_base_path @spec.icon_path
    @actions = {
      start:
        button:
          type: 'group'
          option_group: 'simulation'
          group: 'simulation'
          icon: 'media-skip-backward'
          tooltip: 'Maak het glas leeg'
          on_select: =>
            @change_mode 'start'
          enabled: true
          default: true
      pause:
        button:
          type: 'group'
          option_group: 'simulation'
          group: 'simulation'
          icon: 'media-playback-pause'
          tooltip: 'Pauzeer het vullen van het glas'
          on_select: =>
            @change_mode 'pause'
          enabled: true
      play:
        button:
          type: 'group'
          option_group: 'simulation'
          group: 'simulation'
          icon: 'media-playback-start'
          tooltip: 'Vul het glas'
          on_select: =>
            @change_mode 'play'
          enabled: true
      play_fast:
        button:
          type: 'group'
          option_group: 'simulation'
          group: 'simulation'
          icon: 'media-seek-forward'
          tooltip: 'Vul sneller'
          on_select: =>
            @change_mode 'play_fast'
          enabled: true
      end:
        button:
          type: 'group'
          option_group: 'simulation'
          group: 'simulation'
          icon: 'media-skip-forward'
          tooltip: 'Vul glas helemaal'
          on_select: =>
            @change_mode 'end'
          enabled: true
      time:
        button:
          type: 'switch'
          group: 'option'
          icon: 'chronometer'
          tooltip: 'Laat de tijd zien'
          on_switch_on: =>
            #  console.log "tijd aan"
          on_switch_off: =>
            # console.log "tijd uit"
    }

    @mode = 'start'
    @time = false
    @draw()
  
  switch_mode: (mode) ->
    @mode = mode

  initialize_properties: (properties) ->
    # Initialize properties with properties or default values
    p = {}
    p.buttons = properties?.buttons ? ['start', 'pause', 'play', 'play_fast', 'end', 'time']
    p.icon_path = properties?.icon_path ? 'lib/icons' 
    p
          

  draw: ->
    @draw_buttons

  draw_buttons: ->
    x = @x
    y = @y
    @mode = ""

    
    group = ''
    optiongroups = {}
    sep = 0
    @buttons = {}
    for name, action of @actions
      if name in @prop.buttons
        # only those buttons set are put on the graph
        button = action.button

        if group isnt ''
          if button.group is group
            x += @BUTTON_WIDTH + @BUTTON_SEP
          else
            x += @BUTTON_WIDTH + @GROUP_SEP
        group = button.group



        switch button.type
          when 'action'
            @buttons.name = new ActionButton @paper,
              x: x
              y: y
              icon: button.icon
              tooltip: button.tooltip
              action: button.action
          when 'switch'
            @buttons.name = new SwitchButton @paper,
              x: x
              y: y
              icon: button.icon
              tooltip: button.tooltip
              switched_on: button?.switched_on ? false
              on_switch_on: button.on_switch_on
              on_switch_off: button.on_switch_off
          when 'group'
            optiongroups[button.option_group] = optiongroups[button.option_group] ? []
            optiongroups[button.option_group].push {
              x: x
              y: y
              icon: button.icon
              tooltip: button.tooltip
              value: name
              on_select: button.on_select
              chosen: button.default ? false
            }


    # Add and create buttongroups
    for name, optiongroup of optiongroups
      buttongroup = new ButtonGroup @paper, optiongroup
      for button in buttongroup.buttons
        @buttons[button.value] = button

    
module.exports = Tap
