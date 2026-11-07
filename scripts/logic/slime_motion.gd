class_name SlimeMotion
extends RefCounted
## 슬라임 몸의 늘어남·찌그러짐 계산 (화면과 분리). update()가 스프라이트에 곱할 scale을 돌려준다.
## 숨쉬기 + 이동 리듬(gait_transform: 앞이 먼저 나가고 뒤가 따라붙는 기어가기) + 가감속 스프링 + 기울기 + 머리 곡선 끌림 + 피격 충격.
## 공격(덮치기) 모양은 LungePose가 맡는다.

var _time := 0.0
var _vel := Vector2.ZERO  # 부드럽게 따라가는 이동 입력
var _off := Vector2.ZERO  # 스프링 변형량
var _off_v := Vector2.ZERO
var _crest := 0.0  # 머리 곡선 기울기 (위쪽이 옆으로 밀리는 비율)
var _crest_v := 0.0
var _gait := 0.0  # 이동 리듬 위상 (0~1 주기)


## move: 이동 입력(길이 0~1)
func update(delta: float, move: Vector2) -> Vector2:
	delta = minf(delta, 1.0 / 30.0)  # 프레임이 길게 끊겨도 스프링이 튀지 않게
	_time += delta
	var old_vel := _vel
	_vel = _vel.lerp(move, 1.0 - exp(-Balance.MOVE_FOLLOW * delta))
	var accel := (_vel - old_vel) / delta
	_gait = fposmod(_gait + _vel.length() / Balance.GAIT_PERIOD * delta, 1.0)  # 느리면 주기가 길어짐
	# 관성: 멈추거나 꺾을 때 진행 방향이 눌리고 옆으로 퍼진다 (스프링이 복귀)
	var target := Balance.MOVE_INERTIA * (accel - Vector2(absf(accel.y), absf(accel.x)) * 0.6)
	_off_v += ((target - _off) * Balance.SPRING_STIFFNESS - _off_v * Balance.SPRING_DAMPING) * delta
	_off += _off_v * delta
	# 머리 곡선: 이동 반대쪽으로 끌려오고, 가속할 때 더 뒤처졌다가 출렁이며 돌아온다
	_crest_v += ((-_vel.x * _vel.length() * Balance.CREST_DRAG - _crest) * Balance.CREST_STIFFNESS - _crest_v * Balance.CREST_DAMPING - accel.x * 0.04) * delta
	_crest += _crest_v * delta
	var breath := sin(_time * Balance.BREATH_SPEED) * Balance.BREATH_AMOUNT
	var total := _off + Vector2(-breath * 0.5, breath)
	return Vector2(clampf(1.0 + total.x, 0.5, 1.6), clampf(1.0 + total.y, 0.5, 1.6))


## 맞았을 때: 스프링에 충격을 줘서 납작하게 찌그러졌다 출렁이며 돌아온다
func hit_kick() -> void:
	_off_v += Balance.HIT_KICK


## 이동 리듬 변형 (몸 중심 기준, 도트). 이동 방향 길이가 늘었다 줄고 몸 중심이 앞뒤로 흔들려서,
## 앞쪽 끝이 먼저 나가고 뒤쪽 끝이 따라붙는다. 크기는 속도의 제곱에 비례해 조이스틱을 살짝 밀면 거의 안 변한다.
func gait_transform() -> Transform2D:
	var s := _vel.length()
	if s < 0.02:
		return Transform2D.IDENTITY
	var d := _vel / s
	var n := Vector2(-d.y, d.x)
	var k := 1.0 + Balance.GAIT_STRETCH * s * s * cos(TAU * _gait)
	var w := 1.0 / k
	return Transform2D(d * (k * d.x) + n * (w * n.x), d * (k * d.y) + n * (w * n.y), d * (Balance.GAIT_SHIFT * s * s * sin(TAU * _gait)))


## 이동 방향으로 몸이 기우는 정도 (위쪽이 옆으로 밀리는 비율). 속도에 비례.
func lean() -> float:
	return _vel.x * _vel.length() * Balance.MOVE_LEAN


## 머리 위 곡선의 기울기 (위쪽이 옆으로 밀리는 비율). 이동 반대쪽으로 끌린다.
func crest_shear() -> float:
	return _crest
