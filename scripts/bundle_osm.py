import json, pathlib, urllib.request, urllib.parse
bbox="24.455,54.345,24.480,54.380"
q='[out:json][timeout:90];(way[highway]('+bbox+');way[building]('+bbox+'););out geom;'
request=urllib.request.Request("https://overpass-api.de/api/interpreter",data=urllib.parse.urlencode({"data":q}).encode())
with urllib.request.urlopen(request,timeout=120) as response:
 data=json.load(response)
elements=[e for e in data.get("elements",[]) if e.get("type")=="way" and e.get("geometry")]
if sum("highway" in e.get("tags",{}) for e in elements)<30: raise RuntimeError("Real road data unavailable")
path=pathlib.Path("public/maps/downtown.json")
path.parent.mkdir(parents=True,exist_ok=True)
path.write_text(json.dumps({"elements":elements},separators=(",",":")))
print("Bundled",len(elements),"OSM features")
