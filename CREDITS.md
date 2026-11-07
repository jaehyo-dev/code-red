# 크레딧과 라이선스

이 게임에 쓰인 외부 오픈소스·에셋의 출처와 라이선스입니다.
새로 추가하거나 버전을 바꿀 때마다 이 파일을 함께 고칩니다 (규칙: [CLAUDE.md](CLAUDE.md)의 "오픈소스 사용 규칙").

## 게임에 포함된 것

| 이름 | 버전 | 만든 사람 | 라이선스 | 출처 | 쓰는 곳 | 수정 |
|---|---|---|---|---|---|---|
| Godot Engine | 4.7.2-stable | Godot Engine contributors, Juan Linietsky, Ariel Manzur | MIT (엔진에 포함된 서드파티 구성 요소는 각자의 라이선스) | https://godotengine.org | 게임 엔진, 웹 내보내기 템플릿 | 없음 |
| Galmuri11 (갈무리) | v2.40.4 | Lee Minseo (quiple) | SIL Open Font License 1.1 | https://github.com/quiple/galmuri | 게임 전체 글꼴 `assets/fonts/galmuri/Galmuri11.ttf` | 없음 |

- Godot 엔진과 엔진 구성 요소의 라이선스 전문은 배포할 때 `licenses/godot.txt`로 자동 생성합니다 (`tools/export_licenses.gd`).
- Galmuri 라이선스 전문: [`assets/fonts/galmuri/LICENSE.txt`](assets/fonts/galmuri/LICENSE.txt)

## 개발·배포에만 쓰는 것 (게임에는 포함되지 않음)

| 이름 | 라이선스 | 쓰는 곳 |
|---|---|---|
| GitHub Actions: actions/checkout, actions/cache, actions/configure-pages, actions/upload-pages-artifact, actions/deploy-pages | MIT | `.github/` 자동 테스트·배포 |
| Python 3 표준 라이브러리 | PSF License | `tools/` 변경 기록·버전 도구 |

## 직접 만든 것

- 프로젝트 임시 아이콘 `icon.svg`: 이 프로젝트에서 직접 만듦 (슬라임 콘셉트 확정 후 교체 예정)

## AI로 만든 것

| 이름 | 만든 도구 | 쓰는 곳 | 수정 |
|---|---|---|---|
| 슬라임 콘셉트 후보 `assets/concept/concept_a~d.png` | Codex 내장 이미지 생성 (gpt-image-2), 요청문은 [ASSET_PROMPTS.md](ASSET_PROMPTS.md) | 주인공 모습을 고르기 위한 참고용. 게임에는 포함하지 않음 | 없음 |
| 비교 이미지 `assets/concept/compare.png` | 위 4장을 Pillow로 2x2 배치 | 위와 같음 | 라벨 추가 |
| 진화 도안 `assets/concept/evolution.png` | Codex 내장 이미지 생성 (gpt-image-2), 기준 그림 A·C·B 사용, 요청문은 [ASSET_PROMPTS.md](ASSET_PROMPTS.md) | 1~3단계 진화 방향 참고용 (v0.5.0 스프라이트 제작 기준). 게임에는 포함하지 않음 | 없음 |
| 진화 도안 v2 `assets/concept/evolution_v2.png`, 비교 `evolution_compare.png` | Codex 내장 이미지 생성 (gpt-image-2), 기준 그림 `evolution.png` 사용. 비교 이미지는 Pillow로 v1/v2를 위아래 배치 | 위 진화 도안과 같음 | 없음 (비교는 라벨 추가) |

## v0.1.0 직접 만든 스프라이트

| 이름 | 만든 사람 | 쓰는 곳 | 수정 |
|---|---|---|---|
| `assets/sprites/*.png`, `assets/tiles/tiles.png` (적, 수정, 버섯, 돌더미, 뼈, 항아리, 모닥불, 타일) | 이 프로젝트에서 `tools/make_sprites.py`로 직접 그림 (CC0 수준으로 자유 사용, 외부 에셋 없음) | 동굴 방 | 없음 |
| `assets/sprites/slime_body.png`, `slime_crest.png`, `slime_eyes.png`, `slime_eyes_small.png`, `slime_mouth.png` | AI 도안 `assets/concept/evolution_v2.png`(위 표)의 1단계를 `tools/make_sprites.py`로 잘라 26도트 폭 격자로 줄이고 팔레트에 맞춤 → 몸통·머리 곡선·눈·입 레이어로 분리 (작은 눈은 직접 그림) | 주인공 슬라임 | 축소·색 정리·레이어 분리 |
| 스테이지 콘셉트 `assets/concept/stage_stone_a~c.png`, 비교 `stage_stone_compare.png` | Codex 내장 이미지 생성 (gpt-image-2), 요청문은 [ASSET_PROMPTS.md](ASSET_PROMPTS.md) | C(발광 이끼 동굴) 확정, A·B는 다른 시대용 보관. 참고용이며 게임에는 포함하지 않음 | 없음 (비교는 라벨 추가) |
| `assets/sprites/slime_bite_a.png`, `slime_bite_b.png`, `slime_wrap.png` (입 벌림 2장, 감싸기 1장) | 이 프로젝트에서 `tools/make_sprites.py`의 `make_bite_frames()`로 직접 그림 (슬라임 팔레트, 외부 에셋 없음) | 슬라임 "한 입에 삼키기" 공격 | 없음 |
| 공격 콘셉트 `assets/concept/attack_compare.png` | Codex 내장 이미지 생성 (gpt-image-2), 요청문은 [ASSET_PROMPTS.md](ASSET_PROMPTS.md) | 안 A "한 입에 삼키기" 확정(v0.1.5에서 구현), 안 B "점프 내려찍기"는 폼·무기 변신 연출용 보관, 안 C 폐기. 참고용이며 게임에는 포함하지 않음 | 없음 |
