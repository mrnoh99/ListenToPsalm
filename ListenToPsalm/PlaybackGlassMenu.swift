//
//  PlaybackGlassMenu.swift
//  ListenToPsalm
//

import SwiftUI

/// Apple Music–style Liquid Glass playback bar: play/stop.
struct PlaybackGlassMenu: View {
    let barHeight: CGFloat
    let chapterTitle: String
    let isPlaying: Bool
    let onPlayStop: () -> Void

    @ScaledMetric(relativeTo: .body) private var menuHorizontalPadding: CGFloat = AppControlLayout.barHorizontalPadding

    init(
        barHeight: CGFloat = AppControlLayout.barHeight,
        chapterTitle: String,
        isPlaying: Bool,
        onPlayStop: @escaping () -> Void
    ) {
        self.barHeight = barHeight
        self.chapterTitle = chapterTitle
        self.isPlaying = isPlaying
        self.onPlayStop = onPlayStop
    }

    var body: some View {
        menuButtons
            .frame(height: barHeight)
            .frame(maxWidth: .infinity)
            .modifier(GlassCapsuleSurfaceModifier(
                horizontalPadding: menuHorizontalPadding,
                cornerRadius: AppControlLayout.barCornerRadius
            ))
    }

    private var menuButtons: some View {
        Button(action: onPlayStop) {
            Label {
                Text(chapterTitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityHidden(true)
            } icon: {
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .accessibilityHidden(true)
            }
            .font(AppControlTypography.prominentLabelFont)
            .labelStyle(.titleAndIcon)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.accentColor)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AccessibilitySupport.koreanText(AccessibilitySupport.playbackButtonLabel(chapterTitle: chapterTitle, isPlaying: isPlaying)))
        .accessibilityRemoveTraits(.isButton)
        .accessibilityHint(AccessibilitySupport.koreanText(isPlaying ? "재생을 멈춥니다" : "선택한 장을 재생합니다"))
        .accessibilityIdentifier("playback-button")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

