class_name Balance
extends RefCounted
## 게임 플레이 수치를 한곳에 모아 둔다. 맵 크기는 타일 개수만 바꾸면 된다.

# --- 맵 (타일 1칸 = 도트 16칸 x 3 = 48픽셀) ---
const TILE := 48
## 가로 2화면 x 세로 3화면 (720x1280 기준 약 1440x3840)
const MAP_TILES := Vector2i(30, 80)
## 바깥 벽 두께 (타일 개수)
const WALL_THICKNESS := 3

# --- 슬라임 ---
const PLAYER_SPEED := 270.0
const PLAYER_HP := 5
const PLAYER_RADIUS := 30.0
## 맞은 뒤 무적 시간 (초)
const PLAYER_INVULN := 0.8

# --- 적 (동굴 딱정벌레) ---
const ENEMY_SPEED := 95.0
const ENEMY_HP := 3
const ENEMY_RADIUS := 21.0
const ENEMY_DAMAGE := 1
const ENEMY_MAX := 8
const ENEMY_SPAWN_INTERVAL := 1.5
## 슬라임에게서 이 거리 이상 떨어진 곳에서 나타남
const ENEMY_SPAWN_MIN_DIST := 520.0

# --- 자동 공격: 점액탄 ---
const ATTACK_INTERVAL := 0.45
const ATTACK_RANGE := 440.0
const GLOB_SPEED := 560.0
const GLOB_DAMAGE := 1
const GLOB_RADIUS := 9.0
const GLOB_LIFETIME := 1.2

# --- 조작·카메라 ---
const JOYSTICK_RADIUS := 90.0
const JOYSTICK_DEADZONE := 0.15
const CAMERA_SMOOTHING := 6.0

# --- 조명 ---
## 동굴 전체를 어둡게 하는 색
const CAVE_DARKNESS := Color(0.55, 0.58, 0.80)
