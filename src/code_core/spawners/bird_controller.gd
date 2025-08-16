extends Node2D


@export var background: NodePath
@export var spawn_padding := 100.0

@export var egg_bird_scene: PackedScene
@export var long_bird_scene: PackedScene
@export var chonky_bird_scene: PackedScene
@export var regular_bird_scene: PackedScene

@export var spawn_limit_by_score := 1000
@export var desired_birds_on_screen := 5

@export var camera: Camera2D


signal scored

var _remaining_spawn_limit := spawn_limit_by_score
var background_bounds: Rect2
var _min_x := -INF
var _max_x := INF

var _can_shoot := true

var spawn_attempts := 0

var _on_screen_count := 0
var _regular_spawn_timer: Timer

func _ready() -> void:
	# Initialize bird spawners or any other setup needed
	if not background.is_empty():
		var bg_node := get_node(background)
		background_bounds = Rect2(bg_node.global_position, bg_node.get_size())
	else:
		background_bounds = Rect2(Vector2(-500, -500), Vector2(1000, 1000)) # Default bounds if no background

	_min_x = background_bounds.position.x + spawn_padding
	_max_x = background_bounds.position.x + background_bounds.size.x - spawn_padding

	print("Background bounds: ", background_bounds)
	randomize()
	_create_spawn_timer()

func _create_spawn_timer() -> void:
	_regular_spawn_timer = Timer.new()
	_regular_spawn_timer.wait_time = 1.0 # Adjust the spawn interval as needed
	_regular_spawn_timer.one_shot = true
	_regular_spawn_timer.connect("timeout", Callable(self, "_on_spawn_timer_timeout"))
	add_child(_regular_spawn_timer)
	_regular_spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	print("Spawn timer triggered")
	_try_spawn_bird()
	if _remaining_spawn_limit <= 0 or spawn_attempts > 100:
		_regular_spawn_timer.stop()
		print("No more birds can be spawned or too many attempts.")
		return
	_regular_spawn_timer.wait_time = randf_range(1.0, 3.0) # Randomize the next spawn time
	_regular_spawn_timer.start()


func _try_spawn_bird() -> void:
	spawn_attempts += 1
	var dragoon_t: Enums.dragoon_type = Enums.dragoon_type.values()[randi() % 4]
	var distance_level: Enums.distance_level = Enums.distance_level.values()[randi() % 5] # 0 to 4 for Close, Near, Mid, Far, Distant
	var speed_level: Enums.speed_level = Enums.speed_level.values()[randi() % 5] # 0 to 4 for Idle, Slow, Normal, Fast, VeryFast


	var bird_value = distance_level + dragoon_t + speed_level
	print("Trying to spawn bird with value: ", bird_value)
	var scene := _scene_for_type(dragoon_t)
	if not scene:
		print("No scene found for dragoon type: ", dragoon_t)
	
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
		var dir: int = spawn_data[1]

		bird.global_position.x = spawn_pos.x
		bird.connect("screen_visible", Callable(self, "_on_bird_screen_visible"))
		bird.connect("shot", Callable(self, "_on_bird_shot"))
		add_child(bird)
		bird.set_limits(_min_x, _max_x, dir)
		_remaining_spawn_limit -= bird_value
		print("Spawned bird: ", bird.name, " at position: ", spawn_pos, " with direction: ", dir)
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


func _on_bird_shot(bird: Node2D, hit_zone: Enums.hit_zone) -> void:
	if !_can_shoot:
		print("Cannot shoot, reloading or not allowed.")
		return
	if hit_zone == Enums.hit_zone.Head:
		scored.emit(bird.value)
		bird.queue_free()
		_on_screen_count = max(0, _on_screen_count - 1)
	elif hit_zone == Enums.hit_zone.Body:
		pass
	else:
		print("Unknown hit zone: ", hit_zone)

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
	return [Vector2(x, y), -1 if from_left else 1]

func _visible_world_rect() -> Rect2:
	var vp_size := get_viewport().get_visible_rect().size
	if camera and camera is Camera2D:
		var cam := camera as Camera2D
		var size := Vector2(vp_size.x * cam.zoom.x, vp_size.y * cam.zoom.y)
		var top_left := cam.global_position - size / 2
		return Rect2(top_left, size)
	return Rect2(Vector2.ZERO, vp_size)
