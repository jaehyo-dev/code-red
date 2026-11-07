class_name SlimeMotion
extends RefCounted
## 슬라임 몸의 늘어남·찌그러짐 계산 (화면과 분리). update()가 스프라이트에 곱할 scale을 돌려준다.
## 숨쉬기 + 이동 늘어남(스프링이라 멈출 때 찌그러졌다 복귀) + 공격 자세 + 피격 충격.

var _time := 0.0
var _vel := Vector2.ZERO  # 부드럽게 따라가는 이동 입력
var _off := Vector2.ZERO  # 스프링 변형량
var _off_v := Vector2.ZERO


## move: 이동 입력(길이 0~1), phase/progress: AttackCycle의 단계와 진행도
func update(delta: float, move: Vector2, phase: int, progress: float) -> Vector2:
	delta = minf(delta, 1.0 / 30.0)  # 프레임이 길게 끊겨도 스프링이 튀지 않게
	_time += delta
	var old_vel := _vel
	_vel = _vel.lerp(move, 1.0 - exp(-Balance.MOVE_FOLLOW * delta))
	var accel := (_vel - old_vel) / delta
	# 방향이 갑자기 바뀌어도 _vel이 0을 지나며 이어지므로 늘어남이 자연스럽게 바뀐다
	var ax := absf(_vel.x)
	var ay := absf(_vel.y)
	var target := Vector2(
		Balance.MOVE_STRETCH * ax - Balance.MOVE_SQUASH * ay,
		Balance.MOVE_STRETCH * ay - Balance.MOVE_SQUASH * ax)
	# 관성: 멈추거나 꺾을 때 진행 방향이 눌리고 옆으로 퍼진다 (스프링이 출렁이며 복귀)
	target += Balance.MOVE_INERTIA * (accel - Vector2(absf(accel.y), absf(accel.x)) * 0.6)
	_off_v += ((target - _off) * Balance.SPRING_STIFFNESS - _off_v * Balance.SPRING_DAMPING) * delta
	_off += _off_v * delta
	var breath := sin(_time * Balance.BREATH_SPEED) * Balance.BREATH_AMOUNT
	var total := _off + _attack_pose(phase, progress) + Vector2(-breath * 0.5, breath)
	return Vector2(clampf(1.0 + total.x, 0.5, 1.6), clampf(1.0 + total.y, 0.5, 1.6))


## 맞았을 때: 스프링에 충격을 줘서 납작하게 찌그러졌다 출렁이며 돌아온다
func hit_kick() -> void:
	_off_v += Balance.HIT_KICK


func _attack_pose(phase: int, progress: float) -> Vector2:
	match phase:
		AttackCycle.Phase.WINDUP: return Balance.WINDUP_POSE * ease(progress, 0.4)
		AttackCycle.Phase.STRIKE: return Balance.WINDUP_POSE.lerp(Balance.STRIKE_POSE, progress)
		AttackCycle.Phase.RECOVER: return Balance.STRIKE_POSE.lerp(Vector2.ZERO, ease(progress, 0.5))
	return Vector2.ZERO
