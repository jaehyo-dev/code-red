class_name Arena
extends RefCounted
## 벽으로 둘러싸인 방 하나의 크기·경계 계산 (화면과 분리). 크기는 Balance의 타일 개수로만 정한다.

## 타일 종류
enum Tile { FLOOR, WALL, WALL_EDGE_TOP, WALL_EDGE_BOTTOM, WALL_EDGE_LEFT, WALL_EDGE_RIGHT }

var map_tiles: Vector2i
var tile: int
var wall: int


func _init(p_map_tiles := Balance.MAP_TILES, p_tile := Balance.TILE, p_wall := Balance.WALL_THICKNESS) -> void:
	map_tiles = p_map_tiles
	tile = p_tile
	wall = p_wall


## 맵 전체 (벽 포함, 픽셀)
func map_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(map_tiles * tile))


## 걸어 다닐 수 있는 바닥 (벽 안쪽, 픽셀)
func floor_rect() -> Rect2:
	return Rect2(Vector2(wall * tile, wall * tile), Vector2((map_tiles - Vector2i(wall * 2, wall * 2)) * tile))


## 반지름 radius인 물체가 벽 밖으로 나가지 않게 위치를 안쪽으로 당긴다.
func clamp_inside(pos: Vector2, radius: float) -> Vector2:
	var r := floor_rect().grow(-radius)
	return Vector2(clampf(pos.x, r.position.x, r.end.x), clampf(pos.y, r.position.y, r.end.y))


## 타일 칸 하나의 종류. 바닥과 맞닿은 벽 안쪽 줄은 EDGE (위·아래 우선).
func tile_kind(cell: Vector2i) -> Tile:
	var lo := wall
	var hi_x := map_tiles.x - wall
	var hi_y := map_tiles.y - wall
	if cell.x >= lo and cell.x < hi_x and cell.y >= lo and cell.y < hi_y:
		return Tile.FLOOR
	if cell.y == lo - 1 and cell.x >= lo - 1 and cell.x <= hi_x:
		return Tile.WALL_EDGE_TOP
	if cell.y == hi_y and cell.x >= lo - 1 and cell.x <= hi_x:
		return Tile.WALL_EDGE_BOTTOM
	if cell.x == lo - 1 and cell.y >= lo and cell.y < hi_y:
		return Tile.WALL_EDGE_LEFT
	if cell.x == hi_x and cell.y >= lo and cell.y < hi_y:
		return Tile.WALL_EDGE_RIGHT
	return Tile.WALL


## 칸마다 항상 같은 변형 번호(0 ~ count-1). 무작위 타일이 실행마다 바뀌지 않게 한다.
static func variant(cell: Vector2i, count: int) -> int:
	return absi(cell.x * 73856093 ^ cell.y * 19349663) % count


## 바닥 안의 무작위 점 (벽에서 margin 이상 떨어진)
func random_point(rng: RandomNumberGenerator, margin: float) -> Vector2:
	var r := floor_rect().grow(-margin)
	return Vector2(rng.randf_range(r.position.x, r.end.x), rng.randf_range(r.position.y, r.end.y))


## avoid에서 min_dist 이상 떨어진 무작위 점. 30번 시도해도 없으면 마지막 후보를 그대로 쓴다.
func random_point_away(rng: RandomNumberGenerator, margin: float, avoid: Vector2, min_dist: float) -> Vector2:
	var p := random_point(rng, margin)
	for i in 30:
		if p.distance_to(avoid) >= min_dist:
			break
		p = random_point(rng, margin)
	return p
