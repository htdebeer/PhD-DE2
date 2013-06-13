export_glass = (glass) ->

  export_string = cocktail_glass.to_full_json()

  w = window.open ''
  w.document.open 'text/plain'
  w.document.write export_string

cocktail_json = '{"path":"M 419 102 l -152 245 l 0 185 c 0 23.25 101 11.75 106 25","foot":{"x":255,"y":557},"stem":{"x":255,"y":532},"bowl":{"x":255,"y":347},"edge":{"x":255,"y":102},"height_in_mm":150,"spec":{"round_max":"cl","mm_from_top":0},"measure_lines":{},"nr_of_measure_lines":0}'

erlenmeyer_json = '{"path":"M 307 103 l 0 123 l 100 299 c 10 25 9.5 26 -63 28 l -1 2 l 2 2","foot":{"x":255,"y":557},"stem":{"x":255,"y":555},"bowl":{"x":255,"y":553},"edge":{"x":255,"y":103},"height_in_mm":149,"spec":{"round_max":"cl","mm_from_top":0},"measure_lines":{},"nr_of_measure_lines":0}'



Glass = require './widgets/glass/glass'
WGlass = require './widgets/glass/wglass'
WVerticalRuler = require './widgets/ruler/wvertical_ruler'
WHorizontalRuler = require './widgets/ruler/whorizontal_ruler'
WGlassGrafter = require './widgets/glass/wgrafter'


cocktail_glass = new Glass cocktail_json
erlenmeyer_glass = new Glass erlenmeyer_json


PIXEL_PER_MM = 455 / 15
HEIGHT = (15 + 5) * PIXEL_PER_MM
WIDTH = HEIGHT
MM_HEIGHT = 20
MM_PER_PIXEL = 1/ PIXEL_PER_MM


canvas = Raphael 'test', WIDTH, HEIGHT
#edit_canvas = Raphael 'edit', WIDTH, HEIGHT

#grafter = new WGlassGrafter edit_canvas, 0, 0, WIDTH, HEIGHT, MM_PER_PIXEL


erlenmeyer_representation = new WGlass canvas, 50, 35, erlenmeyer_glass,
  fill: 'red'
  
cocktail_representation = new WGlass canvas, 40, 40, cocktail_glass

selected = {selected: null}

cocktail_representation.start_selectable( selected )
erlenmeyer_representation.start_selectable( selected )
# cocktail_representation.start_manual_diff()
# Fixx manual diff later, if needed

cocktail_representation.fill_to_height 111
erlenmeyer_representation.fill_to_height 98

RULER_WIDTH = 30
RULER_LENGTH = HEIGHT - RULER_WIDTH
MM_RULER = 190


vruler = new WVerticalRuler canvas, 0, 0, RULER_WIDTH, RULER_LENGTH, MM_RULER
hruler = new WHorizontalRuler canvas, RULER_WIDTH, RULER_LENGTH, RULER_LENGTH, RULER_WIDTH, MM_RULER


# d3 graph test


FLOW_RATE = 20

