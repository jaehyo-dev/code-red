class_name Sparkle
extends Node2D
## 뱉어낸 대상 위에서 잠깐 반짝이는 별 몇 개 (도트 3픽셀 격자). 시간이 지나면 스스로 사라진다.

var _t := 0.0
const STARS := [Vector2(-18, -30), Vector2(10, -42), Vector2(24, -24)]


func _process(delta: float) -> void:
	_t += delta
	if _t >= Balance.SPARKLE_TIME:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := _t / Balance.SPARKLE_TIME
	var col := Color(1.0, 0.9, 0.3, 1.0 - k * k)
	for i in STARS.size():
		# 별마다 시간차를 두고 커졌다 작아지는 모양: 큰 별은 + (3픽셀 칸 5개), 작은 별은 칸 1개
		var phase := sin((k * 1.4 - i * 0.15) * PI)
		if phase <= 0.0:
			continue
		var c: Vector2 = (STARS[i] + Vector2(0, -k * 12.0)).snappedf(3.0)
		var cells := [Vector2.ZERO] if phase < 0.5 else [Vector2.ZERO, Vector2(3, 0), Vector2(-3, 0), Vector2(0, 3), Vector2(0, -3)]
		for cell: Vector2 in cells:
			draw_rect(Rect2(c + cell, Vector2(3, 3)), col)
