class_name Glob
extends Node2D
## 슬라임이 쏘는 점액탄. 적에게 닿거나 벽에 닿거나 시간이 다 되면 사라진다.

var direction := Vector2.RIGHT
var arena: Arena
var _life := Balance.GLOB_LIFETIME


func _ready() -> void:
	add_child(Art.sprite("glob"))
	add_child(Art.light(Color(0.8, 0.3, 1.0), 90.0, 0.8))


func _process(delta: float) -> void:
	position += direction * Balance.GLOB_SPEED * delta
	_life -= delta
	if _life <= 0.0 or not arena.floor_rect().has_point(position):
		queue_free()
		return
	for e: Enemy in get_tree().get_nodes_in_group("enemies"):
		if position.distance_to(e.position) <= Balance.GLOB_RADIUS + Balance.ENEMY_RADIUS:
			e.take_damage(Balance.GLOB_DAMAGE)
			queue_free()
			return
