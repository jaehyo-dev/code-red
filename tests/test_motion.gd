extends TestCase
## 몸 공격의 시간 흐름(AttackCycle), 한 입에 삼키기 모양(BitePose)·삼키는 연출(Swallow), 슬라임 모션(SlimeMotion), 얼굴(SlimeFace), 방향 맞추기를 확인한다.

const DT := 1.0 / 60.0


func test_공격_단계가_준비_입벌림_감쌈_복귀_쿨다운_순서로_돈다() -> void:
	var c := AttackCycle.new()
	assert_eq(c.phase, AttackCycle.Phase.IDLE)
	var seen: Array = []
	var hits := 0
	for i in 180:
		if c.update(DT, true):
			hits += 1
		if seen.is_empty() or seen[-1] != c.phase:
			seen.append(c.phase)
	var P := AttackCycle.Phase
	assert_eq(seen.slice(0, 6), [P.WINDUP, P.OPEN, P.ENGULF, P.RECOVER, P.IDLE, P.WINDUP])
	# 한 바퀴 1.3초: 첫 피해 0.22+0.2+0.14=0.56초, 두 번째 1.86초 → 3초 동안 2번
	assert_eq(hits, 2, "한 바퀴에 피해는 한 번")


func test_대상이_없으면_공격을_시작하지_않음() -> void:
	var c := AttackCycle.new()
	for i in 60:
		assert_true(not c.update(DT, false))
	assert_eq(c.phase, AttackCycle.Phase.IDLE)


func test_피해는_감싸는_단계에서만_한_번_그리고_감싸기_시작이_알려짐() -> void:
	var c := AttackCycle.new()
	var hit_phase := -1
	var engulf_enters := 0
	for i in 75:  # 한 바퀴(1.3초) 안
		var landed := c.update(DT, true)
		if c.entered == AttackCycle.Phase.ENGULF:
			engulf_enters += 1
		if landed and hit_phase == -1:
			hit_phase = c.phase
	assert_eq(hit_phase, AttackCycle.Phase.ENGULF)
	assert_eq(engulf_enters, 1, "감싸기 시작은 한 번만 알려짐")


func test_가만히_있으면_숨쉬듯_조금_늘었다_줄어듦() -> void:
	var m := SlimeMotion.new()
	var lo := 9.0
	var hi := 0.0
	for i in 300:
		var s := m.update(DT, Vector2.ZERO)
		lo = minf(lo, s.y)
		hi = maxf(hi, s.y)
	assert_true(hi > 1.02 and lo < 0.98, "세로가 1 위아래로 움직임 %f~%f" % [lo, hi])
	assert_true(hi < 1.1 and lo > 0.9, "너무 크게 흔들리지 않음")


## 오른쪽 이동의 리듬 변형을 프레임별로 모은다: [길이 배율, 앞쪽 끝 x, 뒤쪽 끝 x]
func _gait_run(m: SlimeMotion, input: Vector2, frames: int) -> Array:
	var out: Array = []
	for i in frames:
		m.update(DT, input)
		var t := m.gait_transform()
		out.append([t.x.x, (t * Vector2(13, 0)).x, (t * Vector2(-13, 0)).x])
	return out


func _crossings(rows: Array, from: int) -> int:
	var n := 0
	for i in range(from + 1, rows.size()):
		if rows[i - 1][0] < 1.0 and rows[i][0] >= 1.0:
			n += 1
	return n


func _peak_dev(rows: Array) -> float:
	var d := 0.0
	for r in rows:
		d = maxf(d, absf(r[0] - 1.0))
	return d


func test_최고속도에서_이동_리듬은_약_0점35초_주기로_늘었다_줄었다() -> void:
	var rows := _gait_run(SlimeMotion.new(), Vector2.RIGHT, 180)
	# 60프레임 이후 2초 동안 약 5.7주기
	var cycles := _crossings(rows, 60)
	assert_true(cycles >= 5 and cycles <= 6, "2초에 5~6주기 %d" % cycles)
	assert_true(_peak_dev(rows) > 0.15 and _peak_dev(rows) < 0.25, "길이가 ±20%% 안팎 %f" % _peak_dev(rows))


func test_속도가_느리면_주기는_길고_크기는_작음() -> void:
	var full := _peak_dev(_gait_run(SlimeMotion.new(), Vector2.RIGHT, 180))
	var half_rows := _gait_run(SlimeMotion.new(), Vector2.RIGHT * 0.5, 180)
	assert_true(_peak_dev(half_rows) < full * 0.5, "절반 속도: 변형이 절반 아래 %f" % _peak_dev(half_rows))
	assert_true(_crossings(half_rows, 60) <= 3, "절반 속도: 주기가 길어짐")
	assert_true(_peak_dev(_gait_run(SlimeMotion.new(), Vector2.RIGHT * 0.15, 180)) < 0.02, "조이스틱을 살짝 밀면 거의 안 변함")


