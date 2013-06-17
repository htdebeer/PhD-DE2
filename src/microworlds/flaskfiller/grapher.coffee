

class Grapher

  constructor: (@flaskfiller, container, @config) ->
    @CONTAINER_DIMENSIONS =
      width: @config.graph.dimensions.width
      height: @config.graph.dimensions.height
    @MARGINS =
      top: 10
      right: 20
      left: 60
      bottom: 60
    @GRAPH_DIMENSIONS =
      width: @CONTAINER_DIMENSIONS.width - @MARGINS.left - @MARGINS.right
      height: @CONTAINER_DIMENSIONS.height - @MARGINS.top - @MARGINS.bottom


    @QUANTITIES = @config.graph.quantities
    @set_x_quantity('time')
    @set_y_quantity('height')
    @step_size = @QUANTITIES['time'].step

      
    @svg_graph = container.append('svg')
        .attr('width', @CONTAINER_DIMENSIONS.width)
        .attr('height', @CONTAINER_DIMENSIONS.height)
      .append('g')
        .attr('transform', "translate(#{@MARGINS.left},#{@MARGINS.top})")
        .attr('id', 'graph_container')

    @glasses = []
    for glass in @config.glasses
      @add_graph glass

    @graph_settings = container.append('form')
      .classed('form-inline', true)

    @graph_settings.append('label').text 'stapgrootte'
    @stepsize = @graph_settings.append('input')
      .attr('id', 'stepsize')
      .classed('input-mini', true)
      .attr('type', 'number')
      .attr('min', '0.01')
      .attr('step', 'any')
      .attr('value', 1)
      .on('change', @set_step_size())
    @graph_settings.append('label').text 'horizontale as'
    @select_x = @graph_settings.append('select')
      .classed('input-mini', true)
      .attr('id', 'x-quantity')

    for name, q of @QUANTITIES
      @select_x.append('option')
        .attr('value', name)
        .text q.unit

    @select_x.on('change', @change_x_quantity())

    @graph_settings.append('label').text 'verticale as'
    @select_y = @graph_settings.append('select')
      .classed('input-mini', true)
      .attr('id', 'y-quantity')

    for name, q of @QUANTITIES
      @select_y.append('option')
        .attr('value', name)
        .text q.unit

    @select_y.on('change', @change_y_quantity())

  change_y_quantity: ->
    return =>
      e = document.getElementById("y-quantity")
      sel = e.options[e.selectedIndex].value
      @set_y_quantity sel
      @redraw_graphs()

  change_x_quantity: ->
    return =>
      e = document.getElementById("x-quantity")
      sel = e.options[e.selectedIndex].value
      @set_x_quantity sel
      @redraw_graphs()

  set_step_size: ->
    return =>
      @step_size = parseFloat d3.select('#stepsize').property('value')
      @redraw_graphs()

  add_graph: (glass) ->
    glass.graph =
      name: glass.name
      data: glass.glass.get_data(@config.flow_rate)
      color: glass.color
      toggled:
        graph: true
        chart: false
        tangent: true
    @glasses.push glass
    @redraw_graphs()

  redraw_graphs: ->
    @compute_scales()
    for glass in @glasses
      if glass.graph.toggled.graph
        graph = d3.select("##{glass.name}-graph")
        graph.remove() unless graph.empty()
        @draw_graph glass, glass.name
      if glass.graph.toggled.chart
        chart = d3.select("##{glass.name}-chart")
        chart.remove() unless chart.empty()
        @draw_chart glass, glass.name

      tangents = d3.select("##{glass.name}-tangents")
      tangents.remove() unless tangents.empty()
      @draw_tangents glass, glass.name

  remove_graph: (glass) ->
    graph = d3.select("##{glass.name}-graph")
    graph.remove() unless graph.empty()
    chart = d3.select("##{glass.name}-chart")
    chart.remove() unless chart.empty()
    tangents = d3.select("##{glass.name}-tangents")
    tangents.remove() unless tangents.empty()
    @glasses.splice @glasses.indexOf(glass), 1
    @redraw_graphs()
    

  set_x_quantity: (quantity) ->
    @X_QUANTITY = @QUANTITIES[quantity]

  set_y_quantity: (quantity) ->
    @Y_QUANTITY = @QUANTITIES[quantity]

  compute_scales: ->
    @all_graphs = d3.merge (glass.graph.data for glass in @glasses)

    @x_extent = d3.extent @all_graphs, (d) => d[@X_QUANTITY.name]

    @x_scale = d3.scale.linear()
      .range([0, @GRAPH_DIMENSIONS.width])
      .domain(@x_extent)


    @y_extent = d3.extent @all_graphs, (d) => d[@Y_QUANTITY.name]
    @y_scale = d3.scale.linear()
      .range([@GRAPH_DIMENSIONS.height, 0])
      .domain(@y_extent)
    
  
    @x_axis = d3.svg.axis()
      .scale(@x_scale)
      .tickSubdivide(3)

    @y_axis = d3.svg.axis()
      .scale(@y_scale)
      .orient('left')
      .tickSubdivide(3)

    xaxis = d3.select('g.x.axis')
    if xaxis.empty()
      xaxis = @svg_graph.append('g')
        .attr('class', 'x axis')
        .attr('transform', "translate(0,#{@GRAPH_DIMENSIONS.height})")
    xaxis.call(@x_axis)


    yaxis = d3.select('g.y.axis')
    if yaxis.empty()
      yaxis = @svg_graph.append('g')
        .attr('class', 'y axis')
    yaxis.call(@y_axis)


    xraster = d3.select('g.x.grid')
    if xraster.empty()
      xraster = @svg_graph.append("g")
        .attr("class", "x grid")

    xraster.attr("transform", "translate(0," + @GRAPH_DIMENSIONS.height + ")")
      .call(@x_axis.tickSize(-@GRAPH_DIMENSIONS.height, 0, 0).tickFormat(""))

    yraster = d3.select('g.y.grid')
    if yraster.empty()
      yraster = @svg_graph.append("g")
        .attr("class", "y grid")
    yraster.call(@y_axis.tickSize(-@GRAPH_DIMENSIONS.width, 0, 0).tickFormat(""))

    ylabel = d3.select('#ylabel')
    if ylabel.empty()
      d3.select('.y.axis')
        .append('text')
        .attr('id', 'ylabel')

    ylabel.attr('text-anchor', 'middle')
      .text("#{@Y_QUANTITY.label} (#{@Y_QUANTITY.unit})")
      .attr('transform', 'rotate(-270,0,0)')
      .attr('x', @GRAPH_DIMENSIONS.height / 2)
      .attr('y', 50)

    xlabel = d3.select('#xlabel')
    if xlabel.empty()
      xlabel = d3.select('.x.axis')
        .append('text')
        .attr('id', 'xlabel')
    xlabel.attr('text-anchor', 'middle')
      .text("#{@X_QUANTITY.label} (#{@X_QUANTITY.unit})")
      .attr('x', @GRAPH_DIMENSIONS.width / 2)
      .attr('y', @MARGINS.bottom - @MARGINS.top )
      

  toggle_chart: (glass) ->
    if glass.graph.toggled.chart
      chart = d3.select("##{glass.name}-chart")
      glass.graph.toggled.chart = false
      chart.remove()
    else
      glass.graph.toggled.chart = true
      @draw_chart glass, glass.name

  toggle_graph: (glass) ->
    if glass.graph.toggled.graph
      graph = d3.select("##{glass.name}-graph")
      glass.graph.toggled.graph = false
      graph.remove()
    else
      glass.graph.toggled.graph = true
      @draw_graph glass, glass.name

  draw_graph: (glass, id) ->


    line = d3.svg.line()
      .x((d) => @x_scale(d[@X_QUANTITY.name]))
      .y((d) => @y_scale(d[@Y_QUANTITY.name]))
      .interpolate('cardinal')
      .tension(0)

    g = d3.select('#graph_container')
      .append('g')
      .attr('id', "#{glass.name}-graph")
      .attr('class', glass.name)

    data = glass.graph.data
    g.append('path')
      .attr('d', line(data))
      .attr('class', 'graph')
      .attr('fill', 'none')
      .attr('stroke', glass.color)
      .style('stroke-wdith', 3)


      # @toggle_tangents glass

  draw_chart: (glass, id) ->
    
    g = d3.select('#graph_container')
      .append('g')
      .attr('id', "#{glass.name}-chart")
      .attr('class', glass.name)

    data = []
    i = 1
    end = glass.graph.data.length
    prev = glass.graph.data[0]
    while i < end
      elt = glass.graph.data[i]
      if Math.abs(prev[@X_QUANTITY.name] - elt[@X_QUANTITY.name]) >= @step_size
        data.push elt
        prev = elt
      i++

    g.selectAll('rect-bar')
      .data(data)
      .enter()
      .append('rect')
        .attr('x', (d) => @x_scale(d[@X_QUANTITY.name]))
        .attr('y', (d) => @y_scale(d[@Y_QUANTITY.name]))
        .attr('width', @x_scale(@step_size))
        .attr('height', (d) =>
          @GRAPH_DIMENSIONS.height - @y_scale(d[@Y_QUANTITY.name]))
        .attr('fill', glass.color)
        .attr('fill-opacity', 0.8)
        .attr('stroke', glass.color)

        # @toggle_tangents glass
    
  toggle_tangents: (glass) ->
    graph = d3.select("##{glass.name}-tangents")
    if graph.empty()
      @draw_tangents glass, glass.name
    else
      graph.remove()

  draw_tangents: (glass, id) ->
    g = d3.select('#graph_container')
      .append('g')
      .attr('id', "#{glass.name}-tangents")
      .attr('class', glass.name)

    line = d3.svg.line()
      .x((d) => @x_scale(d[@X_QUANTITY.name]))
      .y((d) => @y_scale(d[@Y_QUANTITY.name]))
      .interpolate('cardinal')
      .tension(0)

    g = d3.select('#graph_container')
      .append('g')
      .attr('id', "#{glass.name}-tangents")
      .attr('class', glass.name)

    g.append('path')
      .attr('d', line(glass.graph.data))
      .attr('fill', 'none')
      .attr('stroke', 'white')
      .attr('stroke-opacity', 0)
      .attr('stroke-width', 7)
      .on('mouseover', (d, i) =>

    
        line_path = d3.select("##{glass.name}-tangents path")[0][0]

       
        length_at_point = 0
        total_length = line_path.getTotalLength()
        bigstep = 50
        while (line_path.getPointAtLength(length_at_point).x < d3.mouse(line_path)[0] and length_at_point < total_length)
          length_at_point += bigstep

        length_at_point -= bigstep

        while (line_path.getPointAtLength(length_at_point).x < d3.mouse(line_path)[0] and length_at_point < total_length)
          length_at_point++
        
        this_point = line_path.getPointAtLength(length_at_point)

        if length_at_point > 10 and length_at_point < total_length - 10
          prev_point = line_path.getPointAtLength(length_at_point - 9)
          next_point = line_path.getPointAtLength(length_at_point + 9)
          delta =
            x: next_point.x - prev_point.x
            y: next_point.y - prev_point.y
        else
          return

        LENGTH = 5

        tangent = d3.select('#graph_container')
          .append('line')
            .attr('stroke', 'black')
            .attr('class', 'tangent')
            .attr('id', 'tangent')
            .attr('stroke-width', 1)
            .attr('x1', this_point.x - delta.x * LENGTH)
            .attr('y1', this_point.y - delta.y * LENGTH)
            .attr('x2', this_point.x + delta.x * LENGTH)
            .attr('y2', this_point.y + delta.y * LENGTH)
      )
        .on('mouseout', (d,i) =>
          d3.select('#tangent').remove()
        )
  

module.exports = Grapher
