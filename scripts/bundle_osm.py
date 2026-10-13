"""Bundle an actual OpenStreetMap district for offline Android gameplay."""
import json
import pathlib
import time
import urllib.error
import urllib.parse
import urllib.request

BBOX = "24.455,54.345,24.480,54.380"
QUERY = ('[out:json][timeout:75];(way[highway](' + BBOX +
         ');way[building](' + BBOX + '););out geom;')
SERVERS = (
    "https://overpass.kumi.systems/api/interpreter",
    "https://overpass.private.coffee/api/interpreter",
    "https://overpass.nchc.org.tw/api/interpreter",
    "https://overpass-api.de/api/interpreter",
)
out = pathlib.Path("public/maps/downtown.json")
out.parent.mkdir(parents=True, exist_ok=True)
for server in SERVERS:
    try:
        req = urllib.request.Request(
            server,
            data=urllib.parse.urlencode({"data": QUERY}).encode("utf-8"),
            headers={
                "User-Agent": "AbuDhabiDrive3D/0.4 (offline game map; OSM attribution)",
                "Accept": "application/json",
                "Content-Type": "application/x-www-form-urlencoded",
            },
        )
        with urllib.request.urlopen(req, timeout=40) as response:
            data = json.load(response)
        elements = [
            element for element in data.get("elements", [])
            if element.get("type") == "way"
            and len(element.get("geometry", [])) >= 2
        ]
        roads = sum(bool(item.get("tags", {}).get("highway")) for item in elements)
        buildings = sum(bool(item.get("tags", {}).get("building")) for item in elements)
        if roads < 30 or buildings < 15:
            raise RuntimeError(f"Insufficient data: {roads} roads, {buildings} buildings")
        out.write_text(json.dumps({"elements": elements}, separators=(",", ":")), encoding="utf8")
        print(f"Bundled {roads} real roads and {buildings} buildings from {server}.", flush=True)
        break
    except Exception as exc:
        print(f"OSM provider {server} unavailable: {exc}", flush=True)
        time.sleep(2)
else:
    # Independent fallback: extract a real Abu Dhabi district from Geofabrik's
    # OSM PBF archive instead of fabricating streets when Overpass is unavailable.
    import subprocess
    import sys
    import tempfile
    print("Using independent Geofabrik OSM extract fallback", flush=True)
    subprocess.run([sys.executable, "-m", "pip", "install", "--quiet", "osmium"], check=True)
    import osmium
    with tempfile.TemporaryDirectory() as directory:
        pbf = pathlib.Path(directory) / "gcc-states.osm.pbf"
        download = urllib.request.Request(
            "https://download.geofabrik.de/asia/gcc-states-latest.osm.pbf",
            headers={"User-Agent": "AbuDhabiDrive3D/0.4 (OpenStreetMap offline game)"},
        )
        with urllib.request.urlopen(download, timeout=180) as response, pbf.open("wb") as dest:
            import shutil
            shutil.copyfileobj(response, dest)
        print("Downloaded PBF archive; collecting local streets and buildings", flush=True)
        class Collector(osmium.SimpleHandler):
            def __init__(self):
                super().__init__()
                self.elements = []
            def way(self, way):
                tags = dict(way.tags)
                if not (tags.get("highway") or tags.get("building")):
                    return
                geo = []
                inside = False
                for node in way.nodes:
                    if not node.location.valid():
                        continue
                    lat, lon = node.location.lat, node.location.lon
                    geo.append({"lat": lat, "lon": lon})
                    if 24.455 <= lat <= 24.480 and 54.345 <= lon <= 54.380:
                        inside = True
                if inside and len(geo) >= 2:
                    self.elements.append({"type": "way", "id": way.id, "tags": tags, "geometry": geo})
        collector = Collector()
        collector.apply_file(str(pbf), locations=True)
        roads = sum("highway" in e["tags"] for e in collector.elements)
        buildings = sum("building" in e["tags"] for e in collector.elements)
        if roads < 30 or buildings < 15:
            raise SystemExit(f"Geofabrik extract also insufficient: {roads} roads and {buildings} buildings")
        out.write_text(json.dumps({"elements": collector.elements}, separators=(",", ":")), encoding="utf8")
        print(f"Bundled {roads} real roads and {buildings} real buildings using Geofabrik", flush=True)
