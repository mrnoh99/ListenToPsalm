//
//  PsalmBrowseGlassBar.swift
//  ListenToPsalm
//

import SwiftUI

/// Floating Liquid Glass bar: browse context title (left) and sleep timer control (right).
struct PsalmBrowseGlassBar<SleepTimerLabel: View>: View {
    let barHeight: CGFloat
    let contextTitle: String
    let onContextTitleTap: () -> Void
    let onSleepTimerTap: () -> Void
    @ViewBuilder var sleepTimerLabel: () -> SleepTimerLabel

    @ScaledMetric(relativeTo: .body) private var horizontalPadding: CGFloat = AppControlLayout.barHorizontalPadding

    init(
        barHeight: CGFloat = AppControlLayout.barHeight,
        contextTitle: String,
        onContextTitleTap: @escaping () -> Void,
        onSleepTimerTap: @escaping () -> Void,
        @ViewBuilder sleepTimerLabel: @escaping () -> SleepTimerLabel
    ) {
        self.barHeight = barHeight
        self.contextTitle = contextTitle
        self.onContextTitleTap = onContextTitleTap
        self.onSleepTimerTap = onSleepTimerTap
        self.sleepTimerLabel = sleepTimerLabel
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: performContextTitleTap) {
                Text(contextTitle)
                    .font(AppControlTypography.labelFont)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: barHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(AccessibilitySupport.koreanText(contextTitle))
            .accessibilityHint(AccessibilitySupport.koreanText("재생 중인 시편의 분류로 이동합니다"))
            .accessibilityIdentifier("browse-context-title-button")

            Button(action: performSleepTimerTap) {
                Label {
                    sleepTimerLabel()
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .accessibilityHidden(true)
                } icon: {
                    Image(systemName: "timer")
                        .accessibilityHidden(true)
                }
                .font(AppControlTypography.labelFont)
                .labelStyle(.titleAndIcon)
                .fixedSize(horizontal: true, vertical: false)
                .frame(height: barHeight)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(AccessibilitySupport.koreanText(AccessibilitySupport.sleepTimerButtonLabel))
            .accessibilityRemoveTraits(.isButton)
            .accessibilityHint(AccessibilitySupport.koreanText("수면 타이머를 설정합니다"))
            .accessibilityIdentifier("sleep-timer-button")
        }
        .frame(maxWidth: .infinity)
        .frame(height: barHeight)
        .modifier(GlassCapsuleSurfaceModifier(
            horizontalPadding: horizontalPadding,
            cornerRadius: AppControlLayout.barCornerRadius
        ))
    }

    private func performContextTitleTap() {
        AccessibilitySupport.haptic(.selection)
        onContextTitleTap()
    }

    private func performSleepTimerTap() {
        AccessibilitySupport.haptic(.selection)
        onSleepTimerTap()
    }
}

// MARK: - Glass capsule surface

struct GlassCapsuleSurfaceModifier: ViewModifier {
    let horizontalPadding: CGFloat
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .padding(.horizontal, horizontalPadding)
                .background {
                    Capsule(style: .continuous)
                        .fill(.clear)
                        .glassEffect(.regular, in: .capsule)
                }
        } else {
            content
                .padding(.horizontal, horizontalPadding)
                .background {
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Capsule(style: .continuous)
                                .strokeBorder(.white.opacity(0.32), lineWidth: 0.75)
                        }
                        .shadow(color: .black.opacity(0.1), radius: 14, y: 5)
                }
        }
    }
}
