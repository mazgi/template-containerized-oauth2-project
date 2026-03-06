//
//  AppGitShaUITests.swift
//  appUITests
//

import XCTest

final class AppGitShaUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testGitShaLabelIsVisible() throws {
        let label = app.staticTexts["gitShaLabel"]
        XCTAssertTrue(label.waitForExistence(timeout: 10))
        XCTAssertFalse(label.label.isEmpty)
    }

    func testGitShaLabelShowsCombinedFormat() throws {
        let label = app.staticTexts["gitShaLabel"]
        XCTAssertTrue(label.waitForExistence(timeout: 10))

        // Wait for the backend fetch to update the label to f/b or f: format
        let predicate = NSPredicate(format: "label BEGINSWITH 'f/b: ' OR label BEGINSWITH 'f: '")
        expectation(for: predicate, evaluatedWith: label, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
    }
}
