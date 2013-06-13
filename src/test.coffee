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
#erlenmeyer_glass = new Glass erlenmeyer_json


PIXEL_PER_MM = 455 / 15
HEIGHT = (15 + 5) * PIXEL_PER_MM
WIDTH = HEIGHT
MM_HEIGHT = 20
MM_PER_PIXEL = 1/ PIXEL_PER_MM


canvas = Raphael 'test', WIDTH, HEIGHT
edit_canvas = Raphael 'edit', WIDTH, HEIGHT

grafter = new WGlassGrafter edit_canvas, 0, 0, WIDTH, HEIGHT, MM_PER_PIXEL


#erlenmeyer_representation = new WGlass canvas, 50, 35, erlenmeyer_glass,
  fill: 'red'
  
cocktail_representation = new WGlass canvas, 40, 40, cocktail_glass

selected = {selected: null}

#cocktail_representation.start_selectable( selected )
erlenmeyer_representation.start_selectable( selected )
# cocktail_representation.start_manual_diff()
# Fixx manual diff later, if needed

cocktail_representation.fill_to_height 111
erlenmeyer_representation.fill_to_height 98

RULER_WIDTH = 30
RULER_LENGTH = HEIGHT - RULER_WIDTH
MM_RULER = Math.ceil(RULER_LENGTH / PIXEL_PER_MM)


vruler = new WVerticalRuler canvas, 0, 0, RULER_WIDTH, RULER_LENGTH, MM_RULER
hruler = new WHorizontalRuler canvas, RULER_WIDTH, RULER_LENGTH, RULER_LENGTH, RULER_WIDTH, MM_RULER
