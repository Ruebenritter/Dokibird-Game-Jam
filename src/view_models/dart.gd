extends PanelContainer

class_name Dart

var _blink_timer: Timer
var _blinking := false

func _ready() -> void:
    _blink_timer = Timer.new()
    _blink_timer.wait_time = 0.2
    _blink_timer.one_shot = false
    _blink_timer.autostart = false

    _blink_timer.connect("timeout", Callable(self, "_on_blink_timer_timeout"))

    add_child(_blink_timer)

func _on_blink_timer_timeout() -> void:
    visible = not visible

func blink():
    if _blinking:
        return
    _blinking = true
    _blink_timer.start()

func stop_blinking():
    if not _blinking:
        return
    _blinking = false
    _blink_timer.stop()
    visible = true