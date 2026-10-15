extends Node2D

# Bharat Open World - Phase 1 prototype.
# All art is original procedural pixel-style drawing so the project has no missing asset dependencies.

const SAVE_PATH := "user://bharat_save.json"
const WORLD_SIZE := Vector2(2200, 2600)
const PLAYER_SPEED := 175.0
const VEHICLE_SPEED := 290.0
const TILE := 32

var player_pos := Vector2(1100, 1280)
var player_dir := Vector2.DOWN
var vehicle_pos := Vector2(1190, 1280)
var in_vehicle := false
var mission_stage := 0
var cash := 250
var health := 100
var elapsed := 0.0
var message := "Welcome to Naya Nagar. Visit the chai stall!"
var message_time := 6.0
var move_vector := Vector2.ZERO
var joystick_touch := -1
var joystick_origin := Vector2.ZERO
var joystick_current := Vector2.ZERO
var interaction_requested := false
var save_requested := false
var npc_positions: Array[Vector2] = []
var npc_offsets: Array[Vector2] = []
var buildings: Array[Rect2] = []
var trees: Array[Vector2] = []
var rocks: Array[Vector2] = []
var road_rects: Array[Rect2] = []
var stall_rect := Rect2(1280, 1190, 112, 82)
var mission_target := Vector2(1336, 1230)
var camera_pos := Vector2.ZERO
var screen_size := Vector2(480, 854)
var font: Font

func _ready() -> void:
    randomize()
    font = ThemeDB.fallback_font
    _build_world()
    _load_game()
    set_process(true)
    set_process_input(true)

func _build_world() -> void:
    # Road grid, roadside plots and a compact neighbourhood layout.
    road_rects = [
        Rect2(0, 1030, WORLD_SIZE.x, 170),
        Rect2(900, 0, 170, WORLD_SIZE.y),
        Rect2(0, 1530, WORLD_SIZE.x, 140),
        Rect2(400, 400, 140, 850),
        Rect2(1370, 700, 140, 850)
    ]
    buildings = [
        Rect2(560, 850, 210, 140), Rect2(1120, 790, 200, 160),
        Rect2(1510, 880, 190, 120), Rect2(570, 1260, 190, 150),
        Rect2(1570, 1270, 200, 150), Rect2(560, 1750, 210, 160),
        Rect2(1050, 1810, 250, 150), Rect2(1510, 1770, 220, 170),
        Rect2(800, 2150, 220, 170), Rect2(1330, 2200, 230, 160)
    ]
    trees.clear()
    rocks.clear()
    npc_positions = [Vector2(800, 1150), Vector2(1000, 1400), Vector2(1450, 1430), Vector2(1220, 970), Vector2(900, 1730), Vector2(1690, 1580)]
    npc_offsets = [Vector2(1,0), Vector2(0,1), Vector2(-1,0), Vector2(0,-1), Vector2(1,1), Vector2(-1,1)]
    for i in range(105):
        var p := Vector2(randf_range(45, WORLD_SIZE.x - 45), randf_range(50, WORLD_SIZE.y - 50))
        if _is_on_road(p) or _near_building(p, 75) or p.distance_to(player_pos) < 160:
            continue
        trees.append(p)
    for i in range(34):
        rocks.append(Vector2(randf_range(50, WORLD_SIZE.x-50), randf_range(60, WORLD_SIZE.y-60)))

func _is_on_road(p: Vector2) -> bool:
    for r in road_rects:
        if r.has_point(p):
            return true
    return false

func _near_building(p: Vector2, margin: float) -> bool:
    for r in buildings:
        if r.grow(margin).has_point(p):
            return true
    return stall_rect.grow(margin).has_point(p)

func _process(delta: float) -> void:
    elapsed += delta
    if message_time > 0:
        message_time -= delta
    var input_dir := move_vector
    if Input.is_action_pressed("ui_left"): input_dir.x -= 1
    if Input.is_action_pressed("ui_right"): input_dir.x += 1
    if Input.is_action_pressed("ui_up"): input_dir.y -= 1
    if Input.is_action_pressed("ui_down"): input_dir.y += 1
    input_dir = input_dir.limit_length()
    if input_dir.length() > 0.05:
        player_dir = input_dir.normalized()
        var speed := VEHICLE_SPEED if in_vehicle else PLAYER_SPEED
        var candidate := player_pos + input_dir.normalized() * speed * delta
        if not _blocked(candidate):
            player_pos = candidate
        if in_vehicle:
            vehicle_pos = player_pos
    for i in range(npc_positions.size()):
        var wobble := Vector2(sin(elapsed * 0.7 + i) * 8.0, cos(elapsed * 0.55 + i) * 5.0)
        # NPCs drift gently around their home points, avoiding fake high-cost AI.
        npc_positions[i] += wobble * delta * 0.22
    if interaction_requested:
        interaction_requested = false
        _interact()
    if save_requested:
        save_requested = false
        _save_game()
        _show_message("Game saved on this device.")
    queue_redraw()

