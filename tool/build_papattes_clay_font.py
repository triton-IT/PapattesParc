"""Build the Papattes clay lettering prototype from the bundled Nunito font.

Requires fonttools. Nunito and this derivative are covered by assets/fonts/OFL.txt.
"""
from math import sin
from pathlib import Path

from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'assets/fonts/Nunito-Variable.ttf'
TARGET = ROOT / 'assets/fonts/PapattesModelage.ttf'


def main():
    font = instantiateVariableFont(TTFont(SOURCE), {'wght': 900}, inplace=True)
    glyf = font['glyf']
    # A smooth, small deformation shared by all points in a glyph preserves
    # readable counters and curves while giving the outlines a handmade feel.
    for name in font.getGlyphOrder():
        glyph = glyf[name]
        if glyph.isComposite() or glyph.numberOfContours <= 0:
            continue
        phase = sum(ord(c) for c in name) * .17
        for i, (x, y) in enumerate(glyph.coordinates):
            dx = 7 * sin(y / 145 + phase) + 3 * sin(x / 185 + phase)
            dy = 5 * sin(x / 150 + phase) + 2 * sin(y / 180 + phase)
            glyph.coordinates[i] = (round(x + dx), round(y + dy))
        glyph.recalcBounds(glyf)
    names = {
        1: 'Papattes Modelage', 2: 'Regular',
        3: 'Papattes Modelage Regular 1.0', 4: 'Papattes Modelage',
        6: 'PapattesModelage-Regular', 16: 'Papattes Modelage', 17: 'Regular',
    }
    for record in font['name'].names:
        if record.nameID in names:
            record.string = names[record.nameID].encode(record.getEncoding())
    font['OS/2'].usWeightClass = 400
    font['head'].macStyle &= ~1
    font['OS/2'].fsSelection &= ~(1 << 5)
    font['OS/2'].fsSelection |= 1 << 6
    font.save(TARGET)
    print(TARGET)


if __name__ == '__main__':
    main()
