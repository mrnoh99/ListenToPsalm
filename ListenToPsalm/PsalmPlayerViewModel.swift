//
//  PsalmPlayerViewModel.swift
//  ListenToPsalm
//
//  Created by NohJaisung on 5/12/26.
//

import AVFoundation
import Combine
import CoreMedia
import Foundation
#if canImport(MediaPlayer)
import MediaPlayer
#endif

@MainActor
final class PsalmPlayerViewModel: ObservableObject {
    enum SleepTimerOption: String, CaseIterable, Identifiable {
        case thirtyMinutes
        case sixtyMinutes
        case ninetyMinutes
        case oneHundredTwentyMinutes
        case continuous

        var id: String { rawValue }

        var title: String {
            switch self {
            case .thirtyMinutes: return "30분"
            case .sixtyMinutes: return "60분"
            case .ninetyMinutes: return "90분"
            case .oneHundredTwentyMinutes: return "120분"
            case .continuous: return "계속"
            }
        }

        var duration: TimeInterval? {
            switch self {
            case .thirtyMinutes: return 30 * 60
            case .sixtyMinutes: return 60 * 60
            case .ninetyMinutes: return 90 * 60
            case .oneHundredTwentyMinutes: return 120 * 60
            case .continuous: return nil
            }
        }
    }

    @Published var browseMode: BrowseMode = .all {
        didSet { applyBrowseModeChange(from: oldValue) }
    }

    @Published var selectedBook: PsalmBook = .one {
        didSet { applySubfilterChange() }
    }

    @Published var selectedGenre: PsalmGenre = .praise {
        didSet { applySubfilterChange() }
    }

    @Published var selectedLiturgy: PsalmLiturgy = .penitential {
        didSet { applySubfilterChange() }
    }

    @Published private(set) var favoriteNumbers: Set<Int> = PsalmFavorites.load()

    @Published var selectedPsalm: Psalm = Psalm(number: 1)
    @Published var sleepTimerOption: SleepTimerOption = .continuous {
        didSet {
            guard oldValue != sleepTimerOption else { return }
            scheduleSleepTimerIfNeeded()
            AccessibilitySupport.haptic(.selection)
        }
    }

    @Published private(set) var sleepTimerStartDate: Date?
    @Published private(set) var sleepTimerEndDate: Date?
    @Published private(set) var currentPlayingPsalm: Psalm?
    @Published private(set) var scrollRequestID = UUID()
    @Published private(set) var missingResourceNames: [String] = []
    @Published private(set) var playbackMessage: String?
    @Published private(set) var isPlaying = false
    /// Elapsed time of the current `AVPlayerItem` (for in-list progress UI).
    @Published private(set) var playbackElapsedSeconds: TimeInterval = 0
    /// Duration of the current `AVPlayerItem` when known (`> 0`); otherwise `0`.
    @Published private(set) var playbackDurationSeconds: TimeInterval = 0
    @Published private(set) var launchResumeOffer: LaunchResumeOffer?

    private let player = AVQueuePlayer()
    private let supportedAudioExtensions = ["m4a", "mp3"]
    private var itemPsalms: [ObjectIdentifier: Psalm] = [:]
    private var playbackObservers: [NSObjectProtocol] = []
    private var playbackTimeObserver: Any?
    private var lastObservedCurrentItemID: ObjectIdentifier?
    private var sleepTimerTask: Task<Void, Never>?
    private var isRemoteCommandCenterConfigured = false
    private var isAudioInterruptionObserverRegistered = false
    /// Set when Siri or the system briefly interrupts playback; cleared after resume or stop.
    private var shouldResumeAfterAudioInterruption = false
    private var audioSessionConfigurationTask: Task<Void, Never>?

    private struct PlaybackResumeBookmark {
        let psalm: Psalm
        let time: CMTime
    }

