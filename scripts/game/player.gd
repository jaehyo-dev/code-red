class_name Player
extends Node2D
## 보라 슬라임 (1단계). 입력 방향으로 움직이고, 가까운 적이 있으면 몸을 늘여 덮쳐 공격한다.
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
var _face := SlimeFace.new()
var _has_target := false
var _peak := Vector2(1.0, 0.0)  # 이번 덮치기의 최대 (늘어남 배율, 밀림 도트)
var _stop := 0.0  # 히트스톱 남은 시간
var _eff_move := Vector2.ZERO  # 공격 중 느려진 이동 입력
# 슬라임은 SubViewport에 도트 크기로 그린 뒤 3배로 키워 보여 준다:
# 늘이고 기울여도 도트가 항상 3x3 픽셀 격자로 보이게 하기 위해서다.
var _view: SubViewport
var _image: Sprite2D  # 뷰포트 그림을 화면에 보여 주는 스프라이트
var _rig: Node2D  # 몸 전체 변형(늘어남·기울기·덮치기)이 걸리는 노드
var _crest: Node2D  # 머리 위 곡선 (밑동을 기준으로 끌림)
var _face_node: Node2D  # 눈·입 (몸 위에서 쏠림)
var _eyes: Sprite2D

const VIEW_DOTS := 128  # 뷰포트 한 변 (도트). 늘어난 몸이 들어갈 만큼 크게
const SCALE := 3  # 도트 1칸 = 화면 3픽셀
const EYES := preload("res://assets/sprites/slime_eyes.png")
const EYES_SMALL := preload("res://assets/sprites/slime_eyes_small.png")
const CREST_ROWS := 8  # make_sprites.py의 CREST_ROWS와 같음


func _ready() -> void:
	_view = SubViewport.new()
	_view.size = Vector2i(VIEW_DOTS, VIEW_DOTS)
	_view.transparent_bg = true
	_view.disable_3d = true
	_view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(_view)
	_rig = Node2D.new()
	_view.add_child(_rig)
	var top_left := -Balance.SLIME_HALF  # 스프라이트 왼쪽 위 (몸 중심 기준)
	_rig.add_child(_layer("slime_body", top_left))
	_crest = Node2D.new()
	_crest.position = Vector2(0, top_left.y + CREST_ROWS)  # 곡선 밑동이 기울기 기준점
	_crest.add_child(_layer("slime_crest", top_left - _crest.position))
	_rig.add_child(_crest)
	_face_node = Node2D.new()
	_eyes = _layer("slime_eyes", top_left)
	_face_node.add_child(_eyes)
	_face_node.add_child(_layer("slime_mouth", top_left))
	_view.add_child(_face_node)  # 몸과 따로 둬서 몸이 늘어나도 얼굴은 안 찌그러지고 몸 중간에 보인다
	_image = Sprite2D.new()
	_image.texture = _view.get_texture()
	_image.scale = Vector2(SCALE, SCALE)
	_image.position = Vector2(0, -SCALE * 17)  # 발이 노드 위치에 오도록
	_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_image)
	add_child(Art.light(Color(0.75, 0.25, 1.0), 240.0, 1.1))


## 뷰포트 안의 스프라이트 한 장 (왼쪽 위 기준)
func _layer(sprite_name: String, pos: Vector2) -> Sprite2D:
	var s := Art.sprite(sprite_name)
	s.centered = false
	s.scale = Vector2.ONE / SCALE  # 3배 확대된 그림을 도트 크기로 되돌림
	s.position = pos
	return s


func _process(delta: float) -> void:
	if dead:
		return
	if _stop > 0.0:  # 히트스톱: 타격 순간 잠깐 멈춤
		_stop -= delta
		return
	_invuln = maxf(0.0, _invuln - delta)
	_flash = maxf(0.0, _flash - delta)
	# 피격: 번쩍임, 이후 무적 시간 동안 반투명 깜빡임
	if _flash > 0.0:
		_image.modulate = Color(2.5, 2.5, 2.5)
	else:
		_image.modulate = Color(1, 1, 1, 0.5 if _invuln > 0.0 and int(_invuln * 14.0) % 2 == 1 else 1.0)
	# 공격 중에는 느리게 움직여서 덮칠 방향이 흐트러지지 않게 한다
	_eff_move = move_input * (1.0 if _attack.phase == AttackCycle.Phase.IDLE else Balance.ATTACK_MOVE_MULT)
	position = arena.clamp_inside(position + _eff_move * Balance.PLAYER_SPEED * delta, Balance.PLAYER_RADIUS)
	_update_attack(delta)
	_pose_body(delta)


