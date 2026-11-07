class_name AttackCycle
extends RefCounted
## 몸 공격의 시간 흐름: 대기 → 준비(웅크림) → 타격 → 복귀 → 쿨다운. 화면과 분리된 상태 기계.

enum Phase { IDLE, WINDUP, STRIKE, RECOVER }

var phase := Phase.IDLE
var _t := 0.0
var _cooldown := 0.0
var _hit_done := false


## delta만큼 진행한다. 타격이 맞는 순간(몸이 거의 다 늘어난 때) 한 프레임만 true.
func update(delta: float, has_target: bool) -> bool:
	var landed := false
	match phase:
		Phase.IDLE:
			_cooldown = maxf(0.0, _cooldown - delta)
			if has_target and _cooldown <= 0.0:
				_enter(Phase.WINDUP)
		Phase.WINDUP:
			_t += delta
			if _t >= Balance.ATTACK_WINDUP:
				_enter(Phase.STRIKE)
		Phase.STRIKE:
			_t += delta
			if not _hit_done and _t >= Balance.ATTACK_STRIKE * Balance.ATTACK_HIT_AT:
				_hit_done = true
				landed = true
			if _t >= Balance.ATTACK_STRIKE:
				_enter(Phase.RECOVER)
		Phase.RECOVER:
			_t += delta
			if _t >= Balance.ATTACK_RECOVER:
				_cooldown = Balance.ATTACK_COOLDOWN
				_enter(Phase.IDLE)
	return landed


## 현재 단계의 진행도 0~1
func progress() -> float:
	var d := _duration()
	return 1.0 if d <= 0.0 else clampf(_t / d, 0.0, 1.0)


func _duration() -> float:
	match phase:
		Phase.WINDUP: return Balance.ATTACK_WINDUP
		Phase.STRIKE: return Balance.ATTACK_STRIKE
		Phase.RECOVER: return Balance.ATTACK_RECOVER
	return 0.0


func _enter(p: Phase) -> void:
	phase = p
	_t = 0.0
	_hit_done = false
