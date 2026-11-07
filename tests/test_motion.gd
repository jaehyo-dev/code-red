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


func test_이동하면_가로로_늘어나고_멈추면_찌그러졌다_복귀() -> void:
	var m := SlimeMotion.new()
	var widest := 0.0
	for i in 60:
		widest = maxf(widest, m.update(DT, Vector2.RIGHT).x)
	assert_true(widest > 1.12, "진행 방향(가로)으로 늘어남 %f" % widest)
	var narrowest := 9.0
	for i in 40:  # 멈춘 뒤: 스프링이 반대로 출렁인다 (가로가 1보다 줄어듦)
		narrowest = minf(narrowest, m.update(DT, Vector2.ZERO).x)
	assert_true(narrowest < 0.99, "멈출 때 찌그러짐 %f" % narrowest)
	var s := Vector2.ZERO
	for i in 300:
		s = m.update(DT, Vector2.ZERO)
	assert_true(absf(s.x - 1.0) < 0.05, "다시 원래 크기로 복귀 %f" % s.x)


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


func test_덮치기_길이는_웅크림_늘어남_눌림_복귀_순서() -> void:
	var peak := 2.0
	var crouch := LungePose.length(AttackCycle.Phase.WINDUP, 1.0, peak)
	assert_true(crouch < 0.85, "웅크리면 방향 길이가 줄어듦 %f" % crouch)
	assert_eq(LungePose.length(AttackCycle.Phase.STRIKE, 0.0, peak), crouch, "웅크림에서 이어짐")
	assert_true(is_equal_approx(LungePose.length(AttackCycle.Phase.STRIKE, 1.0, peak), peak), "타격 끝에 최대")
	assert_true(is_equal_approx(LungePose.length(AttackCycle.Phase.RECOVER, 0.0, peak), peak), "복귀는 최대에서 시작")
	var lowest := 9.0
	for i in 101:
		lowest = minf(lowest, LungePose.length(AttackCycle.Phase.RECOVER, i / 100.0, peak))
	assert_true(lowest < 0.95 and lowest > 0.7, "닿은 뒤 살짝 눌림 %f" % lowest)
	assert_true(is_equal_approx(LungePose.length(AttackCycle.Phase.RECOVER, 1.0, peak), 1.0), "원래 길이로 복귀")
	assert_eq(LungePose.length(AttackCycle.Phase.IDLE, 0.0, peak), 1.0)


func test_늘어난_만큼_옆은_가늘어지고_뒤쪽_끝은_고정_앞쪽_끝은_사거리에_닿음() -> void:
	for dir: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN, Vector2(1, 1).normalized()]:
		var k := LungePose.peak_for(dir)
		var t := LungePose.transform(dir, k)
		var r := LungePose.body_radius(dir)
		assert_true((t * (-dir * r)).distance_to(-dir * r) < 0.001, "뒤쪽 끝 고정 %s" % dir)
		var tip := (t * (dir * r)).dot(dir)
		assert_true(absf(tip - Balance.LUNGE_TIP_DOTS) < 0.5 or k == Balance.LUNGE_MAX_STRETCH or k == 1.2, "앞쪽 끝이 닿는 거리 %s: %f" % [dir, tip])
		assert_true(LungePose.width(k) < 1.0, "옆은 가늘어짐 %f" % LungePose.width(k))
		assert_true(t.determinant() > 0.0, "뒤집히지 않음")
	assert_true(is_equal_approx(LungePose.width(1.0), 1.0), "안 늘어나면 그대로")


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