    private var resumeBookmark: PlaybackResumeBookmark?
    private var navigationSnapBackTask: Task<Void, Never>?
    private var launchResumeOfferDismissed = false
    private var lastPersistedPsalmID: String?
    private var lastPersistedElapsed: TimeInterval = -1

    init() {
        if let first = visiblePsalms.first {
            selectedPsalm = first
        }
        refreshLaunchResumeOffer()
    }

    var visiblePsalms: [Psalm] {
        PsalmCatalog.psalms(
            browseMode: browseMode,
            book: selectedBook,
            genre: selectedGenre,
            liturgy: selectedLiturgy,
            favorites: favoriteNumbers
        )
    }

    var browseContextTitle: String {
        switch browseMode {
        case .all:
            return "전체 1–150편"
        case .byBook:
            return "\(selectedBook.title) · \(selectedBook.theme)"
        case .byGenre:
            if let subtitle = selectedGenre.subtitle {
                return "\(selectedGenre.title) · \(subtitle)"
            }
            return selectedGenre.title
        case .byLiturgy:
            return "\(selectedLiturgy.title) · \(selectedLiturgy.usage)"
        case .favorites:
            return favoriteNumbers.isEmpty ? "즐겨찾기" : "즐겨찾기 \(favoriteNumbers.count)편"
        }
    }

    /// Whether stopping left a position that Play can resume.
    var resumeBookmarkAvailable: Bool {
        resumeBookmark != nil
    }

    /// Chapter shown on the play/stop control: now playing, resume target, launch offer, or next from selection.
    var playbackTargetPsalm: Psalm {
        if let currentPlayingPsalm {
            return currentPlayingPsalm
        }
        if let resumeBookmark {
            return resumeBookmark.psalm
        }
        if let launchResumeOffer {
            return launchResumeOffer.psalm
        }
        return selectedPsalm
    }

    var playbackTargetPsalmTitle: String {
        playbackTargetPsalm.title
    }

    func selectPsalm(_ psalm: Psalm) {
        selectedPsalm = psalm
    }

    func refreshLaunchResumeOffer() {
        guard !launchResumeOfferDismissed, !isPlaying, resumeBookmark == nil else {
            launchResumeOffer = nil
            return
        }
        guard let saved = PlaybackPersistence.load(),
              let psalm = saved.psalm,
              saved.elapsedSeconds >= 3 else {
            launchResumeOffer = nil
            return
        }
        launchResumeOffer = LaunchResumeOffer(psalm: psalm, elapsedSeconds: saved.elapsedSeconds)
        browseMode = .all
        selectedBook = psalm.book
        selectedPsalm = psalm
    }

    func dismissLaunchResumeOffer() {
        launchResumeOfferDismissed = true
        launchResumeOffer = nil
    }

    @discardableResult
    func resumeFromLaunchOffer() -> Bool {
        guard let offer = launchResumeOffer else { return false }

        launchResumeOfferDismissed = true
        launchResumeOffer = nil

        resumeBookmark = PlaybackResumeBookmark(
            psalm: offer.psalm,
            time: CMTime(seconds: offer.elapsedSeconds, preferredTimescale: 600)
        )

        guard resumePlaybackAfterStop() else { return false }
        AccessibilitySupport.haptic(.play)
        return true
    }

    func selectBrowseMode(_ mode: BrowseMode) {
        guard browseMode != mode else {
            if let playing = currentPlayingPsalm, visiblePsalms.contains(playing) {
                selectedPsalm = playing
                requestScrollToCurrentPsalm()
            } else if let stopped = stoppedResumePsalm(in: visiblePsalms) {
                selectedPsalm = stopped
                requestScrollToCurrentPsalm()
            }
            considerSchedulingNavigationSnapBackAfterBrowsing()
            return
        }
        browseMode = mode
        AccessibilitySupport.haptic(.selection)
        if stoppedResumePsalm(in: visiblePsalms) != nil {
            requestScrollToCurrentPsalm()
        }
        considerSchedulingNavigationSnapBackAfterBrowsing()
    }

