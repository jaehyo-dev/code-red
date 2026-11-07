class_name Swallow
extends RefCounted
## "삼키는 연출"의 계산 (화면과 분리). 몸 안에 비친 대상이 줄어들고 꿀럭거리다 소화되어 사라지는 흐름.
## 슬라임 공격에 묶이지 않는다: 아이템·생명체 삼키기에서도 SwallowFx와 함께 그대로 쓴다.


## 몸 안에 들어간 정도 inside(0~1)에 따른 대상 크기 배율 (1 → SWALLOW_INNER_SCALE)
static func inner_scale(inside: float) -> float:
	return lerpf(1.0, Balance.SWALLOW_INNER_SCALE, ease(clampf(inside, 0.0, 1.0), 0.4))


## 소화 정도 digest(0~1)에 따른 크기 배율 (1 → 0, 끝에서 정확히 0)
static func digest_scale(digest: float) -> float:
	return pow(1.0 - clampf(digest, 0.0, 1.0), 1.5)


## 몸이 꿀럭거리는 정도 (-WOBBLE ~ +WOBBLE)
static func wobble(time: float) -> float:
	return sin(time * Balance.SWALLOW_WOBBLE_SPEED) * Balance.SWALLOW_WOBBLE


## 비치는 투명도: 소화될수록 옅어진다
static func alpha(digest: float) -> float:
	return Balance.SWALLOW_ALPHA * (1.0 - 0.5 * clampf(digest, 0.0, 1.0))
