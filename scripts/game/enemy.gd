class_name Enemy
extends Node2D
## 적 1종: 동굴 딱정벌레. 슬라임을 향해 곧장 걸어와 닿으면 피해를 준다.
## shortcut: 적끼리 겹침을 풀지 않음, 적이 늘어나는 v0.2.0 웨이브 때 분리 이동 추가.

signal died

var target: Player
var hp := Balance.ENEMY_HP
var _sprite: Sprite2D
var _flash := 0.0
## 삼켜져서 몸 안에 있는 동안 true: 움직이지도 공격하지도 않고 보이지도 않는다 (몸 안의 모습은 SwallowFx가 그린다)
var swallowed := false


func _ready() -> void:
	add_to_group("enemies")
	_sprite = Art.sprite("enemy")
	add_child(_sprite)
	# 어두운 바닥에서도 구분되도록 주황빛 작은 조명 (스프라이트에도 밝은 외곽선이 있음)
	add_child(Art.light(Color(1.0, 0.55, 0.3), 110.0, 0.7))


func _process(delta: float) -> void:
	if swallowed:
		return
	_flash = maxf(0.0, _flash - delta)
	_sprite.modulate = Color(2.5, 2.5, 2.5) if _flash > 0.0 else Color.WHITE
	if target == null or target.dead:
		return
	var to_target := target.position - position
	position += to_target.normalized() * Balance.ENEMY_SPEED * delta
	if to_target.length() <= Balance.ENEMY_RADIUS + Balance.PLAYER_RADIUS:
		target.hit(Balance.ENEMY_DAMAGE)


## 삼킨 몸 안에 비출 그림
func texture() -> Texture2D:
	return _sprite.texture


## 삼켜진다: 멈추고 숨는다
func swallow() -> void:
	swallowed = true
	visible = false


## 피해를 입히고 죽었는지 돌려준다. 죽으면 바로 사라진다 (삼킨 쪽 SwallowFx가 소화 연출을 그린다)
func bite(amount: int) -> bool:
	hp -= amount
	if hp > 0:
		return false
	remove_from_group("enemies")  # 소화되는 동안 다시 노려지지 않게
	died.emit()
	queue_free()
	return true


## 살아서 뱉어진다: from_dir 방향으로 날아가며 별이 반짝인다
func release(from_dir: Vector2) -> void:
	swallowed = false
	visible = true
	position += from_dir * Balance.MELEE_KNOCKBACK
	_flash = Balance.HIT_FLASH
	add_child(Sparkle.new())
