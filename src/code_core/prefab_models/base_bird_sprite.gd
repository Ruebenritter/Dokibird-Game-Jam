extends AnimatedSprite2D

signal shot
signal screen_visible

@export var speed_level := Enums.speed_level.Normal
@export var dragoon_type: Enums.dragoon_type = Enums.dragoon_type.Egg
@export var distance_level: Enums.distance_level = Enums.distance_level.Close
@export var is_flightless_bird := false
#@export var bird_skins: Array[Resource]
@export var squeak_sounds: Array[Resource]


var _map_border_left := -INF
var _map_border_right := INF
var _lane_y: float = 0.0
var _goes_left := true

enum MoveState {
	Default,
	Kockback,
}
var _move_state: MoveState = MoveState.Default
var _knock_velocity: float = 0.0
var _knock_duration: float = 0.0

# Shooting
var head_clicked := false
var body_clicked := false
var resolve_timer: Timer
var value: int = 0

var is_sick: bool = true

# visuals
var _texture_y_offset: float = 0.0

# sounds
var _headshot_squeak: sfx
var _bodyshot_squeak: sfx
var _spawn_sound: sfx

func _ready() -> void:
	_debounce_hits()

	_sort_sounds()
	if is_sick:
		play("sick")
	else:
		play("default")

	%BirdNoiser.stream = _spawn_sound.sound_effect
	%BirdNoiser.play()

func _process(delta: float) -> void:
	if _move_state == MoveState.Kockback:
		global_position.x = clamp(global_position.x + _knock_velocity * delta, _map_border_left, _map_border_right)
		_knock_velocity = move_toward(_knock_velocity, 0.0, 3000.0 * delta)
		_knock_duration -= delta
		if _knock_duration <= 0.0:
			_move_state = MoveState.Default
	else:
		_move(delta, _goes_left)

func _sort_sounds() -> void:
	if not squeak_sounds.is_empty():
		for sound in squeak_sounds:
			match sound.sfx_type:
				Enums.sfx_type.BirdSqueak_Good:
					_headshot_squeak = sound
				Enums.sfx_type.BirdSqueak_Bad:
					_bodyshot_squeak = sound
				Enums.sfx_type.Spawn:
					_spawn_sound = sound
				_: break

func _debounce_hits() -> void:
	resolve_timer = Timer.new()
	resolve_timer.wait_time = 0.001 # 1ms
	resolve_timer.one_shot = true
	resolve_timer.connect("timeout", Callable(self, "_on_resolve_timeout"))
	add_child(resolve_timer)

func try_construct(type: Enums.dragoon_type, distance: Enums.distance_level, bird_speed: Enums.speed_level) -> bool:
	dragoon_type = type
	distance_level = distance
	speed_level = bird_speed

	match type:
		Enums.dragoon_type.Egg:
			is_flightless_bird = true
		Enums.dragoon_type.Long:
			is_flightless_bird = false
		Enums.dragoon_type.Regular:
			is_flightless_bird = randi() % 2 == 0 # Randomly flightless or not
		Enums.dragoon_type.Chonky:
			is_flightless_bird = true
			bird_speed = Enums.speed_level.Idle
		_: is_flightless_bird = false # Default to flying for any other type

	if is_flightless_bird:
		if distance == Enums.distance_level.Distant or distance == Enums.distance_level.Close:
			print("Flightless birds cannot be spawned at Distant or Close distance.")
			return false
	else:
		if distance == Enums.distance_level.Close or speed_level == Enums.speed_level.Idle:
			print("Flying birds cannot be spawned at Close distance or with Idle speed_level.")
			return false

	_lane_y = _distance_to_y_lane(distance, is_flightless_bird)
	scale = _distance_to_scale()

	_texture_y_offset = _animation_frame_y_offset()
	global_position.y = _lane_y - _texture_y_offset

	# preliminary z value to keep birds on top. need to reorder with buildings
	z_index = 1000 - int(distance)
	
	value = max(1, 3 + (type as int * 2) + (distance as int * 2) + (bird_speed as int))
	return true


func _distance_to_y_lane(distance: Enums.distance_level, flightless: bool) -> float:
	if flightless:
		match distance:
			Enums.distance_level.Near: return Enums.ground_levels.ForeGround
			Enums.distance_level.Mid: return Enums.ground_levels.MidGround
			Enums.distance_level.Far: return Enums.ground_levels.BackGround
			_: return Enums.ground_levels.MidGround
	else:
		match distance:
			Enums.distance_level.Near: return Enums.fly_zone_lane.Hover
			Enums.distance_level.Mid: return Enums.fly_zone_lane.Jump
			Enums.distance_level.Far: return Enums.fly_zone_lane.HighRise
			Enums.distance_level.Distant: return Enums.fly_zone_lane.Fly
			_: return Enums.fly_zone_lane.Jump

