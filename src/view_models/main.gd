extends Control

@export var cursor_scene: PackedScene


var _cursor: AnimatedSprite2D
var _cursor_target_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	# Initialize the cursor
	_cursor = cursor_scene.instantiate() as AnimatedSprite2D
	add_child(_cursor)

	%MainCamera.position = %Frame.size / 2


func _process(_delta: float) -> void:
	_cursor_target_position = get_viewport().get_mouse_position()
	_cursor.position = _cursor_target_position

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		pass # ToDo Crosshair movement animation -> inaccuracy
