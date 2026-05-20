//
//  ContentView.swift
//  ListenToPsalm
//
//  Created by NohJaisung on 5/12/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var player = PsalmPlayerStore.shared.viewModel
    @State private var isSleepTimerPickerPresented = false
    @State private var isBookPickerPresented = false
    @State private var isGenrePickerPresented = false
    @State private var isLiturgyPickerPresented = false
    @State private var controlsHeaderBottomOffset: CGFloat = 0
    @ScaledMetric(relativeTo: .body) private var chapterListRowMinHeight: CGFloat = 58
    @ScaledMetric(relativeTo: .body) private var chapterListRowVerticalInset: CGFloat = 12
    @ScaledMetric(relativeTo: .title3) private var controlBarHeight: CGFloat = AppControlLayout.barHeight
    @ScaledMetric(relativeTo: .body) private var browseGridSpacing: CGFloat = 8
    @ScaledMetric(relativeTo: .body) private var floatingBarHorizontalInset: CGFloat = AppControlLayout.floatingBarHorizontalInset
    @ScaledMetric(relativeTo: .body) private var floatingBarVerticalInset: CGFloat = AppControlLayout.floatingBarVerticalInset
    @ScaledMetric(relativeTo: .body) private var topContentInset: CGFloat = 16
    @ScaledMetric(relativeTo: .caption2) private var footerBarHeight: CGFloat = 28
    @ScaledMetric(relativeTo: .body) private var chapterListGlassPeek: CGFloat = 24
    @ScaledMetric(relativeTo: .body) private var floatingHeaderFadeHeight: CGFloat = 36
    @ScaledMetric(relativeTo: .body) private var floatingPlaybackFadeHeight: CGFloat = 48
    @ScaledMetric(relativeTo: .largeTitle) private var estimatedAppTitleHeight: CGFloat = 41
    @ScaledMetric(relativeTo: .body) private var headerSectionSpacing: CGFloat = 12
    @ScaledMetric(relativeTo: .body) private var headerBottomPadding: CGFloat = 8
    @ScaledMetric(relativeTo: .body) private var controlsOverlayBottomReserve: CGFloat = 72

    private var browseColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: browseGridSpacing),
            GridItem(.flexible(), spacing: browseGridSpacing)
        ]
    }

    private static let chapterListEdgeSpacerRowCount = 3

    private static let sleepTimerTimedOptions: [PsalmPlayerViewModel.SleepTimerOption] = [
        .thirtyMinutes,
        .sixtyMinutes,
        .ninetyMinutes,
        .oneHundredTwentyMinutes
    ]

    private let playingChapterRowBackground = Color.accentColor.opacity(0.34)
    private let playingChapterIconColor = Color.accentColor

    var body: some View {
        mainLayout
            .modifier(MainChromeModifier(
                scenePhase: scenePhase,
                isSleepTimerPickerPresented: $isSleepTimerPickerPresented,
                sleepTimerTimedOptions: Self.sleepTimerTimedOptions,
                sleepTimerActionTitle: sleepTimerActionTitle(for:),
                selectSleepTimer: selectSleepTimer(_:),
                onAppear: {
                    player.refreshLaunchResumeOffer()
                },
                reassertPlayback: { player.reassertAudioPlaybackIfNeeded() }
            ))
            .onPreferenceChange(ControlsHeaderBottomOffsetKey.self) { controlsHeaderBottomOffset = $0 }
    }

    /// Top scroll inset: keeps chapter rows below the title and 2×2 grid (no overlap with 「시편듣기」).
    private var chapterListTopContentMargin: CGFloat {
        if controlsHeaderBottomOffset > 0 {
            return controlsHeaderBottomOffset
        }
        return estimatedControlsHeaderBottomOffset
    }

    private var estimatedControlsHeaderBottomOffset: CGFloat {
        topContentInset
            + estimatedAppTitleHeight
            + headerSectionSpacing
            + (controlBarHeight * 3 + browseGridSpacing * 2)
            + headerSectionSpacing
            + controlBarHeight
            + headerBottomPadding
    }

    private var mainLayout: some View {
        VStack(spacing: 0) {
            chapterListWithFloatingControls
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            launchResumeOfferBanner
                .padding(.top, 4)

            playbackMessage
                .padding(.top, 4)

            footerBar
                .frame(height: footerBarHeight)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }

    private var footerBar: some View {
        Text("by njs 2026")
            .font(.system(size: 8))
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityHidden(true)
    }

    private var appTitleView: some View {
        Text("시편듣기")
            .font(.largeTitle.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
            .accessibilitySortPriority(50)
    }

    /// Title + gospel grid + sleep timer; measured height is the chapter list top inset.
    /// The title/grid section keeps an opaque background so scrolling rows stay hidden behind it,
    /// while the sleep timer row is left transparent so chapter rows scroll under the glass capsule.
    private var controlsHeaderChrome: some View {
        VStack(spacing: 0) {
            VStack(spacing: headerSectionSpacing) {
                appTitleView
                browseHub
            }
            .padding(.top, topContentInset)
            .padding(.bottom, headerSectionSpacing)
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .systemBackground))

            sleepTimerRow
                .padding(.bottom, headerBottomPadding)
        }
        .frame(maxWidth: .infinity)
        .background {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ControlsHeaderBottomOffsetKey.self,
                    value: geometry.size.height
                )
            }
        }
    }

    private var chapterListWithFloatingControls: some View {
        ZStack(alignment: .top) {
            chapterList
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            floatingControlsOverlay
        }
    }

    private var floatingControlsOverlay: some View {
        VStack(spacing: 0) {
            controlsHeaderChrome

            floatingBrowseHeaderFade

            Spacer(minLength: 0)
                .allowsHitTesting(false)

            floatingPlaybackOverlay
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .accessibilityElement(children: .contain)
    }

    /// Visual fade below the header chrome.
    private var floatingBrowseHeaderFade: some View {
        LinearGradient(
            colors: [
                Color(uiColor: .systemBackground).opacity(0.42),
                Color(uiColor: .systemBackground).opacity(0.18),
                Color(uiColor: .systemBackground).opacity(0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: floatingHeaderFadeHeight)
        .padding(.top, floatingBarVerticalInset)
        .allowsHitTesting(false)
    }

    private var floatingPlaybackOverlay: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [
                    Color(uiColor: .systemBackground).opacity(0),
                    Color(uiColor: .systemBackground).opacity(0.18),
                    Color(uiColor: .systemBackground).opacity(0.42)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: floatingPlaybackFadeHeight)
            .allowsHitTesting(false)

            playbackControls
                .padding(.horizontal, floatingBarHorizontalInset)
                .padding(.bottom, floatingBarVerticalInset)
        }
    }

    private var browseHub: some View {
        VStack(spacing: browseGridSpacing) {
            HStack(spacing: browseGridSpacing) {
                browseModeButton(.all)
                browseModeButton(.byBook)
            }
            HStack(spacing: browseGridSpacing) {
                browseModeButton(.byGenre)
                browseModeButton(.byLiturgy)
            }
            browseModeButton(.favorites)
        }
        .confirmationDialog("권별 보기", isPresented: $isBookPickerPresented, titleVisibility: .visible) {
            ForEach(PsalmBook.allCases) { book in
                Button("\(book.pickerLabel) — \(book.theme)") {
                    player.selectedBook = book
                    player.selectBrowseMode(.byBook)
                }
            }
            Button("취소", role: .cancel) {}
        }
        .confirmationDialog("장르별", isPresented: $isGenrePickerPresented, titleVisibility: .visible) {
            ForEach(PsalmGenre.allCases) { genre in
                Button(genre.pickerLabel) {
                    player.selectedGenre = genre
                    player.selectBrowseMode(.byGenre)
                }
            }
            Button("취소", role: .cancel) {}
        }
        .confirmationDialog("전례별 (가톨릭)", isPresented: $isLiturgyPickerPresented, titleVisibility: .visible) {
            ForEach(PsalmLiturgy.allCases) { liturgy in
                Button(liturgy.pickerLabel) {
                    player.selectedLiturgy = liturgy
                    player.selectBrowseMode(.byLiturgy)
                }
            }
            Button("취소", role: .cancel) {}
        }
    }

    private func browseModeButton(_ mode: BrowseMode) -> some View {
        Button {
            switch mode {
            case .all, .favorites:
                player.selectBrowseMode(mode)
            case .byBook:
                if player.browseMode == .byBook {
                    isBookPickerPresented = true
                } else {
                    player.selectBrowseMode(.byBook)
                    isBookPickerPresented = true
                }
            case .byGenre:
                if player.browseMode == .byGenre {
                    isGenrePickerPresented = true
                } else {
                    player.selectBrowseMode(.byGenre)
                    isGenrePickerPresented = true
                }
            case .byLiturgy:
                if player.browseMode == .byLiturgy {
                    isLiturgyPickerPresented = true
                } else {
                    player.selectBrowseMode(.byLiturgy)
                    isLiturgyPickerPresented = true
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(mode.shortTitle)
                    .font(AppControlTypography.prominentLabelFont)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if mode == .favorites {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity, minHeight: controlBarHeight)
            .foregroundStyle(player.browseMode == mode ? .white : .primary)
            .background(
                player.browseMode == mode ? Color.accentColor : Color(uiColor: .secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: AppControlLayout.barCornerRadius)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("browse-\(mode.accessibilitySuffix)")
        .accessibilitySortPriority(40)
    }

    private func selectSleepTimer(_ option: PsalmPlayerViewModel.SleepTimerOption) {
        player.sleepTimerOption = option
        player.recordBrowseInteractionWhilePlaying()
        isSleepTimerPickerPresented = false
    }

    private func sleepTimerActionTitle(for option: PsalmPlayerViewModel.SleepTimerOption) -> String {
        if player.sleepTimerOption == option {
            return "\(option.title) ✓"
        }
        return option.title
    }

    private var sleepTimerRow: some View {
        PsalmBrowseGlassBar(
            barHeight: controlBarHeight,
            contextTitle: player.browseContextTitle,
            onSleepTimerTap: {
                player.recordBrowseInteractionWhilePlaying()
                isSleepTimerPickerPresented = true
            },
            sleepTimerLabel: { sleepTimerButtonLabel }
        )
        .padding(.horizontal, floatingBarHorizontalInset)
        .accessibilitySortPriority(30)
    }

    @ViewBuilder
    private var sleepTimerButtonLabel: some View {
        if player.sleepTimerOption == .continuous {
            Text("남은시간: ∞")
        } else if let endDate = player.sleepTimerEndDate {
            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                Text("남은시간: \(sleepTimerCountdownText(until: endDate, now: timeline.date))")
            }
        } else {
            Text("남은시간: \(player.sleepTimerOption.title)")
        }
    }

    private func sleepTimerCountdownText(until endDate: Date, now: Date) -> String {
        let seconds = max(0, endDate.timeIntervalSince(now))
        let total = Int(seconds.rounded(.down))
        let minutes = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private var chapterListRowInsets: EdgeInsets {
        EdgeInsets(
            top: chapterListRowVerticalInset,
            leading: 16,
            bottom: chapterListRowVerticalInset,
            trailing: 16
        )
    }

    @ViewBuilder
    private func chapterListSpacerRow(id: String) -> some View {
        Color.clear
            .frame(minHeight: chapterListRowMinHeight)
            .listRowInsets(chapterListRowInsets)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .accessibilityHidden(true)
            .accessibilityRemoveTraits(.isButton)
            .allowsHitTesting(false)
            .id(id)
    }

    private func chapterListRow(_ chapter: Psalm) -> some View {
        ChapterListRowView(
            chapter: chapter,
            player: player,
            rowInsets: chapterListRowInsets,
            playingBackground: playingChapterRowBackground,
            iconColor: playingChapterIconColor,
            onPlay: { player.togglePsalmPlayback(chapter) }
        )
    }

    private var chapterList: some View {
        ScrollViewReader { proxy in
            ChapterListScrollView(
                listID: "\(player.browseMode.rawValue)-\(player.selectedBook.rawValue)-\(player.selectedGenre.rawValue)-\(player.selectedLiturgy.rawValue)",
                psalms: player.visiblePsalms,
                player: player,
                proxy: proxy,
                topContentMargin: chapterListTopContentMargin,
                bottomContentMargin: controlsOverlayBottomReserve + chapterListGlassPeek,
                rowMinHeight: chapterListRowMinHeight,
                edgeSpacerRowCount: Self.chapterListEdgeSpacerRowCount,
                spacerRow: chapterListSpacerRow(id:),
                chapterRow: chapterListRow,
                scrollAfterListChange: scrollAfterListChange(with:),
                scrollToCurrentChapter: scrollToCurrentChapter(_:with:),
                scrollToChapter: { scrollToChapter($0, with: proxy, anchor: .center) }
            )
        }
    }

    private var playbackControls: some View {
        PlaybackGlassMenu(
            barHeight: controlBarHeight,
            chapterTitle: player.playbackTargetPsalmTitle,
            isPlaying: player.isPlaying,
            onPlayStop: {
                if player.isPlaying {
                    player.stop()
                } else if player.resumePlaybackAfterStop() {
                } else if player.resumeFromLaunchOffer() {
                } else {
                    player.playFromSelection()
                }
            }
        )
        .accessibilitySortPriority(20)
    }

    @ViewBuilder
    private var launchResumeOfferBanner: some View {
        if let offer = player.launchResumeOffer, !player.isPlaying {
            Button {
                _ = player.resumeFromLaunchOffer()
            } label: {
                Label(offer.buttonTitle, systemImage: "play.circle.fill")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel(offer.accessibilityLabel)
            .accessibilityIdentifier("launch-resume-offer")
        }
    }

    @ViewBuilder
    private var playbackMessage: some View {
        if let message = player.playbackMessage {
            Label(message, systemImage: "exclamationmark.triangle")
                .font(.callout)
                .foregroundStyle(.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func scrollAfterListChange(with proxy: ScrollViewProxy) {
        if player.isPlaying,
           let playing = player.currentPlayingPsalm,
           player.visiblePsalms.contains(playing) {
            scrollToChapter(playing, with: proxy, anchor: .center)
            return
        }
        if player.canResumePsalm(player.selectedPsalm),
           player.visiblePsalms.contains(player.selectedPsalm) {
            scrollToChapter(player.selectedPsalm, with: proxy, anchor: .center)
            return
        }
        guard let first = player.visiblePsalms.first else { return }
        scrollToChapter(first, with: proxy, anchor: .center)
    }

    private func scrollToChapter(
        _ chapter: Psalm,
        with proxy: ScrollViewProxy,
        anchor: UnitPoint
    ) {
        withAnimation {
            proxy.scrollTo(chapter.id, anchor: anchor)
        }
    }

    private func scrollToCurrentChapter(_ chapter: Psalm?, with proxy: ScrollViewProxy) {
        guard let chapter else { return }
        scrollToChapter(chapter, with: proxy, anchor: .center)
    }

}

// MARK: - Chapter list (split out to ease Swift type-checking)

private struct ChapterListRowView: View {
    let chapter: Psalm
    @ObservedObject var player: PsalmPlayerViewModel
    let rowInsets: EdgeInsets
    let playingBackground: Color
    let iconColor: Color
    let onPlay: () -> Void

    private var isCurrentlyPlaying: Bool {
        player.isPlaying && chapter == player.currentPlayingPsalm
    }

    private var canResume: Bool {
        player.canResumePsalm(chapter)
    }

    /// Playing or stopped with a resume position — keeps the active row look.
    private var isActiveChapter: Bool {
        isCurrentlyPlaying || canResume
    }

    private var chapterProgress: (elapsed: TimeInterval, total: TimeInterval)? {
        guard isActiveChapter, player.playbackDurationSeconds > 0 else { return nil }
        return (player.playbackElapsedSeconds, player.playbackDurationSeconds)
    }

    private var showsPlaybackTime: Bool {
        chapterProgress != nil
    }

    private var playbackElapsedAndTotalLabel: String {
        guard let progress = chapterProgress else { return "0:00" }
        return "\(formatPlaybackTime(progress.elapsed)) / \(formatPlaybackTime(progress.total))"
    }

    private func formatPlaybackTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds.rounded(.down))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }

    private var rowBackground: Color {
        isActiveChapter ? playingBackground : .clear
    }

    private var accessibilityProgressText: String? {
        guard let progress = chapterProgress else { return nil }
        if isCurrentlyPlaying {
            return "재생중"
        } else if canResume {
            let elapsed = formatPlaybackTime(progress.elapsed)
            let total = formatPlaybackTime(progress.total)
            let percentage = Int((progress.elapsed / progress.total * 100).rounded())
            return "\(elapsed) / \(total), \(percentage)% 재생됨"
        }
        return nil
    }

    var body: some View {
        Button(action: onPlay, label: { rowLabel })
            .id(chapter.id)
            .buttonStyle(.plain)
            .listRowInsets(rowInsets)
            .listRowBackground(rowBackground)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(AccessibilitySupport.spokenChapterTitle(for: chapter))
            .accessibilityIdentifier(chapter.accessibilitySuffix)
            .accessibilitySortPriority(10)
            .modifier(AccessibilityProgressModifier(progressText: accessibilityProgressText))
    }

    private var rowLabel: some View {
        VStack(alignment: .leading, spacing: 6) {
            titleRow
            if let progress = chapterProgress {
                ChapterListRowProgressView(
                    elapsed: progress.elapsed,
                    total: progress.total,
                    iconColor: iconColor
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var titleRow: some View {
        HStack(spacing: 8) {
            Text(chapter.title)
                .fontWeight(isActiveChapter ? .semibold : .regular)
                .lineLimit(1)
                .accessibilityHidden(true)

            if showsPlaybackTime {
                Text(playbackElapsedAndTotalLabel)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .fixedSize()
                    .accessibilityHidden(true)
            }

            Spacer(minLength: 4)
            chapterStatusIcon
        }
    }

    @ViewBuilder
    private var chapterStatusIcon: some View {
        if isCurrentlyPlaying {
            Image(systemName: "speaker.wave.2.fill")
                .foregroundStyle(iconColor)
        } else if canResume {
            Image(systemName: "stop.fill")
                .foregroundStyle(iconColor)
        } else if chapter == player.selectedPsalm {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.tint)
        }
    }
}

private struct ChapterListRowProgressView: View {
    let elapsed: TimeInterval
    let total: TimeInterval
    let iconColor: Color

    var body: some View {
        Group {
            if total > 0 {
                ProgressView(
                    value: min(elapsed, total),
                    total: total
                )
                .progressViewStyle(.linear)
                .tint(iconColor)
            } else {
                Capsule()
                    .fill(Color.secondary.opacity(0.22))
                    .frame(height: 3)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.linear(duration: 0.2), value: elapsed)
        .accessibilityHidden(true)
    }
}

private struct ChapterListScrollView<SpacerRow: View, ChapterRow: View>: View {
    let listID: String
    let psalms: [Psalm]
    @ObservedObject var player: PsalmPlayerViewModel
    let proxy: ScrollViewProxy
    let topContentMargin: CGFloat
    let bottomContentMargin: CGFloat
    let rowMinHeight: CGFloat
    let edgeSpacerRowCount: Int
    let spacerRow: (String) -> SpacerRow
    let chapterRow: (Psalm) -> ChapterRow
    let scrollAfterListChange: (ScrollViewProxy) -> Void
    let scrollToCurrentChapter: (Psalm, ScrollViewProxy) -> Void
    let scrollToChapter: (Psalm) -> Void

    var body: some View {
        listContent
            .modifier(ChapterListStyleModifier(
                listID: listID,
                topContentMargin: topContentMargin,
                bottomContentMargin: bottomContentMargin,
                rowMinHeight: rowMinHeight
            ))
            .modifier(ChapterListScrollSyncModifier(
                player: player,
                proxy: proxy,
                scrollAfterListChange: scrollAfterListChange,
                scrollToCurrentChapter: scrollToCurrentChapter,
                scrollToChapter: scrollToChapter
            ))
    }

    private var listContent: some View {
        List {
            ForEach(0..<edgeSpacerRowCount, id: \.self) { index in
                spacerRow("chapter-list-top-spacer-\(index)")
            }

            ForEach(psalms) { psalm in
                chapterRow(psalm)
            }

            ForEach(0..<edgeSpacerRowCount, id: \.self) { index in
                spacerRow("chapter-list-bottom-spacer-\(index)")
            }
        }
    }
}

private struct ChapterListStyleModifier: ViewModifier {
    let listID: String
    let topContentMargin: CGFloat
    let bottomContentMargin: CGFloat
    let rowMinHeight: CGFloat

    func body(content: Content) -> some View {
        content
            .id(listID)
            .listStyle(.plain)
            .contentMargins(.vertical, 0, for: .scrollContent)
            .contentMargins(.top, topContentMargin, for: .scrollContent)
            .contentMargins(.bottom, bottomContentMargin, for: .scrollContent)
            .scrollContentBackground(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .environment(\.defaultMinListRowHeight, rowMinHeight)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct ChapterListScrollSyncModifier: ViewModifier {
    @ObservedObject var player: PsalmPlayerViewModel
    let proxy: ScrollViewProxy
    let scrollAfterListChange: (ScrollViewProxy) -> Void
    let scrollToCurrentChapter: (Psalm, ScrollViewProxy) -> Void
    let scrollToChapter: (Psalm) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                scrollAfterListChange(proxy)
            }
            .onChange(of: player.browseMode) { _, _ in
                Task { @MainActor in
                    await Task.yield()
                    scrollAfterListChange(proxy)
                }
            }
            .onChange(of: player.selectedBook) { _, _ in
                Task { @MainActor in
                    await Task.yield()
                    scrollAfterListChange(proxy)
                }
            }
            .onChange(of: player.selectedGenre) { _, _ in
                Task { @MainActor in
                    await Task.yield()
                    scrollAfterListChange(proxy)
                }
            }
            .onChange(of: player.selectedLiturgy) { _, _ in
                Task { @MainActor in
                    await Task.yield()
                    scrollAfterListChange(proxy)
                }
            }
            .onChange(of: player.favoriteNumbers) { _, _ in
                Task { @MainActor in
                    await Task.yield()
                    scrollAfterListChange(proxy)
                }
            }
            .onChange(of: player.currentPlayingPsalm) { _, psalm in
                guard let psalm, player.visiblePsalms.contains(psalm) else { return }
                scrollToCurrentChapter(psalm, proxy)
            }
            .onChange(of: player.scrollRequestID) { _, _ in
                let psalm = player.currentPlayingPsalm
                    ?? (player.visiblePsalms.contains(player.selectedPsalm) ? player.selectedPsalm : nil)
                guard let psalm, player.visiblePsalms.contains(psalm) else { return }
                scrollToChapter(psalm)
            }
    }
}

// MARK: - Main chrome (split out to ease Swift type-checking)

private struct AccessibilityProgressModifier: ViewModifier {
    let progressText: String?
    
    func body(content: Content) -> some View {
        if let progressText = progressText {
            content.accessibilityValue(progressText)
        } else {
            content
        }
    }
}

private struct MainChromeModifier: ViewModifier {
    let scenePhase: ScenePhase
    @Binding var isSleepTimerPickerPresented: Bool
    let sleepTimerTimedOptions: [PsalmPlayerViewModel.SleepTimerOption]
    let sleepTimerActionTitle: (PsalmPlayerViewModel.SleepTimerOption) -> String
    let selectSleepTimer: (PsalmPlayerViewModel.SleepTimerOption) -> Void
    let onAppear: () -> Void
    let reassertPlayback: () -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    reassertPlayback()
                }
            }
            .confirmationDialog(
                "수면 타이머",
                isPresented: $isSleepTimerPickerPresented,
                titleVisibility: .visible
            ) {
                ForEach(sleepTimerTimedOptions) { option in
                    Button(sleepTimerActionTitle(option)) {
                        selectSleepTimer(option)
                    }
                    .accessibilityLabel(option.title)
                    .accessibilityHint("수면 타이머를 \(option.title)로 설정")
                }
                Button(sleepTimerActionTitle(.continuous)) {
                    selectSleepTimer(.continuous)
                }
                .accessibilityLabel("연속 재생")
                .accessibilityHint("수면 타이머를 비활성화하고 연속 재생")
                Button("취소", role: .cancel) {}
                    .accessibilityLabel("취소")
                    .accessibilityHint("타이머 설정을 취소")
            } message: {
                Text("타이머 시간을 정합니다")
            }
            .onAppear(perform: onAppear)
    }
}

private struct ControlsHeaderBottomOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    ContentView()
}