func test_앞쪽_끝이_먼저_나가고_뒤쪽_끝이_따라붙음() -> void:
	var rows := _gait_run(SlimeMotion.new(), Vector2.RIGHT, 240)
	var f := -1
	var r := -1
	for i in range(120, 238):
		if f < 0 and rows[i][1] > rows[i - 1][1] and rows[i][1] > rows[i + 1][1]:
			f = i
		if f >= 0 and r < 0 and rows[i][2] > rows[i - 1][2] and rows[i][2] > rows[i + 1][2]:
			r = i
	assert_true(f > 0 and r > f and r - f <= 12, "앞쪽 끝 최대(%d) 다음에 뒤쪽 끝 최대(%d)" % [f, r])


func test_멈추면_출렁임_없이_깔끔하게_복귀() -> void:
	var m := SlimeMotion.new()
	_gait_run(m, Vector2.RIGHT, 90)
	var lowest := 9.0
	for i in 60:  # 멈춘 직후 1초: 숨쉬기(±4%)보다 크게 눌리지 않음
		var s := m.update(DT, Vector2.ZERO)
		lowest = minf(lowest, minf(s.x, s.y))
	assert_true(lowest > 0.9, "멈출 때 크게 찌그러지지 않음 %f" % lowest)
	for i in 120:
		m.update(DT, Vector2.ZERO)
	assert_true(m.gait_transform() == Transform2D.IDENTITY or absf(m.gait_transform().x.x - 1.0) < 0.005, "리듬 변형이 사라짐")
	assert_true(absf(m.lean()) < 0.005, "곧게 복귀")


func test_방향이_갑자기_바뀌어도_프레임마다_크게_튀지_않음() -> void:
	var m := SlimeMotion.new()
	for i in 60:
		m.update(DT, Vector2.RIGHT)
	var prev := m.update(DT, Vector2.LEFT)
	var worst := 0.0
	for i in 60:
		var s := m.update(DT, Vector2.LEFT if i < 30 else Vector2.UP)
		worst = maxf(worst, maxf(absf(s.x - prev.x), absf(s.y - prev.y)))
		prev = s
	assert_true(worst < 0.07, "한 프레임 변화가 7%% 미만 %f" % worst)


func test_이동하면_진행_방향으로_기울고_머리_곡선은_반대로_끌림() -> void:
	var m := SlimeMotion.new()
	for i in 20:
		m.update(DT, Vector2.RIGHT)
	assert_true(m.lean() > 0.05, "오른쪽으로 기움 %f" % m.lean())
	assert_true(m.crest_shear() < -0.05, "곡선은 왼쪽으로 끌림 %f" % m.crest_shear())
	for i in 20:
		m.update(DT, Vector2.LEFT)
	assert_true(m.lean() < -0.05 and m.crest_shear() > 0.05, "왼쪽으로 가면 반대")
	for i in 300:
		m.update(DT, Vector2.ZERO)
	assert_true(absf(m.lean()) < 0.01 and absf(m.crest_shear()) < 0.01, "멈추면 곧게 복귀")


func test_프레임은_웅크림_벌림_감쌈_뱉기_순서로_바뀜() -> void:
	var P := AttackCycle.Phase
	var F := BitePose.Frame
	assert_eq(BitePose.frame(P.IDLE, 0.0), F.BODY)
	assert_eq(BitePose.frame(P.WINDUP, 1.0), F.BODY, "웅크림은 평소 몸")
	assert_eq(BitePose.frame(P.OPEN, 0.0), F.OPEN_A)
	assert_eq(BitePose.frame(P.OPEN, 1.0), F.OPEN_B)
	assert_eq(BitePose.frame(P.ENGULF, 0.5), F.WRAP)
	assert_eq(BitePose.frame(P.RECOVER, 0.0), F.OPEN_B, "뱉을 때 입이 벌어짐")
	assert_eq(BitePose.frame(P.RECOVER, 1.0), F.BODY, "끝에서 평소 몸")


func test_몸은_물러났다가_적에게_닿고_제자리로_돌아옴() -> void:
	var P := AttackCycle.Phase
	var reach := 150.0
	assert_true(BitePose.travel(P.WINDUP, 1.0, reach) < -5.0, "웅크리며 뒤로 물러남")
	assert_eq(BitePose.travel(P.OPEN, 0.0, reach), BitePose.travel(P.WINDUP, 1.0, reach), "웅크림에서 이어짐")
	assert_true(is_equal_approx(BitePose.travel(P.OPEN, 1.0, reach), reach * Balance.BITE_OPEN_REACH), "입 벌림이 끝나면 일부만 다가감")
	assert_true(is_equal_approx(BitePose.travel(P.ENGULF, 1.0, reach), reach), "감싸면 적 위치까지 감")
	assert_true(is_equal_approx(BitePose.travel(P.ENGULF, 0.0, reach), BitePose.travel(P.OPEN, 1.0, reach)), "입 벌림에서 이어짐")
	assert_true(is_equal_approx(BitePose.travel(P.RECOVER, 0.0, reach), reach), "복귀는 적 위치에서 시작")
	assert_true(is_equal_approx(BitePose.travel(P.RECOVER, 1.0, reach), 0.0), "제자리로 복귀")
	assert_eq(BitePose.squash(P.IDLE, 0.0, 0.0), Vector2.ONE)
	assert_true(BitePose.squash(P.WINDUP, 1.0, 0.0).y < 0.9, "웅크리면 낮아짐")
	assert_true(BitePose.squash(P.OPEN, 1.0, 0.0).y > 1.05, "솟으면 길어짐")
	assert_true(is_equal_approx(BitePose.squash(P.RECOVER, 1.0, 0.0).x, 1.0), "복귀하면 원래 크기")


