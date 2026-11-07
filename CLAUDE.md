# 프로젝트 규칙

코드:레드(가칭): Godot 4 (GDScript)로 만드는 도트 그래픽 모바일 웨이브 서바이벌. 진한 보라색 슬라임 돌연변이(베놈 느낌)가 지형·물건·생명체를 삼켜 무기로 쓴다. 설계는 [GAME_SPEC.md](GAME_SPEC.md)를 따른다.

## 게임 요약

- 기본 공격은 몸으로(촉수·덮치기, 총알 없음). 원거리·장판 공격은 삼킨 아이템에서만 나옴(v0.3.0). 성장은 삼키기 → DNA → 진화 하나뿐(경험치·레벨업 없음).
- 세로 720x1280, 자동 공격 + 가상 조이스틱 이동, 웹(GitHub Pages) 배포.
- 삼킨 아이템은 무기가 되고, 무기끼리 융합 가능 (예: 돌 + 불 = 파이어볼).
- 생명체를 삼키면 DNA를 얻고, DNA로 영구 스탯이 오름 (진화).
- 시대별 스테이지 (원시 → 석기 → 철기 …), 웨이브 방식, 중간보스와 시대 보스.
- 에셋은 오픈소스(Kenney, OpenGameArt, itch.io CC0)를 우선 쓰고 출처는 CREDITS.md에 기록.

## 기본

- 나는 웹 개발을 공부하는 학생이야. 한국어로 대화하고, 코드에는 한국어 주석을 달아줘.
- 너는 이 프로젝트의 리더야. 계획을 세우고 작업을 나누고 최종 판단을 해.
- 기본 브랜치는 `main`이야.

## 판단 기준

- 되돌릴 수 있는 결정(수치, 디자인 세부, 파일 구조, 버전 번호, 작업 순서)은 묻지 말고 합리적으로 정해서 진행하고 보고에 "내가 판단한 것"으로 적어.
- 다음 경우에만 멈추고 물어봐:
  - 되돌리기 어려운 작업 (기록 다시 쓰기, 강제 푸시, 파일·브랜치·태그·릴리스 삭제, 저장소 설정 변경)
  - 비용, 계정, 보안, 개인정보
  - 내 요청끼리 충돌할 때
- 막히면 먼저 스스로 다른 방법을 찾고, 그래도 안 되면 내가 할 일을 한 번에 정리해서 알려줘.

## 단계별 진행

- 한 번에 한 단계만 만들어. 끝나면(최종 검토 통과 + main 푸시) 멈춰서 보고해. 내가 자동 진행을 허락한 경우에만 다음 단계로 넘어가. 다음 단계 기능을 미리 만들지 마.
- 단계 계획과 상태는 [PROGRESS.md](PROGRESS.md)의 표를 따른다 (v0.1.1 ~ v0.7.0).
- 단계마다: 테스트 → 네 코드 리뷰 → final-reviewer 최종 검토 → 통과하면 main에 푸시.
- 버전 하나를 끝내고 보고하면, 다음 작업 전에 /clear를 하라고 알려줘.
- 보고에 넣을 것: 만든 것, 내가 판단한 것(이유 포함), 리뷰 지적과 반영 여부, 검토 결과(테스트 결과 포함), 내가 직접 확인할 부분(PC·휴대폰 조작), 저장소·게임 주소, 다음 단계 한 줄.
  - 저장소: https://github.com/jaehyo-dev/code-red
  - 게임: https://jaehyo-dev.github.io/code-red/

## 테스트 방법

Godot 4.7.2 (`.github/workflows/deploy.yml`의 `GODOT_VERSION`과 같은 버전). 이 PC에서는 `GODOT=~/Downloads/Godot.app/Contents/MacOS/Godot`.

```bash
# 1) 리소스 가져오기 (반드시 먼저. 새로 받은 저장소, .godot/ 삭제 후, class_name 추가·변경 후)
godot --headless --path . --import
# 2) 게임 자동 테스트 (tests/test_*.gd)
bash tests/run_tests.sh
# 3) 도구·버전 자동 테스트 (tools/test_*.py)
python3 -m unittest discover -s tools -p "test_*.py" -v
# 4) 웹 내보내기 확인 (웹 내보내기 템플릿 필요)
mkdir -p build/web
godot --headless --path . --export-release "Web" "$PWD/build/web/index.html"
```

