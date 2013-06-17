
GlassTable = require './glass_table'
Simulation = require './simulation'
Grapher = require './grapher'

class FlaskFiller

  constructor: (config) ->
    @config = config

    @glasses = if config?.glasses then config.glasses else []


    @container = d3.select "##{config.id}"

    @simulation_container = @container.append('figure')
      .attr('id', 'simulatie')
    @simulation = new Simulation @, @simulation_container, config
    
    @table = new GlassTable @, @container, config
   

    @graph_container = @container.append('figure')
      .attr('id', 'grafiek')
    @graph = new Grapher @, @graph_container, config

    if @config?.hide_graph
      @graph_container.style 'display', 'none'


  change_glass: (glass) ->
    console.log "changing"
    return =>
      @table.update_row( glass )

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

module.exports = FlaskFiller
