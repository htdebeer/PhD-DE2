


json_glasses =
  cocktail: '{"path":"M 419 102 l -152 245 l 0 185 c 0 23.25 101 11.75 106 25","foot":{"x":255,"y":557},"stem":{"x":255,"y":532},"bowl":{"x":255,"y":347},"edge":{"x":255,"y":102},"height_in_mm":150,"spec":{"round_max":"cl","mm_from_top":0},"measure_lines":{},"nr_of_measure_lines":0}'
  erlenmeyer: '{"path":"M 307 103 l 0 123 l 100 299 c 10 25 9.5 26 -63 28 l -1 2 l 2 2","foot":{"x":255,"y":557},"stem":{"x":255,"y":555},"bowl":{"x":255,"y":553},"edge":{"x":255,"y":103},"height_in_mm":149,"spec":{"round_max":"cl","mm_from_top":0},"measure_lines":{},"nr_of_measure_lines":0}'
  longdrink: '{"path":"M 339 92 l 0 326 l 0 3 l 0 6","foot":{"x":255,"y":427},"stem":{"x":255,"y":421},"bowl":{"x":255,"y":418},"edge":{"x":255,"y":92},"height_in_mm":110,"spec":{"round_max":"cl","mm_from_top":0},"measure_lines":{},"nr_of_measure_lines":0}'
  longdrink_smal: '{"path":"M 324 179 l 0 332 l 0 22 l 0 24","foot":{"x":255,"y":557},"stem":{"x":255,"y":533},"bowl":{"x":255,"y":511},"edge":{"x":255,"y":179},"height_in_mm":124,"spec":{"round_max":"cl","mm_from_top":5},"measure_lines":{},"nr_of_measure_lines":0}'
  longdrink_breed: '{"path":"M 429 153 l 0 385 l 0 17 l 0 2","foot":{"x":255,"y":557},"stem":{"x":255,"y":555},"bowl":{"x":255,"y":538},"edge":{"x":255,"y":153},"height_in_mm":133,"spec":{"round_max":"cl","mm_from_top":5},"measure_lines":{},"nr_of_measure_lines":0}'
  longdrink_vreemd: '{"path":"M 318 254 l 0 150 l 88 2 l 0 122 l 0 15 l 0 14","foot":{"x":255,"y":557},"stem":{"x":255,"y":543},"bowl":{"x":255,"y":528},"edge":{"x":255,"y":254},"height_in_mm":99,"spec":{"round_max":"cl","mm_from_top":5},"measure_lines":{},"nr_of_measure_lines":0}'
  wijn: '{"path":"M 361 123 c 21 92.75 1 176.25 -90 255 l 0 164 l 89 15","foot":{"x":255,"y":557},"stem":{"x":255,"y":542},"bowl":{"x":255,"y":378},"edge":{"x":255,"y":123},"height_in_mm":143,"spec":{"round_max":"cl","mm_from_top":0},"measure_lines":{},"nr_of_measure_lines":0}'
  rondbodemkolf: '{"path":"M 315 73 l 0 161 c 192 45.75 192 262.25 -4 319 l -13 2 l -10 2","foot":{"x":255,"y":557},"stem":{"x":255,"y":555},"bowl":{"x":255,"y":553},"edge":{"x":255,"y":73},"height_in_mm":159,"spec":{"round_max":"cl","mm_from_top":5},"measure_lines":{},"nr_of_measure_lines":0}'
  cognac: '{"path":"M 346 223 c 24.5 67.75 45 103.25 37 151 c -3 29 -16 78 -118 92 l 0 62 c -4 21.25 73.5 13.75 89 29","foot":{"x":255,"y":557},"stem":{"x":255,"y":528},"bowl":{"x":255,"y":466},"edge":{"x":255,"y":223},"height_in_mm":110,"spec":{"round_max":"cl","mm_from_top":0},"measure_lines":{},"nr_of_measure_lines":0}'
  bier: '{"path":"M 363 253 l 0 94 c 1 16.75 -3 11.25 -12 31 l -25 175 l 0 2 l 0 2","foot":{"x":255,"y":557},"stem":{"x":255,"y":555},"bowl":{"x":255,"y":553},"edge":{"x":255,"y":253},"height_in_mm":100,"spec":{"round_max":"cl","mm_from_top":0},"measure_lines":{},"nr_of_measure_lines":0}'

Glass = require './widgets/glass/glass'
FlaskFiller = require './microworlds/flaskfiller/flaskfiller'

random_color = ->
  hexes = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']
  colors = []
  i = 0
  while i < 6
    colors.push hexes[Math.round(Math.random()*(hexes.length-1))]
    i++

  "##{colors.join ''}"

create_glass = (json_glasses, name) ->
  glass =
    name: name
    glass: new Glass json_glasses[name]
    color: random_color()
  glass

FLOW_RATE = 20

$(document).ready ->
  ff = new FlaskFiller
    id: 'flaskfiller'
    flow_rate: FLOW_RATE
    mm_per_pixel: 0.01
    glasses: [create_glass(json_glasses, 'cocktail')]
    glass_specs: json_glasses
    hide_graph: false
    graph:
      dimensions:
        width: 700
        height: 500
      quantities:
        time:
          name: 'time'
          label: 'verstreken tijd'
          unit: 'sec'
          step: 0.2
        volume:
          name: 'volume'
          label: 'volume'
          unit: 'ml'
          step: 1
        height:
          name: 'height'
          label: 'hoogtestijging van het waterpeil'
          unit: 'cm'
          step: 0.1

