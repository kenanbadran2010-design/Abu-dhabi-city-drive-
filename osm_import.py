import csv,json,math,re,time,urllib.parse,urllib.request
from pathlib import Path
root=Path(__file__).resolve().parent
s,w,n,e=24.457,54.344,24.494,54.390
lat0,lon0=(s+n)/2,(w+e)/2
mlon=111320*math.cos(math.radians(lat0))
q=f'[out:json][timeout:150];(way[highway~"^(motorway|trunk|primary|secondary|tertiary|residential|unclassified|service|living_street|pedestrian|motorway_link|trunk_link|primary_link|secondary_link|tertiary_link)$"]({s},{w},{n},{e});way[building]({s},{w},{n},{e});node[amenity][name]({s},{w},{n},{e});node[tourism][name]({s},{w},{n},{e}););out geom;'
def xy(p): return ((p['lon']-lon0)*mlon,-(p['lat']-lat0)*111132)
data=None
for url in ['https://overpass.kumi.systems/api/interpreter','https://overpass-api.de/api/interpreter','https://overpass.nchc.org.tw/api/interpreter']:
 try:
  req=urllib.request.Request(url,data=urllib.parse.urlencode({'data':q}).encode(),headers={'User-Agent':'AbuDhabiCityDrive-OSMImporter/1.0'})
  with urllib.request.urlopen(req,timeout=180) as resp:data=json.load(resp)
  if data.get('elements'):break
 except Exception as ex:print('Overpass retry:',str(ex),flush=True);time.sleep(2)
if not data or not data.get('elements'):raise RuntimeError('Could not fetch real OpenStreetMap geometry')
roads=[];buildings=[];places=[]
for el in data['elements']:
 tags=el.get('tags',{});geo=el.get('geometry',[])
 if el['type']=='way' and 'highway' in tags and len(geo)>1:
  width={'motorway':17,'trunk':15,'primary':13,'secondary':11,'tertiary':10,'residential':7,'service':5,'pedestrian':5}.get(tags['highway'],7)
  for a,b in zip(geo,geo[1:]):
   ax,az=xy(a);bx,bz=xy(b)
   if 2<math.hypot(bx-ax,bz-az)<300:roads.append((round(ax,2),round(az,2),round(bx,2),round(bz,2),width))
 elif el['type']=='way' and 'building' in tags and len(geo)>2:
  pts=[xy(p) for p in geo];xs=[p[0] for p in pts];zs=[p[1] for p in pts]
  dx=max(xs)-min(xs);dz=max(zs)-min(zs)
  if not (3<dx<180 and 3<dz<180):continue
  match=re.match(r'^\s*(\d+(?:\.\d+)?)',tags.get('height',''))
  levels=tags.get('building:levels','')
  height=float(match.group(1)) if match else float(levels)*3.2 if levels.isdigit() else 15
  buildings.append((round((min(xs)+max(xs))/2,2),round((min(zs)+max(zs))/2,2),round(dx,2),round(dz,2),round(max(3,min(height,180)),1)))
 elif el['type']=='node' and tags.get('name') and ('amenity' in tags or 'tourism' in tags):
  x,z=xy(el);places.append((round(x,2),round(z,2),tags['name'].replace(',',' ').replace('\n',' ')[:60]))
if len(roads)<100 or len(buildings)<50:raise RuntimeError(f'Incomplete OSM download: {len(roads)} roads {len(buildings)} buildings')
for name,rows in [('roads.csv',roads[:5000]),('buildings.csv',buildings[:2000]),('places.csv',places[:200])]:
 with (root/name).open('w',newline='',encoding='utf8') as f:csv.writer(f).writerows(rows)
print(f'OSM imported: {len(roads)} road segments, {len(buildings)} buildings, {len(places)} places',flush=True)
