console.log "test"

cocktail_json = '{"path":"M 419 102 l -152 245 l 0 185 c 0 23.25 101 11.75 106 25","foot":{"x":255,"y":557},"stem":{"x":255,"y":532},"bowl":{"x":255,"y":347},"edge":{"x":255,"y":102},"height_in_mm":150,"spec":{"round_max":"cl","mm_from_top":0},"measure_lines":{},"nr_of_measure_lines":0}'

canvas = Raphael 'test', 500, 500
console.log "in"

Glass = require './widgets/glass/glass'
WGlass = require './widgets/glass/wglass'

cocktail_glass = new Glass cocktail_json

export_string = cocktail_glass.to_full_json()

w = window.open ''
w.document.open 'text/plain'
w.document.write export_string

cocktail_representation = new WGlass canvas, 1, 1, cocktail_glass