func test_입_프레임_방향은_좌우_뒤집기와_45도_회전() -> void:
	var right := Vector2.RIGHT
	for dir: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN, Vector2(1, 1).normalized(), Vector2(-1, -1).normalized(), Vector2(-1, 1).normalized()]:
		var out := BitePose.direction(dir) * right
		assert_true(out.dot(dir) > 0.92, "입이 적 쪽을 향함 %s → %s" % [dir, out])
	assert_eq(BitePose.direction(Vector2.RIGHT), Transform2D.IDENTITY, "오른쪽은 그대로")
	assert_true(BitePose.direction(Vector2.LEFT).determinant() < 0.0, "왼쪽은 뒤집기")
	var slight := BitePose.direction(Vector2.from_angle(deg_to_rad(10))) * right
	assert_true(slight.is_equal_approx(Vector2.RIGHT), "10도 정도는 정면으로 맞춤")


func test_삼키는_연출은_줄어들고_소화되어_정확히_사라짐() -> void:
	assert_eq(Swallow.inner_scale(0.0), 1.0)
	assert_true(is_equal_approx(Swallow.inner_scale(1.0), Balance.SWALLOW_INNER_SCALE), "몸 안에서 작게 보임")
	assert_true(Swallow.inner_scale(0.5) < 1.0 and Swallow.inner_scale(0.5) > Balance.SWALLOW_INNER_SCALE)
	assert_eq(Swallow.digest_scale(0.0), 1.0)
	assert_eq(Swallow.digest_scale(1.0), 0.0, "소화가 끝나면 크기 0")
	var prev := 2.0
	for i in 11:
		var s := Swallow.digest_scale(i / 10.0)
		assert_true(s < prev, "계속 작아짐")
		prev = s
	assert_true(Swallow.alpha(1.0) < Swallow.alpha(0.0), "소화될수록 옅어짐")
	var lo := 0.0
	var hi := 0.0
	for i in 200:
		var w := Swallow.wobble(i * DT)
		lo = minf(lo, w)
		hi = maxf(hi, w)
	assert_true(hi > Balance.SWALLOW_WOBBLE * 0.9 and lo < -Balance.SWALLOW_WOBBLE * 0.9, "꿀럭이며 양쪽으로 출렁")


func test_얼굴은_가는_방향으로_쏠리고_위를_보면_눈이_작아짐() -> void:
	var f := SlimeFace.new()
	assert_eq(f.offset(), Vector2i.ZERO, "처음엔 정면")
	for i in 30:
		f.update(DT, Vector2.RIGHT)
	assert_true(f.offset().x >= 3 and f.offset().y == 0, "오른쪽으로 쏠림 %s" % f.offset())
	assert_true(not f.small_eyes())
	for i in 30:
		f.update(DT, Vector2.ZERO)  # 목표가 없으면 마지막 방향 유지
	assert_true(f.offset().x >= 3, "방향 유지")
	for i in 30:
		f.update(DT, Vector2.UP)
	assert_true(f.offset().y <= -5 and f.small_eyes(), "위: 얼굴이 올라가고 눈이 작아짐 %s" % f.offset())
	for i in 30:
		f.update(DT, Vector2.DOWN)
	assert_true(f.offset().y > 0 and f.offset().y <= 3 and not f.small_eyes(), "아래: 얼굴이 내려와 정면을 봄 %s" % f.offset())


func test_공격_준비_안에_얼굴이_대상_쪽으로_돌아감() -> void:
	var f := SlimeFace.new()
	var dir := Vector2.from_angle(deg_to_rad(-30))
	for i in roundi(Balance.ATTACK_WINDUP / DT):
		f.update(DT, dir)
	assert_true(f.look.dot(dir) > 0.93, "준비가 끝나면 얼굴이 대상 쪽으로 거의 돌아감 %f" % f.look.dot(dir))


func test_피격_충격은_납작하게_찌그러뜨리고_돌아옴() -> void:
	var m := SlimeMotion.new()
	m.hit_kick()
	var flattest := 9.0
	for i in 15:
		flattest = minf(flattest, m.update(DT, Vector2.ZERO).y)
	assert_true(flattest < 0.82, "납작해짐 %f" % flattest)
	var s := Vector2.ZERO
	for i in 300:
		s = m.update(DT, Vector2.ZERO)
	assert_true(absf(s.y - 1.0) < 0.06, "복귀 %f" % s.y)