- 출력뿐 아니라 종료 코드까지 확인해. 게임 테스트는 `godot -s`로 직접 부르지 말고 `tests/run_tests.sh`로 실행해 (Godot는 파싱 실패에도 종료 코드 0이라, 래퍼가 "결과:" 줄을 확인해 실패로 바꿔 줌).
- 테스트 작성: `tests/test_이름.gd`에서 `extends TestCase`, `test_`로 시작하는 함수에서 `assert_eq`, `assert_true` 등을 써.
- 로직(계산, 점수, 저장, 융합 규칙 등)은 화면·노드와 분리해 `scripts/logic/`에 두고 직접 호출해 자동 테스트해. 무작위 값은 시드를 받게 해서 결과를 고정해.
- 게임 플레이 수치는 `scripts/balance.gd` 한곳에 모아 둬 (v0.1.0에서 만든다).
- 화면 확인: 웹으로 내보내 로컬 서버로 열고 PC(1280x720)와 휴대폰(390x844) 크기로 직접 확인해. 콘솔 오류가 없어야 해. 캡처는 바뀐 화면만, 필요한 크기만 찍어.
- GitHub Actions가 모든 브랜치 푸시마다 1~4를 실행해. 작업 브랜치에 푸시하면 Actions 결과도 확인해.

## 코드 리뷰와 최종 검토

- 리뷰 지적(네 리뷰, Codex, 검토자)은 그대로 받아들이지 말고 하나씩 "수용 / 거절 + 이유"로 정리해. 최종 판단은 의견이 아니라 실제 실행 결과로 해.
- 검토 크기: 작은 수정은 테스트 + final-reviewer만, 보통 기능은 테스트 + 내 리뷰 + final-reviewer, 큰 기능(새 시스템, 화면 전체 개편)은 Codex review와 /ponytail-review까지.
- 코드 리뷰 뒤 final-reviewer 서브에이전트(`.claude/agents/final-reviewer.md`)로 최종 검토를 받아. 검토자에게는 이번 단계의 요구사항만 전달하고 작업 과정 설명은 넘기지 마.
- 최종 검토가 끝날 때마다 `git status`로 검토자가 파일을 바꾸지 않았는지 확인해(.gitignore의 생성물 제외). 바뀌었으면 그 검토는 무효야.
- "불통과"면 고치고 재검토는 최대 2번. 그래도 안 되면 멈추고 보고해. "통과"가 나와야만 완료로 보고해.
- 어렵고 큰 일(새 시스템 설계, 화면 전체 구조, 원인을 못 찾는 버그, 성능 문제)은 architect 서브에이전트(opus)에게 먼저 방향을 물어봐. 작은 수정에는 부르지 마.
- 기능을 완성하면 /ponytail-review로 줄일 수 있는 부분을 확인해. 단, 내가 요청한 기능과 게임의 재미를 위한 연출은 줄이지 마.

## GitHub

- main에는 최종 검토를 통과한 것만 푸시해. 불통과이거나 테스트가 실패하면 절대 푸시하지 마. 작업 브랜치는 보존용으로 언제든 푸시해도 돼.
- 커밋 이메일은 GitHub 비공개 이메일(350977072+jaehyo-dev@users.noreply.github.com)만 써.
- 비밀번호, API 키, 토큰은 절대 커밋하지 마. 클라이언트에는 공개용 키만 넣고 데이터 접근은 서버 쪽 권한(Row Level Security 등)으로 막아.

## 버전 관리

- Semantic Versioning. 기준은 "그 시점에 실제로 배포된(main, GitHub Pages) 상태".
  - 메이저: 기존 기록·저장 데이터·사용 방식과 호환되지 않는 변경 / 마이너: 새 기능 / 패치: 버그 수정, 수치·표현의 작은 조정
- 버전을 올릴 때마다 CHANGELOG.md를 한국어로 먼저 쓰고, 버전 번호는 `project.godot`의 `config/version` 한 곳에만 둬 (화면은 이 값을 읽고, 자동 테스트가 CHANGELOG와 일치하는지 확인).
- 태그와 GitHub Release는 직접 만들지 마. main 푸시 때 `.github/workflows/deploy.yml`이 CHANGELOG 최신 버전으로 태그·릴리스를 만들고 GitHub Pages에 배포해. 버전 태그는 지우거나 옮기지 마 (이전 버전을 `versions/`에 다시 빌드하는 데 쓰임).
- 코드가 바뀌지 않는 변경(문서, 워크플로)은 버전을 올리지 않아도 돼. 버전을 올리는 푸시는 한 번에 하나씩 하고, 워크플로·릴리스·게임 주소에서 새 버전이 열리는지 확인해.
- 빌드 결과물(`build/`, `_site/`)은 커밋하지 마.

