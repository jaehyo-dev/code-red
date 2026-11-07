class_name Stage
extends Node2D
## 단일 방 스테이지: 타일맵 바닥·벽, 장식 오브젝트, 슬라임, 적 생성, 카메라, 조명.

signal player_died

## 0이면 실행마다 다른 무작위, 0이 아니면 항상 같은 배치·적 위치 (테스트용)
@export var rng_seed := 0

var arena := Arena.new()
var player: Player
## 조이스틱 입력 (main이 연결). 없으면 방향키·WASD로 움직인다.
var joystick: Joystick
var _rng := RandomNumberGenerator.new()
var _world: Node2D
var _spawn_cd := 0.0
var _fires: Array[PointLight2D] = []
var _time := 0.0


func _ready() -> void:
	if rng_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = rng_seed
	# 동굴 전체를 어둡게: 빛이 있는 곳만 밝다
	var dark := CanvasModulate.new()
	dark.color = Balance.CAVE_DARKNESS
	add_child(dark)
	_build_tiles()
	# Y 정렬 월드: 아래쪽에 있는 것이 위에 그려진다
	_world = Node2D.new()
	_world.y_sort_enabled = true
	add_child(_world)
	var start := arena.floor_rect().get_center() + Vector2(0, arena.floor_rect().size.y * 0.3)
	_build_objects(start)
	_build_player(start)


func _build_tiles() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(Balance.TILE, Balance.TILE)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load("res://assets/tiles/tiles.png")
	atlas.texture_region_size = ts.tile_size
	for y in 3:
		for x in 4:
			atlas.create_tile(Vector2i(x, y))
	ts.add_source(atlas, 0)
	var layer := TileMapLayer.new()
	layer.tile_set = ts
	layer.z_index = -10
	add_child(layer)
	for y in arena.map_tiles.y:
		for x in arena.map_tiles.x:
			var cell := Vector2i(x, y)
			var coords: Vector2i
			match arena.tile_kind(cell):
				Arena.Tile.FLOOR: coords = Vector2i(Arena.variant(cell, 4), 0)
				Arena.Tile.WALL: coords = Vector2i(Arena.variant(cell, 3), 1)
				Arena.Tile.WALL_EDGE_TOP: coords = Vector2i(0, 2)
				Arena.Tile.WALL_EDGE_BOTTOM: coords = Vector2i(1, 2)
				Arena.Tile.WALL_EDGE_LEFT: coords = Vector2i(2, 2)
				_: coords = Vector2i(3, 2)
			layer.set_cell(cell, 0, coords)


func _build_objects(start: Vector2) -> void:
	# 장식 배치는 실행 난수와 별개로 고정 시드 (방 모양이 매번 같다)
	for o: Dictionary in CaveLayout.generate(arena, 1234, start):
		var holder := Node2D.new()
		holder.position = o["pos"]
		var kind: String = o["kind"]
		var s := Art.sprite_feet(kind)
		holder.add_child(s)
		var light := _light_for(kind)
		if light != null:
			light.position = s.position
			holder.add_child(light)
			if kind == "campfire":
				_fires.append(light)
		_world.add_child(holder)


## 빛이 나는 오브젝트만 조명을 단다 (수정·버섯·모닥불)
func _light_for(kind: String) -> PointLight2D:
	match kind:
		"crystal": return Art.light(Color(0.35, 0.85, 1.0), 170.0, 0.9)
		"mushroom": return Art.light(Color(0.3, 1.0, 0.85), 95.0, 0.8)
		"campfire": return Art.light(Color(1.0, 0.6, 0.25), 300.0, 1.2)
	return null


func _build_player(start: Vector2) -> void:
	player = Player.new()
	player.arena = arena
	player.position = start
	player.died.connect(func(): player_died.emit())
	_world.add_child(player)
	# 카메라: 슬라임을 부드럽게 따라가고 맵 가장자리에서 멈춘다 (limit이 벽 밖을 가림)
	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = Balance.CAMERA_SMOOTHING
	var m := arena.map_rect()
	cam.limit_left = int(m.position.x)
	cam.limit_top = int(m.position.y)
	cam.limit_right = int(m.end.x)
	cam.limit_bottom = int(m.end.y)
	player.add_child(cam)


func _process(delta: float) -> void:
	_time += delta
	# 모닥불 불빛이 일렁이게
	for i in _fires.size():
		_fires[i].energy = 1.2 + sin(_time * 9.0 + i * 2.0) * 0.12
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if joystick != null and joystick.active:
		dir = joystick.vector
	player.move_input = dir
	if player.dead:
		return
	_spawn_cd -= delta
	if _spawn_cd <= 0.0 and get_tree().get_nodes_in_group("enemies").size() < Balance.ENEMY_MAX:
		_spawn_cd = Balance.ENEMY_SPAWN_INTERVAL
		_spawn_enemy()


func _spawn_enemy() -> void:
	var e := Enemy.new()
	e.target = player
	e.position = arena.random_point_away(_rng, 60.0, player.position, Balance.ENEMY_SPAWN_MIN_DIST)
	_world.add_child(e)
