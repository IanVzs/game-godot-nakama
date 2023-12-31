# Extended character that is controlled by the user and does not respond to
# server events. Intead, it sends some of its own to notify the server of certain
# inputs.
class_name Player
extends Character

var input_locked := false
var accel := Vector2.ZERO
var last_direction := Vector2.ZERO

var is_active := true setget set_is_active

onready var timer: Timer = $Timer
onready var camera_2d: Camera2D = $Camera2D


func _ready() -> void:
	#warning-ignore: return_value_discarded
	timer.connect("timeout", self, "_on_Timer_timeout")
	hide()


func _physics_process(_delta: float) -> void:
	direction = _get_direction()
	if Input.is_action_just_pressed("jump"):
		print_debug("跳! 跳高高！")
		deal_jump()

func deal_jump() -> void:
	print_debug("跳!")
	if state == States.ON_GROUND:
		jump()

func _unhandled_input(event: InputEvent) -> void:
	# 这个函数只会捕获UI、或者说HUD不要的事件。很容易被人抢走。所以在触屏设备中,
	# 使用HUD来做虚拟摇杆和按键时就接收不到动作了...就很尴尬
	# 所以暂时不用啦,等以后需要时再使用
	if event.is_action_pressed("jump") and state == States.ON_GROUND:
		# jump()
		print_debug("jump event catched")

func setup(username: String, color: Color, position: Vector2, level_limits: Rect2) -> void:
	self.username = username
	self.color = color
	global_position = position
	spawn()
	camera_2d.set_limits(level_limits)
	set_process(true)
	show()


func spawn() -> void:
	set_process_unhandled_input(false)
	.spawn()
	yield(self, "spawned")
	set_process_unhandled_input(true)


func jump() -> void:
	.jump()
	ServerConnection.send_jump()


func set_is_active(value: bool) -> void:
	is_active = value
	set_process(value)
	set_process_unhandled_input(value)
	timer.paused = not value


func _get_direction() -> Vector2:
	if not is_processing_unhandled_input():
		return Vector2.ZERO

	var new_direction := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"), 0
	)
	if new_direction != last_direction:
		ServerConnection.send_direction_update(new_direction.x)
		last_direction = new_direction
	return new_direction


func _on_Timer_timeout() -> void:
	ServerConnection.send_position_update(global_position)


func _on_GameUI_chat_edit_started() -> void:
	self.is_active = false


func _on_GameUI_chat_edit_ended() -> void:
	self.is_active = true


func _on_GameUI_color_changed(new_color: Color) -> void:
	self.color = new_color
	self.is_active = true
