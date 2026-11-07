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


func test_적이_생기고_자동_공격이_맞혀_쓰러뜨림() -> void:
	var stage := _make_stage()
	await wait_frames()
	# 시작하자마자 적이 하나 생긴다 (생성 타이머가 0에서 시작)
	var enemies := get_tree().get_nodes_in_group("enemies")
	assert_eq(enemies.size(), 1)
	var e: Enemy = enemies[0]
	e.position = stage.player.position + Vector2(200, 0)  # 사거리 안
	stage.player._fire()
	assert_eq(stage._world.get_children().filter(func(n): return n is Glob).size(), 1, "점액탄 발사")
	for i in 240:  # 시간을 흘려 점액탄을 맞힘 (적 hp 3 → 3발)
		await wait_frames()
		if not is_instance_valid(e) or e.is_queued_for_deletion():
			break
		stage.player._attack_cd = 0.0
	assert_true(not is_instance_valid(e) or e.is_queued_for_deletion(), "적이 쓰러짐 (hp 3 → 점액탄 3발)")
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
