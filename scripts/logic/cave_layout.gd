class_name CaveLayout
extends RefCounted
## 동굴 방의 장식 오브젝트 배치 (화면과 분리). 같은 시드면 항상 같은 배치가 나온다.

## 종류별 개수 / 다른 오브젝트와 최소 간격 / 벽 가까이에만 둘지
const KINDS := {
	"crystal": {"count": 8, "gap": 260.0, "near_wall": true},
	"mushroom": {"count": 12, "gap": 150.0, "near_wall": true},
	"rubble": {"count": 8, "gap": 220.0, "near_wall": false},
	"bones": {"count": 6, "gap": 260.0, "near_wall": false},
	"pot": {"count": 5, "gap": 260.0, "near_wall": false},
	"campfire": {"count": 3, "gap": 700.0, "near_wall": false},
}
## 벽 가까이 = 바닥 가장자리에서 이 거리 안
const WALL_BAND := 130.0
## 오브젝트가 벽·슬라임 시작 위치와 겹치지 않게 하는 여백
const MARGIN := 60.0
const SPAWN_CLEAR := 220.0


## 반환: [{"kind": String, "pos": Vector2}, ...]. 간격을 지킬 자리를 못 찾은 오브젝트는 건너뛴다.
static func generate(arena: Arena, rng_seed: int, spawn_pos: Vector2) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var placed: Array = []
	# 모닥불처럼 간격이 큰 것부터 놓아야 자리가 남는다
	var order := KINDS.keys()
	order.sort_custom(func(a, b): return KINDS[a]["gap"] > KINDS[b]["gap"])
	for kind: String in order:
		var spec: Dictionary = KINDS[kind]
		for i in int(spec["count"]):
			for attempt in 40:
				var pos := _candidate(arena, rng, spec["near_wall"])
				if pos.distance_to(spawn_pos) < SPAWN_CLEAR:
					continue
				if _too_close(placed, pos, float(spec["gap"])):
					continue
				placed.append({"kind": kind, "pos": pos})
				break
	return placed


static func _candidate(arena: Arena, rng: RandomNumberGenerator, near_wall: bool) -> Vector2:
	var p := arena.random_point(rng, MARGIN)
	if not near_wall:
		return p
	# 네 변 중 하나로 끌어당겨 벽 가까이에 둔다
	var r := arena.floor_rect().grow(-MARGIN)
	var band := rng.randf_range(0.0, WALL_BAND - MARGIN)
	match rng.randi_range(0, 3):
		0: p.x = r.position.x + band
		1: p.x = r.end.x - band
		2: p.y = r.position.y + band
		_: p.y = r.end.y - band
	return p


static func _too_close(placed: Array, pos: Vector2, gap: float) -> bool:
	for o: Dictionary in placed:
		# 이미 놓인 것의 간격과 이번 간격 중 작은 쪽을 지킨다 (큰 오브젝트끼리만 멀리 떨어지게)
		if pos.distance_to(o["pos"]) < minf(gap, KINDS[o["kind"]]["gap"]):
			return true
	return false
