"""Fail if source illustrations or 3D authoring files enter a runtime asset bundle."""
import sys
from pathlib import Path
root = Path(sys.argv[1])
assert root.is_dir(), root
bad = [p for p in root.rglob('*') if p.is_file() and
       ('3d' in p.parts or p.suffix.lower() in ('.blend', '.blend1', '.glb', '.gltf', '.obj', '.fbx') or
        (p.suffix.lower() == '.png' and
         (p.name == 'park_map.png' or any(x in p.parts for x in
          ('level_art', 'mahjong', 'solitaire', 'sokoban', 'food_sort', 'animal_markers', 'match3'))) and 'optimized' not in p.parts))]
assert not bad, '\n'.join(str(p) for p in bad)
print('Runtime assets checked:', root)
