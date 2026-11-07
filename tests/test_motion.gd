extends TestCase
## 몸 공격의 시간 흐름(AttackCycle), 슬라임 모션(SlimeMotion), 부채꼴 판정을 확인한다.

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
	# 2초 동안: 한 바퀴 0.79초, 첫 타격 약 0.25초 → 0.25, 1.04, 1.83초에 3번 타격
	assert_eq(hits, 3, "한 단계에 타격은 한 번")


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
		var s := m.update(DT, Vector2.ZERO, AttackCycle.Phase.IDLE, 0.0)
		lo = minf(lo, s.y)
		hi = maxf(hi, s.y)
	assert_true(hi > 1.02 and lo < 0.98, "세로가 1 위아래로 움직임 %f~%f" % [lo, hi])
	assert_true(hi < 1.1 and lo > 0.9, "너무 크게 흔들리지 않음")


func test_이동하면_가로로_늘어나고_멈추면_찌그러졌다_복귀() -> void:
	var m := SlimeMotion.new()
	var widest := 0.0
	for i in 60:
		widest = maxf(widest, m.update(DT, Vector2.RIGHT, AttackCycle.Phase.IDLE, 0.0).x)
	assert_true(widest > 1.12, "진행 방향(가로)으로 늘어남 %f" % widest)
	var narrowest := 9.0
	for i in 40:  # 멈춘 뒤: 스프링이 반대로 출렁인다 (가로가 1보다 줄어듦)
		narrowest = minf(narrowest, m.update(DT, Vector2.ZERO, AttackCycle.Phase.IDLE, 0.0).x)
	assert_true(narrowest < 0.99, "멈출 때 찌그러짐 %f" % narrowest)
	var s := Vector2.ZERO
	for i in 300:
		s = m.update(DT, Vector2.ZERO, AttackCycle.Phase.IDLE, 0.0)
	assert_true(absf(s.x - 1.0) < 0.05, "다시 원래 크기로 복귀 %f" % s.x)


func test_방향이_갑자기_바뀌어도_프레임마다_크게_튀지_않음() -> void:
	var m := SlimeMotion.new()
	for i in 60:
		m.update(DT, Vector2.RIGHT, AttackCycle.Phase.IDLE, 0.0)
	var prev := m.update(DT, Vector2.LEFT, AttackCycle.Phase.IDLE, 0.0)
	var worst := 0.0
	for i in 60:
		var s := m.update(DT, Vector2.LEFT if i < 30 else Vector2.UP, AttackCycle.Phase.IDLE, 0.0)
		worst = maxf(worst, maxf(absf(s.x - prev.x), absf(s.y - prev.y)))
		prev = s
	assert_true(worst < 0.07, "한 프레임 변화가 7%% 미만 %f" % worst)


func test_공격_준비는_웅크리고_타격은_늘어남() -> void:
	var m := SlimeMotion.new()
	var wind := m.update(DT, Vector2.ZERO, AttackCycle.Phase.WINDUP, 1.0)
	var strike := m.update(DT, Vector2.ZERO, AttackCycle.Phase.STRIKE, 1.0)
	assert_true(wind.y < 0.8 and wind.x > 1.1, "웅크림: 납작하고 넓게 %s" % wind)
	assert_true(strike.y > 1.1 and strike.x < 0.95, "타격: 길쭉하게 %s" % strike)


func test_피격_충격은_납작하게_찌그러뜨리고_돌아옴() -> void:
	var m := SlimeMotion.new()
	m.hit_kick()
	var flattest := 9.0
	for i in 15:
		flattest = minf(flattest, m.update(DT, Vector2.ZERO, AttackCycle.Phase.IDLE, 0.0).y)
	assert_true(flattest < 0.82, "납작해짐 %f" % flattest)
	var s := Vector2.ZERO
	for i in 300:
		s = m.update(DT, Vector2.ZERO, AttackCycle.Phase.IDLE, 0.0)
	assert_true(absf(s.y - 1.0) < 0.06, "복귀 %f" % s.y)
