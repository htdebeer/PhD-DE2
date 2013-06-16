
# wtap.coffee (c) 2012 HT de Beer
#
# tab and filling simulator
#

Widget = require '../widget'

class WTap extends Widget

  constructor: (@canvas, @x, @y, @spec) ->

    super(@canvas, @x, @y, @spec)
   
    @PADDING = 5
    @TIME_LABEL_SEP = 10
    @TAB_SEP = 5
    @GROUP_SEP = 15

    @mode = 'start'
    @timer = false
    @volume = 0
    @time = 0
    @speed = @spec.flow_rate  #ml/sec

    @time_step = 50
    @ml_per_time_step = (@speed/1000) * @time_step

    @speed_per_msec = @speed / 1000
    @msec_per_tenth_ml = 1 / (@speed_per_msec * 10)
    @sec_per_tenth_ml = 1 / (@speed*10)


    @filling = false
    @id = 0

    @draw()
    @graph?.attr
      path: @glass.get_current_graph()

  empty: =>
    @time = 0
    @volume = 0
    @update_labels()
    @filling = false
    @glass.make_empty(@sec_per_tenth_ml)
    @spec.glass_to_fill.fill_to_height @glass.current_height
    @graph?.attr
      path: @glass.get_current_graph()
    @stream.hide()

  pause: =>
    @stream.hide()
    clearInterval @id
    @filling = false

  start: =>
    clearInterval @id
    @filling = true
    @id = setInterval @fill, @time_step
    @stream.show()

  fill: =>
    if @filling and not @glass.is_full()
      @time += @time_step / 1000
      @volume += @ml_per_time_step
      @update_labels()
      @glass.fill_to_volume @volume
      @spec.glass_to_fill.fill_to_height @glass.current_height
      water_level_height = (@spec.glass_to_fill.points.water_level.left.y-@spec.glass_to_fill.points.edge.left.y) + @spec.stream_extra
      @graph?.attr
        path: @glass.get_current_graph()
      @stream.attr
        height: water_level_height

    else if @glass.is_full()
      @simulation.select 'end'
      

  fill_to_next_ml: =>
    @stream.hide()
    height = @glass.current_height
    next_height = @glass.maximum_height
    for vol, ml of @glass.measure_lines
      if ml.height > height
        next_height = Math.min next_height, ml.height

    @glass.fill_to_height Math.ceil(next_height)
    @volume = @glass.current_volume
    if next_height is @glass.maximum_height
      @volume = @glass.maximum_volume
    @time = @volume / @speed
    @filling = false
    @update_labels()
    clearInterval @id
    @spec.glass_to_fill.fill_to_height @glass.current_height
    @graph?.attr
      path: @glass.get_current_graph()
    

  full: =>
    @stream.hide()
    @volume = @glass.maximum_volume
    @time = @sec_per_tenth_ml * @volume * 10
    @filling = false
    @glass.fill_to_volume @volume
    @update_labels()
    clearInterval @id
    @spec.glass_to_fill.fill_to_height @glass.current_height
    @graph?.attr
      path: @glass.get_current_graph()

  update_labels: ->
    @label.attr
      text: "#{@volume.toFixed(1)} ml"
    @time_label.attr
      text: "#{@time.toFixed(1)} seconden"
  
  change_mode: (mode) ->
    @mode = mode


  draw: ->
    @time_label = @canvas.text @x, @y + @PADDING +  @TIME_LABEL_SEP, "30,9 seconden"
    @time_label.attr
      'font-family': 'sans-serif'
      'font-size': '18pt'
      'text-anchor': 'end'
    tlbb = @time_label.getBBox()
    @time_label.hide()
    @widgets.push @time_label

    tappath = "M 0 27.5 V 20 A 10 10 90 0 1 10 10 L 20 10 V 5
                    H 12.5 A 1.25 1.25 90 0 1 12.5 2.25 H 21.25 
                    A 1.25 1.25 180 0 1 23.75 2.25 H 32.5 
                    A 1.25 1.25 90 0 1 32.5 5 H 25 V 10
                    H 40 V 5 A 2.5 2.5 90 0 1 42.5 2.5 V 27.5
                    A 2.5 2.5 90 0 1 40 25 V 20 H 12.5
                    A 2.5 2.5 90 0 0 10 22.5 V 27.5 Z"
    @tap = @canvas.path tappath
    @tap.attr
        stroke: '#bbb'
        fill: '#ddd'
        'fill-opacity': 0.2
        transform: 's3'
    tapbb = @tap.getBBox(true)


    tapx = @x + (tapbb.width)/2
    tapy = @y + @PADDING + @TIME_LABEL_SEP + tlbb.height*2 + @TIME_LABEL_SEP
    @tap.transform "...T#{tapx},#{tapy}"
    @time_label.attr
      x: @x + (tlbb.width)/2 + tlbb.width
      text: "0 seconden"
      y: @y + @PADDING +  @TIME_LABEL_SEP + tlbb.height/3

    bbtap = @tap.getBBox()
    @widgets.push @tap

    @label = @canvas.text 0, 0, "888,8 ml"
    @label.attr
        'font-family': 'Helvetica, Arial, sans-serif'
        'font-size': 18
        'text-anchor': 'end'
    bblabel = @label.getBBox()
    LABEL_SEP = 10
    @label.attr
        x: bbtap.x + bbtap.width - LABEL_SEP
        y: bbtap.y + bbtap.height - bblabel.height - LABEL_SEP*1.5
        text: "0 ml"
    @widgets.push @label

    stream_x = bbtap.x + 3
    stream_y = bbtap.y2
    @stream = @canvas.rect stream_x, stream_y, 25, 0
    @stream.attr
      fill: '#abf'
      'fill-opacity': 0.1
      stroke: 'none'
    @widgets.push @stream
    @stream.hide()


module.exports = WTap
