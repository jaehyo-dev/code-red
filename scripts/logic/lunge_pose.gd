class_name LungePose
extends RefCounted
## 덮치기 모양 계산 (화면과 분리). 몸을 덮칠 방향으로 늘이되 뒤쪽 끝은 고정하고, 늘어난 만큼 옆은 가늘어진다.
## 좌표는 슬라임 몸 중심 기준 도트 단위.


## dir 방향으로 몸 중심에서 몸 가장자리까지의 거리 (타원 근사)
static func body_radius(dir: Vector2) -> float:
	var h := Balance.SLIME_HALF
	return 1.0 / sqrt(pow(dir.x / h.x, 2) + pow(dir.y / h.y, 2))


## 앞쪽 끝이 LUNGE_TIP_DOTS에 닿도록 하는 최대 늘어남 배율 (뒤쪽 끝 고정이라 tip = r * (2k - 1))
static func peak_for(dir: Vector2) -> float:
	return clampf((Balance.LUNGE_TIP_DOTS / body_radius(dir) + 1.0) * 0.5, 1.2, Balance.LUNGE_MAX_STRETCH)


## 단계와 진행도(0~1)에 따른 덮칠 방향 길이 배율.
## 준비: 1 → 웅크림 / 타격: 웅크림 → peak (빠르게 쭉) / 복귀: peak → 눌림(1 미만) → 탄성으로 1
static func length(phase: int, progress: float, peak: float) -> float:
	match phase:
		AttackCycle.Phase.WINDUP:
			return lerpf(1.0, Balance.CROUCH_LENGTH, ease(progress, 0.4))
		AttackCycle.Phase.STRIKE:
			return lerpf(Balance.CROUCH_LENGTH, peak, ease(progress, 0.35))
		AttackCycle.Phase.RECOVER:
			return 1.0 + (peak - 1.0) * cos(progress * TAU) * pow(1.0 - progress, 3.0)
	return 1.0


## 늘어난 길이 k에 맞는 옆 방향 배율 (부피가 보존되는 느낌)
static func width(k: float) -> float:
	return pow(k, -Balance.LUNGE_VOLUME)


## dir 방향으로 k배 늘이는 변환. 몸 뒤쪽 가장자리를 고정점으로 한다.
static func transform(dir: Vector2, k: float) -> Transform2D:
	var n := Vector2(-dir.y, dir.x)
	var w := width(k)
	var pivot := -dir * body_radius(dir)
	var x_axis := dir * (k * dir.x) + n * (w * n.x)
	var y_axis := dir * (k * dir.y) + n * (w * n.y)
	var origin := pivot - (x_axis * pivot.x + y_axis * pivot.y)
	return Transform2D(x_axis, y_axis, origin)
