"""Render the project's original vector-style recovery mark as Windows icons."""
from pathlib import Path
from PIL import Image, ImageDraw
import math

root = Path(__file__).resolve().parents[1] / 'assets'
root.mkdir(exist_ok=True)
s = 1024
im = Image.new('RGBA', (s, s))
d = ImageDraw.Draw(im)
d.rounded_rectangle((32, 32, 992, 992), radius=220, fill='#111B2C', outline='#344967', width=16)
d.arc((218, 218, 806, 806), 135, 440, fill='#63E3CE', width=78)
d.polygon([(207, 570), (194, 779), (394, 712)], fill='#63E3CE')
d.rounded_rectangle((401, 380, 623, 654), radius=40, fill='#657BF2')
d.rounded_rectangle((441, 425, 583, 467), radius=12, fill='#E7F4FF')
d.ellipse((479, 547, 545, 613), fill='#E7F4FF')
im.resize((256,256), Image.Resampling.LANCZOS).save(root / 'manager.png')
im.save(root / 'manager.ico', sizes=[(16,16),(24,24),(32,32),(48,48),(64,64),(128,128),(256,256)])
