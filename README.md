# ListenToPsalm

**시편듣기** — 가톨릭 시편(1–150편) 오디오 듣기 iOS 앱

[ListenToGospel](https://github.com/mrnoh99/ListenToGospel)과 동일한 재생·접근성·수면 타이머·Siri/단축어 패턴을 사용합니다.

## GitHub Pages

| 용도 | URL |
|------|-----|
| Marketing | https://mrnoh99.github.io/ListenToPsalm/ |
| Support | https://mrnoh99.github.io/ListenToPsalm/support.html |
| Privacy | https://mrnoh99.github.io/ListenToPsalm/privacy.html |

`docs/` 푸시 후 [Settings → Pages](https://github.com/mrnoh99/ListenToPsalm/settings/pages)에서 **GitHub Actions** 또는 **`/docs`** 브랜치 게시를 설정하세요.

## Xcode

- 프로젝트: `ListenToPsalm.xcodeproj`
- 소스: `ListenToPsalm/`
- 오디오: `ListenToPsalm/AudioFiles/` (`시편 001편.m4a` … `시편 150편.m4a`)
- 번들 ID: `njs.ListenToPsalm`
- 표시 이름: 시편듣기

## 탐색 (2×3 허브)

- **전체** (1–150편)
- **권별** — 제1권(1–41) … 제5권(107–150)
- **장르** — 찬양·탄원·감사·순례(120–134)·지혜
- **전례** — 7대 참회시편·할렐·메시아
- **즐겨찾기**

## 시리 예시

- 「시편듣기에서 시편 23편 재생」
- 「시편듣기에서 이어서 재생」
- 「시편듣기 수면 타이머 30분」
- 「시편듣기 정지」

## 오디오

`AudioFiles/`에 시편 `.m4a` 파일을 추가한 뒤 Xcode에서 빌드하세요. 파일명은 `Psalm.swift`의 `resourceName`과 일치해야 합니다.

## 관련 앱

- [ListenToGospel (복음서듣기)](https://github.com/mrnoh99/ListenToGospel)
