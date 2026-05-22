//
//  AccessibilitySupport.swift
//  ListenToPsalm
//

import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
import AudioToolbox
#endif

/// Shared label typography for gospel grid, header title, sleep timer, and playback.
enum AppControlTypography {
    static let labelFont: Font = .body.weight(.semibold)
    /// Larger label for primary controls (gospel grid cells and the play/stop button).
    static let prominentLabelFont: Font = .title3.weight(.semibold)
}

/// Shared dimensions for 2×2 gospel cells and floating glass control bars.
enum AppControlLayout {
    static let barHeight: CGFloat = 48
    static let barCornerRadius: CGFloat = 14
    static let floatingBarHorizontalInset: CGFloat = 4
    static let floatingBarVerticalInset: CGFloat = 6
    static let barHorizontalPadding: CGFloat = 16
}

enum AccessibilitySupport {
    enum Haptic {
        case play
        case stop
        case chapterChange
        case selection
    }

    /// VoiceOver label for the sleep timer control (`타이머` + `버튼`, no punctuation that reads as “dot”).
    static let sleepTimerButtonLabel = "타이머 버튼"

    /// Wraps text in a `Text` view tagged with `accessibilitySpeechLanguage = "ko-KR"`
    /// so VoiceOver reads Hangul with the Korean voice regardless of system locale.
    static func koreanText(_ string: String) -> Text {
        var attr = AttributedString(string)
        attr.accessibilitySpeechLanguage = "ko-KR"
        return Text(attr)
    }

    private static let sinoKoreanDigits = ["", "일", "이", "삼", "사", "오", "육", "칠", "팔", "구"]

    /// Chapter numbers for VoiceOver: `2` → `이` (not `둘`).
    static func spokenSinoKoreanNumber(_ number: Int) -> String {
        guard number > 0 else { return "영" }
        guard number < 100 else { return String(number) }

        if number < 10 {
            return sinoKoreanDigits[number]
        }
        if number < 20 {
            let ones = number % 10
            return ones == 0 ? "십" : "십\(sinoKoreanDigits[ones])"
        }

        let tens = number / 10
        let ones = number % 10
        let tensWord = "\(sinoKoreanDigits[tens])십"
        if ones == 0 {
            return tensWord
        }
        return "\(tensWord)\(sinoKoreanDigits[ones])"
    }

    /// VoiceOver psalm title, e.g. `시편 23편` → `시편 이십삼편`.
    static func spokenPsalmTitle(for psalm: Psalm) -> String {
        "시편 \(spokenSinoKoreanNumber(psalm.number))편"
    }

    /// VoiceOver title parsed from a display string.
    static func spokenPsalmTitle(_ title: String) -> String {
        guard let match = title.range(of: #"(\d+)\s*편"#, options: .regularExpression) else {
            return title
        }
        let digits = title[match].replacingOccurrences(of: "편", with: "")
        guard let number = Int(digits.filter(\.isNumber)) else {
            return title
        }
        return "시편 \(spokenSinoKoreanNumber(number))편"
    }

    static func spokenChapterTitle(for chapter: Psalm) -> String {
        spokenPsalmTitle(for: chapter)
    }

    static func spokenChapterTitle(_ title: String) -> String {
        spokenPsalmTitle(title)
    }

    /// VoiceOver label for the floating play/stop bar button.
    static func playbackButtonLabel(chapterTitle: String, isPlaying: Bool) -> String {
        let spokenTitle = spokenChapterTitle(chapterTitle)
        return isPlaying ? "\(spokenTitle) 중지 버튼" : "\(spokenTitle) 재생 버튼"
    }

    static func spokenDuration(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0초" }

        let total = Int(seconds.rounded(.down))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60

        if hours > 0 {
            return "\(hours)시간 \(minutes)분 \(secs)초"
        }
        if minutes > 0 {
            return "\(minutes)분 \(secs)초"
        }
        return "\(secs)초"
    }

    static func haptic(_ kind: Haptic) {
        #if os(iOS)
        switch kind {
        case .play:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            // 재생 시작 소리
            AudioServicesPlaySystemSound(1519) // 시스템 재생 소리
        case .stop:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            // 정지 소리
            AudioServicesPlaySystemSound(1520) // 시스템 정지 소리
        case .chapterChange:
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            // 챕터 변경 소리
            AudioServicesPlaySystemSound(1519)
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
            // 선택/버튼 누름 소리
            AudioServicesPlaySystemSound(1519) // 시스템 버튼 소리
        }
        #endif
    }
}

