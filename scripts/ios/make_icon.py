"""Render the existing code-native sunMark from src/art.js at app-icon scale."""
import json
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[2] / "ios/Tonari/Assets.xcassets"
icon = root / "AppIcon.appiconset"
icon.mkdir(parents=True, exist_ok=True)
size = 2048
im = Image.new("RGB", (size, size), "#f4f8fc")
d = ImageDraw.Draw(im)
# The page's sunMark uses a 40x40 viewbox. Give it the same 5..35 margins.
scale = size / 40
for y in range(round(13 * scale), round(33 * scale)):
    dy = y / scale - 23
    width = (100 - dy * dy) ** 0.5
    t = (y / scale - 13) / 20
    color = tuple(round(a + (b-a)*t) for a, b in zip((255,210,122),(255,159,110)))
    d.line([(round((20-width)*scale),y),(round((20+width)*scale),y)], fill=color)
for a,b in [((5,30),(35,30)),((20,6),(20,10)),((8.5,11),(11.3,13.8)),((31.5,11),(28.7,13.8))]:
    line_color = "#ff9f6e" if a == (5,30) else "#ffc35c"
    points = [(round(x*scale),round(y*scale)) for x,y in (a,b)]
    d.line(points,fill=line_color,width=round(2.4*scale))
    radius = 1.2*scale
    for x,y in points: d.ellipse((x-radius,y-radius,x+radius,y+radius),fill=line_color)
im.resize((1024,1024),Image.Resampling.LANCZOS).save(icon / "AppIcon.png")
(icon / "Contents.json").write_text(json.dumps({"images":[{"filename":"AppIcon.png","idiom":"universal","platform":"ios","size":"1024x1024"}],"info":{"author":"xcode","version":1}},indent=2),encoding="utf-8")
(root / "Contents.json").write_text('{"info":{"author":"xcode","version":1}}\n',encoding="utf-8")
launch = root / "LaunchBackground.colorset"
launch.mkdir(exist_ok=True)
(launch / "Contents.json").write_text(json.dumps({"colors":[{"idiom":"universal","color":{"color-space":"srgb","components":{"red":"0.9569","green":"0.9725","blue":"0.9882","alpha":"1.000"}}}],"info":{"author":"xcode","version":1}},indent=2),encoding="utf-8")
print("Rendered existing sun mark; 1024px RGB icon")
