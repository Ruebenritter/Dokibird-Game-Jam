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

# visuals
var _skin: BirdSkin

func _ready() -> void:
	scale = Vector2(0.5, 0.5) # Default scale, can be overridden by skin
	_debounce_hits()

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
			speed = Enums.speed_level.Idle
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

	# flying birds cannot be close
	if not flightless_bird and distance == Enums.distance_level.Close:
		print("Flying birds cannot be spawned at Close distance.")
		return false

	# match distance to fly zone
	match distance:
		Enums.distance_level.Close:
			_lane_y = Enums.ground_levels.ForeGround
		Enums.distance_level.Near:
			_lane_y = Enums.ground_levels.ForeGround if flightless_bird else Enums.fly_zone_lane.Hover
		Enums.distance_level.Mid:
			_lane_y = Enums.ground_levels.MidGround if flightless_bird else Enums.fly_zone_lane.Jump
		Enums.distance_level.Far:
			_lane_y = Enums.ground_levels.BackGround if flightless_bird else Enums.fly_zone_lane.HighRise
		Enums.distance_level.Distant:
			_lane_y = Enums.fly_zone_lane.Fly

	global_position.y = _lane_y

	value = (distance + type) * bird_speed / 100


	z_index = - distance_level + 1000

	return true

func set_limits(left_x: float, right_x: float, goes_left: bool) -> void:
	_map_border_left = left_x
	_map_border_right = right_x
	_goes_left = goes_left

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
		global_position.y = _lane_y + (randf() * 20 - 10) # Randomize Y position slightly when changing direction


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

func _on_head_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		head_clicked = true
		_start_resolve()

func _on_body_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		body_clicked = true
		_start_resolve()


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	screen_visible.emit(self, true)


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	screen_visible.emit(self, false)
