class_name SlimeFace
extends RefCounted
## 슬라임 얼굴(눈·입 레이어)이 바라보는 방향 계산 (화면과 분리). 방향별 그림 없이 위치와 눈 크기로 표현한다.

## 바라보는 방향 (길이 0~1, 0이면 정면)
var look := Vector2.ZERO


## target: 보고 싶은 방향(길이 1). ZERO면 마지막으로 보던 쪽을 유지한다.
func update(delta: float, target: Vector2) -> void:
	if target != Vector2.ZERO:
		look = look.lerp(target, 1.0 - exp(-Balance.FACE_FOLLOW * delta))


## 얼굴이 몸 위에서 쏠리는 도트 (위를 볼수록 많이 올라가고, 아래는 조금만 내려가 정면을 보임)
func offset() -> Vector2i:
	var up := look.y < 0.0
	return Vector2i(roundi(look.x * Balance.FACE_SHIFT.x), roundi(look.y * (Balance.FACE_RISE if up else Balance.FACE_SHIFT.y)))


## 위를 볼 때는 눈이 작아진다
func small_eyes() -> bool:
	return look.y < Balance.FACE_SMALL_EYES_LOOK
