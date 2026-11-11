import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Source rectangles contain the original, individually modelled clay glyphs.
// Coordinates are kept with the atlas so the images are never resampled at build time.
const _letterRects = <String, Rect>{
  'A': Rect.fromLTRB(34, 30, 200, 196),
  'B': Rect.fromLTRB(235, 30, 377, 200),
  'C': Rect.fromLTRB(403, 31, 550, 201),
  'D': Rect.fromLTRB(583, 30, 730, 200),
  'E': Rect.fromLTRB(770, 32, 903, 202),
  'F': Rect.fromLTRB(950, 32, 1076, 199),
  'G': Rect.fromLTRB(1113, 31, 1264, 200),
  'H': Rect.fromLTRB(1294, 32, 1433, 198),
  'I': Rect.fromLTRB(63, 229, 159, 394),
  'J': Rect.fromLTRB(222, 227, 354, 394),
  'K': Rect.fromLTRB(392, 229, 538, 392),
  'L': Rect.fromLTRB(576, 228, 711, 392),
  'M': Rect.fromLTRB(736, 229, 916, 393),
  'N': Rect.fromLTRB(933, 229, 1084, 393),
  'O': Rect.fromLTRB(1102, 228, 1268, 394),
  'P': Rect.fromLTRB(1295, 229, 1435, 393),
  'Q': Rect.fromLTRB(30, 414, 197, 581),
  'R': Rect.fromLTRB(226, 414, 365, 580),
  'S': Rect.fromLTRB(403, 414, 535, 582),
  'T': Rect.fromLTRB(565, 417, 713, 579),
  'U': Rect.fromLTRB(738, 417, 894, 580),
  'V': Rect.fromLTRB(920, 418, 1078, 580),
  'W': Rect.fromLTRB(1090, 419, 1274, 578),
  'X': Rect.fromLTRB(1284, 419, 1432, 578),
  'Y': Rect.fromLTRB(32, 596, 187, 754),
  'Z': Rect.fromLTRB(214, 598, 362, 755),
  'a': Rect.fromLTRB(393, 628, 541, 754),
  'b': Rect.fromLTRB(578, 596, 717, 756),
  'c': Rect.fromLTRB(753, 629, 882, 755),
  'd': Rect.fromLTRB(923, 596, 1062, 756),
  'e': Rect.fromLTRB(1106, 630, 1238, 758),
  'f': Rect.fromLTRB(1286, 595, 1409, 756),
  'g': Rect.fromLTRB(40, 775, 176, 928),
  'h': Rect.fromLTRB(225, 764, 360, 918),
  'i': Rect.fromLTRB(438, 768, 502, 918),
  'j': Rect.fromLTRB(575, 767, 687, 926),
  'k': Rect.fromLTRB(747, 765, 874, 918),
  'l': Rect.fromLTRB(951, 766, 1018, 918),
  'm': Rect.fromLTRB(1092, 791, 1260, 915),
  'n': Rect.fromLTRB(1282, 793, 1418, 917),
  'o': Rect.fromLTRB(30, 944, 175, 1075),
  'p': Rect.fromLTRB(223, 937, 357, 1078),
  'q': Rect.fromLTRB(394, 940, 532, 1078),
  'r': Rect.fromLTRB(582, 948, 699, 1074),
  's': Rect.fromLTRB(756, 943, 873, 1075),
  't': Rect.fromLTRB(925, 924, 1047, 1077),
  'u': Rect.fromLTRB(1098, 946, 1241, 1076),
  'v': Rect.fromLTRB(1281, 947, 1422, 1074),
};
const _numberRects = <String, Rect>{
  '0': Rect.fromLTRB(66, 31, 283, 288),
  '1': Rect.fromLTRB(378, 33, 529, 288),
  '2': Rect.fromLTRB(644, 34, 849, 286),
  '3': Rect.fromLTRB(928, 31, 1130, 289),
  '4': Rect.fromLTRB(1198, 30, 1431, 288),
  '5': Rect.fromLTRB(1499, 35, 1702, 291),
  '6': Rect.fromLTRB(68, 321, 281, 578),
  '7': Rect.fromLTRB(354, 328, 566, 578),
  '8': Rect.fromLTRB(631, 321, 849, 580),
  '9': Rect.fromLTRB(921, 322, 1130, 578),
  ':': Rect.fromLTRB(1267, 361, 1352, 541),
  '·': Rect.fromLTRB(1556, 415, 1638, 493),
  '×': Rect.fromLTRB(70, 636, 281, 846),
  '(': Rect.fromLTRB(392, 606, 527, 872),
  ')': Rect.fromLTRB(683, 605, 811, 872),
  '!': Rect.fromLTRB(974, 606, 1074, 872),
  '?': Rect.fromLTRB(1210, 601, 1401, 872),
  '-': Rect.fromLTRB(1491, 693, 1701, 779),
};