    func toggleFavorite(_ number: Int) {
        favoriteNumbers = PsalmFavorites.toggle(number)
        if browseMode == .favorites {
            applySubfilterChange()
        }
    }

    func isFavorite(_ number: Int) -> Bool {
        favoriteNumbers.contains(number)
    }

    func stoppedResumePsalm(in psalms: [Psalm]) -> Psalm? {
        guard !isPlaying,
              let bookmark = resumeBookmark,
              psalms.contains(bookmark.psalm) else {
            return nil
        }
        return bookmark.psalm
    }

    func play(_ psalm: Psalm) {
        cancelNavigationSnapBack()
        resumeBookmark = nil
        launchResumeOffer = nil
        selectedPsalm = psalm
        playFromSelection()
    }

    func togglePsalmPlayback(_ psalm: Psalm) {
        if isPlaying, currentPlayingPsalm == psalm {
            stop()
            return
        }

        if !isPlaying, resumeBookmark?.psalm == psalm {
            selectedPsalm = psalm
            if resumePlaybackAfterStop() {
                return
            }
        }

        play(psalm)
    }

    func canResumePsalm(_ psalm: Psalm) -> Bool {
        !isPlaying && resumeBookmark?.psalm == psalm
    }

    func playFromSelection() {
        cancelNavigationSnapBack()
        
        playbackMessage = nil
        currentPlayingPsalm = nil

        guard rebuildPsalmQueue() else {
            isPlaying = false
            playbackMessage = missingAudioPlaybackMessage()
            return
        }

        // 실제 재생 시작 직전에만 오디오 세션 설정
        configureAudioSession()
        configureNowPlayingSupportIfNeeded()
        startPlayback(seekTo: nil)
    }

    func resumePlaybackAfterStop() -> Bool {
        cancelNavigationSnapBack()
        guard let bookmark = resumeBookmark else { return false }

        let resumePsalm = bookmark.psalm
        let resumeTime = bookmark.time

        browseMode = .all
        selectedBook = resumePsalm.book
        selectedPsalm = resumePsalm

        playbackMessage = nil
        currentPlayingPsalm = nil

        guard rebuildPsalmQueue() else {
            isPlaying = false
            playbackMessage = missingAudioPlaybackMessage()
            return false
        }

        // 실제 재생 시작 직전에만 오디오 세션 설정
        configureAudioSession()
        configureNowPlayingSupportIfNeeded()
        
        resumeBookmark = nil
        startPlayback(seekTo: resumeTime)
        return true
    }

    func pause() {
        cancelNavigationSnapBack()
        shouldResumeAfterAudioInterruption = false
        player.pause()
        sleepTimerTask?.cancel()
        isPlaying = false
        updateNowPlayingInfo()
    }

    func resume() {
        cancelNavigationSnapBack()
        configureAudioSession()

        guard !player.items().isEmpty else {
            if resumePlaybackAfterStop() { return }
            playFromSelection()
            return
        }

        player.play()
        isPlaying = true
        updateCurrentPlayingPsalm()
        requestScrollToCurrentPsalm()
        scheduleSleepTimerIfNeeded()
        updateNowPlayingInfo()
    }

    func stop() {
        cancelNavigationSnapBack()
        shouldResumeAfterAudioInterruption = false
        var pausedElapsed: TimeInterval = 0
        var pausedDuration: TimeInterval = 0
        if let item = player.currentItem,
           let psalm = itemPsalms[ObjectIdentifier(item)] {
            let time = player.currentTime()
            resumeBookmark = PlaybackResumeBookmark(psalm: psalm, time: time)
            if time.seconds.isFinite {
                pausedElapsed = max(0, time.seconds)
            }
            let duration = item.duration.seconds
            if duration.isFinite, duration > 0 {
                pausedDuration = duration
            }
        }

        player.pause()
        resetQueueState()
        sleepTimerTask?.cancel()
        missingResourceNames = []
        playbackMessage = nil
        currentPlayingPsalm = nil
        isPlaying = false
        if resumeBookmark != nil {
            playbackElapsedSeconds = pausedElapsed
            playbackDurationSeconds = pausedDuration
        } else {
            playbackElapsedSeconds = 0
            playbackDurationSeconds = 0
        }
        clearNowPlayingInfo()

        if let bookmark = resumeBookmark {
            persistPlayback(from: bookmark.psalm, elapsedSeconds: CMTimeGetSeconds(bookmark.time))
        }

        AccessibilitySupport.haptic(.stop)
        refreshLaunchResumeOffer()
    }

