
GlassTable = require './glass_table'
Simulation = require './simulation'
Grapher = require './grapher'

class FlaskFiller

  constructor: (config) ->
    @config = config

    @glasses = if config?.glasses then config.glasses else []


    @container = d3.select "##{config.id}"
    @container.attr('class', 'accordion')

    
    @simulation_container = @_create_accordion_group @container,
      'simulation',
      'Glazen vullen simulatie'
    @simulation = new Simulation @, @simulation_container, config

    @table_container = @_create_accordion_group @container,
      'table',
      'Glazen'
    @table = new GlassTable @, @table_container, config

    @graph_container = @_create_accordion_group @container,
      'graph',
      'Grafiek'
    @graph = new Grapher @, @graph_container, config


  add: (glass) ->
    @glasses.push glass
    @table.add_row glass
    @simulation.add_glass glass
    @graph.add_graph glass

  remove: (glass) ->
    @table.remove_row glass
    @simulation.remove_glass glass
    @graph.remove_graph glass
    @glasses.splice @glasses.indexOf(glass), 1

  _create_accordion_group: (parent, name, heading_text, open = true) ->
    parent_id = parent.attr 'id'
    content_id = "#{parent_id}-#{name}"

    group = parent.append('div')
        .classed('accordion-group', true)

    heading = group.append('div')
      .classed('accordion-heading', true)
      .append('a')
        .classed('accordion-toggle', true)
        .attr('data-toggle', 'collapse')
        .attr('data-parent', "##{content_id}")
        .attr('href', "##{content_id}")
        .text(heading_text)

    content_container = group.append('div')
      .attr('id', content_id)
      .classed('accordion-body', true)
      .classed('collapse', true)

    content_container.attr('class', 'accordion-body collapse in') if open

    content = content_container.append('div')
        .classed('accordion-inner', true)


    content



module.exports = FlaskFiller
