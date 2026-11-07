class_name SwallowFx
extends Node2D
## 삼키는 연출 부품: 대상 그림을 몸 안에 반투명하게 비춰 주고, 줄이고, 꿀럭거리게 하고, 소화시켜 없앤다.
## 슬라임 공격 코드를 모른다. 몸 노드 안에 자식으로 넣고 setup() → 매 프레임 tick()만 부르면 된다.
## 예) 아이템 삼키기·생명체 삼키기에서 재사용 (v0.3.0, v0.5.0).

## 몸 안에 들어간 정도 0~1 (크기가 줄어듦)
var inside := 0.0
## 소화 정도 0~1 (1이면 사라짐)
var digest := 0.0
var _sprite: Sprite2D
var _base_scale := 1.0
var _time := 0.0
var _flash := 0.0


## texture: 비출 대상 그림, base_scale: 이 노드가 놓인 좌표계에서 그림 1픽셀의 크기 (도트 크기 뷰포트면 1/3)
func setup(texture: Texture2D, base_scale := 1.0) -> void:
	_base_scale = base_scale
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	tick(0.0)


## 피해 순간 하얗게 번쩍
func flash() -> void:
	_flash = Balance.HIT_FLASH


func tick(delta: float) -> void:
	_time += delta
	_flash = maxf(0.0, _flash - delta)
	var w := Swallow.wobble(_time)
	var s := Swallow.inner_scale(inside) * Swallow.digest_scale(digest) * _base_scale
	_sprite.scale = Vector2(s * (1.0 - w), s * (1.0 + w))  # 몸이 꿀럭이는 만큼 반대로 출렁
	var a := Swallow.alpha(digest)
	_sprite.modulate = Color(2.5, 2.5, 2.5, 1.0) if _flash > 0.0 else Color(Balance.SWALLOW_TINT, a)