    /// Called when the app moves between foreground, inactive, or background while playback should continue (e.g. screen lock).
    func reassertAudioPlaybackIfNeeded() {
        guard isPlaying else { return }
        
        // 시리 등의 외부 인터럽션 후 오디오 세션 복원
        Task {
            // 잠시 대기 (다른 오디오 앱이 완전히 종료될 시간)
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
            
            await MainActor.run {
                configureAudioSession()
                
                // 오디오 세션이 성공적으로 설정되었고 플레이어가 정지되어 있다면 재생 재개
                if player.rate == 0, player.currentItem != nil,
                   !(playbackMessage?.contains("오디오 설정 중 문제가 발생했습니다") == true) {
                    player.play()
                }
                updateNowPlayingInfo()
            }
        }
    }

    /// While playing, call when the user moves the 2×2 gospel grid (or similar) so 20s of no such interaction snaps UI to the current track.
    func recordBrowseInteractionWhilePlaying() {
        considerSchedulingNavigationSnapBackAfterBrowsing()
    }

    private func cancelNavigationSnapBack() {
        navigationSnapBackTask?.cancel()
        navigationSnapBackTask = nil
    }

    private func considerSchedulingNavigationSnapBackAfterBrowsing() {
        cancelNavigationSnapBack()

        guard isPlaying, let playing = currentPlayingPsalm else { return }
        guard !navigationUIAlignedWithCurrentTrack(playing) else { return }

        navigationSnapBackTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(nanoseconds: 20_000_000_000)
            } catch {
                return
            }
            self.snapUIToCurrentTrackIfStillNeeded()
        }
    }

    private func navigationUIAlignedWithCurrentTrack(_ playing: Psalm) -> Bool {
        visiblePsalms.contains(playing) && selectedPsalm.id == playing.id
    }

    private func snapUIToCurrentTrackIfStillNeeded() {
        navigationSnapBackTask = nil
        guard isPlaying, let playing = currentPlayingPsalm else { return }
        guard !navigationUIAlignedWithCurrentTrack(playing) else { return }

        if !visiblePsalms.contains(playing) {
            browseMode = .all
            selectedBook = playing.book
        }
        if selectedPsalm.id != playing.id {
            selectedPsalm = playing
        }
        requestScrollToCurrentPsalm()
    }

    private func applyBrowseModeChange(from oldMode: BrowseMode) {
        guard oldMode != browseMode else { return }
        if let playing = currentPlayingPsalm, visiblePsalms.contains(playing) {
            selectedPsalm = playing
        } else if let stopped = stoppedResumePsalm(in: visiblePsalms) {
            selectedPsalm = stopped
        } else if let first = visiblePsalms.first {
            selectedPsalm = first
        }
    }

    private func applySubfilterChange() {
        if let playing = currentPlayingPsalm, visiblePsalms.contains(playing) {
            selectedPsalm = playing
        } else if let stopped = stoppedResumePsalm(in: visiblePsalms) {
            selectedPsalm = stopped
        } else if let first = visiblePsalms.first {
            selectedPsalm = first
        }
    }

    private func configureAudioSession() {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        registerAudioInterruptionObserverOnce()

        audioSessionConfigurationTask?.cancel()
        audioSessionConfigurationTask = Task { @MainActor [weak self] in
            guard let self else { return }

            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            do {
                let session = AVAudioSession.sharedInstance()
                let currentCategory = session.category
                let currentMode = session.mode

                if currentCategory == .playback && currentMode == .spokenAudio {
                    if playbackMessage?.contains("오디오 설정 중 문제가 발생했습니다") == true {
                        playbackMessage = nil
                    }
                    return
                }

                try session.setCategory(.playback, mode: .default, options: [])

                do {
                    try session.setActive(true)
                    try session.setCategory(
                        .playback,
                        mode: .spokenAudio,
                        options: [.allowBluetoothA2DP, .mixWithOthers]
                    )
                } catch {
                    #if DEBUG
                    print("오디오 세션 활성화 지연됨: \(error)")
                    #endif
                }

                if playbackMessage?.contains("오디오 설정 중 문제가 발생했습니다") == true ||
                    playbackMessage?.contains("오디오 세션 설정에 실패했습니다") == true {
                    playbackMessage = nil
                }
            } catch let error as NSError {
                #if DEBUG
                print("오디오 세션 설정 지연됨: \(error)")
                #endif

                guard isPlaying else { return }

                let errorMessage: String
                if let avError = error as? AVError {
                    switch avError.code {
                    case .applicationIsNotAuthorized:
                        errorMessage = "오디오 권한이 없습니다. 설정에서 권한을 확인해주세요."
                    default:
                        errorMessage = "오디오 설정 중 문제가 발생했습니다. 잠시 후 다시 시도해주세요."
                    }
                } else {
                    let description = error.localizedDescription.lowercased()
                    if description.contains("interrupted") || description.contains("interrupt") {
                        errorMessage = "다른 앱의 오디오 사용으로 중단되었습니다. 잠시 후 다시 시도해주세요."
                    } else if description.contains("resource") || description.contains("busy") {
                        errorMessage = "오디오 리소스를 사용할 수 없습니다. 다른 앱 종료 후 시도해주세요."
                    } else if description.contains("category") || description.contains("mode") {
                        errorMessage = "오디오 설정을 변경할 수 없습니다. 잠시 후 다시 시도해주세요."
                    } else {
                        errorMessage = "오디오 설정 중 문제가 발생했습니다. 잠시 후 다시 시도해주세요."
                    }
                }

                playbackMessage = errorMessage
            }
        }
        #endif
    }

    #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    private func registerAudioInterruptionObserverOnce() {
        guard !isAudioInterruptionObserverRegistered else { return }
        isAudioInterruptionObserverRegistered = true

        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let typeRaw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let optionsRaw = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.handleAudioSessionInterruption(typeRaw: typeRaw, optionsRaw: optionsRaw)
            }
        }
    }

    private func handleAudioSessionInterruption(typeRaw: UInt?, optionsRaw: UInt?) {
        guard let typeRaw,
              let type = AVAudioSession.InterruptionType(rawValue: typeRaw) else {
            return
        }

        switch type {
        case .began:
            guard isPlaying else { return }
            // Siri / system UI: pause AVPlayer only (keep `isPlaying` so we can resume).
            shouldResumeAfterAudioInterruption = true
            player.pause()

        case .ended:
            let shouldResume = shouldResumeAfterAudioInterruption
            shouldResumeAfterAudioInterruption = false
            clearAudioInterruptionPlaybackMessage()

            guard shouldResume, isPlaying else { return }

            // Siri often omits `.shouldResume`; still restore when we paused for interruption.
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsRaw ?? 0)
            let systemSaysResume = options.contains(.shouldResume)
            resumePlaybackAfterExternalInterruption(systemSaysResume: systemSaysResume)

        @unknown default:
            break
        }
    }

    private func clearAudioInterruptionPlaybackMessage() {
        if playbackMessage?.contains("다른 앱의 오디오 사용으로") == true {
            playbackMessage = nil
        }
    }

    private func resumePlaybackAfterExternalInterruption(systemSaysResume: Bool) {
        Task {
            // Brief delay so Siri / system audio releases the session.
            let delay: UInt64 = systemSaysResume ? 300_000_000 : 500_000_000
            try? await Task.sleep(nanoseconds: delay)

            await MainActor.run {
                guard self.isPlaying, self.player.currentItem != nil else { return }
                guard !(self.playbackMessage?.contains("오디오 설정 중 문제가 발생했습니다") == true) else {
                    return
                }

                self.configureAudioSession()
                #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
                try? AVAudioSession.sharedInstance().setActive(true)
                #endif

                if self.player.rate == 0 {
                    self.player.play()
                }
                self.updateNowPlayingInfo()
                self.clearAudioInterruptionPlaybackMessage()
            }
        }
    }
    #endif

    private func resourceNameVariants(_ name: String) -> [String] {
        let nfc = name.precomposedStringWithCanonicalMapping
        let nfd = name.decomposedStringWithCanonicalMapping
        var variants: [String] = []
        for candidate in [name, nfc, nfd] where !variants.contains(candidate) {
            variants.append(candidate)
        }
        return variants
    }

    private func audioURL(for psalm: Psalm) -> URL? {
        let resourceNames = resourceNameVariants(psalm.resourceName)
        let subdirectories = ["AudioFiles", "ListenToPsalm/AudioFiles"]

        for subdirectory in subdirectories {
            for resourceName in resourceNames {
                for fileExtension in supportedAudioExtensions {
                    if let url = Bundle.main.url(
                        forResource: resourceName,
                        withExtension: fileExtension,
                        subdirectory: subdirectory
                    ) {
                        return url
                    }
                }
            }
        }

        for resourceName in resourceNames {
            for fileExtension in supportedAudioExtensions {
                if let url = Bundle.main.url(
                    forResource: resourceName,
                    withExtension: fileExtension
                ) {
                    return url
                }
            }
        }

        return audioURLFromDirectoryListing(for: psalm)
    }

    private func audioURLFromDirectoryListing(for psalm: Psalm) -> URL? {
        guard let resourceBase = Bundle.main.resourceURL else { return nil }
        let target = psalm.resourceName.precomposedStringWithCanonicalMapping

        for folder in ["AudioFiles", "ListenToPsalm/AudioFiles"] {
            let directoryURL = resourceBase.appendingPathComponent(folder, isDirectory: true)
            guard let fileURLs = try? FileManager.default.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil
            ) else {
                continue
            }

            for fileURL in fileURLs {
                guard supportedAudioExtensions.contains(fileURL.pathExtension.lowercased()) else { continue }
                let stem = fileURL.deletingPathExtension().lastPathComponent
                if stem.precomposedStringWithCanonicalMapping == target {
                    return fileURL
                }
            }
        }
        return nil
    }

    private func alignSelectedPsalmWithVisibleList() {
        guard visiblePsalms.contains(selectedPsalm) else {
            if let first = visiblePsalms.first {
                selectedPsalm = first
            }
        }
    }

    private func missingAudioPlaybackMessage() -> String {
        if missingResourceNames.isEmpty {
            return "앱 번들에서 시편 오디오 파일을 찾지 못했습니다. AudioFiles 폴더를 확인한 뒤 Clean Build 해 주세요."
        }

        let missingCount = missingResourceNames.count
        if missingCount == 1, let path = missingResourceNames.first {
            return "앱 번들에서 오디오 파일을 찾지 못했습니다. (\(path))"
        }
        return "앱 번들에서 시편 오디오 \(missingCount)개를 찾지 못했습니다."
    }

    private func resetQueueState() {
        player.removeAllItems()
        removePlaybackObservers()
        itemPsalms = [:]
        lastObservedCurrentItemID = nil
    }

    private func rebuildPsalmQueue() -> Bool {
        alignSelectedPsalmWithVisibleList()
        let requestedPsalm = selectedPsalm
        let order = PsalmCatalog.playbackOrder(in: visiblePsalms, startingAt: selectedPsalm)

        resetQueueState()
        missingResourceNames = []

        for psalm in order {
            guard let url = audioURL(for: psalm) else {
                missingResourceNames.append(psalm.resourceDisplayPath)
                continue
            }

            let item = AVPlayerItem(url: url)
            itemPsalms[ObjectIdentifier(item)] = psalm
            addPlaybackObserver(for: item)
            player.insert(item, after: nil)
        }

        guard let firstItem = player.items().first,
              let firstPsalm = itemPsalms[ObjectIdentifier(firstItem)] else {
            return false
        }

        if selectedPsalm.id != firstPsalm.id {
            selectedPsalm = firstPsalm
            if requestedPsalm.id != firstPsalm.id {
                playbackMessage = "\(requestedPsalm.title) 오디오를 찾지 못해 \(firstPsalm.title)부터 재생합니다."
            }
        }

        return true
    }

    private func startPlayback(seekTo seekTime: CMTime?) {
        let seconds = seekTime.map { CMTimeGetSeconds($0) } ?? 0
        let shouldSeek = seconds.isFinite && seconds > 0.25

        if shouldSeek, let seekTime {
            player.seek(
                to: seekTime,
                toleranceBefore: CMTime(seconds: 0.5, preferredTimescale: 600),
                toleranceAfter: CMTime(seconds: 0.5, preferredTimescale: 600)
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.player.play()
                    self.playbackDidStart()
                }
            }
        } else {
            player.play()
            playbackDidStart()
        }
    }

    private func playbackDidStart() {
        cancelNavigationSnapBack()
        playbackMessage = nil
        isPlaying = true
        updateCurrentPlayingPsalm()
        requestScrollToCurrentPsalm()
        scheduleSleepTimerIfNeeded()

        AccessibilitySupport.haptic(.play)
        launchResumeOffer = nil
    }

    private func addPlaybackObserver(for item: AVPlayerItem) {
        let observer = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in
            Task { @MainActor [weak self] in
                self?.handlePotentialQueueItemTransition()
            }
        }

        playbackObservers.append(observer)
    }

    private func addPlaybackTimeObserverIfNeeded() {
        guard playbackTimeObserver == nil else { return }

        playbackTimeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 4),
            queue: .main
        ) { _ in
            Task { @MainActor [weak self] in
                self?.observePlayerProgress()
            }
        }
    }

    private func removePlaybackObservers() {
        playbackObservers.forEach(NotificationCenter.default.removeObserver)
        playbackObservers = []
    }

    /// `AVQueuePlayer` can still report the finished `currentItem` in the same turn as `AVPlayerItemDidPlayToEndTime`; re-check after a yield so the playing row advances with the queue.
    private func handlePotentialQueueItemTransition() {
        observePlayerProgress()
        Task { @MainActor [weak self] in
            await Task.yield()
            self?.observePlayerProgress()
        }
    }

    private func observePlayerProgress() {
        let currentItemID = player.currentItem.map(ObjectIdentifier.init)

        if currentItemID != lastObservedCurrentItemID {
            let advancedToNewChapter = lastObservedCurrentItemID != nil
            lastObservedCurrentItemID = currentItemID
            updateCurrentPlayingPsalm()
            requestScrollToCurrentPsalm()
            if advancedToNewChapter, isPlaying, currentItemID != nil {
                AccessibilitySupport.haptic(.chapterChange)
            }
        }

        updateNowPlayingInfo()
        refreshPlaybackProgressForUI()
        persistPlaybackProgressIfNeeded()
    }

    private func updateCurrentPlayingPsalm() {
        guard let currentItem = player.currentItem else {
            currentPlayingPsalm = nil
            isPlaying = false
            if resumeBookmark == nil {
                playbackElapsedSeconds = 0
                playbackDurationSeconds = 0
            }
            return
        }

        currentPlayingPsalm = itemPsalms[ObjectIdentifier(currentItem)]
        syncSelectedPsalmWithPlayback()
        updateNowPlayingInfo()
        refreshPlaybackProgressForUI()
    }

    private func syncSelectedPsalmWithPlayback() {
        guard let playing = currentPlayingPsalm else { return }
        guard visiblePsalms.contains(playing) else { return }
        guard selectedPsalm.id != playing.id else { return }
        selectedPsalm = playing
    }

    private func refreshPlaybackProgressForUI() {
        guard isPlaying, player.currentItem != nil else {
            if resumeBookmark != nil {
                return
            }
            playbackElapsedSeconds = 0
            playbackDurationSeconds = 0
            return
        }

        let elapsed = player.currentTime().seconds
        playbackElapsedSeconds = elapsed.isFinite ? max(0, elapsed) : 0

        if let item = player.currentItem {
            let dur = item.duration.seconds
            if dur.isFinite, dur > 0 {
                playbackDurationSeconds = dur
            } else {
                playbackDurationSeconds = 0
            }
        }
    }

    private func requestScrollToCurrentPsalm() {
        scrollRequestID = UUID()
    }

    private func scheduleSleepTimerIfNeeded() {
        sleepTimerTask?.cancel()

        guard let duration = sleepTimerOption.duration else {
            sleepTimerStartDate = nil
            sleepTimerEndDate = nil
            return
        }

        let startDate = Date()
        sleepTimerStartDate = startDate
        sleepTimerEndDate = startDate.addingTimeInterval(duration)

        guard isPlaying else {
            return
        }

        sleepTimerTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            } catch {
                return
            }

            self?.stop()
        }
    }

    private func configureNowPlayingSupportIfNeeded() {
        configureRemoteCommandCenter()
        addPlaybackTimeObserverIfNeeded()
    }

    private func configureRemoteCommandCenter() {
        #if canImport(MediaPlayer)
        guard !isRemoteCommandCenterConfigured else { return }

        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.stopCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { _ in
            Task { @MainActor [weak self] in
                self?.resume()
            }
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { _ in
            Task { @MainActor [weak self] in
                self?.pause()
            }
            return .success
        }

        commandCenter.stopCommand.isEnabled = true
        commandCenter.stopCommand.addTarget { _ in
            Task { @MainActor [weak self] in
                self?.stop()
            }
            return .success
        }

        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isPlaying ? self.pause() : self.resume()
            }
            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false

        isRemoteCommandCenterConfigured = true
        #endif
    }

    private func updateNowPlayingInfo() {
        #if canImport(MediaPlayer)
        guard let psalm = currentPlayingPsalm else {
            clearNowPlayingInfo()
            return
        }

        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: psalm.title,
            MPMediaItemPropertyArtist: "시편듣기",
            MPMediaItemPropertyAlbumTitle: browseContextTitle,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]

        let elapsedTime = player.currentTime().seconds
        if elapsedTime.isFinite {
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
        }

        if let duration = player.currentItem?.duration.seconds, duration.isFinite {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        #endif
    }

    private func clearNowPlayingInfo() {
        #if canImport(MediaPlayer)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        #endif
    }

    private func persistPlaybackProgressIfNeeded() {
        guard isPlaying, let psalm = currentPlayingPsalm else { return }

        let elapsed = player.currentTime().seconds
        guard elapsed.isFinite, elapsed >= 3 else { return }

        let psalmID = String(psalm.id)
        if psalmID == lastPersistedPsalmID,
           abs(elapsed - lastPersistedElapsed) < 5 {
            return
        }

        lastPersistedPsalmID = psalmID
        lastPersistedElapsed = elapsed
        persistPlayback(from: psalm, elapsedSeconds: elapsed)
    }

    private func persistPlayback(from psalm: Psalm, elapsedSeconds: TimeInterval) {
        PlaybackPersistence.save(psalm: psalm, elapsedSeconds: elapsedSeconds)
    }
}
