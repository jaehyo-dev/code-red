extends Control
## 시작 화면 겸 HUD: 스테이지를 시작하고, 체력·버전·쓰러짐 안내를 보여 준다.
## 버전은 project.godot 한 곳에서 읽어 보여 준다.


func _ready() -> void:
	%VersionLabel.text = "v" + str(ProjectSettings.get_setting("application/config/version"))
	var stage: Stage = %Stage
	stage.joystick = %Joystick
	_show_hp(stage.player.hp)
	stage.player.hp_changed.connect(_show_hp)
	stage.player_died.connect(func(): %GameOverLabel.show())


func _show_hp(hp: int) -> void:
	%HpLabel.text = "HP %d / %d" % [hp, Balance.PLAYER_HP]


## 쓰러진 뒤 화면을 누르면 다시 시작
func _input(event: InputEvent) -> void:
	if %GameOverLabel.visible and event is InputEventScreenTouch and event.pressed:
		get_tree().reload_current_scene()
