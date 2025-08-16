extends AnimatedSprite2D

signal shot
signal screen_visible

@export var speed := Enums.speed_level.Normal
@export var dragoon_type: Enums.dragoon_type = Enums.dragoon_type.Egg
@export var distance_level: Enums.distance_level = Enums.distance_level.Close
@export var flightless_bird := false
#@export var bird_skins: Array[Resource]


var _map_border_left := -INF
var _map_border_right := INF
var _lane_y: float = 0.0
var _goes_left := true

# Shooting
var head_clicked := false
var body_clicked := false
var resolve_timer: Timer
var value: int = 0

var is_sick: bool = true

# visuals
var _texture_y_offset: float = 0.0

func _ready() -> void:
	_debounce_hits()
	if is_sick:
		play("sick")
	else:
		play("default")

func _process(delta: float) -> void:
	_move(delta, _goes_left)

func _debounce_hits() -> void:
	resolve_timer = Timer.new()
	resolve_timer.wait_time = 0.001 # 1ms
	resolve_timer.one_shot = true
	resolve_timer.connect("timeout", Callable(self, "_on_resolve_timeout"))
	add_child(resolve_timer)

func try_construct(type: Enums.dragoon_type, distance: Enums.distance_level, bird_speed: Enums.speed_level) -> bool:
	match type:
		Enums.dragoon_type.Egg:
			flightless_bird = true
		Enums.dragoon_type.Long:
			flightless_bird = false
		Enums.dragoon_type.Regular:
			flightless_bird = randi() % 2 == 0 # Randomly flightless or not
		Enums.dragoon_type.Chonky:
			flightless_bird = true
			bird_speed = Enums.speed_level.Idle
		_: return false

	# chonky and egg are flightless and can only be near, mid or far
	if type == Enums.dragoon_type.Egg or type == Enums.dragoon_type.Chonky:
		if distance == Enums.distance_level.Close:
			print("Egg and Chonky birds cannot be spawned at Close distance.")
			return false
		if distance == Enums.distance_level.Distant:
			print("Distant distance is not allowed for any bird type.")
			return false
	
	# if regular is flightless, it can only be near, mid or far
	if type == Enums.dragoon_type.Regular and flightless_bird:
		if distance == Enums.distance_level.Close:
			print("Regular flightless birds cannot be spawned at Close distance.")
			return false
		if distance == Enums.distance_level.Distant:
			print("Distant distance is not allowed for any bird type.")
			return false

	# flying birds cannot be close or idle
	if not flightless_bird and (distance == Enums.distance_level.Close or bird_speed == Enums.speed_level.Idle):
		print("Flying birds cannot be spawned at Close distance.")
		return false

	# match distance to fly zone
	match distance:
		Enums.distance_level.Close:
			_lane_y = Enums.ground_levels.ForeGround
		Enums.distance_level.Near:
			_lane_y = Enums.ground_levels.ForeGround as int if flightless_bird else Enums.fly_zone_lane.Hover
		Enums.distance_level.Mid:
			_lane_y = Enums.ground_levels.MidGround as int if flightless_bird else Enums.fly_zone_lane.Jump
		Enums.distance_level.Far:
			_lane_y = Enums.ground_levels.BackGround as int if flightless_bird else Enums.fly_zone_lane.HighRise
		Enums.distance_level.Distant:
			_lane_y = Enums.fly_zone_lane.Fly

	
	value = (distance + type) * (bird_speed / 100.0) as int

	var scale_1d := _distance_to_scale()
	scale = Vector2(scale_1d, scale_1d)
	print("Constructing bird with type: ", type, ", distance: ", distance, ", speed: ", bird_speed, ", scale: ", scale)

	# set texture offset from frame[0] in "default"
	var anim := &"default"
	if sprite_frames and sprite_frames.has_animation(anim) and sprite_frames.get_frame_count(anim) > 0:
		var frame_tex: Texture2D = sprite_frames.get_frame_texture(anim, 0)
		if frame_tex:
			_texture_y_offset = frame_tex.get_height() * (1.0 - scale_1d) / 2.0
	else:
		push_warning("No 'default' animation found on %s" % name)

	
	global_position.y = _lane_y - _texture_y_offset

	z_index = - distance_level + 1000

	dragoon_type = type
	distance_level = distance
	speed = bird_speed

	return true

func _distance_to_scale() -> float:
	match distance_level:
		Enums.distance_level.Close: return 0.6
		Enums.distance_level.Near: return 0.5
		Enums.distance_level.Mid: return 0.4
		Enums.distance_level.Far: return 0.3
		Enums.distance_level.Distant: return 0.2
		_: return 0.1

func set_limits(left_x: float, right_x: float, goes_left: bool) -> void:
	_map_border_left = left_x
	_map_border_right = right_x
	_goes_left = goes_left

	# flip the sprite if it goes right
	if not goes_left:
		scale.x = - abs(scale.x)
	else:
		scale.x = abs(scale.x)

func _move(delta: float, goes_left: bool) -> void:
	if flightless_bird:
		pass # walk -> only distances allowed near, mid and far for 3 ground lanes
	else:
		pass # fly -> all distances allowed for 4 fly lanes

	var dir: int = -1 if goes_left else 1
	var speed_value: int = speed as int
	var new_x: float = clamp(global_position.x + (dir * speed_value * delta), _map_border_left, _map_border_right)
	global_position.x = new_x

	if is_equal_approx(new_x, _map_border_left) or is_equal_approx(new_x, _map_border_right):
		_goes_left = not goes_left
		#global_position.y = _lane_y + (randf() * 20 - 10) # Randomize Y position slightly when changing direction
		scale.x = scale.x * -1 # Flip the sprite when changing direction

# Hit handling
func _start_resolve() -> void:
	if resolve_timer.is_stopped():
		resolve_timer.start()

func _on_resolve_timeout() -> void:
	if head_clicked:
		handle_head_shot()
	elif body_clicked:
		handle_body_shot()

func handle_head_shot() -> void:
	print("Headshot detected on dragoon of type: ", dragoon_type)
	shot.emit(self, Enums.hit_zone.Head)

func handle_body_shot() -> void:
	print("Body shot detected on dragoon of type: ", dragoon_type)
	shot.emit(self, Enums.hit_zone.Body)

func _on_head_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		head_clicked = true
		_start_resolve()

func _on_body_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		body_clicked = true
		_start_resolve()


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	screen_visible.emit(self, true)


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	screen_visible.emit(self, false)

func make_healthy() -> void:
	is_sick = false
	play("default")