# GitHub Pages로 마케팅·지원 URL 게시하기

이 폴더(`docs/`)는 App Store Connect의 **Marketing URL**과 **Support URL**에 넣을 수 있는 정적 웹 페이지입니다.

## 게시 후 사용할 URL 예시

저장소 이름이 `ListenToPsalm`이고 GitHub 사용자명이 `mrnoh99`일 때:

| 용도 | URL |
|------|-----|
| Marketing URL | `https://mrnoh99.github.io/ListenToPsalm/` |
| Support URL | `https://mrnoh99.github.io/ListenToPsalm/support.html` |
| 개인정보 처리방침 | `https://mrnoh99.github.io/ListenToPsalm/privacy.html` |

(조직 페이지나 커스텀 도메인을 쓰면 위 주소를 그에 맞게 바꿉니다.)

## `404`가 나올 때 (마케팅 URL이 안 열릴 때)

저장소에 `docs/`가 있어도 **GitHub Pages 게시를 켜지 않으면** `https://mrnoh99.github.io/ListenToPsalm/` 는 404입니다.

1. [저장소 Settings → Pages](https://github.com/mrnoh99/ListenToPsalm/settings/pages) 로 이동합니다.
2. **Build and deployment** 의 **Source**가 `Deploy from GitHub Actions` 또는 `Deploy from a branch` 중 하나로 설정돼 있는지 확인합니다. `Disable` 이면 아래 방법 중 하나를 선택합니다.
3. 저장 후 **Actions** 탭에서 최근 워크플로가 성공했는지 확인합니다. 성공 후에도 캐시 때문에 1~2분 뒤에 열릴 수 있습니다.

## GitHub에서 설정 (방법 1: 브랜치에서 `/docs` 게시)

1. 이 `docs` 폴더를 저장소 **main**(또는 기본 브랜치)에 푸시합니다.
2. GitHub 저장소 → **Settings** → **Pages**
3. **Build and deployment** → **Source**: *Deploy from a branch*
4. **Branch**: `main` / **Folder**: `/docs` → **Save**
5. 몇 분 뒤 위와 같은 `https://…github.io/…/` 주소가 활성화됩니다.

## GitHub에서 설정 (방법 2: GitHub Actions — 권장)

저장소 루트에 `.github/workflows/deploy-github-pages.yml` 이 포함되어 있으면, **main**에 푸시할 때마다 `docs/` 전체가 Pages로 올라갑니다.

1. 해당 워크플로 파일이 **main**에 있는지 확인합니다.
2. **Settings** → **Pages** → **Build and deployment** → **Source** 에서 **GitHub Actions** 를 선택합니다. (처음이면 GitHub이 워크플로를 안내할 수 있습니다.)
3. **Actions** 탭에서 **Deploy GitHub Pages** 워크플로가 초록색으로 완료되는지 확인합니다.

방법 1과 2는 **동시에 쓰지 말고** 하나만 선택합니다. 이미 브랜치 방식으로 잘 열리면 Actions로 바꿀 필요는 없습니다.

## 수정할 항목

- `index.html`: `#app-store-link` 의 `href` 를 승인 후 실제 App Store 앱 URL로 교체
- `support.html`: 지원 이메일은 `jsnoh2010@gmail.com` 로 설정되어 있습니다.
- App Store **앱 개인정보** 항목에 `privacy.html` 전체 URL을 넣을 수 있습니다.
- 앱 표기명은 문서 전반에서 **시편듣기** 로 통일되어 있습니다.

## 참고

- `.nojekyll` 파일은 Jekyll 없이 정적 HTML만 서빙할 때 사용합니다.
- 저장소가 **비공개**여도 GitHub Pages 무료 플랜에서는 공개 사이트 정책을 확인하세요.
