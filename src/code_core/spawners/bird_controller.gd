extends Node2D


@export var background: NodePath
@export var camera: Camera2D
@export var spawn_padding := 100.0

@export var egg_bird_scene: PackedScene
@export var long_bird_scene: PackedScene
@export var chonky_bird_scene: PackedScene
@export var regular_bird_scene: PackedScene

@export var spawn_limit_by_score := 1000
@export var desired_birds_on_screen := 5
@export var spawn_interval_min_seconds := 1.0
@export var spawn_interval_max_seconds := 3.0


signal scored(value: int)
signal bird_count_changed(count: int)

var _remaining_spawn_limit: int
var _world_bounds: Rect2
var _min_x: float
var _max_x: float

var _can_shoot := true

var spawn_attempts := 0
var _on_screen_count := 0
var _spawn_timer: Timer

func _ready() -> void:
	_remaining_spawn_limit = spawn_limit_by_score
	_resolve_world_bounds()
	_create_spawn_timer()

func _create_spawn_timer() -> void:
	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = true
	_spawn_timer.connect("timeout", Callable(self, "_on_spawn_timer_timeout"))
	add_child(_spawn_timer)
	_restart_spawn_timer()

func _restart_spawn_timer() -> void:
	_spawn_timer.wait_time = randf_range(spawn_interval_min_seconds, spawn_interval_max_seconds)
	_spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	if _remaining_spawn_limit <= 0 or spawn_attempts > 100:
		_spawn_timer.stop()
		print("No more birds can be spawned or too many attempts.")
		return

	_try_spawn_bird()
	_spawn_timer.wait_time = randf_range(1.0, 3.0) # Randomize the next spawn time
	_spawn_timer.start()

func _resolve_world_bounds() -> void:
	if background.is_empty():
		push_error("Background node path is not set or invalid.")
		return
	
	var sky_node = get_node(background).get_node("Sky") as TextureRect

	if not sky_node or not sky_node.texture:
		push_error("Sky texture is not set or invalid.")
		return

	_world_bounds = Rect2(sky_node.global_position, sky_node.size)
	_min_x = _world_bounds.position.x
	_max_x = _world_bounds.position.x + _world_bounds.size.x


func _pick_bird_config() -> Dictionary:
	var tries := 8
	while tries > 0:
		tries -= 1
		var dragoon_type: Enums.dragoon_type = Enums.dragoon_type.values()[randi() % 4]
		var distance_level: Enums.distance_level = Enums.distance_level.values()[randi() % 5]
		var speed_level: Enums.speed_level = Enums.speed_level.values()[randi() % 5]

		var value_estimate := _estimate_value(dragoon_type, distance_level, speed_level)
		if value_estimate <= _remaining_spawn_limit:
			return {
				"dragoon_type": dragoon_type,
				"distance_level": distance_level,
				"speed_level": speed_level,
				"value_estimate": value_estimate
			}
		print("Failed to pick a valid bird config, trying again...")
	return {}

func _estimate_value(t: int, d: int, s: int) -> int:
	return 3 + (t * 2) + (d * 2) + s

# func _try_spawn_bird_once() -> void: 9

# 	var config = _pick_bird_config()
# 	if not config:
# 		print("Failed to pick a valid bird configuration.")
# 		return
	
# 	var scene := _scene_for_type(config.dragoon_type)
# 	if not scene:
# 		print("No scene found for dragoon type: ", config.dragoon_type)
# 		return

	# var bird := scene.instantiate() as AnimatedSprite2D

