# Mice Invaders

A single-screen browser game scaffold built with Godot 4. This repository currently contains only the project structure; no gameplay logic has been added yet.

## Opening the project

1. Install Godot 4.7.
2. Open the project manager and import `project.godot`.
3. Open the project and press `F5` to run the main scene.

The main scene is `res://scenes/Main.tscn`, a minimal `Node2D` root with an attached script at `res://scripts/main.gd`.

## Web export

The web export uses the preset named exactly `Web`, defined in `export_presets.cfg`.

With Godot installed and export templates available, run:

```bash
godot --headless --export-release Web build/web/index.html
```

This writes the exported game to `build/web/index.html`.

To serve the export locally:

```bash
cd build/web
python3 -m http.server 8080
```

Then open `http://localhost:8080` in a browser.
