using System;
using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Appium;
using OpenQA.Selenium.Appium.Windows;
using OpenQA.Selenium.Support.UI;

namespace E2ETests;

[SetUpFixture]
public class AppiumSetup
{
    private static WindowsDriver? _driver;

    public static WindowsDriver Driver =>
        _driver ?? throw new InvalidOperationException("WindowsDriver is not initialized. Ensure AppiumSetup has run.");

    [OneTimeSetUp]
    public void RunBeforeAnyTests()
    {
        var appId = TestContext.Parameters["AppId"];
        if (string.IsNullOrEmpty(appId) || appId.Contains("REPLACE_WITH"))
        {
            throw new InvalidOperationException(
                "AppId is not configured. Update test.runsettings with your app's Package Family Name. " +
                "Run: Get-AppxPackage | Where-Object { $_.Name -like '*f0af5309*' } | Select-Object PackageFamilyName");
        }

        var appiumUrl = TestContext.Parameters["AppiumUrl"] ?? "http://127.0.0.1:4723";

        var options = new AppiumOptions
        {
            AutomationName = "windows",
            PlatformName = "Windows",
            App = appId,
        };
        options.AddAdditionalAppiumOption("appium:appArguments", "--uitesting");
        options.AddAdditionalAppiumOption("ms:waitForAppLaunch", 10);

        // Use 120s command timeout: WinUI 3 cold-start with Windows App SDK runtime
        // initialization can exceed the default 60s on CI runners.
        _driver = new WindowsDriver(new Uri(appiumUrl), options, TimeSpan.FromSeconds(120));
        _driver.Manage().Window.Maximize();
        _driver.Manage().Timeouts().ImplicitWait = TimeSpan.FromSeconds(5);

        // Wait for the app to fully load before running tests.
        // On CI (cold start with Windows App SDK runtime init), this can take 30+ seconds.
        var wait = new WebDriverWait(_driver, TimeSpan.FromSeconds(60));
        wait.Until(d =>
        {
            try
            {
                return d.FindElement(MobileBy.AccessibilityId("signin_emailTextBox")).Displayed;
            }
            catch (NoSuchElementException)
            {
                return false;
            }
        });
    }

    [OneTimeTearDown]
    public void RunAfterAnyTests()
    {
        _driver?.Quit();
        _driver = null;
    }
}
