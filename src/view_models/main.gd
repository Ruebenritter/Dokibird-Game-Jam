extends Control


@export var startup_scene: PackedScene
@export var game_scene: PackedScene
@export var game_over_scene: PackedScene

var final_score: int = 0
var _child: Node = null

func _ready() -> void:
	# Initialize the main view model
	var startup_view_model = startup_scene.instantiate()
	add_child(startup_view_model)
	_child = startup_view_model

	# bind to start_game signal
	startup_view_model.connect("start_game", Callable(self, "_on_start_game"))

func _on_start_game() -> void:
	# Switch to the game scene
	if _child:
		_child.queue_free()

	var game_view_model = game_scene.instantiate()
	add_child(game_view_model)
	_child = game_view_model

	game_view_model.connect("game_over", Callable(self, "_on_game_over"))

func _on_game_over(score: int) -> void:
	if _child:
		_child.queue_free()

	var game_over_view_model = game_over_scene.instantiate()
	add_child(game_over_view_model)
	_child = game_over_view_model

	game_over_view_model.connect("restart_game", Callable(self, "_on_restart_game"))
	game_over_view_model.set_score(score)

func _on_restart_game() -> void:
	_on_start_game()
