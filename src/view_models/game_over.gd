extends Control

signal restart_game


func _on_retry_button_texture_pressed() -> void:
	restart_game.emit()

func _set_score(score: int) -> void:
	print("Game Over! Your score: ", score)