func _try_spawn_bird() -> void:
	spawn_attempts += 1
	var dragoon_t: Enums.dragoon_type = Enums.dragoon_type.values()[randi() % 4]
	var distance_level: Enums.distance_level = Enums.distance_level.values()[randi() % 5] # 0 to 4 for Close, Near, Mid, Far, Distant
	var speed_level: Enums.speed_level = Enums.speed_level.values()[randi() % 5] # 0 to 4 for Idle, Slow, Normal, Fast, VeryFast


	var bird_value = distance_level + dragoon_t + speed_level
	var scene := _scene_for_type(dragoon_t)
	if not scene:
		print("No scene found for dragoon type: ", dragoon_t)
		return
	
	var bird := scene.instantiate() as AnimatedSprite2D

	if not bird.try_construct(dragoon_t, distance_level, speed_level):
		print("Failed to construct bird.") # bird construction can fail if distance_level is not compatible with bird type (flightless)
		bird.queue_free()
		return

	if spawn_attempts > 100:
		print("Too many spawn attempts.")
		return

	if _remaining_spawn_limit <= 0:
		print_debug("Spawn limit reached, cannot spawn more birds.")
		return
	
	if bird_value > _remaining_spawn_limit:
		print_debug("Not enough spawn limit left for bird value: ", bird_value)
		_try_spawn_bird()
		return

	if bird:
		var spawn_data := _choose_spawn_outside_viewport()
		var spawn_pos: Vector2 = spawn_data[0]
		var from_left: bool = spawn_data[1]

		bird.global_position.x = spawn_pos.x
		bird.connect("screen_visible", Callable(self, "_on_bird_screen_visible"))
		bird.connect("shot", Callable(self, "_on_bird_shot"))
		add_child(bird)
		bird.set_limits(_min_x, _max_x, !from_left)
		_remaining_spawn_limit -= bird_value
		print("Spawned bird: ", bird.name, " at position: ", spawn_pos, " that goes left: ", !from_left)
		spawn_attempts = 0
	else:
		push_error("Failed to instantiate bird from scene.")

func _scene_for_type(dragoon_t: Enums.dragoon_type) -> PackedScene:
	match dragoon_t:
		Enums.dragoon_type.Egg: return egg_bird_scene
		Enums.dragoon_type.Long: return long_bird_scene
		Enums.dragoon_type.Regular: return regular_bird_scene
		Enums.dragoon_type.Chonky: return chonky_bird_scene
		_: return null


func _on_bird_shot(bird: AnimatedSprite2D, hit_zone: Enums.hit_zone) -> void:
	if !_can_shoot:
		print("Cannot shoot, reloading or not allowed.")
		return

	if hit_zone == Enums.hit_zone.Head:
		if bird.is_sick:
			scored.emit(bird.value)
			bird.make_healthy()
			pass
		_on_screen_count = max(0, _on_screen_count - 1)
	elif hit_zone == Enums.hit_zone.Body:
		if bird.is_sick:
			_duplicate_and_bounce(bird)

	else:
		print("Unknown hit zone: ", hit_zone)


func _duplicate_and_bounce(original_bird: AnimatedSprite2D) -> void:
	print("Duplicating and bouncing bird: ", original_bird.name)

	var scene := _scene_for_type(original_bird.dragoon_type)
	if not scene:
		print("No scene found for dragoon type: ", original_bird.dragoon_type)
		return
	
	var duplicate_bird := scene.instantiate() as AnimatedSprite2D
	if not duplicate_bird:
		print("Failed to instantiate duplicate bird.")
		return

	add_child(duplicate_bird)
	await duplicate_bird.ready

	if not duplicate_bird.try_construct(original_bird.dragoon_type, original_bird.distance_level, original_bird.bird_speed):
		print("Failed to construct duplicate bird.")
		duplicate_bird.queue_free()
		return

	duplicate_bird.global_position.x = original_bird.global_position.x + 1.0
	duplicate_bird.global_position.y = original_bird.global_position.y

	duplicate_bird.set_limits(_min_x, _max_x, !original_bird.is_going_left())

	duplicate_bird.connect("screen_visible", Callable(self, "_on_bird_screen_visible"))
	duplicate_bird.connect("shot", Callable(self, "_on_bird_shot"))

	print("Duplicated bird: ", duplicate_bird.name, " at position: ", duplicate_bird.global_position)

	
func _on_bird_screen_visible(_bird: Node2D, bird_visible: bool) -> void:
	if bird_visible:
		_on_screen_count += 1
	else:
		_on_screen_count = max(0, _on_screen_count - 1)
	
	print("Bird on screen count: ", _on_screen_count)

func set_can_shoot(value: bool) -> void:
	_can_shoot = value
	print("Can shoot set to: ", _can_shoot)

func _choose_spawn_outside_viewport() -> Array:
	var rect := _visible_world_rect()
	var from_left := randf() < 0.5
	var x := rect.position.x - spawn_padding if from_left else rect.end.x + spawn_padding
	var y := randf_range(rect.position.y, rect.position.y + rect.size.y)
	return [Vector2(x, y), from_left]

func _visible_world_rect() -> Rect2:
	var vp_size := get_viewport().get_visible_rect().size
	if camera and camera is Camera2D:
		var cam := camera as Camera2D
		var size := Vector2(vp_size.x * cam.zoom.x, vp_size.y * cam.zoom.y)
		var top_left := cam.global_position - size / 2
		return Rect2(top_left, size)
	return Rect2(Vector2.ZERO, vp_size)
