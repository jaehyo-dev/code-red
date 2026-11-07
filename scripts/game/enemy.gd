class_name Enemy
extends Node2D
## 적 1종: 동굴 딱정벌레. 슬라임을 향해 곧장 걸어와 닿으면 피해를 준다.
## shortcut: 적끼리 겹침을 풀지 않음, 적이 늘어나는 v0.2.0 웨이브 때 분리 이동 추가.

signal died

var target: Player
var hp := Balance.ENEMY_HP


func _ready() -> void:
	add_to_group("enemies")
	add_child(Art.sprite("enemy"))
	# 어두운 바닥에서도 구분되도록 주황빛 작은 조명 (스프라이트에도 밝은 외곽선이 있음)
	add_child(Art.light(Color(1.0, 0.55, 0.3), 110.0, 0.7))


func _process(delta: float) -> void:
	if target == null or target.dead:
		return
	var to_target := target.position - position
	position += to_target.normalized() * Balance.ENEMY_SPEED * delta
	if to_target.length() <= Balance.ENEMY_RADIUS + Balance.PLAYER_RADIUS:
		target.hit(Balance.ENEMY_DAMAGE)


func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		died.emit()
		queue_free()
