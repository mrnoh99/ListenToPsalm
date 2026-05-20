# App Store Connect — iPhone 스크린샷

**실제 시뮬레이터 캡처**(권장) 또는 `scripts/generate_app_store_screenshots.py` 로 만든 목업 PNG입니다.

## 시뮬레이터에서 캡처 (권장)

**iPhone 17 Pro Max** 등이 켜져 있을 때:

```bash
# 한 장씩 (화면 맞춘 뒤 실행)
./scripts/capture_one_screenshot.sh 02-playing-progress.png

# 안내에 따라 5장 연속
./scripts/capture_simulator_screenshots_interactive.sh
```

또는 Simulator 포커스 후 **⌘S** → 바탕화면 PNG (1320×2868)를 아래 폴더로 옮깁니다.

| 폴더 | 크기 | Connect에서 선택 |
|------|------|------------------|
| `iPhone-6.7-Display/` | 1290 × 2796 | iPhone 6.7" 디스플레이 |
| `iPhone-6.9-Display/` | 1320 × 2868 | iPhone 6.9" 디스플레이 (iPhone 17 Pro Max 등) |

## 파일 설명

| 파일 | 내용 |
|------|------|
| `01-home-matthew.png` | 시편 선택 · 마태오 · 장 목록 |
| `02-playing-progress.png` | 재생 중 · 진행/전체 시간 · 진행 바 |
| `03-gospel-john.png` | 요한시편 선택 |
| `04-sleep-timer.png` | 수면 타이머 선택 시트 |
| `05-mark-continuous.png` | 마르코시편 연속 재생 |

## 목업 PNG 다시 생성 (시뮬레이터 없을 때)

```bash
python3 scripts/generate_app_store_screenshots.py
```

## 업로드 방법

1. [App Store Connect](https://appstoreconnect.apple.com) → 앱 → **iOS 앱** → 버전
2. **미리보기 및 스크린샷** → **iPhone 6.7"** (또는 **6.9"**) 디스플레이
3. 위 폴더의 PNG를 순서대로 드래그

## 참고

- 실제 기기·시뮬레이터 캡처가 필요하면 Xcode에서 실행 후 **Cmd+S** 로 저장한 뒤 같은 해상도로 교체할 수 있습니다.
- **앱 미리보기(동영상)** 는 별도 제작이 필요합니다(선택 사항).