func _distance_to_scale() -> Vector2:
	match distance_level:
		Enums.distance_level.Close: return Vector2(0.6, 0.6)
		Enums.distance_level.Near: return Vector2(0.5, 0.5)
		Enums.distance_level.Mid: return Vector2(0.4, 0.4)
		Enums.distance_level.Far: return Vector2(0.3, 0.3)
		Enums.distance_level.Distant: return Vector2(0.2, 0.2)
		_: return Vector2(0.1, 0.1)

func _animation_frame_y_offset() -> float:
	if sprite_frames and sprite_frames.has_animation(&"default"):
		var frames := sprite_frames
		if frames.get_frame_count(&"default") > 0:
			var texture: Texture2D = frames.get_frame_texture(&"default", 0)
			if texture:
				return texture.get_height() * (1.0 - scale.y) * 0.5
	return 0.0
	

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
	if is_flightless_bird:
		pass # walk -> only distances allowed near, mid and far for 3 ground lanes
	else:
		pass # fly -> all distances allowed for 4 fly lanes

	var dir: int = -1 if goes_left else 1
	var speed_value: int = speed_level as int
	var new_x: float = clamp(global_position.x + (dir * speed_value * delta), _map_border_left, _map_border_right)
	global_position.x = new_x

	if is_equal_approx(new_x, _map_border_left) or is_equal_approx(new_x, _map_border_right):
		_goes_left = not goes_left
		#global_position.y = _lane_y + (randf() * 20 - 10) # Randomize Y position slightly when changing direction
		scale.x = scale.x * -1 # Flip the sprite when changing direction

func start_knockback(left: bool, velocity: float, duration: float) -> void:
	print("Starting knockback: left=%s, velocity=%s, duration=%s" % [left, velocity, duration])
	_move_state = MoveState.Kockback
	_knock_velocity = velocity * (-1 if left else 1)
	_knock_duration = duration

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
	%BirdNoiser.stream = _headshot_squeak.sound_effect
	%BirdNoiser.play()
	shot.emit(self, Enums.hit_zone.Head)

func handle_body_shot() -> void:
	%BirdNoiser.stream = _bodyshot_squeak.sound_effect
	%BirdNoiser.play()
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

func ensure_fits_view(cam: Camera2D, margin: float = 8.0) -> void:
	if cam == null or !is_instance_valid(cam):
		return

	var max_iters := 5
	while max_iters > 0:
		max_iters -= 1
		var cam_rect: Rect2 = _camera_rect(cam)
		var r := _sprite_screen_aabb()

		if cam_rect.grow(-margin).encloses(r):
			print("Bird fits in camera view, no adjustment needed.")
			return
		
		var pushed: bool = _push_to_nearer_lane()
		if pushed:
			global_position.y = _lane_y - _animation_frame_y_offset()
			continue

		var clamped_x: float = clamp(global_position.x, cam_rect.position.x + margin, cam_rect.end.x - margin)
		global_position.x = clamped_x
		break

func _push_to_nearer_lane() -> bool:
	# Move distance one step towards Close if rules allow.
	var order := [Enums.distance_level.Distant, Enums.distance_level.Far, Enums.distance_level.Mid, Enums.distance_level.Near, Enums.distance_level.Close]
	var idx := order.find(distance_level)
	if idx == -1 or idx >= order.size() - 1:
		return false
	var next_d: Enums.distance_level = order[idx + 1]

	# Respect flightless/flying constraints:
	if is_flightless_bird:
		if next_d == Enums.distance_level.Close or next_d == Enums.distance_level.Distant:
			return false
	else:
		if next_d == Enums.distance_level.Close:
			return false

	distance_level = next_d
	_lane_y = _distance_to_y_lane(distance_level, is_flightless_bird)
	scale = _distance_to_scale()
	return true
	
func _sprite_screen_aabb() -> Rect2:
	# Approx AABB in world space from sprite texture size and transform.
	var frames := sprite_frames
	if frames == null or !frames.has_animation(&"default") or frames.get_frame_count(&"default") == 0:
		return Rect2(global_position, Vector2(32, 32))
	var tex := frames.get_frame_texture(&"default", 0)
	var s: float = abs(scale.x)
	var size := Vector2(tex.get_width() * s, tex.get_height() * s)
	var pos := Vector2(global_position.x - size.x * 0.5, global_position.y - size.y * 0.5)
	return Rect2(pos, size)

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	screen_visible.emit(self, true)


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	screen_visible.emit(self, false)

func make_healthy() -> void:
	is_sick = false
	play("default")

func is_going_left() -> bool:
	return _goes_left

func _camera_rect(cam: Camera2D) -> Rect2:
	var vp := get_viewport().get_visible_rect().size
	var size := Vector2(vp.x * cam.zoom.x, vp.y * cam.zoom.y)
	var tl := cam.global_position - size * 0.5
	return Rect2(tl, size)
