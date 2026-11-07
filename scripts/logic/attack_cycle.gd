class_name AttackCycle
extends RefCounted
## 몸 공격의 시간 흐름: 대기 → 준비(웅크림) → 입 벌림 → 감쌈 → 복귀(뱉기) → 쿨다운. 화면과 분리된 상태 기계.

enum Phase { IDLE, WINDUP, OPEN, ENGULF, RECOVER }

var phase := Phase.IDLE
## 이번 update에서 새로 들어간 단계 (없으면 -1). 감싸기 시작 같은 순간을 알아챌 때 쓴다
var entered := -1
var _t := 0.0
var _cooldown := 0.0
var _hit_done := false


## delta만큼 진행한다. 피해 순간(감싸는 중 ENGULF_HIT_AT 지점) 한 프레임만 true.
func update(delta: float, has_target: bool) -> bool:
	var landed := false
	entered = -1
	match phase:
		Phase.IDLE:
			_cooldown = maxf(0.0, _cooldown - delta)
			if has_target and _cooldown <= 0.0:
				_enter(Phase.WINDUP)
		Phase.WINDUP:
			_t += delta
			if _t >= Balance.ATTACK_WINDUP:
				_enter(Phase.OPEN)
		Phase.OPEN:
			_t += delta
			if _t >= Balance.ATTACK_OPEN:
				_enter(Phase.ENGULF)
		Phase.ENGULF:
			_t += delta
			if not _hit_done and _t >= Balance.ATTACK_ENGULF * Balance.ENGULF_HIT_AT:
				_hit_done = true
				landed = true
			if _t >= Balance.ATTACK_ENGULF:
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
		Phase.OPEN: return Balance.ATTACK_OPEN
		Phase.ENGULF: return Balance.ATTACK_ENGULF
		Phase.RECOVER: return Balance.ATTACK_RECOVER
	return 0.0


func _enter(p: Phase) -> void:
	phase = p
	entered = p
	_t = 0.0
	_hit_done = false