func _blocked(p: Vector2) -> bool:
    if p.x < 20 or p.y < 20 or p.x > WORLD_SIZE.x-20 or p.y > WORLD_SIZE.y-20:
        return true
    for r in buildings:
        if r.grow(10).has_point(p):
            return true
    if stall_rect.grow(8).has_point(p):
        return true
    return false

func _interact() -> void:
    if player_pos.distance_to(vehicle_pos) < 76 and not in_vehicle:
        in_vehicle = true
        player_pos = vehicle_pos
        _show_message("You got on the scooter. Use the joystick to drive.")
        return
    if in_vehicle:
        in_vehicle = false
        player_pos += Vector2(48, 0)
        _show_message("You parked the scooter.")
        return
    if player_pos.distance_to(mission_target) < 190:
        if mission_stage == 0:
            mission_stage = 1
            _show_message("Chai stall: deliver tea to the station worker.")
        elif mission_stage == 1:
            mission_stage = 2
            cash += 150
            _show_message("Delivery complete! You earned ₹150.")
        else:
            _show_message("The chaiwala says: 'Come back for more work!'")
    else:
        _show_message("Nothing to interact with nearby. Find the yellow mission marker.")

func _show_message(text_value: String) -> void:
    message = text_value
    message_time = 4.5

func _save_game() -> void:
    var data := {
        "player_x": player_pos.x, "player_y": player_pos.y,
        "vehicle_x": vehicle_pos.x, "vehicle_y": vehicle_pos.y,
        "cash": cash, "health": health, "mission_stage": mission_stage,
        "in_vehicle": in_vehicle
    }
    var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify(data))
        f.close()

func _load_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not f: return
    var parsed = JSON.parse_string(f.get_as_text())
    f.close()
    if typeof(parsed) == TYPE_DICTIONARY:
        player_pos = Vector2(float(parsed.get("player_x", player_pos.x)), float(parsed.get("player_y", player_pos.y)))
        vehicle_pos = Vector2(float(parsed.get("vehicle_x", vehicle_pos.x)), float(parsed.get("vehicle_y", vehicle_pos.y)))
        cash = int(parsed.get("cash", cash))
        health = int(parsed.get("health", health))
        mission_stage = int(parsed.get("mission_stage", mission_stage))
        in_vehicle = bool(parsed.get("in_vehicle", in_vehicle))

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_E or event.keycode == KEY_SPACE:
            interaction_requested = true
        elif event.keycode == KEY_F5:
            save_requested = true
    if event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x < screen_size.x * 0.52 and event.position.y > screen_size.y * 0.55:
                joystick_touch = event.index
                joystick_origin = event.position
                joystick_current = event.position
                _update_joystick()
            elif event.position.x > screen_size.x * 0.72 and event.position.y > screen_size.y * 0.55:
                if event.position.y < screen_size.y * 0.78:
                    interaction_requested = true
                else:
                    save_requested = true
        elif event.index == joystick_touch:
            joystick_touch = -1
            move_vector = Vector2.ZERO
    elif event is InputEventScreenDrag and event.index == joystick_touch:
        joystick_current = event.position
        _update_joystick()

func _update_joystick() -> void:
    var delta := joystick_current - joystick_origin
    move_vector = (delta / 55.0).limit_length()
    if move_vector.length() < 0.16:
        move_vector = Vector2.ZERO

func _draw() -> void:
    screen_size = get_viewport_rect().size
    camera_pos = player_pos - screen_size * 0.5
    camera_pos.x = clamp(camera_pos.x, 0, WORLD_SIZE.x - screen_size.x)
    camera_pos.y = clamp(camera_pos.y, 0, WORLD_SIZE.y - screen_size.y)
    draw_set_transform(-camera_pos, 0, Vector2.ONE)
    _draw_world()
    _draw_entities()
    draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
    _draw_hud()

