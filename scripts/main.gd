extends Control
## 시작 화면 (세팅 단계의 빈 화면). 버전은 project.godot 한 곳에서 읽어 보여 준다.


func _ready() -> void:
	%VersionLabel.text = "v" + str(ProjectSettings.get_setting("application/config/version"))
