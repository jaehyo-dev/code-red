extends TestCase
## 몸 공격의 시간 흐름(AttackCycle), 덮치기 모양(LungePose), 슬라임 모션(SlimeMotion), 얼굴(SlimeFace), 부채꼴 판정을 확인한다.

const DT := 1.0 / 60.0


func test_공격_단계가_준비_타격_복귀_쿨다운_순서로_돈다() -> void:
	var c := AttackCycle.new()
	assert_eq(c.phase, AttackCycle.Phase.IDLE)
	var seen: Array = []
	var hits := 0
	for i in 120:
		if c.update(DT, true):
			hits += 1
		if seen.is_empty() or seen[-1] != c.phase:
			seen.append(c.phase)
	assert_eq(seen.slice(0, 5), [AttackCycle.Phase.WINDUP, AttackCycle.Phase.STRIKE, AttackCycle.Phase.RECOVER, AttackCycle.Phase.IDLE, AttackCycle.Phase.WINDUP])
	# 2초 동안: 한 바퀴 0.95초, 첫 타격 약 0.38초 → 0.38, 1.33초에 2번 타격
	assert_eq(hits, 2, "한 단계에 타격은 한 번")


func test_대상이_없으면_공격을_시작하지_않음() -> void:
	var c := AttackCycle.new()
	for i in 60:
		assert_true(not c.update(DT, false))
	assert_eq(c.phase, AttackCycle.Phase.IDLE)


func test_타격은_타격_단계_중간에_한_번만() -> void:
	var c := AttackCycle.new()
	var hit_phase := -1
	for i in 120:
		if c.update(DT, true):
			hit_phase = c.phase
			break
	assert_eq(hit_phase, AttackCycle.Phase.STRIKE)


func test_부채꼴_판정() -> void:
	var arc := deg_to_rad(55.0)
	assert_true(Targeting.in_cone(Vector2.ZERO, Vector2.RIGHT, Vector2(100, 0), 130.0, arc), "정면")
	assert_true(Targeting.in_cone(Vector2.ZERO, Vector2.RIGHT, Vector2(80, 80), 130.0, arc), "45도")
	assert_true(not Targeting.in_cone(Vector2.ZERO, Vector2.RIGHT, Vector2(0, 100), 130.0, arc), "90도 밖")
	assert_true(not Targeting.in_cone(Vector2.ZERO, Vector2.RIGHT, Vector2(200, 0), 130.0, arc), "거리 밖")
	assert_true(not Targeting.in_cone(Vector2.ZERO, Vector2.RIGHT, Vector2(-100, 0), 130.0, arc), "뒤쪽")


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


func test_덮치기_두_안_모두_웅크림_늘어남_눌림_복귀_순서() -> void:
	for st in [Balance.STYLE_STRETCH, Balance.STYLE_HOP]:
		LungePose.style = st
		var peak := LungePose.peak_for(Vector2.RIGHT)
		var crouch := LungePose.pose(AttackCycle.Phase.WINDUP, 1.0, peak)
		assert_true(crouch.x < 0.95 and crouch.y < 0.0, "웅크리며 뒤로 물러남 %s (안 %d)" % [crouch, st])
		assert_eq(LungePose.pose(AttackCycle.Phase.STRIKE, 0.0, peak), crouch, "웅크림에서 이어짐")
		assert_eq(LungePose.pose(AttackCycle.Phase.STRIKE, 1.0, peak), peak, "타격 끝에 최대")
		assert_eq(LungePose.pose(AttackCycle.Phase.RECOVER, 0.0, peak), peak, "복귀는 최대에서 시작")
		var lowest := 9.0
		for i in 101:
			lowest = minf(lowest, LungePose.pose(AttackCycle.Phase.RECOVER, i / 100.0, peak).x)
		assert_true(lowest < 0.95 and lowest > 0.7, "닿은 뒤 살짝 눌림 %f" % lowest)
		var end := LungePose.pose(AttackCycle.Phase.RECOVER, 1.0, peak)
		assert_true(is_equal_approx(end.x, 1.0) and is_equal_approx(end.y, 0.0), "제자리로 복귀")
		assert_eq(LungePose.pose(AttackCycle.Phase.IDLE, 0.0, peak), Vector2(1, 0))
	LungePose.style = Balance.ATTACK_STYLE


func test_두_안_모두_앞쪽_끝이_사거리_끝의_적에게_닿고_옆은_가늘어짐() -> void:
	for st in [Balance.STYLE_STRETCH, Balance.STYLE_HOP]:
		LungePose.style = st
		for dir: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN, Vector2(1, 1).normalized(), Vector2(-1, -2).normalized()]:
			var peak := LungePose.peak_for(dir)
			var t := LungePose.transform(dir, peak.x, peak.y)
			var r := LungePose.body_radius(dir)
			var tip := (t * (dir * r)).dot(dir)
			assert_true(absf(tip - Balance.LUNGE_TIP_DOTS) < 0.5, "앞쪽 끝이 목표에 닿음 안%d %s: %f" % [st, dir, tip])
			assert_true(tip * 3.0 >= Balance.MELEE_RANGE - Balance.ENEMY_RADIUS, "사거리 끝 적의 가장자리까지 닿음")
			var back := LungePose.transform(dir, peak.x, 0.0) * (-dir * r)
			assert_true(back.distance_to(-dir * r) < 0.001, "밀림 없이 늘어나면 뒤쪽 끝 고정")
			assert_true(LungePose.width(peak.x) < 1.0 and t.determinant() > 0.0, "옆은 가늘어지고 뒤집히지 않음")
	assert_true(is_equal_approx(LungePose.width(1.0), 1.0), "안 늘어나면 그대로")
	LungePose.style = Balance.STYLE_STRETCH
	assert_true(LungePose.peak_for(Vector2.RIGHT).x <= Balance.A_MAX_STRETCH + 0.001, "안 A: 늘어남 상한")
	LungePose.style = Balance.STYLE_HOP
	var hop_px := LungePose.peak_for(Vector2.RIGHT).y * 3.0
	assert_true(hop_px >= 60.0 and hop_px <= 80.0, "안 B: 튀어나가는 거리 60~80픽셀 %f" % hop_px)
	LungePose.style = Balance.ATTACK_STYLE


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
	assert_true(f.look.dot(dir) > 0.97, "준비가 끝나기 전에 얼굴이 대상을 봄 %f" % f.look.dot(dir))


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
