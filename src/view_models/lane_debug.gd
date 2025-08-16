extends Node2D

# You can toggle in editor or via code
@export var enabled := true
@export var color: Color = Color.DARK_RED
@export var thickness: float = 2.0
@export var width: float = 2000.0 # how far to draw horizontally

func _draw() -> void:
	if not enabled: return

	# ground lanes
	for y in [
		Enums.ground_levels.ForeGround,
		Enums.ground_levels.MidGround,
		Enums.ground_levels.BackGround,
		Enums.fly_zone_lane.Hover,
		Enums.fly_zone_lane.Jump,
		Enums.fly_zone_lane.HighRise,
		Enums.fly_zone_lane.Fly
	]:
		draw_line(Vector2(-width / 2, y), Vector2(width / 2, y), color, thickness)
