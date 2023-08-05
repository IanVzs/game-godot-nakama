class_name VirButton

extends Control

# https://github.com/MarcoFazioRandom/Virtual-Joystick-Godot

#### EXPORTED VARIABLE ####

# The color of the button when the joystick is in use.
export(Color) var pressed_color := Color.gray

# If the input is inside this range, the output is zero.
export(float, 0, 200, 1) var deadzone_size : float = 10

# The max distance the tip can reach.
export(float, 0, 500, 1) var clampzone_size : float = 75

# FIXED: The joystick doesn't move.
# DYNAMIC: Every time the joystick area is pressed, the joystick position is set on the touched position.
enum JoystickMode {FIXED, }

export(JoystickMode) var joystick_mode := JoystickMode.FIXED

# VISIBILITY_ALWAYS = Always visible.
# VISIBILITY_TOUCHSCREEN_ONLY = Visible on touch screens only.
enum VisibilityMode {ALWAYS , TOUCHSCREEN_ONLY }

export(VisibilityMode) var visibility_mode := VisibilityMode.ALWAYS

# Use Input Actions
export var use_input_actions := true

# Project -> Project Settings -> Input Map
export var action_jump := "jump"

#### PUBLIC VARIABLES ####

# If the joystick is receiving inputs.
var _pressed := false setget , is_pressed

func is_pressed() -> bool:
	return _pressed

# The joystick output.
var _output := Vector2.ZERO setget , get_output

func get_output() -> Vector2:
	return _output

#### PRIVATE VARIABLES ####

var _touch_index : int = -1

onready var _base := $Base
onready var _tip := $Base/Tip

onready var _base_radius = _base.rect_size * _base.get_global_transform_with_canvas().get_scale() / 2

onready var _base_default_position : Vector2 = _base.rect_position
onready var _tip_default_position : Vector2 = _tip.rect_position

onready var _default_color : Color = _tip.modulate

#### FUNCTIONS ####

func _ready() -> void:
	if not OS.has_touchscreen_ui_hint() and visibility_mode == VisibilityMode.TOUCHSCREEN_ONLY:
		hide()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _is_point_inside_joystick_area(event.position) and _touch_index == -1:
				if (joystick_mode == JoystickMode.FIXED and _is_point_inside_base(event.position)):
					_touch_index = event.index
					_update_button()
					get_tree().set_input_as_handled()
		elif event.index == _touch_index:
			_reset()
			get_tree().set_input_as_handled()
	elif event is InputEventScreenDrag:
		pass

func _move_base(new_position: Vector2) -> void:
	_base.rect_global_position = new_position - _base.rect_pivot_offset * get_global_transform_with_canvas().get_scale()

func _is_point_inside_joystick_area(point: Vector2) -> bool:
	var in_x: bool = point.x >= rect_global_position.x and point.x <= rect_global_position.x + (rect_size.x * get_global_transform_with_canvas().get_scale().x)
	var in_y: bool = point.y >= rect_global_position.y and point.y <= rect_global_position.y + (rect_size.y * get_global_transform_with_canvas().get_scale().y)
	print_debug("是否在Button内-x,y: ", in_x, ",", in_y)
	return in_x and in_y

func _is_point_inside_base(point: Vector2) -> bool:
	var center : Vector2 = _base.rect_global_position + _base_radius
	var vector : Vector2 = point - center
	if vector.length_squared() <= _base_radius.x * _base_radius.x:
		print_debug("_is_point_inside_base True")
		return true
	else:
		return false

func _update_button() -> void:
	_tip.modulate = pressed_color
	_base.modulate = pressed_color
	print_debug("更新按钮 use_input_actions:", use_input_actions)
	if use_input_actions:
		_update_input_actions()

func _update_input_actions():
	print_debug("in _update_input_actions")
	Input.action_press(action_jump)

func _reset():
	_pressed = false
	_output = Vector2.ZERO
	_touch_index = -1
	_tip.modulate = _default_color
	_base.rect_position = _base_default_position
	_tip.rect_position = _tip_default_position
	if use_input_actions:
		if Input.is_action_pressed(action_jump) or Input.is_action_just_pressed(action_jump):
			Input.action_release(action_jump)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
