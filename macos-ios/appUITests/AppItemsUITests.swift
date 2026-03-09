//
//  AppItemsUITests.swift
//  appUITests
//

import XCTest

final class AppItemsUITests: XCTestCase {

    private var app: XCUIApplication!
    private static var counter = 0

    private static func uniqueEmail(_ prefix: String = "items") -> String {
        counter += 1
        return "\(prefix).\(Int(Date().timeIntervalSince1970)).\(counter)@example.com"
    }

    private let defaultPassword = "password123"

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        TestHelpers.dismissSystemAlerts()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helpers

    /// Create a verified user via API + Mailpit, then sign in via UI.
    private func createVerifiedUserAndSignIn(email: String) {
        TestHelpers.createVerifiedUser(email: email, password: defaultPassword)

        let emailField = app.textFields["signin_emailTextField"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText(email)

        app.secureTextFields["signin_passwordTextField"].tap()
        app.secureTextFields["signin_passwordTextField"].typeText(defaultPassword)

        app.buttons["signin_submitButton"].tap()
        TestHelpers.dismissSystemAlerts(app: app)
        XCTAssertTrue(app.staticTexts["dashboard_userEmail"].waitForExistence(timeout: 10))
        // Dismiss "Save Password?" dialog that may appear after dashboard loads
        TestHelpers.dismissSystemAlerts(app: app)
    }

    private func tapTab(_ label: String) {
        // Dismiss any lingering system dialogs before tab navigation
        TestHelpers.dismissSystemAlerts(app: app)

        // iOS 26 Liquid Glass TabView doesn't respond to XCUITest taps.
        // Use the test segmented picker bound to selectedTab.
        let indices = ["Dashboard": 0, "Items": 1, "Settings": 2]
        guard let index = indices[label] else {
            XCTFail("Unknown tab: \(label)")
            return
        }
        let picker = app.segmentedControls.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "Test tab picker not found")
        let segment = picker.buttons.element(boundBy: index)
        XCTAssertTrue(segment.waitForExistence(timeout: 2), "Segment \(index) not found")
        segment.tap()
    }

    private func navigateToItems() {
        tapTab("Items")
        XCTAssertTrue(app.textFields["items_nameTextField"].waitForExistence(timeout: 5))
    }

    private func navigateToDashboard() {
        tapTab("Dashboard")
        XCTAssertTrue(app.staticTexts["dashboard_userEmail"].waitForExistence(timeout: 5))
    }

    private func addItem(name: String) {
        let textField = app.textFields["items_nameTextField"]
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        textField.tap()
        textField.typeText(name)
        app.buttons["items_addButton"].tap()
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 10))
    }

    // MARK: - Empty State

    func testShowsEmptyStateWhenNoItems() throws {
        createVerifiedUserAndSignIn(email: Self.uniqueEmail("empty"))
        navigateToItems()

        XCTAssertTrue(app.staticTexts["items_emptyState"].waitForExistence(timeout: 5))
    }

    // MARK: - Create

    func testCreateItemAppearsInList() throws {
        createVerifiedUserAndSignIn(email: Self.uniqueEmail("create"))
        navigateToItems()

        let itemName = "Test item \(Int(Date().timeIntervalSince1970))"
        addItem(name: itemName)

        XCTAssertFalse(app.staticTexts["items_emptyState"].exists)
    }

    func testInputClearedAfterCreation() throws {
        createVerifiedUserAndSignIn(email: Self.uniqueEmail("cleared"))
        navigateToItems()

        let textField = app.textFields["items_nameTextField"]
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        textField.tap()
        textField.typeText("Cleared after add")
        app.buttons["items_addButton"].tap()

        XCTAssertTrue(app.staticTexts["Cleared after add"].waitForExistence(timeout: 10))
        // When empty, the field shows its placeholder as the value
        XCTAssertEqual(textField.value as? String, "Item name")
    }

    func testAddButtonDisabledWhenInputEmpty() throws {
        createVerifiedUserAndSignIn(email: Self.uniqueEmail("disabled"))
        navigateToItems()

        // Disabled SwiftUI buttons may not appear under app.buttons in the accessibility tree.
        // Use descendants(matching: .any) to find the element regardless of its enabled state.
        let addButton = app.descendants(matching: .any)
            .matching(identifier: "items_addButton")
            .firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        XCTAssertFalse(addButton.isEnabled)

        let textField = app.textFields["items_nameTextField"]
        textField.tap()
        textField.typeText("Valid name")

        // Wait for SwiftUI to re-enable the button after binding update
        let enabledPredicate = NSPredicate(format: "enabled == true")
        expectation(for: enabledPredicate, evaluatedWith: addButton, handler: nil)
        waitForExpectations(timeout: 5)
    }

    // MARK: - Delete

    func testDeleteItemDisappearsFromList() throws {
        createVerifiedUserAndSignIn(email: Self.uniqueEmail("delete"))
        navigateToItems()

        let itemName = "Delete me \(Int(Date().timeIntervalSince1970))"
        addItem(name: itemName)

        app.buttons["Delete \(itemName)"].tap()

        XCTAssertTrue(app.staticTexts[itemName].waitForNonExistence(timeout: 5))
    }

    func testShowsEmptyStateAfterAllItemsDeleted() throws {
        createVerifiedUserAndSignIn(email: Self.uniqueEmail("afterdelete"))
        navigateToItems()

        let itemName = "Only item \(Int(Date().timeIntervalSince1970))"
        addItem(name: itemName)

        app.buttons["Delete \(itemName)"].tap()

        XCTAssertTrue(app.staticTexts["items_emptyState"].waitForExistence(timeout: 5))
    }

    func testCreateMultipleItems() throws {
        createVerifiedUserAndSignIn(email: Self.uniqueEmail("multi"))
        navigateToItems()

        let ts = Int(Date().timeIntervalSince1970)
        let names = ["Alpha \(ts)", "Beta \(ts)", "Gamma \(ts)"]

        for name in names {
            addItem(name: name)
        }

        for name in names {
            XCTAssertTrue(app.staticTexts[name].exists)
        }
    }

    // MARK: - Tab Navigation

    func testTabNavigationToItems() throws {
        createVerifiedUserAndSignIn(email: Self.uniqueEmail("navitems"))
        navigateToItems()

        XCTAssertTrue(app.textFields["items_nameTextField"].exists)
    }

    func testTabNavigationBackToDashboard() throws {
        createVerifiedUserAndSignIn(email: Self.uniqueEmail("navdash"))
        navigateToItems()
        navigateToDashboard()

        XCTAssertTrue(app.staticTexts["dashboard_userEmail"].exists)
    }
}
