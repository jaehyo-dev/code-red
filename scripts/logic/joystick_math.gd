class_name JoystickMath
extends RefCounted
## 가상 조이스틱 계산 (화면과 분리). 시작점에서 현재 손가락 위치까지의 방향·세기를 구한다.


## 반환: 방향 벡터, 길이 0~1. 데드존 안쪽이면 0, 반지름 밖이면 길이 1로 자른다.
static func vector(origin: Vector2, pos: Vector2, radius: float, deadzone: float) -> Vector2:
	var raw := (pos - origin) / radius
	var length := raw.length()
	if length < deadzone:
		return Vector2.ZERO
	return raw.normalized() * minf(length, 1.0)
