extends Node2D


@export var background: NodePath
@export var spawn_padding := 100.0

@export var egg_bird_scene: PackedScene
@export var neck_bird_scene: PackedScene
@export var ball_bird_scene: PackedScene
@export var chonky_bird_scene: PackedScene


var background_bounds: Rect2
var _min_x := -INF
var _max_x := INF

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
	spaw_bird(Enums.dragoon_type.Egg, Enums.distance_level.Close, Enums.speed_level.Normal)

# get a reference to background texture 
# -> size determines spawn zones

# birds spawn outside the map and walk, fly in
# special birds spawn in deterministic locations on the map with unique spawn logic

func _scene_for_type(dragoon_t: Enums.dragoon_type) -> PackedScene:
	match dragoon_t:
		Enums.dragoon_type.Egg:
			return egg_bird_scene
		Enums.dragoon_type.Neck:
			return neck_bird_scene
		Enums.dragoon_type.Ball:
			return ball_bird_scene
		Enums.dragoon_type.Chonky:
			return chonky_bird_scene
		_:
			push_error("Unknown dragoon type: %s" % dragoon_t)
			return null


func spaw_bird(dragoon_t, distance_t, speed_t) -> Node2D:
	var scene := _scene_for_type(dragoon_t)

	if !scene:
		return null

	var bird := scene.instantiate() as Node2D
	add_child(bird)

	var spawn_left := randi() % 2 == 0
	var dir := -1 if spawn_left else 1

	bird.global_position.x = _min_x if spawn_left else _max_x
	bird.global_position.y = 900 # Adjust this based on your game design
	bird.setup(_min_x + spawn_padding, _max_x - spawn_padding, 900, dir)

	bird.speed = speed_t
	bird.dragoon_type = dragoon_t
	bird.distance_level = distance_t

	print("Spawning bird: ", bird.name, " spawns left: ", spawn_left)
	if bird.has_signal("shot"):
		bird.connect("shot", Callable(self, "_on_bird_shot"))

	return bird


func _on_bird_shot(bird: Node2D, hit_zone: Enums.hit_zone) -> void:
	if hit_zone == Enums.hit_zone.Head:
		bird.queue_free()
	elif hit_zone == Enums.hit_zone.Body:
		pass
	else:
		print("Unknown hit zone: ", hit_zone)
