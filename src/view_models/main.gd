extends Control

@export var cursor_scene: PackedScene
@export var ammo_scene: PackedScene

@export var max_ammo: int = 5
@export var reload_time: float = 3.0

@export var camera_pan_speed: float = 100.0
@export var edge_threshold: float = 50.0


var _reloading: bool = false
var _last_round: Dart

var _min_x := 0.0
var _max_x := 0.0
var _fixed_y := 0.0
var _viewport_size: Vector2 = Vector2.ZERO

var _countdownTimer: Timer
@export var countdown_time_seconds: int = 90

func _ready() -> void:
	#Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_viewport_size = get_viewport().get_visible_rect().size

	%MainCamera.position = size / 2
	_fixed_y = %MainCamera.position.y
	_calc_level_limits()

	#_reload()

	# Countdown Timer
	_countdownTimer = Timer.new()
	_countdownTimer.wait_time = 1.0
	_countdownTimer.one_shot = false
	_countdownTimer.autostart = true
	_countdownTimer.connect("timeout", Callable(self, "_on_countdown_timer_timeout"))
	add_child(_countdownTimer)

	%TimeLabel.text = format_time(countdown_time_seconds)
	%ScoreLabel.text = "0"


func _process(delta: float) -> void:
	if !is_inside_tree() or !is_instance_valid(%MainCamera):
		return

	var mouse_pos = get_viewport().get_mouse_position()

	var dx := 0.0
	if mouse_pos.x <= edge_threshold:
		dx = - camera_pan_speed * delta
	elif mouse_pos.x >= _viewport_size.x - edge_threshold:
		dx = camera_pan_speed * delta

	if dx != 0.0:
		var new_x: float = clamp(%MainCamera.global_position.x + dx, _min_x, _max_x)
		%MainCamera.position = Vector2(new_x, _fixed_y) # lock Y

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_LEFT:
				_fire_once()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_reload()

func _fire_once() -> void:
	if not ammo_scene:
		return
	
	if _reloading:
		return

	var count = %AmmoRow.get_child_count()
	if count == 0:
		%BirdControl.set_can_shoot(false)
		return

	var last = %AmmoRow.get_child(count - 1) as Dart
	last.queue_free()

func _reload() -> void:
	if not ammo_scene:
		return

	if _reloading:
		return

	_reloading = true
	%BirdControl.set_can_shoot(false)
	
	_clear_ammo_items()

	var wait_between_reload: float = reload_time / max_ammo

	for i in range(max_ammo):
		await get_tree().create_timer(wait_between_reload).timeout
		if _last_round:
			_last_round.stop_blinking()
		
		var ammo_instance = ammo_scene.instantiate() as Dart
		%AmmoRow.add_child(ammo_instance)

		ammo_instance.blink()
		_last_round = ammo_instance
		

	_last_round.stop_blinking()
	_reloading = false
	%BirdControl.set_can_shoot(true)

func _clear_ammo_items() -> void:
	var children = %AmmoRow.get_children()
	for child in children:
		child.queue_free()

func _calc_level_limits() -> void:
	if !%BackgroundTexture.texture:
		return

	var texture_size = %BackgroundTexture.texture.get_size()
	_min_x = - texture_size.x / 2
	_max_x = texture_size.x / 2

func _on_countdown_timer_timeout() -> void:
	countdown_time_seconds -= 1
	if countdown_time_seconds <= 0:
		_countdownTimer.stop()
		%TimeLabel.text = "FIN"
		return

	%TimeLabel.text = format_time(countdown_time_seconds)


func format_time(seconds: int) -> String:
	var minutes := seconds / 60
	var secs := seconds % 60
	return "%02d:%02d" % [minutes, secs]


func _on_bird_control_scored(value: int) -> void:
	%ScoreLabel.text = str(int(%ScoreLabel.text) + value)