## Codex 협업 (ChatGPT 구독)

- 이미지: 그림이 필요하면 `codex exec --sandbox read-only "<요청>"`로 Codex 내장 이미지 생성(gpt-image-2)을 써. 요청 끝에 항상 "내장 이미지 생성 도구만 사용하고, 스크립트를 만들거나 API를 호출하지 마"를 붙여. API 키는 절대 쓰지 마.
  - 결과는 `~/.codex/generated_images/`의 가장 최근 파일을 찾아 `assets/raw/`(또는 콘셉트는 `assets/concept/`)로 복사해.
  - 투명 배경이 안 되니 단색 배경으로 만들게 하고 배경을 지워 `assets/sprites/`에 저장해. 같은 캐릭터는 기준 그림을 `--image`로 넘겨 모습을 유지해.
  - 만들기 전에 몇 장을 만들지 계획하고, 요청문은 ASSET_PROMPTS.md에 기록해.
- 코드: 같은 버그를 2번 고쳐도 안 풀리면 `codex exec`로 의견을 받아. 큰 기능을 끝내면 `codex review`로 리뷰받고 수용/거절과 이유를 정리해. 최종 판단은 네가 해.
- **Codex 로그 규칙**: Codex를 실행할 때는 먼저 `logs/codex.log`에 `=== [시간] Codex 작업: <요약> ===` 한 줄을 쓰고(`mkdir -p logs`), 명령 끝에 `2>&1 | tee -a logs/codex.log`를 붙여 출력을 남겨. `logs/`는 .gitignore에 있어 커밋되지 않아.
- Codex를 쓸 수 없는 환경이면 건너뛰고 보고에 적어.

## 오픈소스와 에셋

- 필요한 기능은 먼저 검증된 엔진, 애드온, 에셋이 있는지 찾아보고 쓰는 게 나으면 써. 에셋은 Kenney, OpenGameArt, itch.io의 CC0를 우선해.
- 자유롭게: MIT, Apache-2.0, BSD, zlib, CC0. 출처 표시: CC-BY, SIL OFL 1.1(글꼴).
- 먼저 물어볼 것: GPL·AGPL, CC-BY-SA, MPL, LGPL, 라이선스가 불분명하거나 "무료"라고만 된 것.
- 쓰지 않는 것: CC-BY-NC, CC-BY-ND, 다른 게임·영화 등에서 추출한 에셋, 남의 상표·캐릭터.
- 원 제작자의 공식 배포처에서 받고 라이선스를 거기서 직접 확인해. 버전을 고정하고 필요한 파일만 `assets/종류/이름/`에 넣고, 라이선스 전문을 옆에 함께 넣어.
- 쓴 오픈소스, 에셋, AI 그림, 직접 만든 에셋은 모두 CREDITS.md에 기록해(이름, 버전, 만든 사람, 라이선스, 출처, 쓰는 곳, 수정 여부). 기록하지 않은 외부 에셋은 커밋하지 마.

## 프로젝트 구조

```
project.godot            Godot 프로젝트 설정 (게임 버전 config/version)
export_presets.cfg       웹 내보내기 설정 (스레드 없음: GitHub Pages용)
scenes/  scripts/        씬(.tscn)과 스크립트(.gd). 로직은 scripts/logic/
assets/                  외부·직접 만든 에셋 (폴더마다 라이선스 파일)
tests/                   게임 자동 테스트 (run_tests.sh → run_tests.gd 실행기, test_*.gd)
tools/                   변경 기록·버전 페이지·라이선스 도구와 그 테스트
.github/workflows/       자동 테스트, 태그·릴리스, GitHub Pages 배포
.claude/agents/          final-reviewer 최종 검토자
GAME_SPEC.md  CHANGELOG.md  CREDITS.md  PROGRESS.md
```

- Godot가 만드는 `*.import`, `*.uid` 파일은 커밋해. `.godot/`, `build/`는 커밋하지 마.
- 웹 내보내기는 Compatibility 렌더러, 스레드 없음 설정을 유지해 (자동 테스트가 확인).
