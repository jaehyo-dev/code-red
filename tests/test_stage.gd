extends TestCase
## 스테이지(씬)가 실제로 돌아가는지: 이동, 카메라 한계, 적 생성, 자동 공격, 쓰러짐, 조명.


func _make_stage() -> Stage:
	var stage := Stage.new()
	stage.rng_seed = 42
	add_child(stage)
	return stage


func test_시작하면_슬라임과_장식이_생기고_조명이_있다() -> void:
	var stage := _make_stage()
	await wait_frames()
	assert_not_null(stage.player)
	assert_eq(stage.get_children().filter(func(n): return n is CanvasModulate).size(), 1, "어둡게 하는 CanvasModulate")
	var lights := stage.find_children("*", "PointLight2D", true, false)
	# 슬라임 1 + 수정 8 + 버섯 12 + 모닥불 3 이상
	assert_true(lights.size() >= 20, "조명 %d개" % lights.size())
	stage.queue_free()


func test_방향키_입력으로_움직이고_벽_밖으로는_못_나감() -> void:
	var stage := _make_stage()
	await wait_frames()
	var start := stage.player.position
	stage.player.move_input = Vector2.UP
	stage.player._process(0.1)
	assert_true(stage.player.position.y < start.y, "위로 이동")
	stage.player.position = Vector2(-999, -999)
	stage.player._process(0.016)
	assert_true(stage.arena.floor_rect().has_point(stage.player.position), "벽 안쪽")
	stage.queue_free()


func test_카메라_한계가_맵_전체_크기() -> void:
	var stage := _make_stage()
	await wait_frames()
	var cam: Camera2D = stage.player.get_children().filter(func(n): return n is Camera2D)[0]
	assert_true(cam.position_smoothing_enabled, "부드럽게 따라감")
	assert_eq(Vector2(cam.limit_right - cam.limit_left, cam.limit_bottom - cam.limit_top), Vector2(1440, 3840))
	stage.queue_free()


func test_적이_생기고_몸_공격이_맞혀_쓰러뜨림() -> void:
	var stage := _make_stage()
	await wait_frames()
	# 시작하자마자 적이 하나 생긴다 (생성 타이머가 0에서 시작)
	var enemies := get_tree().get_nodes_in_group("enemies")
	assert_eq(enemies.size(), 1)
	var e: Enemy = enemies[0]
	e.target = null  # 적이 움직이지 않게 고정
	e.position = stage.player.position + Vector2(100, 0)  # 근접 사거리 안
	stage.player.set_process(false)  # 시간을 직접 흘려 결과를 고정
	for i in 400:  # 몸 공격을 맞힘 (적 hp 3, 피해 2 → 2번)
		stage.player._process(1.0 / 60.0)
		if not is_instance_valid(e) or e.is_queued_for_deletion():
			break
	assert_true(not is_instance_valid(e) or e.is_queued_for_deletion(), "적이 쓰러짐 (hp 3, 몸 공격 피해 2 → 2번)")
	stage.queue_free()


func test_적을_삼키면_숨고_몸_안에_비치고_뱉으면_살아서_돌아옴() -> void:
	var stage := _make_stage()
	await wait_frames()
	var e: Enemy = get_tree().get_nodes_in_group("enemies")[0]
	e.target = null
	e.position = stage.player.position + Vector2(150, -Balance.BODY_CENTER_Y)  # 몸 중심 높이, 사거리 안
	var saw_swallow := false
	var saw_wrap := false
	var min_hp := e.hp
	for i in 200:
		await wait_frames()
		if e.swallowed:
			saw_swallow = true
			assert_true(not e.visible, "삼켜진 동안 숨음")
			assert_not_null(stage.player._fx, "몸 안에 비추는 연출 부품이 생김")
		saw_wrap = saw_wrap or stage.player._frame_sprite.visible and stage.player._frame_sprite.texture == Player.FRAMES[BitePose.Frame.WRAP]
		min_hp = mini(min_hp, e.hp)
		if saw_swallow and not e.swallowed:
			break
	assert_true(saw_swallow and saw_wrap, "삼키고 감쌈 프레임을 씀")
	assert_eq(e.hp, Balance.ENEMY_HP - Balance.MELEE_DAMAGE, "피해 한 번")
	assert_true(e.visible and not e.swallowed, "뱉어져 다시 보임")
	assert_true(stage.player._face.look.x > 0.9, "얼굴이 적 쪽(오른쪽)을 봄")
	stage.queue_free()


