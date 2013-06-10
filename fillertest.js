(function() {
  var cocktail_json, erlenmeyer_json, vreemde_vaas_json, wijn_json;

  cocktail_json = '{"path":"M 419 102 l -152 245 l 0 185 c 0 23.25 101 11.75 106 25","foot":{"x":255,"y":557},"stem":{"x":255,"y":532},"bowl":{"x":255,"y":347},"edge":{"x":255,"y":102},"height_in_mm":150,"spec":{"round_max":"cl","mm_from_top":0},"measure_lines":{},"nr_of_measure_lines":0}';

  wijn_json = '{"path":"M 361 123 c 21 92.75 1 176.25 -90 255 l 0 164 l 89 15","foot":{"x":255,"y":557},"stem":{"x":255,"y":542},"bowl":{"x":255,"y":378},"edge":{"x":255,"y":123},"height_in_mm":143,"spec":{"round_max":"cl","mm_from_top":0},"measure_lines":{},"nr_of_measure_lines":0}';

  erlenmeyer_json = '{"path":"M 307 103 l 0 123 l 100 299 c 10 25 9.5 26 -63 28 l -1 2 l 2 2","foot":{"x":255,"y":557},"stem":{"x":255,"y":555},"bowl":{"x":255,"y":553},"edge":{"x":255,"y":103},"height_in_mm":149,"spec":{"round_max":"cl","mm_from_top":0},"measure_lines":{},"nr_of_measure_lines":0}';

  vreemde_vaas_json = '{"path":"M 319 265 c -32 10.25 -35 30.75 -6 41 l 88 2 l 0 52 l 70 2 l 0 32 l -105 2 l 0 66 l 38 2 l 0 28 l -134 2 c -7.5 10.75 -10.5 32.25 -6 43 c -4.5 5 182.5 10 166 20","foot":{"x":255,"y":557},"stem":{"x":255,"y":537},"bowl":{"x":255,"y":494},"edge":{"x":255,"y":265},"height_in_mm":96,"spec":{"round_max":"cl","mm_from_top":5},"measure_lines":{},"nr_of_measure_lines":0}';

  $(document).ready(function() {
    var canvas, filler, glass, wineglass;
    canvas = Raphael("test", 1000, 1000);
    wineglass = new Glass("M 250 100 S250,190,170,200 v 75 C 180, 300, 200, 300, 200, 300", {
      x: 150,
      y: 300
    }, {
      x: 150,
      y: 275
    }, {
      x: 150,
      y: 200
    }, {
      x: 150,
      y: 100
    }, 70, {
      round_max: "cl",
      mm_from_top: 2
    });
    filler = new Filler(canvas, 10, 10, wineglass, 1000, 1000, {
      components: ['ruler', 'tap'],
      dimension: '2d',
      buttons: ['manual_diff'],
      editable: true,
      icon_path: 'lib/icons',
      speed_graph: true,
      computer_graph: true,
      hide_all_except_graph: true,
      speed: 35
    });
    return $('#json').click(function() {
      return console.log(filler.graph.user_line.to_json());
    });
  });

}).call(this);
