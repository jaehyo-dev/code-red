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

# --- 몸 공격 (한 입에 삼키기): 웅크림 → 입 벌림(솟으며 다가감) → 감쌈(피해) → 뱉으며 복귀 → 쿨다운 ---
## 가장 가까운 적이 이 거리(슬라임 몸 중심 기준) 안에 들어오면 공격을 시작한다. 입 벌림이 끝날 때 이 거리 + 적 반지름 안에 있어야 삼킨다
const MELEE_RANGE := 190.0
const MELEE_DAMAGE := 2
## 삼켰다 뱉을 때 적이 날아가는 거리
const MELEE_KNOCKBACK := 60.0
const ATTACK_WINDUP := 0.22
const ATTACK_OPEN := 0.20
const ATTACK_ENGULF := 0.40
const ATTACK_RECOVER := 0.28
const ATTACK_COOLDOWN := 0.20
## 감싸는 단계가 이만큼(0~1) 진행했을 때 피해를 준다 (몸이 적을 덮친 직후)
const ENGULF_HIT_AT := 0.35
## 맞은 적이 하얗게 번쩍이는 시간
const HIT_FLASH := 0.1
## 피해 순간 슬라임이 멈추는 시간 (히트스톱)
const HITSTOP := 0.07
## 공격 중(준비~복귀) 이동 속도 배율. 0이면 멈춤. 느려지게 둬서 덮칠 방향은 지키되 조작이 끊기지 않게 한다
const ATTACK_MOVE_MULT := 0.35
## 웅크릴 때 몸이 뒤로 물러나는 거리 (픽셀)
const BITE_PULLBACK := 12.0
## 입 벌림이 끝났을 때 적까지 거리의 이만큼(0~1)을 이미 다가가 있다 (나머지는 감싸며 덮침)
const BITE_OPEN_REACH := 0.6
## 웅크림 때 몸이 퍼지고 낮아지는 정도 / 입 벌림 끝에 솟아 길어지는 정도 (가로, 세로 배율)
const BITE_CROUCH := Vector2(1.15, 0.8)
const BITE_RISE := Vector2(0.92, 1.1)

# --- 삼키는 연출 (몸 안에 비친 대상): 아이템·생명체 삼키기에서도 재사용 ---
## 몸 안에서 대상이 줄어드는 크기 배율 / 비치는 투명도 / 비치는 색 / 꿀럭거림 속도·크기
const SWALLOW_INNER_SCALE := 0.6
const SWALLOW_ALPHA := 0.65
const SWALLOW_TINT := Color(1.0, 0.7, 1.0)
const SWALLOW_WOBBLE_SPEED := 22.0
const SWALLOW_WOBBLE := 0.07
## 대상을 뱉은 뒤 별이 반짝이는 시간
const SPARKLE_TIME := 0.6

# --- 몸 크기 (도트 단위: 슬라임 스프라이트는 26x35도트) ---
## 슬라임 몸의 반 크기 (도트, 몸 중심은 위에서 18번째 줄)
const SLIME_HALF := Vector2(13.0, 18.0)
## 슬라임 발(노드 위치)에서 몸 중심까지의 높이 (픽셀). 사거리·조준은 몸 중심 기준이다
const BODY_CENTER_Y := 51.0

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

# --- 몸통 비틀기 (정지해도 바라보는 방향이 몸에서 보이게) ---
## 바라보는 쪽으로 몸 위쪽이 기우는 비율 / 몸이 쏠리는 도트 / 위를 볼 때 길어지고 아래를 볼 때 낮아지는 비율
const TWIST_SHEAR := 0.08
const TWIST_SHIFT := 1.0
const TWIST_VERT := 0.05

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
