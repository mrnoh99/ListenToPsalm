#!/bin/bash
# Interactive App Store screenshot capture (no Accessibility permission needed).
# Prepare each screen in Simulator, then press Enter.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CAPTURE="$ROOT/scripts/capture_one_screenshot.sh"

steps=(
  "01-home-matthew.png|홈 · 마태오 선택 (기본 화면)"
  "02-playing-progress.png|장 하나 탭 후 재생 · 진행 시간 표시"
  "03-gospel-john.png|요한 버튼 탭"
  "04-sleep-timer.png|시간 선택 버튼 탭 · 수면 타이머 시트"
  "05-mark-continuous.png|닫기 후 마르코 선택 · 재생 중"
)

echo "iPhone 17 Pro Max 시뮬레이터에서 화면을 맞춘 뒤 Enter를 누르세요."
echo "또는 Simulator에서 Cmd+S 로 저장해도 됩니다 (1320×2868)."
echo ""

for entry in "${steps[@]}"; do
  file="${entry%%|*}"
  hint="${entry#*|}"
  echo "── $file"
  echo "   $hint"
  read -r -p "   준비되면 Enter… " _
  "$CAPTURE" "$file"
  echo ""
done

echo "완료: AppStoreScreenshots/iPhone-6.9-Display/ 및 iPhone-6.7-Display/"
