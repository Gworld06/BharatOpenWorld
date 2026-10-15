# Bharat Open World — Phase 1

A small Godot 4 top-down pixel-style prototype for Android. The environment is drawn procedurally in `scripts/main.gd`, so there are no external asset downloads or missing image files.

## Current prototype features
- Procedural Indian neighbourhood: roads, buildings, chai stall, trees, canal, pedestrians and a scooter.
- Top-down movement, keyboard fallback, camera tracking and basic obstacle blocking.
- Touch joystick, Action and Save buttons.
- Interact with the chai stall mission marker; complete the delivery and earn ₹150.
- Enter/exit the scooter and drive it.
- Local save file for player/vehicle positions, cash, health and mission state.
- Offline single-player; no network/API calls.

## Project structure

```text
BharatOpenWorld/
├── project.godot
├── scenes/
│   └── main.tscn
├── scripts/
│   └── main.gd
├── .github/
│   └── workflows/
│       └── android-apk.yml
├── export_presets.cfg        # add locally in Godot after Android export setup
└── README.md
```

## Open and test locally
1. Install Godot 4.x on a computer if available; for phone-only development, edit/upload the project with GitHub and use the cloud build workflow below.
2. Extract this ZIP.
3. Open `project.godot` in Godot 4.x.
4. Press Play (F6/F5 depending on editor layout). Desktop controls: WASD/arrows to move, E/Space to interact, F5 to save.
5. Test touch controls by running an Android export on a device.

## Phone-only GitHub workflow
1. Create a GitHub repository named `BharatOpenWorld`.
2. Upload the extracted project files, preserving the folder structure.
3. Ensure `export_presets.cfg` and `.github/workflows/android-apk.yml` are uploaded; both are included in this ZIP.
4. In the GitHub repository, open Actions and run the workflow.
5. Follow the workflow log. If export templates or Android SDK setup fail, fix that setup step before expecting an APK.
6. Download the generated `BharatOpenWorld-debug-apk` artifact from the successful Actions run and install it on your Android phone. Android may ask you to allow installs from that source.

## Android export setup
The project includes an Android debug export preset and a GitHub Actions workflow using the Godot CI image. The cloud image supplies the engine/export environment; the first run may still reveal version-specific Android export setup issues. If it fails, open the workflow log and adjust the image/version and Android export settings together. The APK is a debug build, not a Play Store release. For release distribution, use your own private keystore and never upload it to a public repository.

## Scope and honest test status
This is a Phase 1 prototype, not a complete GTA-scale game. The world, art and gameplay are intentionally small. It has not been run through the Godot editor or on a physical Android device in this environment; therefore no claim is made that an APK has already compiled or passed device testing. Use the cloud workflow to validate and surface build errors.

## Next milestones
1. Replace procedural rectangles with a cohesive original pixel-art tileset.
2. Add robust physics-based collision, better NPC pathfinding and vehicle handling.
3. Add interiors, day/night lighting, traffic, police, weapons and more mission types.
4. Expand to connected city/village/monument/forest/coastal regions.
