extends AnimatedSprite2D

signal shot
signal screen_visible

@export var speed := Enums.speed_level.Normal
@export var dragoon_type: Enums.dragoon_type = Enums.dragoon_type.Egg
@export var distance_level: Enums.distance_level = Enums.distance_level.Close
@export var flightless_bird := false
@export var bird_skins: Array[Resource]

# ToDo: add image/sprite animation list to pick from depending on dragoon type

var _map_border_left := -INF
var _map_border_right := INF
var _lane_y := 0.0
var _goes_left := true

# Shooting
var head_clicked := false
var body_clicked := false
var resolve_timer: Timer
var value: int = 0

# visuals
var _skin: BirdSkin

func _ready() -> void:
    _debounce_hits()

func _debounce_hits() -> void:
    resolve_timer = Timer.new()
    resolve_timer.wait_time = 0.001 # 1ms
    resolve_timer.one_shot = true
    resolve_timer.connect("timeout", Callable(self, "_on_resolve_timeout"))
    add_child(resolve_timer)

func try_construct(type: Enums.dragoon_type, distance: Enums.distance_level, bird_speed: Enums.speed_level) -> bool:
    value = (distance + type) * bird_speed / 100
    _apply_skin_for(type)
    if _skin == null:
        push_error("No skin found for dragoon type: ", type)
        return false
    return true

func set_limits(left_x: float, right_x: float, lane_y: float, goes_left: bool) -> void:
    _map_border_left = left_x
    _map_border_right = right_x
    _lane_y = lane_y
    _goes_left = goes_left
    global_position.y = _lane_y

func _move(delta: float, goes_left: bool) -> void:
    if flightless_bird:
        pass # walk -> only distances allowed near, mid and far for 3 ground lanes
    else:
        pass # fly -> all distances allowed for 4 fly lanes


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
    
# visuals
func _find_skin(e: Enums.dragoon_type) -> BirdSkin:
    for skin in bird_skins:
        if skin.type == e:
            return skin
    print("No skin found for dragoon type: ", e)
    return null

func _apply_skin_for(e: Enums.dragoon_type) -> void:
    _skin = _find_skin(e) as BirdSkin
    if _skin == null:
        push_error("No skin found for dragoon type: ", e)
        return
    
    self.frames = _skin.frames
    self.flightless_bird = _skin.is_flightless
    self.scale = _skin.scale
    self.animation = "default"
