# Abu Dhabi City Drive — Godot rebuild

This is an **early playable 3D driving foundation**, not the finished Abu Dhabi city game. It currently uses a generated street grid, not imported real Abu Dhabi geographic data.

## Run
Open the city_rebuild folder as a Godot 4 project and press Run. W/Up accelerates, S/Down brakes, A/D steers. Touch controls are also available. Camera button switches views.

## Roadmap
1. Replace generated grid with correctly licensed OpenStreetMap Abu Dhabi road geometry.
2. Add streamed road/building tiles, traffic rules, and collision meshes.
3. Replace placeholder car with licensed vehicle models and improved physics.
4. Add mobile UI scaling, save system, garage, traffic, missions and landmarks.
5. Test performance and configure signed Android exports.

This new version is isolated in city_rebuild so the existing game is not overwritten.
