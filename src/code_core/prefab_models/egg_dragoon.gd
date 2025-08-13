extends Node2D


@export var speed := Enums.speed_level.Normal
@export var dragoon_type: Enums.dragoon_type = Enums.dragoon_type.Egg
@export var distance_level: Enums.distance_level = Enums.distance_level.close

var _min_x := -INF
var _max_x := INF
var _fixed_y := 0.0
var _dir := 1
# after spawn walk across the screen, turn randomly and when hitting obstacles

func setup(left_x: float, right_x: float, lane_y: float, dir: int) -> void:
	_min_x = left_x
	_max_x = right_x
	_fixed_y = lane_y
	_dir = dir
	global_position.y = _fixed_y
	

func walk(delta: float) -> void:
	# Implement walking logic here
	%BirdAnim.play("default")
	var move_speed := speed * delta * _dir
	var new_x := global_position.x + move_speed
	new_x = clamp(new_x, _min_x, _max_x)
	global_position.x = new_x

	# flip direction at limits
	if is_equal_approx(new_x, _min_x) or is_equal_approx(new_x, _max_x):
		_dir *= -1
		%BirdAnim.flip_h = _dir < 0
	

func _ready() -> void:
	%BirdAnim.animation = "default"

func _process(delta: float) -> void:
	walk(delta)
