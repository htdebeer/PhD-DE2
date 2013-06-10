Button = class

  @WIDTH = 34
  @set_width: (width) ->
    @WIDTH = width
  
  @BASEPATH = '.'
  @set_base_path: (basepath = '.') ->
    @BASEPATH = basepath

  constructor: (@paper, button) ->
    @prop = @initialize_properties()
    @x = button?.x ? 0
    @y = button?.y ? 0
    @icon = button?.icon ? "none.png"
    @tooltip = button?.tooltip ? ""
    @draw()
  

  initialize_properties: ->
    {
      corners: 2
      normal:
        fill: 'white'
        stroke: 'silver'
        'fill-opacity': 1
        'stroke-opacity': 0.5
        'stroke-width': 0.5
      disabled:
        fill: 'gray'
        stroke: 'silver'
        'fill-opacity': 0.5
        'stroke-opacity': 0.8
      activated:
        'stroke-width': 2
        fill: 'yellow'
        stroke: 'gray'
        'fill-opacity': 0.25
        'stroke-opacity': 1
      switched_on:
        fill: 'purple'
        'stroke-width': 2
        stroke: 'gray'
        'fill-opacity': 0.25
        'stroke-opacity': 1
      highlight:
        fill: 'orange'
        stroke: 'gray'
        'fill-opacity': 0.5
        'stroke-opacity': 1
    }


  draw: ->
    width = Button.WIDTH
    @back = @paper.rect @x, @y, width, width
    @back.attr @prop.normal
    basepath = Button.BASEPATH
    @image = @paper.image "#{basepath}/#{@icon}.png", @x+1, @y+1, width - 2, width - 2
    @image.attr
      'font-family': 'sans-serif'
      'font-size': "#{width-2}px"
      title: @tooltip

    @elements = @paper.set @back, @image

module.exports = Button