// Accents are combined with the illustrated base glyph, so the original text
// remains available to assistive technology and no word falls back as a whole.
const _accented = <String, (String, String)>{
  'é': ('e', 'acute'),
  'è': ('e', 'grave'),
  'ê': ('e', 'circumflex'),
  'ë': ('e', 'diaeresis'),
  'à': ('a', 'grave'),
  'â': ('a', 'circumflex'),
  'î': ('i', 'circumflex'),
  'ï': ('i', 'diaeresis'),
  'ô': ('o', 'circumflex'),
  'ù': ('u', 'grave'),
  'û': ('u', 'circumflex'),
  'ç': ('c', 'cedilla'),
  'É': ('E', 'acute'),
  'È': ('E', 'grave'),
  'Ê': ('E', 'circumflex'),
  'Î': ('I', 'circumflex'),
  'À': ('A', 'grave'),
  'Ç': ('C', 'cedilla'),
};
String _baseGlyph(String c) =>
    _accented[c]?.$1 ??
    (c == '/'
        ? '-'
        : c == '’' || c == "'" || c == '.'
        ? '·'
        : 'wxyz'.contains(c)
        ? c.toUpperCase()
        : c);

Future<ui.Image> _loadAtlas(String path) async {
  final bytes = await rootBundle.load(path);
  final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
  try {
    return (await codec.getNextFrame()).image;
  } finally {
    codec.dispose();
  }
}

/// Hand-modelled bitmap lettering for game HUDs, with a readable fallback.
class ClayText extends StatefulWidget {
  const ClayText(
    this.text, {
    required this.style,
    this.maxLines = 1,
    super.key,
  });
  final String text;
  final TextStyle style;
  final int maxLines;

  @override
  State<ClayText> createState() => _ClayTextState();
}

class _ClayTextState extends State<ClayText> {
  static List<ui.Image>? _cachedImages;
  static final Future<List<ui.Image>> _atlases = Future.wait([
    _loadAtlas('assets/optimized/clay_type/letters.png'),
    _loadAtlas('assets/optimized/clay_type/numbers.png'),
  ]);
  List<ui.Image>? _images;

  @override
  void initState() {
    super.initState();
    _images = _cachedImages;
    if (_images != null) return;
    _atlases
        .then((images) {
          _cachedImages = images;
          if (mounted) setState(() => _images = images);
        })
        .catchError((Object error) {
          assert(() {
            debugPrint('Clay atlas unavailable: $error');
            return true;
          }());
        });
  }

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style
        .merge(widget.style)
        .copyWith(fontFamily: 'PapattesModelage', shadows: const []);
    final characters = widget.text.runes.map(String.fromCharCode).toList();
    final supported = characters.every(
      (c) =>
          c == ' ' ||
          _letterRects.containsKey(_baseGlyph(c)) ||
          _numberRects.containsKey(_baseGlyph(c)),
    );
    final images = _images;
    if (!supported || images == null) {
      return Text(widget.text, maxLines: widget.maxLines, style: style);
    }
    final fontSize = MediaQuery.textScalerOf(
      context,
    ).scale(style.fontSize ?? 14);
    final painter = _ClayPainter(
      characters,
      images,
      fontSize,
      style.color ?? Colors.white,
    );
    return Semantics(
      label: widget.text,
      child: ExcludeSemantics(
        child: SizedBox(
          width: painter.width,
          height: fontSize * 1.25,
          child: CustomPaint(painter: painter),
        ),
      ),
    );
  }
}

class _ClayPainter extends CustomPainter {
  _ClayPainter(this.characters, this.images, this.fontSize, this.color);
  final List<String> characters;
  final List<ui.Image> images;
  final double fontSize;
  final Color color;

  double _height(String c) {
    if (c == '·') return fontSize * .18;
    if (c == '.' || c == '’' || c == "'") return fontSize * .18;
    if (c == '-') return fontSize * .25;
    if (c == ':') return fontSize * .52;
    if ('gpq'.contains(c)) return fontSize * .65;
    if ('aceemnorsuvwxyzéèêëàâô'.contains(c)) return fontSize * .55;
    return fontSize * .73;
  }

  double _width(String c) {
    if (c == ' ') return fontSize * .27;
    if (c == '/') return fontSize * .3;
    final base = _baseGlyph(c);
    final rect = _letterRects[base] ?? _numberRects[base]!;
    return _height(c) * rect.width / rect.height;
  }

  double _advance(String c, String? next) {
    if (c == ' ') return _width(c);
    // Rounded and diagonal outlines leave different amounts of optical space
    // within equally tight sprite rectangles.
    final pair = '$c${next ?? ''}'.toLowerCase();
    final adjustment = switch (pair) {
      'ra' => -.09,
      'py' || 'yg' => -.08,
      'gm' => -.04,
      _ => 0.0,
    };
    return _width(c) + fontSize * (.055 + adjustment);
  }