make_graph = (conf) ->



  CONTAINER_DIMENSIONS =
    width: conf.dimensions.width
    height: conf.dimensions.height
  MARGINS =
    top: 10
    right: 20
    left: 60
    bottom: 60
  GRAPH_DIMENSIONS =
    width: CONTAINER_DIMENSIONS.width - MARGINS.left - MARGINS.right
    height: CONTAINER_DIMENSIONS.height - MARGINS.top - MARGINS.bottom
    
  svg_graph = d3.select("##{conf.id}")
    .append('svg')
      .attr('width', CONTAINER_DIMENSIONS.width)
      .attr('height', CONTAINER_DIMENSIONS.height)
    .append('g')
      .attr('transform', "translate(#{MARGINS.left},#{MARGINS.top})")
      .attr('id', 'graph_container')

  Z_QUANTITY =
    name: 'time'
    label: 'verstreken tijd'
    unit: 'sec'
    step: 1 / FLOW_RATE
  X_QUANTITY =
    name: 'volume'
    label: 'volume in het glas'
    unit: 'ml'
    step: 1

  Y_QUANTITY =
    name: 'height'
    label: 'hoogtestijging van het waterpeil'
    unit: 'cm'
    step: 1

  all_graphs = d3.merge (graph.data for id, graph of conf.graphs)

  x_extent = d3.extent all_graphs, (d) -> d[X_QUANTITY.name]
  x_scale = d3.scale.linear()
    .range([0, GRAPH_DIMENSIONS.width])
    .domain(x_extent)


  y_extent = d3.extent all_graphs, (d) -> d[Y_QUANTITY.name]
  y_scale = d3.scale.linear()
    .range([GRAPH_DIMENSIONS.height, 0])
    .domain(y_extent)

  x_axis = d3.svg.axis()
    .scale(x_scale)
    .tickSubdivide(3)

  y_axis = d3.svg.axis()
    .scale(y_scale)
    .orient('left')
    .tickSubdivide(3)

  svg_graph.append('g')
    .attr('class', 'x axis')
    .attr('transform', "translate(0,#{GRAPH_DIMENSIONS.height})")
    .call(x_axis)

  svg_graph.append('g')
    .attr('class', 'y axis')
    .call(y_axis)

  d3.select('.y.axis')
    .append('text')
      .attr('text-anchor', 'middle')
      .text("#{Y_QUANTITY.label} (#{Y_QUANTITY.unit})")
      .attr('transform', 'rotate(-270,0,0)')
      .attr('x', GRAPH_DIMENSIONS.height / 2)
      .attr('y', 50)

  d3.select('.x.axis')
    .append('text')
      .attr('text-anchor', 'middle')
      .text("#{X_QUANTITY.label} (#{X_QUANTITY.unit})")
      .attr('x', GRAPH_DIMENSIONS.width / 2)
      .attr('y', MARGINS.bottom - MARGINS.top )

  toggle_chart = (id) ->
    chart = d3.select("##{id}-chart")
    if chart.empty()
      draw_chart conf.graphs[id], id
    else
      chart.remove()

  toggle_graph = (id) ->
    graph = d3.select("##{id}-graph")
    if graph.empty()
      draw_graph conf.graphs[id], id
    else
      graph.remove()

  draw_graph = (graph, id) ->
    line = d3.svg.line()
      .x((d) -> x_scale(d[X_QUANTITY.name]))
      .y((d) -> y_scale(d[Y_QUANTITY.name]))
      .interpolate('linear')

    g = d3.select('#graph_container')
      .append('g')
      .attr('id', "#{id}-graph")
      .attr('class', id)

    g.append('path')
      .attr('d', line(graph.data))
      .attr('fill', 'none')
      .attr('stroke', graph.color)

    toggle_tangents id

  draw_chart = (graph, id) ->
    
    g = d3.select('#graph_container')
      .append('g')
      .attr('id', "#{id}-chart")
      .attr('class', id)

    g.selectAll('rect-bar')
      .data(graph.data)
      .enter()
      .append('rect')
        .attr('x', (d) -> x_scale(d[X_QUANTITY.name]))
        .attr('y', (d) -> y_scale(d[Y_QUANTITY.name]))
        .attr('width', x_scale(X_QUANTITY.step))
        .attr('height', (d) ->
          GRAPH_DIMENSIONS.height - y_scale(d[Y_QUANTITY.name]))
        .attr('fill', graph.color)
        .attr('stroke', graph.color)

    toggle_tangents id
    
  toggle_tangents = (id) ->
    graph = d3.select("##{id}-tangents")
    if graph.empty()
      draw_tangents conf.graphs[id], id
    else
      graph.remove()


  tangent = d3.select('#graph_container')
    .append('line')
      .attr('x1', 0)
      .attr('y1', 0)
      .attr('x2', 0)
      .attr('y2', 0)
      .attr('stroke', 'black')
      .attr('stroke-width', 1)

  draw_tangents = (graph, id) ->
    g = d3.select('#graph_container')
      .append('g')
      .attr('id', "#{id}-tangents")
      .attr('class', id)

    g.selectAll('tangent')
      .data(graph.data)
      .enter()
      .append('circle')
        .attr('cx', (d) -> x_scale(d[X_QUANTITY.name]))
        .attr('cy', (d) -> y_scale(d[Y_QUANTITY.name]))
        .attr('r', 3)
        .attr('fill', 'white')
        .attr('fill-opacity', 0)
        .attr('stroke', 'none')
        .on('mouseover', (d, i) =>
          prev =
            x: if i > 0 then graph.data[i-1][X_QUANTITY.name] else d[X_QUANTITY.name]
            y: if i > 0 then graph.data[i-1][Y_QUANTITY.name] else d[Y_QUANTITY.name]
          next =
            x: if i < graph.data.length then graph.data[i+1][X_QUANTITY.name] else d[X_QUANTITY.name]
            y: if i < graph.data.length then graph.data[i+1][Y_QUANTITY.name] else d[Y_QUANTITY.name]
          dd =
            x: next.x - prev.x
            y: next.y - prev.y
          LENGTH = 10


          tangent.attr('x1', x_scale(d[X_QUANTITY.name] - dd.x * LENGTH))
            .attr('y1', y_scale(d[Y_QUANTITY.name] - dd.y * LENGTH))
            .attr('x2', x_scale(d[X_QUANTITY.name] + dd.x * LENGTH))
            .attr('y2', y_scale(d[Y_QUANTITY.name] + dd.y * LENGTH))
        )





  for id, graph of conf.graphs
    toggle_graph id

  graph =
    toggle_graph: toggle_graph
    toggle_chart: toggle_chart

  graph

    


FLOW_RATE = 20
graphs =
  cocktail:
    data: cocktail_glass.get_data(FLOW_RATE)
    color: 'blue'
  erlenmeyer:
    data: erlenmeyer_glass.get_data(FLOW_RATE)
    color: 'red'


conf =
  id: 'd3test'
  graphs: graphs
  dimensions:
    width: 900
    height: 400

g = make_graph conf

cbutton = d3.select '#cocktail'

cbutton.on 'click', (d) ->
  g.toggle_graph 'cocktail'

ebutton = document.getElementById 'erlenmeyer'

ebutton.addEventListener 'click', ->
  g.toggle_graph 'erlenmeyer'

csbutton = document.getElementById 'cocktailbar'
csbutton.addEventListener 'click', ->
  g.toggle_chart 'cocktail'

esbutton = document.getElementById 'erlenmeyerbar'
esbutton.addEventListener 'click', ->
  g.toggle_chart 'erlenmeyer'
