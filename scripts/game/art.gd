class_name Art
extends RefCounted
## 스프라이트와 조명 노드를 만드는 도우미.

static var _light_tex: GradientTexture2D


## assets/sprites/<name>.png 를 가운데 기준으로 놓은 Sprite2D
static func sprite(sprite_name: String) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load("res://assets/sprites/%s.png" % sprite_name)
	return s


## 오브젝트용: 발(아래 가운데)이 노드 위치에 오는 스프라이트 (Y 정렬이 발 기준이 되도록)
static func sprite_feet(sprite_name: String) -> Sprite2D:
	var s := sprite(sprite_name)
	s.position = Vector2(0, -s.texture.get_height() / 2.0)
	return s


## 둥근 PointLight2D. radius는 빛이 닿는 반지름(픽셀)
static func light(color: Color, radius: float, energy := 1.0) -> PointLight2D:
	if _light_tex == null:
		_light_tex = GradientTexture2D.new()
		_light_tex.width = 256
		_light_tex.height = 256
		_light_tex.fill = GradientTexture2D.FILL_RADIAL
		_light_tex.fill_from = Vector2(0.5, 0.5)
		_light_tex.fill_to = Vector2(1.0, 0.5)
		var g := Gradient.new()
		g.set_color(0, Color.WHITE)
		g.set_color(1, Color.BLACK)
		_light_tex.gradient = g
	var l := PointLight2D.new()
	l.texture = _light_tex
	l.texture_scale = radius / 128.0
	l.color = color
	l.energy = energy
	return l