  double get width {
    var result = 0.0;
    for (var i = 0; i < characters.length; i++) {
      result += _advance(
        characters[i],
        i + 1 < characters.length ? characters[i + 1] : null,
      );
    }
    return result;
  }

  @override
  void paint(Canvas canvas, Size size) {
    var x = 0.0;
    // Preserve the painted texture while shifting the cream atlas toward the HUD colour.
    final gold = color.r > .95 && color.g < .9;
    // Mipmaps give cleaner edges when the high-resolution atlas is reduced to
    // the small HUD lettering sizes (high uses bicubic sampling without them).
    final paint = Paint()..filterQuality = FilterQuality.medium;
    if (gold) {
      paint.colorFilter = const ColorFilter.matrix([
        1.04,
        0,
        0,
        0,
        0,
        0,
        1.0,
        0,
        0,
        0,
        0,
        0,
        .57,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]);
    } else {
      paint.colorFilter = const ColorFilter.matrix([
        1.03,
        0,
        0,
        0,
        0,
        0,
        1.04,
        0,
        0,
        0,
        0,
        0,
        1.05,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]);
    }
    for (var i = 0; i < characters.length; i++) {
      final c = characters[i];
      final next = i + 1 < characters.length ? characters[i + 1] : null;
      final width = _width(c);
      if (c != ' ') {
        final base = _baseGlyph(c);
        final source = _letterRects[base] ?? _numberRects[base]!;
        final height = _height(c);
        if (c == '/') {
          canvas.save();
          canvas.translate(x + width / 2, fontSize * .62);
          canvas.rotate(-1.05);
          canvas.drawImageRect(
            images[1],
            source,
            Rect.fromCenter(
              center: Offset.zero,
              width: fontSize * .58,
              height: fontSize * .13,
            ),
            paint,
          );
          canvas.restore();
          x += _advance(c, next);
          continue;
        }
        final top = c == '’' || c == "'"
            ? fontSize * .24
            : c == '.'
            ? fontSize * .25 + fontSize * .73 - height
            : c == '·' || c == '-' || c == ':'
            ? fontSize * .25 + (fontSize * .73 - height) / 2
            : fontSize * .25 +
                  fontSize * .73 -
                  height +
                  ('gpqj'.contains(c) ? fontSize * .09 : 0);
        canvas.drawImageRect(
          images[_letterRects.containsKey(base) ? 0 : 1],
          source,
          Rect.fromLTWH(x, top, width, height),
          paint,
        );
        final accent = _accented[c]?.$2;
        if (accent != null) {
          final accentTop = accent == 'cedilla'
              ? top + height - fontSize * .02
              : top - fontSize * .15;
          final accentWidth =
              width *
              (accent == 'circumflex' || accent == 'diaeresis' ? .5 : .33);
          final accentHeight = fontSize * .12;
          final mark = accent == 'circumflex'
              ? _letterRects['V']!
              : accent == 'cedilla'
              ? _letterRects['c']!
              : _numberRects['-']!;
          final dest = Rect.fromLTWH(
            x + (width - accentWidth) / 2,
            accentTop,
            accentWidth,
            accentHeight,
          );
          canvas.save();
          if (accent == 'circumflex') {
            canvas.translate(dest.center.dx, dest.center.dy);
            canvas.rotate(3.141592653589793);
            canvas.translate(-dest.center.dx, -dest.center.dy);
          } else if (accent == 'acute' || accent == 'grave') {
            canvas.translate(dest.center.dx, dest.center.dy);
            canvas.rotate(accent == 'acute' ? -.55 : .55);
            canvas.translate(-dest.center.dx, -dest.center.dy);
          }
          if (accent == 'diaeresis') {
            final dot = _numberRects['·']!;
            canvas.drawImageRect(
              images[1],
              dot,
              Rect.fromLTWH(
                dest.left,
                dest.top,
                accentWidth * .35,
                accentHeight,
              ),
              paint,
            );
            canvas.drawImageRect(
              images[1],
              dot,
              Rect.fromLTWH(
                dest.right - accentWidth * .35,
                dest.top,
                accentWidth * .35,
                accentHeight,
              ),
              paint,
            );
          } else {
            canvas.drawImageRect(
              images[accent == 'circumflex' || accent == 'cedilla' ? 0 : 1],
              mark,
              dest,
              paint,
            );
          }
          canvas.restore();
        }
      }
      x += _advance(c, next);
    }
  }

  @override
  bool shouldRepaint(_ClayPainter oldDelegate) =>
      oldDelegate.characters.join() != characters.join() ||
      oldDelegate.fontSize != fontSize ||
      oldDelegate.color != color;
}
