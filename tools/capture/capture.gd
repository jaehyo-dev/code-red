extends Node
## GIF 캡처용 장면 (게임에는 쓰이지 않음). 정해진 시나리오로 슬라임을 움직이고 공격시킨 뒤 끝낸다.
## 사용: godot --path . --write-movie out.avi --fixed-fps 30 res://tools/capture/capture.tscn -- attack|turn
## 그 뒤 ffmpeg로 avi를 GIF로 바꾼다 (tools/capture/README 없이 CLAUDE.md의 화면 확인 규칙을 따름).

const FPS := 30
var _scenario := "attack"
var _frame := 0
var _stage: Stage
var _timeline: Array = []


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_scenario = args[0]
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	_stage = main.get_node("%Stage")
	_stage.player.position = _stage.arena.floor_rect().get_center()  # 카메라가 슬라임을 가운데에 두도록
	_stage.set_process(false)  # 자동 적 생성과 입력 대신 이 스크립트가 조종한다
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	# 시나리오: [시작 초, 동작]
	if _scenario == "attack":
		_timeline = [[0.3, "enemy", Vector2(110, -40)], [1.5, "enemy", Vector2(-100, 50)], [2.9, "enemy", Vector2(10, -105)]]
	else:
		_timeline = [[0.4, "move", Vector2.RIGHT], [1.2, "move", Vector2.UP], [2.0, "move", Vector2.LEFT], [2.8, "move", Vector2.DOWN], [3.6, "move", Vector2.ZERO]]


func _process(_delta: float) -> void:
	var t := _frame / float(FPS)
	for step in _timeline:
		if absf(t - step[0]) < 0.5 / FPS:
			if step[1] == "enemy":
				var e := Enemy.new()
				e.position = _stage.player.position + step[2]
				_stage._world.add_child(e)  # target 없음: 가만히 서서 맞는다
			else:
				_stage.player.move_input = step[2]
	_frame += 1
	if t > (4.6 if _scenario == "turn" else 4.2):
		get_tree().quit()
