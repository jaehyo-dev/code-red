extends TestCase
## 스프라이트·타일이 3픽셀 격자로 정리되어 있는지 확인한다 (도트 1칸 = 3x3 픽셀 한 색).

const DIRS := ["res://assets/sprites", "res://assets/tiles"]


func test_모든_스프라이트와_타일은_3픽셀_격자() -> void:
	var count := 0
	for dir in DIRS:
		for f in DirAccess.get_files_at(dir):
			if not f.ends_with(".png"):
				continue
			count += 1
			var img: Image = load(dir + "/" + f).get_image()
			assert_eq(img.get_width() % 3, 0, f + " 가로가 3의 배수")
			assert_eq(img.get_height() % 3, 0, f + " 세로가 3의 배수")
			assert_true(_is_grid(img), f + " 3x3 칸마다 한 색")
	assert_true(count >= 10, "스프라이트 10장 이상: %d" % count)


func _is_grid(img: Image) -> bool:
	for y in range(0, img.get_height(), 3):
		for x in range(0, img.get_width(), 3):
			var c := img.get_pixel(x, y)
			for dy in 3:
				for dx in 3:
					var o := img.get_pixel(x + dx, y + dy)
					# 투명 칸은 가져오기가 색을 바꿔 놓으므로(알파 테두리 보정) 투명끼리는 같은 것으로 본다
					if o != c and not (o.a == 0.0 and c.a == 0.0):
						return false
	return true
