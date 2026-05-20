//
//  AppStoreScreenshotsTests.swift
//  ListenToPsalmUITests
//

import XCTest

final class AppStoreScreenshotsTests: XCTestCase {
    private var outputDirectory: URL {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return projectRoot
            .appendingPathComponent("AppStoreScreenshots/iPhone-6.9-Display", isDirectory: true)
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCaptureAppStoreScreenshots() throws {
        let app = XCUIApplication()
        app.launch()

        try saveScreenshot(named: "01-home-matthew.png", app: app)

        app.buttons["마태오시편 05장"].tap()
        sleep(2)
        try saveScreenshot(named: "02-playing-progress.png", app: app)

        app.buttons["gospel-john"].tap()
        sleep(1)
        try saveScreenshot(named: "03-gospel-john.png", app: app)

        app.buttons["sleep-timer-button"].tap()
        sleep(1)
        try saveScreenshot(named: "04-sleep-timer.png", app: app)

        app.buttons["닫기"].tap()
        sleep(1)

        app.buttons["gospel-mark"].tap()
        sleep(1)
        app.buttons["마르코시편 05장"].tap()
        sleep(2)
        try saveScreenshot(named: "05-mark-continuous.png", app: app)
    }

    @MainActor
    private func saveScreenshot(named filename: String, app: XCUIApplication) throws {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.lifetime = .keepAlways
        add(attachment)

        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let url = outputDirectory.appendingPathComponent(filename)
        let data = XCUIScreen.main.screenshot().pngRepresentation
        try data.write(to: url, options: .atomic)
    }
}
