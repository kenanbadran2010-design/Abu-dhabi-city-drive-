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
    raise SystemExit("All OSM providers failed; refusing to publish a city-free APK")