func _draw_world() -> void:
    draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("#79bda0"))
    # Grass pixel pattern
    for x in range(0, int(WORLD_SIZE.x), 32):
        for y in range(0, int(WORLD_SIZE.y), 32):
            if ((x * 3 + y * 7) % 5) == 0:
                draw_rect(Rect2(x+7, y+9, 3, 3), Color("#5fa889"))
            elif ((x + y) % 7) == 0:
                draw_rect(Rect2(x+21, y+22, 2, 2), Color("#9bd0a9"))
    # Sand/dirt lanes
    draw_rect(Rect2(0, 1450, WORLD_SIZE.x, 80), Color("#d8c38b"))
    # Roads and sidewalks
    for r in road_rects:
        draw_rect(r.grow(18), Color("#d0b98b"))
        draw_rect(r, Color("#66686c"))
        if r.size.x > r.size.y:
            for x in range(int(r.position.x), int(r.end.x), 78):
                draw_rect(Rect2(x, r.position.y + r.size.y/2 - 2, 36, 4), Color("#e8d9a5"))
        else:
            for y in range(int(r.position.y), int(r.end.y), 78):
                draw_rect(Rect2(r.position.x + r.size.x/2 - 2, y, 4, 36), Color("#e8d9a5"))
    # Building plots and roof detail
    for i in range(buildings.size()):
        var b: Rect2 = buildings[i]
        draw_rect(b.grow(12), Color("#9a8a67"))
        draw_rect(Rect2(b.position + Vector2(5, 7), b.size), Color("#5b473d"))
        var roof_color := [Color("#b64e3e"), Color("#d9a75c"), Color("#737d91"), Color("#9a6655")][i % 4]
        draw_rect(Rect2(b.position, b.size), roof_color)
        for xx in range(int(b.position.x)+8, int(b.end.x)-5, 16):
            draw_line(Vector2(xx, b.position.y+4), Vector2(xx, b.end.y-4), roof_color.darkened(0.12), 2)
        draw_rect(Rect2(b.position.x+b.size.x*0.38, b.end.y-8, b.size.x*0.24, 8), Color("#6a4b3c"))
        draw_rect(Rect2(b.position.x+16, b.position.y+18, 24, 20), Color("#8fd6d6"))
    # Chai stall
    draw_rect(stall_rect.grow(8), Color("#8e6846"))
    draw_rect(stall_rect, Color("#c94d3e"))
    draw_rect(Rect2(stall_rect.position.x, stall_rect.position.y+12, stall_rect.size.x, 14), Color("#e8b35b"))
    draw_rect(Rect2(stall_rect.position.x+8, stall_rect.position.y+36, stall_rect.size.x-16, 35), Color("#f0d6a1"))
    draw_string(font, stall_rect.position + Vector2(10, 56), "CHAI", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#6b382b"))
    # Trees and rocks
    for p in trees:
        draw_rect(Rect2(p.x-5, p.y+9, 10, 12), Color("#76553c"))
        draw_rect(Rect2(p.x-17, p.y-15, 34, 27), Color("#24744f"))
        draw_rect(Rect2(p.x-13, p.y-20, 26, 24), Color("#4a9a5e"))
        draw_rect(Rect2(p.x-7, p.y-22, 14, 8), Color("#81c96b"))
        draw_rect(Rect2(p.x-9, p.y-6, 4, 4), Color("#a4db78"))
    for p in rocks:
        draw_rect(Rect2(p.x-5, p.y-4, 10, 8), Color("#8e958d"))
        draw_rect(Rect2(p.x-3, p.y-6, 6, 3), Color("#b4b8ae"))
    # River/canal along the east edge, with pixel-wave highlights
    draw_rect(Rect2(1900, 0, 300, WORLD_SIZE.y), Color("#398fcb"))
    for y in range(0, int(WORLD_SIZE.y), 42):
        draw_line(Vector2(1920, y+10), Vector2(1960, y+3), Color("#72c2e7"), 3)
        draw_line(Vector2(2000, y+25), Vector2(2040, y+18), Color("#72c2e7"), 2)
    draw_rect(Rect2(1875, 0, 25, WORLD_SIZE.y), Color("#b2a18a"))

func _draw_entities() -> void:
    # Mission marker
    var marker_y := mission_target.y + sin(elapsed * 3.0) * 5
    draw_rect(Rect2(mission_target.x-12, marker_y-38, 24, 24), Color("#ffe16b"))
    draw_string(font, Vector2(mission_target.x-5, marker_y-20), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#4a3526"))
    # Scooter
    draw_rect(Rect2(vehicle_pos.x-18, vehicle_pos.y-9, 36, 18), Color("#dc443e"))
    draw_rect(Rect2(vehicle_pos.x-8, vehicle_pos.y-12, 17, 24), Color("#343b46"))
    draw_rect(Rect2(vehicle_pos.x-17, vehicle_pos.y-13, 8, 7), Color("#20252c"))
    draw_rect(Rect2(vehicle_pos.x+9, vehicle_pos.y+6, 8, 7), Color("#20252c"))
    # NPCs
    for i in range(npc_positions.size()):
        var p: Vector2 = npc_positions[i]
        draw_rect(Rect2(p.x-8, p.y-3, 16, 16), Color("#343c48"))
        draw_rect(Rect2(p.x-7, p.y-13, 14, 13), [Color("#d99a65"), Color("#9b6746"), Color("#e7b58c")][i%3])
        draw_rect(Rect2(p.x-8, p.y-16, 16, 5), [Color("#e7b84c"), Color("#456f9a"), Color("#bd5549")][i%3])
    # Player shadow and sprite
    draw_rect(Rect2(player_pos.x-8, player_pos.y+7, 16, 5), Color(0,0,0,0.25))
    if in_vehicle:
        draw_rect(Rect2(player_pos.x-7, player_pos.y-7, 14, 14), Color("#f3c06a"))
        draw_rect(Rect2(player_pos.x-5, player_pos.y-11, 10, 8), Color("#3c5e83"))
    else:
        draw_rect(Rect2(player_pos.x-7, player_pos.y-4, 14, 16), Color("#2c6d83"))
        draw_rect(Rect2(player_pos.x-6, player_pos.y-15, 12, 12), Color("#dba071"))
        draw_rect(Rect2(player_pos.x-7, player_pos.y-18, 14, 5), Color("#332b2a"))
        draw_rect(Rect2(player_pos.x-4, player_pos.y-8, 3, 4), Color("#f0d3a8"))

func _draw_hud() -> void:
    draw_rect(Rect2(10, 10, screen_size.x-20, 86), Color(0.06, 0.09, 0.12, 0.88))
    draw_string(font, Vector2(22, 34), "BHARAT OPEN WORLD  •  NAYA NAGAR", HORIZONTAL_ALIGNMENT_LEFT, screen_size.x-44, 15, Color("#f4d58a"))
    draw_string(font, Vector2(22, 57), "₹%d   HP %d   %s" % [cash, health, "SCOOTER" if in_vehicle else "ON FOOT"], HORIZONTAL_ALIGNMENT_LEFT, screen_size.x-44, 14, Color.WHITE)
    var objective := "Objective: Talk to the chaiwala" if mission_stage == 0 else ("Objective: Deliver tea to the worker" if mission_stage == 1 else "Objective: Delivery complete")
    draw_string(font, Vector2(22, 79), objective, HORIZONTAL_ALIGNMENT_LEFT, screen_size.x-44, 12, Color("#b9e8c8"))
    if message_time > 0:
        draw_rect(Rect2(14, screen_size.y*0.17, screen_size.x-28, 54), Color(0.04, 0.06, 0.08, 0.88))
        draw_string(font, Vector2(24, screen_size.y*0.17+22), message, HORIZONTAL_ALIGNMENT_LEFT, screen_size.x-48, 12, Color.WHITE)
        draw_string(font, Vector2(24, screen_size.y*0.17+40), "Move with left side • Action / Save on right", HORIZONTAL_ALIGNMENT_LEFT, screen_size.x-48, 10, Color("#b8c8d0"))
    # Joystick visual
    var joy_center := joystick_origin if joystick_touch != -1 else Vector2(74, screen_size.y-115)
    draw_circle(joy_center, 44, Color(0.1,0.13,0.16,0.35))
    draw_circle(joy_center + (move_vector*25), 19, Color(0.88,0.86,0.72,0.8))
    # Right-side buttons
    draw_circle(Vector2(screen_size.x-66, screen_size.y-145), 36, Color(0.72,0.24,0.18,0.86))
    draw_string(font, Vector2(screen_size.x-89, screen_size.y-140), "ACTION", HORIZONTAL_ALIGNMENT_LEFT, 50, 11, Color.WHITE)
    draw_circle(Vector2(screen_size.x-66, screen_size.y-65), 28, Color(0.15,0.39,0.57,0.86))
    draw_string(font, Vector2(screen_size.x-80, screen_size.y-61), "SAVE", HORIZONTAL_ALIGNMENT_LEFT, 40, 10, Color.WHITE)
    draw_string(font, Vector2(12, screen_size.y-18), "WASD / arrows • E interact • F5 save", HORIZONTAL_ALIGNMENT_LEFT, screen_size.x-24, 10, Color(1,1,1,0.65))
