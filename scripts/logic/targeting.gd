class_name Targeting
extends RefCounted
## 자동 공격 대상 고르기 (화면과 분리).


## origin에서 range_max 이하인 점 중 가장 가까운 것의 위치. 없으면 null.
static func nearest(origin: Vector2, points: Array, range_max: float) -> Variant:
	var best: Variant = null
	var best_d := range_max * range_max
	for p: Vector2 in points:
		var d := origin.distance_squared_to(p)
		if d <= best_d:
			best_d = d
			best = p
	return best