func test_삼킨_적이_죽으면_뱉지_않고_소화되어_사라짐() -> void:
	var stage := _make_stage()
	await wait_frames()
	var e: Enemy = get_tree().get_nodes_in_group("enemies")[0]
	e.target = null
	e.hp = Balance.MELEE_DAMAGE  # 한 입에 죽음
	e.position = stage.player.position + Vector2(0, -Balance.BODY_CENTER_Y - 150)  # 위쪽
	var min_digest_scale := 1.0
	stage.player.set_process(false)
	for i in 200:
		stage.player._process(1.0 / 60.0)
		if stage.player._fx != null:
			min_digest_scale = minf(min_digest_scale, Swallow.digest_scale(stage.player._fx.digest))
		if not is_instance_valid(e):
			break
	assert_true(not is_instance_valid(e) or e.is_queued_for_deletion(), "적이 사라짐")
	assert_true(min_digest_scale < 0.5, "몸 안에서 작아지며 소화됨 %f" % min_digest_scale)
	for i in 80:
		stage.player._process(1.0 / 60.0)
	assert_true(stage.player._fx == null, "연출 부품이 정리됨")
	stage.queue_free()


func test_가만히_서_있어도_바라보는_쪽으로_몸통이_기움() -> void:
	var stage := _make_stage()
	await wait_frames()
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	stage.player._face.look = Vector2.RIGHT
	await wait_frames(2)
	assert_true(stage.player._rig.transform.y.x < -0.04, "오른쪽을 보면 위쪽이 오른쪽으로 기움 %f" % stage.player._rig.transform.y.x)
	stage.player._face.look = Vector2.LEFT
	await wait_frames(2)
	assert_true(stage.player._rig.transform.y.x > 0.04, "왼쪽을 보면 반대 %f" % stage.player._rig.transform.y.x)
	stage.queue_free()


func test_멀리_있는_적에게는_공격하지_않음() -> void:
	var stage := _make_stage()
	await wait_frames()
	var e: Enemy = get_tree().get_nodes_in_group("enemies")[0]
	e.target = null
	e.position = stage.player.position + Vector2(Balance.MELEE_RANGE + 60.0, 0)
	for i in 60:
		await wait_frames()
	assert_eq(stage.player._attack.phase, AttackCycle.Phase.IDLE, "사거리 밖이면 공격 안 함")
	assert_eq(e.hp, Balance.ENEMY_HP, "체력 그대로")
	stage.queue_free()


func test_적에게_닿으면_체력이_줄고_무적시간_중에는_안_줄고_0이면_쓰러짐() -> void:
	var stage := _make_stage()
	await wait_frames()
	var p := stage.player
	p.hit(1)
	assert_eq(p.hp, Balance.PLAYER_HP - 1)
	p.hit(1)
	assert_eq(p.hp, Balance.PLAYER_HP - 1, "무적 시간")
	for i in Balance.PLAYER_HP:
		p._invuln = 0.0
		p.hit(1)
	assert_eq(p.hp, 0)
	assert_true(p.dead, "쓰러짐")
	stage.queue_free()


func test_적은_슬라임을_향해_다가온다() -> void:
	var stage := _make_stage()
	await wait_frames()
	stage._spawn_enemy()
	var e: Enemy = get_tree().get_nodes_in_group("enemies")[0]
	var before := e.position.distance_to(stage.player.position)
	e._process(0.5)
	assert_true(e.position.distance_to(stage.player.position) < before, "거리가 줄어듦")
	stage.queue_free()