## 몸 중심 (사거리·조준·타격 기준)
func _center() -> Vector2:
	return position + Vector2(0, -Balance.BODY_CENTER_Y)


func _update_attack(delta: float) -> void:
	var points: Array = get_tree().get_nodes_in_group("enemies").map(func(e: Node2D): return e.position)
	var target: Variant = Targeting.nearest(_center(), points, Balance.MELEE_RANGE)
	_has_target = target != null
	# 준비 중에는 가장 가까운 적을 따라 조준하고, 타격이 시작되면 방향을 고정한다
	if target != null and _attack.phase in [AttackCycle.Phase.IDLE, AttackCycle.Phase.WINDUP]:
		_aim = (target - _center()).angle()
		_peak = LungePose.peak_for(Vector2.from_angle(_aim))
	if _attack.update(delta, target != null):
		_strike()


## 타격 순간: 덮치는 방향 부채꼴 안의 모든 적에게 피해
func _strike() -> void:
	var dir := Vector2.from_angle(_aim)
	for e: Enemy in get_tree().get_nodes_in_group("enemies"):
		if Targeting.in_cone(_center(), dir, e.position, Balance.MELEE_REACH + Balance.ENEMY_RADIUS, deg_to_rad(Balance.MELEE_HALF_ARC_DEG)):
			e.take_damage(Balance.MELEE_DAMAGE, dir)
			_stop = Balance.HITSTOP


## 몸 모양: 이동 늘어남·기울기 → 이동 리듬 → 덮치기(늘어남+밀림) 순으로 겹쳐 적용하고, 얼굴·머리 곡선을 옮긴다
func _pose_body(delta: float) -> void:
	var sc := _motion.update(delta, _eff_move)
	var feet := Vector2(0, Balance.SLIME_HALF.y - 1.0)  # 발 기준으로 늘어나고 줄어든다
	# 몸통 비틀기: 바라보는 쪽으로 위쪽이 기울고 몸이 살짝 쏠려서 정지해도 방향이 보인다
	var look := _face.look
	var t := Transform2D(Vector2(sc.x, 0), Vector2(-(_motion.lean() + look.x * Balance.TWIST_SHEAR) * sc.y, sc.y * (1.0 - look.y * Balance.TWIST_VERT)), Vector2.ZERO)
	t.origin = feet - t.basis_xform(feet) + Vector2(look.x * Balance.TWIST_SHIFT, 0)
	var body := _motion.gait_transform() * t
	if _attack.phase != AttackCycle.Phase.IDLE:
		var p := LungePose.pose(_attack.phase, _attack.progress(), _peak)
		body = LungePose.transform(Vector2.from_angle(_aim), p.x, p.y) * body
	var center := Transform2D(0.0, Vector2(VIEW_DOTS, VIEW_DOTS) / 2.0)
	_rig.transform = center * body
	_crest.transform = Transform2D(Vector2.RIGHT, Vector2(-_motion.crest_shear(), 1.0), _crest.position)
	# 얼굴: 공격 중이면 대상 쪽, 아니면 이동 방향을 본다 (공격은 얼굴이 먼저 돌아간 뒤 덮친다)
	var target_look := Vector2.ZERO
	if _attack.phase != AttackCycle.Phase.IDLE or _has_target:
		target_look = Vector2.from_angle(_aim)
	elif move_input.length() > 0.15:
		target_look = move_input.normalized()
	_face.update(delta, target_look)
	# 얼굴은 늘어난 몸의 중간으로 옮기되 모양은 이동 모션만 받는다 (도트 격자에 맞춰 반올림)
	var mid := (body * Vector2.ZERO).round()
	_face_node.transform = center * Transform2D(t.x, t.y, mid + Vector2(_face.offset()))
	_eyes.texture = EYES_SMALL if _face.small_eyes() else EYES


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
		_image.modulate = Color(1, 1, 1, 0.4)
		died.emit()
