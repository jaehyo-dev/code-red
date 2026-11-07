class_name Player
extends Node2D
## 보라 슬라임 (1단계). 입력 방향으로 움직이고, 가까운 적이 있으면 촉수를 휘둘러 공격한다.
## 총알은 없다: 원거리 공격은 삼킨 아이템에서만 나온다 (v0.3.0).

signal hp_changed(hp: int)
signal died

var arena: Arena
## 이동 방향 (길이 0~1). 매 프레임 stage가 넣어 준다.
var move_input := Vector2.ZERO
var hp := Balance.PLAYER_HP
var dead := false
var _invuln := 0.0
var _flash := 0.0
var _aim := 0.0  # 공격 방향 (라디안)
var _attack := AttackCycle.new()
var _motion := SlimeMotion.new()
var _body: Node2D  # 발 기준으로 늘어나고 줄어드는 몸
var _sprite: Sprite2D
var _tentacle: Sprite2D


func _ready() -> void:
	# 촉수가 몸 뒤에서 뻗어 나오도록 먼저 추가
	_tentacle = Art.sprite("tentacle")
	_tentacle.centered = false
	_tentacle.offset = Vector2(0, -_tentacle.texture.get_height() / 2.0)
	_tentacle.visible = false
	add_child(_tentacle)
	_sprite = Art.sprite("slime")
	var half_h := _sprite.texture.get_height() / 2.0
	_sprite.position = Vector2(0, -half_h)
	_body = Node2D.new()
	_body.position = Vector2(0, half_h)  # 발이 노드 위치 아래에 오도록 (중심은 그대로)
	_body.add_child(_sprite)
	add_child(_body)
	add_child(Art.light(Color(0.75, 0.25, 1.0), 240.0, 1.1))


func _process(delta: float) -> void:
	if dead:
		return
	_invuln = maxf(0.0, _invuln - delta)
	_flash = maxf(0.0, _flash - delta)
	# 피격: 번쩍임, 이후 무적 시간 동안 반투명 깜빡임
	if _flash > 0.0:
		_body.modulate = Color(2.5, 2.5, 2.5)
	else:
		_body.modulate = Color(1, 1, 1, 0.5 if _invuln > 0.0 and int(_invuln * 14.0) % 2 == 1 else 1.0)
	position = arena.clamp_inside(position + move_input * Balance.PLAYER_SPEED * delta, Balance.PLAYER_RADIUS)
	if move_input.x != 0.0:
		_sprite.flip_h = move_input.x < 0.0
	_update_attack(delta)
	_body.scale = _motion.update(delta, move_input, _attack.phase, _attack.progress())


func _update_attack(delta: float) -> void:
	var points: Array = get_tree().get_nodes_in_group("enemies").map(func(e: Node2D): return e.position)
	var target: Variant = Targeting.nearest(position, points, Balance.MELEE_RANGE)
	# 준비 중에는 가장 가까운 적을 따라 조준하고, 타격이 시작되면 방향을 고정한다
	if target != null and _attack.phase in [AttackCycle.Phase.IDLE, AttackCycle.Phase.WINDUP]:
		_aim = (target - position).angle()
		_sprite.flip_h = cos(_aim) < 0.0
	if _attack.update(delta, target != null):
		_strike()
	_pose_tentacle()


## 타격 순간: 부채꼴 안의 모든 적에게 피해
func _strike() -> void:
	var dir := Vector2.from_angle(_aim)
	for e: Enemy in get_tree().get_nodes_in_group("enemies"):
		if Targeting.in_cone(position, dir, e.position, Balance.MELEE_REACH + Balance.ENEMY_RADIUS, deg_to_rad(Balance.MELEE_HALF_ARC_DEG)):
			e.take_damage(Balance.MELEE_DAMAGE, dir)


## 촉수 모양: 준비 때 몸 옆에서 살짝 말려 나오고, 타격 때 부채꼴을 쓸며 뻗고, 복귀 때 움츠러든다
func _pose_tentacle() -> void:
	var arc := deg_to_rad(Balance.MELEE_HALF_ARC_DEG)
	var p := _attack.progress()
	match _attack.phase:
		AttackCycle.Phase.WINDUP:
			_tentacle.rotation = _aim - arc
			_tentacle.scale = Vector2(0.15 + 0.25 * p, 1.0)
		AttackCycle.Phase.STRIKE:
			_tentacle.rotation = _aim + lerpf(-arc, arc, p)
			_tentacle.scale = Vector2(lerpf(0.4, 1.0, p), 1.0)
		AttackCycle.Phase.RECOVER:
			_tentacle.rotation = _aim + arc
			_tentacle.scale = Vector2(1.0 - p, 1.0)
	_tentacle.visible = _attack.phase != AttackCycle.Phase.IDLE


## 피해를 받는다. 무적 시간 중이면 무시.
func hit(amount: int) -> void:
	if dead or _invuln > 0.0:
		return
	hp = maxi(0, hp - amount)
	_invuln = Balance.PLAYER_INVULN
	_flash = Balance.PLAYER_FLASH
	_motion.hit_kick()
	hp_changed.emit(hp)
	if hp == 0:
		dead = true
		_tentacle.visible = false
		_body.modulate = Color(1, 1, 1, 0.4)
		died.emit()
