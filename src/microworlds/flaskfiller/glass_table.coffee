
Glass = require '../../widgets/glass/glass'

class GlassTable

  constructor: (@flaskfiller, container, @config) ->

    @selected_all = false
    @is_filling = false
    @timer_id = -1
    @editing = false

    @hide_graph = false

    @table = container.append('table')
      .classed('table', true)
      .classed('table-striped', true)
      .classed('table-hover', true)

    @head = @_create_head()
    

    @body = @table.append('tbody')
    @glasses = []
    for glass in @config.glasses
      @add_row glass

    @foot = @_create_foot()

  graph: (glass) ->
    return =>
      @flaskfiller.graph.toggle_graph(glass)

  chart: (glass) ->
    return =>
      @flaskfiller.graph.toggle_chart(glass)

  empty: (glass) ->
    icon = d3.select("##{glass.name}-fill")
    return =>
      glass.glass.make_empty()
      glass?.representation.fill_to_height glass.glass.current_height
      icon.classed('icon-pause', false).classed('icon-play', true).classed('icon-glass', false)
      @update_row glass

  full: (glass) ->
    icon = d3.select("##{glass.name}-fill")
    return =>
      glass.glass.fill_to_height glass.glass.maximum_height
      glass?.representation.fill_to_height glass.glass.current_height
      icon.classed('icon-pause', false).classed('icon-play', false).classed('icon-glass', true)
      @update_row glass


  set_volume: (glass) ->
    return =>
      volume = parseFloat d3.select("##{glass.name}-volume").property('value')
      glass.glass.fill_to_volume volume
      glass?.representation.fill_to_height glass.glass.current_height
      @update_row glass

  set_height: (glass) ->
    return =>
      height = parseFloat d3.select("##{glass.name}-height").property('value')
      glass.glass.fill_to_height height * 10
      glass?.representation.fill_to_height glass.glass.current_height
      @update_row glass

  set_time: (glass) ->
    return =>
      time = parseFloat d3.select("##{glass.name}-time").property('value')
      volume = time * @config.flow_rate
      glass.glass.fill_to_volume volume
      glass?.representation.fill_to_height glass.glass.current_height
      @update_row glass

      
  update_row: (glass) ->
    d3.select("##{glass.name}-volume").property('value', glass.glass.volume())
    d3.select("##{glass.name}-height").property('value', glass.glass.height())
    d3.select("##{glass.name}-time").property('value', glass.glass.time(@config.flow_rate))



  filling: (glass) ->
    icon = d3.select("##{glass.name}-fill")
    time_step = 50
    return =>
      if @is_filling
        icon.classed('icon-pause', false).classed('icon-play', true)
        glass.representation.stop_filling()
        clearInterval @timer_id
        @is_filling = false
      else
        icon.classed('icon-play', false).classed('icon-pause', true)
        glass.representation.start_filling()
        @timer_id = setInterval @fill(glass), time_step
        @is_filling = true

  fill: (glass) ->
    time_step = 50
    ml_per_time_step = @config.flow_rate *( time_step / 1000)
    icon = d3.select("##{glass.name}-fill")
    return =>
      if @is_filling and not glass.glass.is_full()
        volume = glass.glass.volume() + ml_per_time_step
        glass.glass.fill_to_volume volume
        glass.representation.fill_to_height glass.glass.current_height
        @update_row(glass)

      else if glass.glass.is_full()
        icon.classed('icon-pause', false).classed('icon-glass', true)
        glass.representation.stop_filling()
        clearInterval @timer_id
        @is_filling = false

  add_row: (glass) ->
    row = @body.append('tr')
      .attr('id', glass.name)

    row.append('td')
      .append('input')
        .attr('id', "#{glass.name}-selected")
        .attr('type', 'checkbox')
        .on('click', ->
          if @.checked
            glass.selected = true
          else
            glass.selected = false
        )
    glass.selected = false


    row.append('td')
      .text(glass.name)

    row.append('td')
      .append('input')
      .attr('id', "#{glass.name}-volume")
      .classed('input-mini', true)
      .attr('type', 'number')
      .attr('min', 0)
      .attr('max', glass.glass.maximum_volume)
      .attr('step', 'any')
      .attr('value', glass.glass.volume())
      .on('change', @set_volume(glass))

    row.append('td')
      .append('input')
      .attr('id', "#{glass.name}-height")
      .classed('input-mini', true)
      .attr('type', 'number')
      .attr('min', 0)
      .attr('max', glass.glass.maximum_height)
      .attr('step', 'any')
      .attr('value', glass.glass.height())
      .on('change', @set_height(glass))

    row.append('td')
      .append('input')
      .attr('id', "#{glass.name}-time")
      .classed('input-mini', true)
      .attr('type', 'number')
      .attr('min', 0)
      .attr('max', glass.glass.to_time(glass.glass.maximum_volume, @config.flow_rate))
      .attr('step', 'any')
      .attr('value', glass.glass.time(@config.flow_rate))
      .on('change', @set_time(glass))

    row.append('td')
      .append('button')
      .classed('btn', true)
      .append('i')
      .attr('id', "#{glass.name}-fill")
      .classed('icon-play', true)
      .on('click', @filling(glass))

    row.append('td')
      .append('button')
      .classed('btn', true)
      .append('i')
      .attr('id', "#{glass.name}-empty")
      .classed('icon-backward', true)
      .on('click', @empty(glass))

    row.append('td')
      .append('button')
      .classed('btn', true)
      .append('i')
      .attr('id', "#{glass.name}-full")
      .classed('icon-forward', true)
      .on('click', @full(glass))


    row.append('td')
    #.append('button')
    #.append('i')
    #.attr('id', "#{glass.name}-edit")
    #.classed('icon-wrench', true)
    #.on('click', @edit(glass))

    gb = row.append('td')
      .append('button')
      .classed('btn', true)
      .classed('graphbutton', true)
      
    gb.append('i')
      .attr('id', "#{glass.name}-showgraph")
      .classed('icon-picture', true)
      .on('click', @graph(glass))
    gb.attr('disabled', 'true') if @config?.hide_graph

    gb = row.append('td')
      .append('button')
      .classed('btn', true)
      .classed('graphbutton', true)

    gb.append('i')
      .attr('id', "#{glass.name}-showchart")
      .classed('icon-signal', true)
      .on('click', @chart(glass))
    gb.attr('disabled', 'true') if @config?.hide_graph

    row.append('td')
      .append('button')
      .classed('btn', true)
      .append('i')
      .attr('id', "#{glass.name}-remove")
      .classed('icon-remove-sign', true)
      .on('click', =>
        @flaskfiller.remove glass
      )

    glass.row = row
    @glasses.push glass
    

  remove_row: (glass) ->
    glass.row.remove()

  _name_exists: (name) ->
    same_names = (glass.name for glass in @glasses when glass.name is name)
    if same_names.length > 0
      return true
    else
      return false


  _add_from_menu: (name, spec) ->

    random_color = ->
      hexes = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']
      colors = []
      i = 0
      while i < 6
        colors.push hexes[Math.round(Math.random()*(hexes.length-1))]
        i++

      "##{colors.join ''}"

    if @_name_exists(name)
      i = 1
      while @_name_exists("#{name}-#{i}")
        i++
      name = "#{name}-#{i}"

    return =>
      @flaskfiller.add( {
        name: name
        glass: new Glass spec
        color: random_color()
      })

  _create_add_menu: (place)->
    add_button = place.append('div')
        .classed('btn-group', true)
        .classed('dropup', true)
    add_button.append('a')
          .classed('btn', true)
          .classed('dropdown-toggle', true)
          .attr('data-toggle', 'dropdown')
          .attr('href', '#')
          .html('Voeg een glas toe <span class="caret"></span>')
    menu = add_button.append('ul')
      .classed('dropdown-menu', true)
    for name, spec of @config.glass_specs
      item = menu.append('li')
        .append('a')
          .attr('href', '#')
          .attr('data-glassname', name)
          .text(name.replace(/_/, ' '))

      item.on('click', @_add_from_menu(name, spec))
  
  _create_foot: ->
    foot = @table.append('tfoot').append('tr')
    foot.append('td')
    
    @_create_add_menu foot.append('td')

    foot.append('th')
      .classed('text-right', true)
      .attr('colspan', '3')
      .text 'pas een actie toe op de geselecteerde glazen'
    foot.append('td')
      #.append('button')
      #.append('i')
      #.classed('icon-play', true)
    foot.append('td')
      .append('button')
      .classed('btn', true)
      .append('i')
      .classed('icon-backward', true)
      .on('click', =>
        for glass in @glasses
          if glass.selected
            @empty(glass)()
      )
    foot.append('td')
      .append('button')
      .classed('btn', true)
      .append('i')
      .classed('icon-forward', true)
      .on('click', =>
        for glass in @glasses
          if glass.selected
            @full(glass)()
      )
    foot.append('td')
    foot.append('td')
    foot.append('td')
    foot.append('td')
      .append('button')
      .classed('btn', true)
      .append('i')
      .classed('icon-remove-sign', true)
      .on('click', =>
        for glass in @glasses
          if glass.selected
            @flaskfiller.remove glass
      )
    foot

  _create_head: ->
    head = @table.append('thead').append('tr')
    head.append('th')
      .append('input')
        .attr('id', "select-all")
        .attr('type', 'checkbox')
        .on('click', =>
          if @selected_all
            for glass in @glasses
              glass.row.select("##{glass.name}-selected").property('checked', false)
              glass.selected = false
            @selected_all = false
          else
            for glass in @glasses
              glass.row.select("##{glass.name}-selected").property('checked', true)
              glass.selected = true
            @selected_all = true
        )

    head.append('th').text 'naam'
    head.append('th').text 'volume (ml)'
    head.append('th').text 'hoogte (cm)'
    head.append('th').text 'tijd (sec)'
    head.append('th').attr('colspan', '7').text 'acties'
    head



module.exports = GlassTable
