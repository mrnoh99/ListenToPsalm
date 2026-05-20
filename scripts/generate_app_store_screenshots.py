#!/usr/bin/env python3
"""Generate App Store Connect iPhone screenshot PNGs for ListenToPsalm."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT_ROOT = ROOT / "AppStoreScreenshots"

# App Store Connect portrait sizes (pixels)
SIZES = {
    "iPhone-6.7-Display": (1290, 2796),
    "iPhone-6.9-Display": (1320, 2868),
}

# Light mode — matches default iOS app appearance
COLORS = {
    "bg": "#FFFFFF",
    "surface": "#F2F2F7",
    "text": "#000000",
    "secondary": "#8E8E93",
    "accent": "#007AFF",
    "teal": "#2D9D8F",
    "teal_row": "#D4EDE9",
    "red": "#FF3B30",
    "border": "#E5E5EA",
    "doxology": "#2D9D8F",
}


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = []
    if bold:
        candidates.extend([
            "/System/Library/Fonts/SFNS-Bold.ttf",
            "/System/Library/Fonts/SFNS.ttf",
            "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
            "/Library/Fonts/Arial Bold.ttf",
        ])
    else:
        candidates.extend([
            "/System/Library/Fonts/SFNS.ttf",
            "/System/Library/Fonts/Supplemental/Arial.ttf",
            "/Library/Fonts/Arial.ttf",
        ])
    for path in candidates:
        try:
            return ImageFont.truetype(path, size=size)
        except OSError:
            continue
    return ImageFont.load_default()


def scale_for(width: int, height: int) -> float:
    return width / 390.0


def rounded_rect(
    draw: ImageDraw.ImageDraw,
    xy: tuple[int, int, int, int],
    radius: int,
    fill: str,
    outline: str | None = None,
) -> None:
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=2 if outline else 0)


class ScreenshotRenderer:
    def __init__(self, width: int, height: int) -> None:
        self.w = width
        self.h = height
        self.s = scale_for(width, height)
        self.img = Image.new("RGB", (width, height), COLORS["bg"])
        self.draw = ImageDraw.Draw(self.img)
        self.pad = int(16 * self.s)
        self.y = int(54 * self.s)

    def _f(self, points: float) -> int:
        return int(points * self.s)

    def _font(self, points: float, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
        return load_font(max(12, self._f(points)), bold=bold)

    def status_bar(self) -> None:
        time_font = self._font(15, bold=True)
        self.draw.text((self.pad, self._f(14)), "9:41", fill=COLORS["text"], font=time_font)
        bx = self.w - self.pad - self._f(68)
        by = self._f(18)
        for i, pct in enumerate((0.35, 0.65, 1.0)):
            self.draw.rounded_rectangle(
                (bx + i * self._f(22), by, bx + i * self._f(22) + self._f(18), by + self._f(10)),
                radius=self._f(2),
                fill=COLORS["text"] if pct > 0.5 else COLORS["border"],
            )
        self.y = self._f(54)

    def doxology(self) -> None:
        text = "+ 찬미 예수님"
        font = self._font(13, bold=True)
        bar_h = self._f(36)
        self.draw.rectangle((0, self.y, self.w, self.y + bar_h), fill="#EAF6F4")
        tw = self.draw.textlength(text, font=font)
        self.draw.text(((self.w - tw) / 2, self.y + self._f(8)), text, fill=COLORS["doxology"], font=font)
        self.y += bar_h + self._f(8)

    def title(self, text: str = "시편듣기") -> None:
        font = self._font(34, bold=True)
        self.draw.text((self.pad, self.y), text, fill=COLORS["text"], font=font)
        self.y += self._f(44)

    def gospel_grid(self, selected: str) -> None:
        names = ["마태오", "마르코", "루카", "요한"]
        gap = self._f(12)
        cell_w = (self.w - 2 * self.pad - gap) // 2
        cell_h = self._f(56)
        font = self._font(20, bold=True)
        for i, name in enumerate(names):
            col, row = i % 2, i // 2
            x0 = self.pad + col * (cell_w + gap)
            y0 = self.y + row * (cell_h + gap)
            active = name == selected
            rounded_rect(
                self.draw,
                (x0, y0, x0 + cell_w, y0 + cell_h),
                self._f(14),
                fill=COLORS["accent"] if active else COLORS["surface"],
            )
            color = "#FFFFFF" if active else COLORS["text"]
            tw = self.draw.textlength(name, font=font)
            self.draw.text((x0 + (cell_w - tw) / 2, y0 + self._f(16)), name, fill=color, font=font)
        self.y += 2 * (cell_h + gap) + self._f(8)

    def gospel_summary(self, korean_name: str, chapter_count: int) -> None:
        title_font = self._font(34, bold=True)
        sub_font = self._font(15)
        self.draw.text((self.pad, self.y), korean_name, fill=COLORS["text"], font=title_font)
        self.y += self._f(40)
        self.draw.text((self.pad, self.y), f"총 {chapter_count}장", fill=COLORS["secondary"], font=sub_font)
        btn_text = "시간 선택"
        btn_font = self._font(17, bold=True)
        btn_w = self._f(120)
        btn_h = self._f(44)
        bx = self.w - self.pad - btn_w
        by = self.y - self._f(36)
        rounded_rect(self.draw, (bx, by, bx + btn_w, by + btn_h), self._f(10), fill=COLORS["bg"], outline=COLORS["border"])
        self.draw.text((bx + self._f(14), by + self._f(10)), btn_text, fill=COLORS["accent"], font=btn_font)
        self.y += self._f(28)

    def sleep_timer_line(self, text: str) -> None:
        font = self._font(22, bold=True)
        tw = self.draw.textlength(text, font=font)
        self.draw.text(((self.w - tw) / 2, self.y), text, fill=COLORS["secondary"], font=font)
        self.y += self._f(36)

    def chapter_list(
        self,
        gospel_prefix: str,
        chapters: list[dict],
        list_height: int | None = None,
    ) -> None:
        if list_height is None:
            list_height = self._f(318)
        x0 = self.pad
        x1 = self.w - self.pad
        rounded_rect(self.draw, (x0, self.y, x1, self.y + list_height), self._f(16), fill=COLORS["bg"], outline=COLORS["border"])
        inner_y = self.y + self._f(8)
        row_h = self._f(54)
        title_font = self._font(17)
        time_font = self._font(13)
        for ch in chapters:
            if inner_y + row_h > self.y + list_height - self._f(4):
                break
            if ch.get("playing"):
                self.draw.rounded_rectangle(
                    (x0 + self._f(4), inner_y, x1 - self._f(4), inner_y + row_h),
                    radius=self._f(12),
                    fill=COLORS["teal_row"],
                )
            title = f"{gospel_prefix} {ch['num']}장"
            weight = title_font if not ch.get("playing") else self._font(17, bold=True)
            self.draw.text((x0 + self._f(16), inner_y + self._f(8)), title, fill=COLORS["text"], font=weight)
            tx = x0 + self._f(16) + self.draw.textlength(title, font=weight) + self._f(8)
            if ch.get("time"):
                self.draw.text((tx, inner_y + self._f(12)), ch["time"], fill=COLORS["secondary"], font=time_font)
            icon_x = x1 - self._f(36)
            if ch.get("playing"):
                self._speaker_icon(icon_x, inner_y + self._f(16))
            elif ch.get("selected"):
                self.draw.ellipse(
                    (icon_x, inner_y + self._f(14), icon_x + self._f(22), inner_y + self._f(36)),
                    fill=COLORS["accent"],
                )
            if ch.get("playing") and ch.get("progress", 0) > 0:
                py = inner_y + row_h - self._f(12)
                pw = x1 - x0 - self._f(32)
                px = x0 + self._f(16)
                self.draw.rounded_rectangle((px, py, px + pw, py + self._f(4)), radius=2, fill=COLORS["border"])
                prog_w = int(pw * ch["progress"])
                if prog_w > 0:
                    self.draw.rounded_rectangle((px, py, px + prog_w, py + self._f(4)), radius=2, fill=COLORS["teal"])
            inner_y += row_h
        self.y += list_height + self._f(12)

    def _speaker_icon(self, x: int, y: int) -> None:
        c = COLORS["teal"]
        self.draw.polygon([(x, y + 8), (x + 8, y + 4), (x + 8, y + 20), (x, y + 16)], fill=c)
        for i, w in enumerate((6, 10, 14)):
            self.draw.arc((x + 4 - i, y - i // 2, x + 20 + i, y + 24 + i // 2), 300, 60, fill=c, width=2)

    def play_button(self, playing: bool) -> None:
        label = "정지" if playing else "재생"
        color = COLORS["red"] if playing else COLORS["accent"]
        btn_h = self._f(56)
        rounded_rect(self.draw, (self.pad, self.y, self.w - self.pad, self.y + btn_h), self._f(14), fill=color)
        font = self._font(20, bold=True)
        tw = self.draw.textlength(label, font=font)
        self.draw.text(((self.w - tw) / 2, self.y + self._f(16)), label, fill="#FFFFFF", font=font)
        self.y += btn_h + self._f(8)

    def footer_credit(self) -> None:
        font = self._font(8)
        text = "by njs 2026"
        tw = self.draw.textlength(text, font=font)
        self.draw.text((self.w - self.pad - tw, self.h - self._f(24)), text, fill=COLORS["secondary"], font=font)

    def save(self, path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        self.img.save(path, "PNG", optimize=True)


def render_screenshots(width: int, height: int, out_dir: Path) -> list[Path]:
    paths: list[Path] = []
    prefix = "마태오복음서"

    # 1 — 홈 (마태오 선택)
    r = ScreenshotRenderer(width, height)
    r.status_bar()
    r.doxology()
    r.title()
    r.gospel_grid("마태오")
    r.gospel_summary("마태오복음서", 28)
    r.sleep_timer_line("남은 시간: ∞")
    r.chapter_list(
        "마태오복음서",
        [
            {"num": 1, "selected": True},
            {"num": 2},
            {"num": 3},
            {"num": 4},
            {"num": 5},
        ],
    )
    r.play_button(playing=False)
    r.footer_credit()
    p1 = out_dir / "01-home-matthew.png"
    r.save(p1)
    paths.append(p1)

    # 2 — 재생 중 (진행/전체 시간 + 진행 바)
    r = ScreenshotRenderer(width, height)
    r.status_bar()
    r.doxology()
    r.title()
    r.gospel_grid("마태오")
    r.gospel_summary("마태오복음서", 28)
    r.sleep_timer_line("남은 시간: 28:15")
    r.chapter_list(
        "마태오복음서",
        [
            {"num": 4},
            {"num": 5, "playing": True, "time": "3:21 / 12:45", "progress": 0.28},
            {"num": 6},
            {"num": 7},
        ],
    )
    r.play_button(playing=True)
    r.footer_credit()
    p2 = out_dir / "02-playing-progress.png"
    r.save(p2)
    paths.append(p2)

    # 3 — 요한시편 선택
    r = ScreenshotRenderer(width, height)
    r.status_bar()
    r.doxology()
    r.title()
    r.gospel_grid("요한")
    r.gospel_summary("요한복음서", 21)
    r.sleep_timer_line("남은 시간: ∞")
    r.chapter_list(
        "요한복음서",
        [
            {"num": 1, "selected": True},
            {"num": 2},
            {"num": 3},
            {"num": 4},
        ],
    )
    r.play_button(playing=False)
    r.footer_credit()
    p3 = out_dir / "03-gospel-john.png"
    r.save(p3)
    paths.append(p3)

    # 4 — 수면 타이머 (시트)
    r = ScreenshotRenderer(width, height)
    r.status_bar()
    r.doxology()
    r.title()
    r.gospel_grid("루카")
    r.gospel_summary("루카복음서", 24)
    r.sleep_timer_line("남은 시간: 60:00")
    r.chapter_list(
        "루카복음서",
        [{"num": 1}, {"num": 2, "playing": True, "time": "1:05 / 18:30", "progress": 0.06}, {"num": 3}],
        list_height=r._f(220),
    )
    r.play_button(playing=True)
    # Dim overlay + sheet
    overlay = Image.new("RGBA", (width, height), (0, 0, 0, 110))
    r.img = r.img.convert("RGBA")
    r.img = Image.alpha_composite(r.img, overlay)
    r.draw = ImageDraw.Draw(r.img)
    sheet_h = int(height * 0.52)
    sheet_y = height - sheet_h
    r.draw.rounded_rectangle((0, sheet_y + 20, width, height), radius=24, fill="#FFFFFF")
    nav_font = r._font(17, bold=True)
    r.draw.text((width // 2 - r.draw.textlength("시간 선택", font=nav_font) // 2, sheet_y + r._f(28)), "시간 선택", fill=COLORS["text"], font=nav_font)
    close_font = r._font(17, bold=True)
    r.draw.text((r.pad, sheet_y + r._f(28)), "닫기", fill=COLORS["accent"], font=close_font)
    grid_y = sheet_y + r._f(72)
    opts = ["30분", "60분", "90분", "120분"]
    gap = r._f(12)
    cell_w = (width - 2 * r.pad - gap) // 2
    cell_h = r._f(68)
    opt_font = r._font(22, bold=True)
    for i, opt in enumerate(opts):
        col, row = i % 2, i // 2
        x0 = r.pad + col * (cell_w + gap)
        y0 = grid_y + row * (cell_h + gap)
        active = opt == "60분"
        rounded_rect(r.draw, (x0, y0, x0 + cell_w, y0 + cell_h), r._f(14), fill=COLORS["accent"] if active else COLORS["surface"])
        color = "#FFFFFF" if active else COLORS["text"]
        tw = r.draw.textlength(opt, font=opt_font)
        r.draw.text((x0 + (cell_w - tw) / 2, y0 + r._f(20)), opt, fill=color, font=opt_font)
    cont_y = grid_y + 2 * (cell_h + gap) + r._f(8)
    rounded_rect(r.draw, (r.pad, cont_y, width - r.pad, cont_y + cell_h), r._f(14), fill=COLORS["surface"])
    tw = r.draw.textlength("계속", font=opt_font)
    r.draw.text(((width - tw) / 2, cont_y + r._f(20)), "계속", fill=COLORS["text"], font=opt_font)
    r.img = r.img.convert("RGB")
    r.draw = ImageDraw.Draw(r.img)
    r.footer_credit()
    p4 = out_dir / "04-sleep-timer.png"
    r.save(p4)
    paths.append(p4)

    # 5 — 연속 재생 (마르코, 여러 장)
    r = ScreenshotRenderer(width, height)
    r.status_bar()
    r.doxology()
    r.title()
    r.gospel_grid("마르코")
    r.gospel_summary("마르코복음서", 16)
    r.sleep_timer_line("남은 시간: ∞")
    r.chapter_list(
        "마르코복음서",
        [
            {"num": 14},
            {"num": 15, "playing": True, "time": "8:02 / 11:20", "progress": 0.71},
            {"num": 16},
        ],
    )
    r.play_button(playing=True)
    r.footer_credit()
    p5 = out_dir / "05-mark-continuous.png"
    r.save(p5)
    paths.append(p5)

    return paths


def main() -> None:
    for folder, (width, height) in SIZES.items():
        out_dir = OUT_ROOT / folder
        paths = render_screenshots(width, height, out_dir)
        print(f"{folder} ({width}x{height}):")
        for p in paths:
            print(f"  {p.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
