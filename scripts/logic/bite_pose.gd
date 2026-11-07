class_name BitePose
extends RefCounted
## "한 입에 삼키기" 몸 모양 계산 (화면과 분리).
## 프레임 그림은 오른쪽을 보는 것 하나뿐이다. 방향은 이렇게 맞춘다:
## 왼쪽은 좌우 뒤집기, 위·아래·대각은 45도 단위로 돌린다 (눈에 보이는 입이 늘 적 쪽을 향함). 감싸기 프레임은 둥근 돔이라 돌리지 않는다.

enum Frame { BODY, OPEN_A, OPEN_B, WRAP }


## 단계와 진행도(0~1)에 맞는 그림 프레임. BODY면 평소 몸(눈·입 레이어 포함)을 그린다
static func frame(phase: int, progress: float) -> Frame:
	match phase:
		AttackCycle.Phase.OPEN:
			return Frame.OPEN_A if progress < 0.45 else Frame.OPEN_B
		AttackCycle.Phase.ENGULF:
			return Frame.WRAP
		AttackCycle.Phase.RECOVER:
			if progress < 0.25:
				return Frame.OPEN_B
			return Frame.OPEN_A if progress < 0.5 else Frame.BODY
	return Frame.BODY


## 몸이 적 쪽으로 나간 거리(픽셀, 음수는 뒤로 물러남). reach는 적 중심까지 거리.
static func travel(phase: int, progress: float, reach: float) -> float:
	var open_end := reach * Balance.BITE_OPEN_REACH
	match phase:
		AttackCycle.Phase.WINDUP:
			return -Balance.BITE_PULLBACK * ease(progress, 0.4)
		AttackCycle.Phase.OPEN:
			return lerpf(-Balance.BITE_PULLBACK, open_end, ease(progress, 0.5))
		AttackCycle.Phase.ENGULF:
			return lerpf(open_end, reach, 1.0 - pow(1.0 - minf(progress / Balance.ENGULF_HIT_AT, 1.0), 3.0))
		AttackCycle.Phase.RECOVER:
			return reach * (1.0 - smoothstep(0.0, 0.8, progress))
	return 0.0


## 몸 가로·세로 배율. 준비는 웅크림, 입 벌림은 솟음, 감싸는 중엔 꿀럭, 복귀는 착지하며 출렁
static func squash(phase: int, progress: float, time: float) -> Vector2:
	match phase:
		AttackCycle.Phase.WINDUP:
			return Vector2.ONE.lerp(Balance.BITE_CROUCH, ease(progress, 0.4))
		AttackCycle.Phase.OPEN:
			return Balance.BITE_CROUCH.lerp(Balance.BITE_RISE, ease(progress, 0.5))
		AttackCycle.Phase.ENGULF:
			var w := Swallow.wobble(time)
			return Vector2(1.0 + w, 1.0 - w)
		AttackCycle.Phase.RECOVER:
			var k := cos(progress * TAU * 1.5) * pow(1.0 - progress, 2.0)
			return Vector2(1.0 + 0.1 * k, 1.0 - 0.1 * k)
	return Vector2.ONE


## 입 프레임에 곱할 방향 변환 (회전·뒤집기만, 이동 없음). 오른쪽은 그대로, 왼쪽은 뒤집고, 위아래·대각은 45도 단위로 돌린다
static func direction(dir: Vector2) -> Transform2D:
	var angle := snappedf(Vector2(absf(dir.x), dir.y).angle(), PI / 4.0)
	var t := Transform2D(angle, Vector2.ZERO)
	return Transform2D(Vector2(-1, 0), Vector2(0, 1), Vector2.ZERO) * t if dir.x < 0.0 else t
