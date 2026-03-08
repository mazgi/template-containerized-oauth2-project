using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Appium;
using E2ETests.Helpers;

namespace E2ETests.Tests;

[TestFixture]
[Order(4)]
public class ThemeE2ETests : BaseTest
{
    [SetUp]
    public void SetUp()
    {
        EnsureOnSignInPage();
    }

    private void SignUpAndNavigateToSettings()
    {
        var email = TestHelpers.UniqueEmail("theme");
        TestHelpers.CreateVerifiedUser(email);

        // Sign in via UI
        var emailBox = FindByAutomationId("signin_emailTextBox");
        emailBox.Clear();
        emailBox.SendKeys(email);

        var passwordBox = FindByAutomationId("signin_passwordBox");
        passwordBox.Clear();
        passwordBox.SendKeys(TestHelpers.DefaultPassword);

        FindByAutomationId("signin_submitButton").Click();
        WaitForElement("dashboard_userEmail", 30);

        // Navigate to Settings tab
        var settingsTab = WaitForText("Settings", 10);
        settingsTab.Click();
        // Wait for a RadioButton (interactive control) — StackPanel AutomationId
        // may not be exposed in the UI Automation tree
        ScrollToElement("theme_system", 15);
    }

    [Test]
    public void ThemePicker_IsVisible()
    {
        SignUpAndNavigateToSettings();
        var systemBtn = ScrollToElement("theme_system");
        Assert.That(systemBtn, Is.Not.Null);
    }

    [Test]
    public void ThemePicker_ShowsAllOptions()
    {
        SignUpAndNavigateToSettings();
        var systemBtn = ScrollToElement("theme_system");
        var lightBtn = ScrollToElement("theme_light");
        var darkBtn = ScrollToElement("theme_dark");
        Assert.That(systemBtn, Is.Not.Null);
        Assert.That(lightBtn, Is.Not.Null);
        Assert.That(darkBtn, Is.Not.Null);
    }

    [Test]
    public void ThemePicker_DefaultIsSystem()
    {
        SignUpAndNavigateToSettings();
        var systemBtn = ScrollToElement("theme_system");
        Assert.That(IsRadioButtonChecked(systemBtn), Is.True);
    }

    [Test]
    public void ThemePicker_SwitchToDark()
    {
        SignUpAndNavigateToSettings();
        var darkBtn = ScrollToElement("theme_dark");
        darkBtn.Click();
        Assert.That(IsRadioButtonChecked(darkBtn), Is.True);

        var systemBtn = ScrollToElement("theme_system");
        Assert.That(IsRadioButtonChecked(systemBtn), Is.False);
    }

    [Test]
    public void ThemePicker_SwitchToLight()
    {
        SignUpAndNavigateToSettings();
        var lightBtn = ScrollToElement("theme_light");
        lightBtn.Click();
        Assert.That(IsRadioButtonChecked(lightBtn), Is.True);

        var systemBtn = ScrollToElement("theme_system");
        Assert.That(IsRadioButtonChecked(systemBtn), Is.False);
    }

    [Test]
    public void ThemePicker_CycleAllModes()
    {
        SignUpAndNavigateToSettings();

        // Default: System
        var systemBtn = ScrollToElement("theme_system");
        Assert.That(IsRadioButtonChecked(systemBtn), Is.True);

        // Switch to Dark
        var darkBtn = ScrollToElement("theme_dark");
        darkBtn.Click();
        Assert.That(IsRadioButtonChecked(darkBtn), Is.True);

        // Switch to Light
        var lightBtn = ScrollToElement("theme_light");
        lightBtn.Click();
        Assert.That(IsRadioButtonChecked(lightBtn), Is.True);

        // Back to System
        systemBtn = ScrollToElement("theme_system");
        systemBtn.Click();
        Assert.That(IsRadioButtonChecked(systemBtn), Is.True);
    }

    // --- Helpers ---

    private static bool IsRadioButtonChecked(AppiumElement element)
    {
        // WinAppDriver reports the toggle state via the "Selected" property
        var selected = element.Selected;
        if (selected) return true;
        // Fallback: check the element attribute
        var val = element.GetAttribute("Toggle.ToggleState");
        return val == "1";
    }
}
