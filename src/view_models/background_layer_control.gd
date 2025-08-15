extends Control

@export var rotation_speed: float = 180

func _ready() -> void:
	var tween = create_tween().set_loops(0)
	tween.tween_property(%WindmillOrigin, "rotation_degrees", rotation_speed, 2.0).as_relative()
