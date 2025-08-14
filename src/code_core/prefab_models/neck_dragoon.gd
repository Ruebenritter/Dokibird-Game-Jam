extends Node2D

signal shot
signal screen_visible

@export var speed := Enums.speed_level.Normal
@export var dragoon_type: Enums.dragoon_type = Enums.dragoon_type.Egg
@export var distance_level: Enums.distance_level = Enums.distance_level.Close

var _min_x := -INF
var _max_x := INF
var _fixed_y := 0.0
var _dir := 1
# after spawn walk across the screen, turn randomly and when hitting obstacles

# shoot debounce
var head_clicked := false
var body_clicked := false
var resolve_timer: Timer


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

	# Initialize the resolve timer
	resolve_timer = Timer.new()
	resolve_timer.wait_time = 0.001 # 1ms
	resolve_timer.one_shot = true
	resolve_timer.connect("timeout", Callable(self, "_on_resolve_timeout"))
	add_child(resolve_timer)

func _process(delta: float) -> void:
	walk(delta)

func _on_resolve_timeout() -> void:
	if head_clicked:
		handle_headshot()
	elif body_clicked:
		handle_body_shot()


	head_clicked = false
	body_clicked = false

func _on_body_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if InputEventMouseButton and event.is_pressed():
		if !event.button_index == MOUSE_BUTTON_LEFT:
			return
		body_clicked = true
		_start_resolve()


func _on_head_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if InputEventMouseButton and event.is_pressed():
		if !event.button_index == MOUSE_BUTTON_LEFT:
			return

		head_clicked = true
		_start_resolve()

func handle_headshot() -> void:
	print("Headshot detected on dragoon of type: ", dragoon_type)
	shot.emit(self, Enums.hit_zone.Head)

func handle_body_shot() -> void:
	print("Body shot detected on dragoon of type: ", dragoon_type)
	shot.emit(self, Enums.hit_zone.Body)

func _start_resolve() -> void:
	if not resolve_timer.is_stopped():
		return
	resolve_timer.start()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	screen_visible.emit(self, false)

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	screen_visible.emit(self, true)
