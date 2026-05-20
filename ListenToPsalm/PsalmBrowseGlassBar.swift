//
//  PsalmBrowseGlassBar.swift
//  ListenToPsalm
//

import SwiftUI

/// Floating Liquid Glass bar: browse context title and sleep timer control.
struct PsalmBrowseGlassBar<SleepTimerLabel: View>: View {
    let barHeight: CGFloat
    let contextTitle: String
    let onSleepTimerTap: () -> Void
    @ViewBuilder var sleepTimerLabel: () -> SleepTimerLabel

    @ScaledMetric(relativeTo: .body) private var horizontalPadding: CGFloat = AppControlLayout.barHorizontalPadding

    init(
        barHeight: CGFloat = AppControlLayout.barHeight,
        contextTitle: String,
        onSleepTimerTap: @escaping () -> Void,
        @ViewBuilder sleepTimerLabel: @escaping () -> SleepTimerLabel
    ) {
        self.barHeight = barHeight
        self.contextTitle = contextTitle
        self.onSleepTimerTap = onSleepTimerTap
        self.sleepTimerLabel = sleepTimerLabel
    }

    var body: some View {
        Button(action: performSleepTimerTap) {
            HStack(alignment: .center, spacing: 12) {
                Text(contextTitle)
                    .font(AppControlTypography.labelFont)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityHidden(true)

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
            }
            .frame(maxWidth: .infinity)
            .frame(height: barHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AccessibilitySupport.sleepTimerButtonLabel)
        .accessibilityRemoveTraits(.isButton)
        .accessibilityHint("수면 타이머를 설정합니다")
        .accessibilityIdentifier("sleep-timer-button")
        .modifier(GlassCapsuleSurfaceModifier(
            horizontalPadding: horizontalPadding,
            cornerRadius: AppControlLayout.barCornerRadius
        ))
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
