extends Node2D


@export var background: NodePath
@export var spawn_padding := 100.0

@export var egg_bird_scene: PackedScene
@export var neck_bird_scene: PackedScene
@export var ball_bird_scene: PackedScene
@export var chonky_bird_scene: PackedScene


func _ready() -> void:
    # Initialize bird spawners or any other setup needed
    randomize()
    spaw_bird(Enums.dragoon_type.Egg, Enums.distance_level.close, Enums.speed_level.Normal)

# get a reference to background texture 
# -> size determines spawn zones

# birds spawn outside the map and walk, fly in
# special birds spawn in deterministic locations on the map with unique spawn logic

func _scene_for_type(dragoon_t: Enums.dragoon_type) -> PackedScene:
    match dragoon_t:
        Enums.dragoon_type.Egg:
            return egg_bird_scene
        Enums.dragoon_type.Neck:
            return neck_bird_scene
        Enums.dragoon_type.Ball:
            return ball_bird_scene
        Enums.dragoon_type.Chonky:
            return chonky_bird_scene
        _:
            push_error("Unknown dragoon type: %s" % dragoon_t)
            return null


func spaw_bird(dragoon_t, distance_t, speed_t) -> Node2D:
    var scene := _scene_for_type(dragoon_t)

    if !scene:
        return null

    var bird := scene.instantiate() as Node2D
    add_child(bird)

    var spawn_left := randi() % 2 == 0
    var dir := -1 if spawn_left else 1

    bird.global_position.x = -500 if spawn_left else 500
    bird.global_position.y = 700 # Adjust this based on your game design
    bird.setup(-500, 500, 700, dir)
    return bird
