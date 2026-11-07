extends TestCase
## 조이스틱·조준·방(Arena)·장식 배치 로직 테스트 (화면 없이 직접 호출).


func test_조이스틱_데드존_안은_0() -> void:
	assert_eq(JoystickMath.vector(Vector2(100, 100), Vector2(105, 100), 90.0, 0.15), Vector2.ZERO)


func test_조이스틱_반지름_안은_비례하고_밖은_길이_1() -> void:
	var half := JoystickMath.vector(Vector2.ZERO, Vector2(45, 0), 90.0, 0.15)
	assert_eq(half, Vector2(0.5, 0))
	var far := JoystickMath.vector(Vector2.ZERO, Vector2(0, 900), 90.0, 0.15)
	assert_eq(far, Vector2(0, 1))


func test_가장_가까운_적을_고르고_사거리_밖은_무시() -> void:
	var pts := [Vector2(300, 0), Vector2(100, 0), Vector2(-200, 0)]
	assert_eq(Targeting.nearest(Vector2.ZERO, pts, 250.0), Vector2(100, 0))
	assert_eq(Targeting.nearest(Vector2.ZERO, pts, 50.0), null)
	assert_eq(Targeting.nearest(Vector2.ZERO, [], 500.0), null)


func test_맵_크기는_타일_개수에서_나옴() -> void:
	var a := Arena.new(Vector2i(30, 80), 48, 3)
	assert_eq(a.map_rect().size, Vector2(1440, 3840))
	assert_eq(a.floor_rect(), Rect2(144, 144, 1152, 3552))
	# 타일 개수만 바꿔도 따라 바뀐다
	assert_eq(Arena.new(Vector2i(10, 20), 48, 3).map_rect().size, Vector2(480, 960))


func test_밖으로_나가려는_위치를_바닥_안으로_당김() -> void:
	var a := Arena.new()
	var f := a.floor_rect()
	assert_eq(a.clamp_inside(Vector2(-500, -500), 30.0), f.position + Vector2(30, 30))
	assert_eq(a.clamp_inside(Vector2(9999, 9999), 30.0), f.end - Vector2(30, 30))
	assert_eq(a.clamp_inside(f.get_center(), 30.0), f.get_center())


func test_타일_종류_바닥_벽_안쪽줄() -> void:
	var a := Arena.new(Vector2i(30, 80), 48, 3)
	assert_eq(a.tile_kind(Vector2i(15, 40)), Arena.Tile.FLOOR)
	assert_eq(a.tile_kind(Vector2i(0, 0)), Arena.Tile.WALL)
	assert_eq(a.tile_kind(Vector2i(15, 2)), Arena.Tile.WALL_EDGE_TOP)
	assert_eq(a.tile_kind(Vector2i(15, 77)), Arena.Tile.WALL_EDGE_BOTTOM)
	assert_eq(a.tile_kind(Vector2i(2, 40)), Arena.Tile.WALL_EDGE_LEFT)
	assert_eq(a.tile_kind(Vector2i(27, 40)), Arena.Tile.WALL_EDGE_RIGHT)
	assert_eq(a.tile_kind(Vector2i(15, 1)), Arena.Tile.WALL)


func test_타일_변형은_항상_같고_범위_안() -> void:
	for y in 20:
		for x in 20:
			var v := Arena.variant(Vector2i(x, y), 4)
			assert_true(v >= 0 and v < 4, "변형 범위")
			assert_eq(v, Arena.variant(Vector2i(x, y), 4))


func test_장식_배치는_시드가_같으면_같고_모두_바닥_안() -> void:
	var a := Arena.new()
	var start := Vector2(720, 2800)
	var one := CaveLayout.generate(a, 1234, start)
	assert_eq(one, CaveLayout.generate(a, 1234, start), "같은 시드")
	assert_true(one != CaveLayout.generate(a, 99, start), "다른 시드")
	var counts := {}
	for o: Dictionary in one:
		assert_true(a.floor_rect().has_point(o["pos"]), "바닥 안: %s" % o["pos"])
		assert_true((o["pos"] as Vector2).distance_to(start) >= CaveLayout.SPAWN_CLEAR, "시작 위치 비움")
		counts[o["kind"]] = counts.get(o["kind"], 0) + 1
	# 요청한 6종이 모두 나온다
	for kind in ["crystal", "mushroom", "rubble", "bones", "pot", "campfire"]:
		assert_true(counts.get(kind, 0) > 0, "%s 배치됨" % kind)


func test_적_생성_위치는_슬라임에서_멀다() -> void:
	var a := Arena.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var me := a.floor_rect().get_center()
	for i in 20:
		var p := a.random_point_away(rng, 60.0, me, 500.0)
		assert_true(a.floor_rect().has_point(p))
		assert_true(p.distance_to(me) >= 500.0)
