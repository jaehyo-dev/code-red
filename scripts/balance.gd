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

# --- 몸 공격 (덮치기): 준비(웅크림) → 타격(몸이 늘어나며 튀어나감) → 복귀(눌렸다 튕김) → 쿨다운 ---
## 가장 가까운 적이 이 거리(슬라임 몸 중심 기준) 안에 들어오면 공격을 시작한다
const MELEE_RANGE := 190.0
## 몸이 닿는 거리. 적의 반지름만큼 더해서 판정한다
const MELEE_REACH := 190.0
## 타격 부채꼴 절반 각도(도). 덮치는 방향 앞쪽만 맞는다
const MELEE_HALF_ARC_DEG := 30.0
const MELEE_DAMAGE := 2
## 맞은 적이 밀려나는 거리
const MELEE_KNOCKBACK := 24.0
const ATTACK_WINDUP := 0.28
const ATTACK_STRIKE := 0.12
const ATTACK_RECOVER := 0.30
const ATTACK_COOLDOWN := 0.25
## 타격 단계가 이만큼(0~1) 진행했을 때 적에게 닿는다 (몸이 거의 다 늘어난 순간)
const ATTACK_HIT_AT := 0.8
## 맞은 적이 하얗게 번쩍이는 시간
const HIT_FLASH := 0.1
## 타격 순간 슬라임과 맞은 적이 멈추는 시간 (히트스톱)
const HITSTOP := 0.05
## 공격 중(준비~복귀) 이동 속도 배율. 0이면 멈춤. 느려지게 둬서 덮칠 방향은 지키되 조작이 끊기지 않게 한다
const ATTACK_MOVE_MULT := 0.35

# --- 덮치기 모양 (도트 단위: 슬라임 스프라이트는 26x35도트) ---
## 덮치기 모양 안: 0 = 안 A(늘어남 위주), 1 = 안 B(짧은 돌진). 이 값 하나로 바꾼다
const STYLE_STRETCH := 0
const STYLE_HOP := 1
const ATTACK_STYLE := STYLE_HOP
## 슬라임 몸의 반 크기 (도트, 몸 중심은 위에서 18번째 줄)
const SLIME_HALF := Vector2(13.0, 18.0)
## 슬라임 발(노드 위치)에서 몸 중심까지의 높이 (픽셀). 사거리·조준은 몸 중심 기준이다
const BODY_CENTER_Y := 51.0
## 덮칠 때 몸의 앞쪽 끝이 닿는 거리 (몸 중심에서, 도트): 사거리 끝의 적 가장자리에 살짝 겹침
const LUNGE_TIP_DOTS := (MELEE_RANGE - ENEMY_RADIUS) / 3.0 + 1.0
## 늘어난 만큼 옆이 가늘어지는 정도 (1 = 넓이 보존, 0 = 안 가늘어짐)
const LUNGE_VOLUME := 0.7
## 안 A: 최대 늘어남 배율 / 웅크릴 때 길이 / 웅크릴 때 뒤로 물러나는 도트. 모자란 거리는 몸이 앞으로 밀려 채움
const A_MAX_STRETCH := 1.9
const A_CROUCH := 0.78
const A_PULLBACK := 6.0
## 안 B: 앞으로 튀어나가는 도트(23도트 = 약 70픽셀) / 웅크릴 때 길이 / 뒤로 물러나는 도트. 늘어남은 남는 거리만큼만
const B_HOP_DOTS := 23.0
const B_CROUCH := 0.88
const B_PULLBACK := 2.0

# --- 슬라임 모션 (늘어남·찌그러짐 비율. 0.2 = 20%) ---
const BREATH_SPEED := 2.6
const BREATH_AMOUNT := 0.04
## 이동 속도를 따라가는 부드러움 (클수록 빨리 따라감)
const MOVE_FOLLOW := 10.0
## 가속·감속(관성)이 변형에 미치는 정도
const MOVE_INERTIA := 0.008
## 이동 방향으로 몸이 기우는 정도 (위쪽이 옆으로 밀리는 비율, 속도에 비례)
const MOVE_LEAN := 0.08
## 머리 위 곡선이 이동 반대쪽으로 끌려오는 정도와 그 스프링
const CREST_DRAG := 0.35
const CREST_STIFFNESS := 140.0
const CREST_DAMPING := 18.0
## 이동 리듬(기어가기): 최대 속도에서 한 주기 시간(초). 속도가 느리면 주기가 길어진다
const GAIT_PERIOD := 0.35
## 최대 속도에서 이동 방향 길이가 변하는 비율(±), 몸 중심이 앞뒤로 움직이는 도트. 둘 다 속도의 제곱에 비례해 작은 입력엔 거의 안 움직인다
const GAIT_STRETCH := 0.20
const GAIT_SHIFT := 3.0
## 늘어남·찌그러짐 스프링: 강성, 감쇠 (감쇠가 작을수록 많이 출렁임)
const SPRING_STIFFNESS := 220.0
const SPRING_DAMPING := 22.0
## 맞았을 때 스프링에 주는 충격 (옆으로 퍼지고 납작해짐)
const HIT_KICK := Vector2(11.0, -11.0)
const PLAYER_FLASH := 0.12

# --- 얼굴 (눈·입 레이어가 바라보는 쪽으로 쏠림) ---
const FACE_FOLLOW := 14.0
## 옆/아래로 쏠리는 최대 도트, 위로 올라가는 최대 도트
const FACE_SHIFT := Vector2(4.0, 3.0)
const FACE_RISE := 6.0
## 이 값보다 위를 보면 눈이 작아진다 (-1 = 바로 위)
const FACE_SMALL_EYES_LOOK := -0.5

# --- 조작·카메라 ---
const JOYSTICK_RADIUS := 90.0
const JOYSTICK_DEADZONE := 0.15
const CAMERA_SMOOTHING := 6.0

# --- 조명 ---
## 동굴 전체를 어둡게 하는 색
const CAVE_DARKNESS := Color(0.55, 0.58, 0.80)
