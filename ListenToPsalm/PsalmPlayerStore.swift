//
//  PsalmPlayerStore.swift
//  ListenToPsalm
//

import Foundation

/// Shared player used by SwiftUI and App Intents / Siri / Shortcuts.
@MainActor
final class PsalmPlayerStore {
    static let shared = PsalmPlayerStore()

    let viewModel: PsalmPlayerViewModel

    private init() {
        viewModel = PsalmPlayerViewModel()
    }

    @discardableResult
    func playPsalm(number: Int) -> String {
        guard let psalm = PsalmCatalog.psalm(number) else {
            return "시편은 1편부터 150편까지 있습니다."
        }
        viewModel.play(psalm)
        return "\(psalm.title) 재생을 시작합니다."
    }

    @discardableResult
    func resumePlayback() -> String {
        if viewModel.isPlaying {
            return "이미 재생 중입니다."
        }
        if viewModel.resumePlaybackAfterStop() {
            return "정지했던 위치에서 이어서 재생합니다."
        }
        viewModel.playFromSelection()
        return "\(viewModel.selectedPsalm.title) 재생을 시작합니다."
    }

    @discardableResult
    func setSleepTimer(minutes: Int) -> String {
        guard let option = sleepTimerOption(for: minutes) else {
            return "30, 60, 90, 120분 중에서 선택해 주세요."
        }
        viewModel.sleepTimerOption = option
        if viewModel.isPlaying {
            return "수면 타이머 \(minutes)분이 설정되었습니다."
        }
        return "수면 타이머 \(minutes)분으로 설정했습니다. 재생 중에 적용됩니다."
    }

    private func sleepTimerOption(for minutes: Int) -> PsalmPlayerViewModel.SleepTimerOption? {
        switch minutes {
        case 30: return .thirtyMinutes
        case 60: return .sixtyMinutes
        case 90: return .ninetyMinutes
        case 120: return .oneHundredTwentyMinutes
        default: return nil
        }
    }
}
