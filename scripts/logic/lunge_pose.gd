class_name LungePose
extends RefCounted
## 덮치기 모양 계산 (화면과 분리). 좌표는 슬라임 몸 중심 기준 도트 단위.
## 모양은 (길이 배율 k, 앞으로 밀리는 도트 shift) 두 값으로 정한다. 뒤쪽 끝에서 k배 늘이고 몸을 shift만큼 민다.
## 안 A(STYLE_STRETCH): 늘어남 위주, 몸이 뒤로 물러났다 늘어나며 나가고 모자란 거리만 밀림.
## 안 B(STYLE_HOP): 짧은 돌진, 몸이 B_HOP_DOTS만큼 튀어나가고 늘어남은 적당히.

## 쓰는 안. 기본은 Balance.ATTACK_STYLE (캡처 장면이 바꿔 가며 쓴다)
static var style := Balance.ATTACK_STYLE


## dir 방향으로 몸 중심에서 몸 가장자리까지의 거리 (타원 근사)
static func body_radius(dir: Vector2) -> float:
	var h := Balance.SLIME_HALF
	return 1.0 / sqrt(pow(dir.x / h.x, 2) + pow(dir.y / h.y, 2))


## 이번 덮치기의 최대치 Vector2(k, shift). 앞쪽 끝이 LUNGE_TIP_DOTS에 닿도록 (tip = shift + r * (2k - 1)).
static func peak_for(dir: Vector2) -> Vector2:
	var r := body_radius(dir)
	var tip := Balance.LUNGE_TIP_DOTS
	var shift := Balance.B_HOP_DOTS if style == Balance.STYLE_HOP else maxf(0.0, tip - r * (2.0 * Balance.A_MAX_STRETCH - 1.0))
	return Vector2(clampf(((tip - shift) / r + 1.0) * 0.5, 1.2, 2.4), shift)


## 단계와 진행도(0~1)에 따른 Vector2(길이 배율, 밀림 도트). peak는 peak_for() 값.
## 준비: 웅크리며 뒤로 물러남 / 타격: 쭉 나감 / 복귀: 닿은 뒤 눌렸다 탄성으로 제자리
static func pose(phase: int, progress: float, peak: Vector2) -> Vector2:
	var hop := style == Balance.STYLE_HOP
	var crouch := Balance.B_CROUCH if hop else Balance.A_CROUCH
	var pull := -(Balance.B_PULLBACK if hop else Balance.A_PULLBACK)
	match phase:
		AttackCycle.Phase.WINDUP:
			var e := ease(progress, 0.4)
			return Vector2(lerpf(1.0, crouch, e), pull * e)
		AttackCycle.Phase.STRIKE:
			# 안 B는 몸이 먼저 튀어나가고, 안 A는 먼저 늘어난 뒤 몸이 따라 밀림
			var ek := ease(progress, 0.5 if hop else 0.35)
			var es := ease(progress, 0.3 if hop else 2.0)
			return Vector2(lerpf(crouch, peak.x, ek), lerpf(pull, peak.y, es))
		AttackCycle.Phase.RECOVER:
			var k := 1.0 + (peak.x - 1.0) * cos(progress * TAU) * pow(1.0 - progress, 3.0)
			return Vector2(k, peak.y * pow(1.0 - progress, 2.0))
	return Vector2(1.0, 0.0)


## 늘어난 길이 k에 맞는 옆 방향 배율 (부피가 보존되는 느낌)
static func width(k: float) -> float:
	return pow(k, -Balance.LUNGE_VOLUME)


## dir 방향으로 k배 늘이고 shift만큼 미는 변환. 늘어날 때 몸 뒤쪽 가장자리를 고정점으로 한다.
static func transform(dir: Vector2, k: float, shift := 0.0) -> Transform2D:
	var n := Vector2(-dir.y, dir.x)
	var w := width(k)
	var pivot := -dir * body_radius(dir)
	var x_axis := dir * (k * dir.x) + n * (w * n.x)
	var y_axis := dir * (k * dir.y) + n * (w * n.y)
	var origin := pivot - (x_axis * pivot.x + y_axis * pivot.y) + dir * shift
	return Transform2D(x_axis, y_axis, origin)
