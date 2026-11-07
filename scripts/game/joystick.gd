class_name Joystick
extends Control
## 떠 있는 가상 조이스틱: 화면 아무 곳이나 누르면 그 자리가 중심이 되고, 끌면 방향이 정해진다.

var active := false
## 현재 방향 (길이 0~1)
var vector := Vector2.ZERO
var _origin := Vector2.ZERO
var _pos := Vector2.ZERO
var _finger := -1


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _finger == -1:
			_finger = event.index
			_origin = event.position
			_pos = event.position
			active = true
		elif not event.pressed and event.index == _finger:
			_finger = -1
			active = false
			vector = Vector2.ZERO
	elif event is InputEventScreenDrag and event.index == _finger:
		_pos = event.position
	else:
		return
	vector = JoystickMath.vector(_origin, _pos, Balance.JOYSTICK_RADIUS, Balance.JOYSTICK_DEADZONE) if active else Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	if not active:
		return
	draw_circle(_origin, Balance.JOYSTICK_RADIUS, Color(1, 1, 1, 0.12))
	draw_arc(_origin, Balance.JOYSTICK_RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 3.0)
	draw_circle(_origin + vector * Balance.JOYSTICK_RADIUS, 34.0, Color(0.75, 0.3, 1.0, 0.7))
