extends Node
## GIF 캡처용 장면 (게임에는 쓰이지 않음). 정해진 시나리오로 슬라임을 움직이고 공격시킨 뒤 끝낸다.
## 사용: godot --path . --write-movie out.avi --fixed-fps 60 res://tools/capture/capture.tscn -- attack [stretch|hop]
##       (시나리오: attack = 적 3마리 차례로 덮치기, turn = 가만히→출발→방향 전환→멈춤)
## 도트가 선명하게 찍히도록 실행 전에 프로젝트 폴더에 override.cfg(창 크기 덮어쓰기 해제)를 임시로 만들고, 끝나면 지운다 (tools/capture/run.sh).
## 그 뒤 ffmpeg로 avi를 GIF로 바꾼다 (보통 속도는 30fps로 줄이고, 0.5배속은 60fps 프레임을 30fps로 틀어 만든다).

const FPS := 60
var _scenario := "attack"
var _frame := 0
var _stage: Stage
var _timeline: Array = []


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_scenario = args[0]
	if args.size() > 1:  # 덮치기 모양 안을 상수 대신 여기서 고른다
		LungePose.style = Balance.STYLE_STRETCH if args[1] == "stretch" else Balance.STYLE_HOP
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	_stage = main.get_node("%Stage")
	_stage.player.position = _stage.arena.floor_rect().get_center()  # 카메라가 슬라임을 가운데에 두도록
	_stage.set_process(false)  # 자동 적 생성과 입력 대신 이 스크립트가 조종한다
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	# 시나리오: [시작 초, 동작, 값]. 적 위치는 몸 중심 기준 (사거리 190 안, 가장자리가 닿을 만큼)
	var c := Vector2(0, -Balance.BODY_CENTER_Y)
	if _scenario == "attack":
		_timeline = [[0.3, "enemy", c + Vector2(180, 0)], [1.8, "enemy", c + Vector2(0, -170)], [3.3, "enemy", c + Vector2(-150, 40)]]
	else:
		# 가만히 → 살짝 밀기 → 최고 속도 → 방향 전환 → 멈춤
		_timeline = [[0.8, "move", Vector2.RIGHT * 0.3], [1.6, "move", Vector2.RIGHT], [2.5, "move", Vector2.UP], [3.3, "move", Vector2.LEFT], [4.1, "move", Vector2.ZERO]]


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
	if t > (5.8 if _scenario == "turn" else 5.0):
		get_tree().quit()
