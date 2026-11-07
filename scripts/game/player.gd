class_name Player
extends Node2D
## 보라 슬라임 (1단계). 입력 방향으로 움직이고, 가까운 적에게 점액탄을 자동으로 쏜다.

signal hp_changed(hp: int)
signal died

var arena: Arena
## 이동 방향 (길이 0~1). 매 프레임 stage가 넣어 준다.
var move_input := Vector2.ZERO
var hp := Balance.PLAYER_HP
var dead := false
var _invuln := 0.0
var _attack_cd := 0.0
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = Art.sprite("slime")
	add_child(_sprite)
	add_child(Art.light(Color(0.75, 0.25, 1.0), 240.0, 1.1))


func _process(delta: float) -> void:
	if dead:
		return
	_invuln = maxf(0.0, _invuln - delta)
	# 맞은 직후 깜빡임
	_sprite.visible = _invuln <= 0.0 or int(_invuln * 14.0) % 2 == 0
	position = arena.clamp_inside(position + move_input * Balance.PLAYER_SPEED * delta, Balance.PLAYER_RADIUS)
	if move_input.x != 0.0:
		_sprite.flip_h = move_input.x < 0.0
	_attack_cd -= delta
	if _attack_cd <= 0.0:
		_fire()


func _fire() -> void:
	var points: Array = get_tree().get_nodes_in_group("enemies").map(func(e: Node2D): return e.position)
	var target: Variant = Targeting.nearest(position, points, Balance.ATTACK_RANGE)
	if target == null:
		return
	_attack_cd = Balance.ATTACK_INTERVAL
	var g := Glob.new()
	g.arena = arena
	g.position = position
	g.direction = (target - position).normalized()
	get_parent().add_child(g)


## 피해를 받는다. 무적 시간 중이면 무시.
func hit(amount: int) -> void:
	if dead or _invuln > 0.0:
		return
	hp = maxi(0, hp - amount)
	_invuln = Balance.PLAYER_INVULN
	hp_changed.emit(hp)
	if hp == 0:
		dead = true
		_sprite.visible = true
		_sprite.modulate = Color(1, 1, 1, 0.4)
		died.emit()
