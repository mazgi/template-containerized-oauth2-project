using System;
using OpenQA.Selenium;
using OpenQA.Selenium.Appium;
using OpenQA.Selenium.Appium.Windows;
using OpenQA.Selenium.Support.UI;
namespace E2ETests.Helpers;

public abstract class BaseTest
{
    protected WindowsDriver Driver => AppiumSetup.Driver;

    protected AppiumElement FindByAutomationId(string automationId)
    {
        return (AppiumElement)Driver.FindElement(MobileBy.AccessibilityId(automationId));
    }

    protected AppiumElement WaitForElement(string automationId, int timeoutSeconds = 15)
    {
        var wait = new WebDriverWait(Driver, TimeSpan.FromSeconds(timeoutSeconds));
        return (AppiumElement)wait.Until(d =>
        {
            try
            {
                var el = d.FindElement(MobileBy.AccessibilityId(automationId));
                return el.Displayed ? el : null;
            }
            catch (NoSuchElementException)
            {
                return null;
            }
        })!;
    }

    protected AppiumElement ScrollToElement(string automationId, int timeoutSeconds = 15)
    {
        // Wait for the element to exist in the UI Automation tree, regardless of
        // viewport position. Unlike WaitForElement, this does NOT require Displayed
        // to be true. Use this for elements inside a ScrollViewer that may be
        // off-screen. WinAppDriver's Click() uses IInvokeProvider for button-like
        // elements, which works even when the element is scrolled out of view.
        var wait = new WebDriverWait(Driver, TimeSpan.FromSeconds(timeoutSeconds));
        return (AppiumElement)wait.Until(d =>
        {
            try
            {
                return d.FindElement(MobileBy.AccessibilityId(automationId));
            }
            catch (NoSuchElementException)
            {
                return null;
            }
        })!;
    }

    protected AppiumElement WaitForText(string text, int timeoutSeconds = 15)
    {
        var wait = new WebDriverWait(Driver, TimeSpan.FromSeconds(timeoutSeconds));
        return (AppiumElement)wait.Until(d =>
        {
            try
            {
                var el = d.FindElement(By.XPath($"//*[@Name='{text}']"));
                return el.Displayed ? el : null;
            }
            catch (NoSuchElementException)
            {
                return null;
            }
        })!;
    }

    protected void WaitForElementGone(string automationId, int timeoutSeconds = 10)
    {
        var wait = new WebDriverWait(Driver, TimeSpan.FromSeconds(timeoutSeconds));
        wait.Until(d =>
        {
            try
            {
                var el = d.FindElement(MobileBy.AccessibilityId(automationId));
                return !el.Displayed;
            }
            catch (NoSuchElementException)
            {
                return true;
            }
        });
    }

    protected void WaitForEnabled(string automationId, int timeoutSeconds = 15)
    {
        var wait = new WebDriverWait(Driver, TimeSpan.FromSeconds(timeoutSeconds));
        wait.Until(d =>
        {
            try
            {
                var el = d.FindElement(MobileBy.AccessibilityId(automationId));
                return el.Enabled;
            }
            catch (NoSuchElementException)
            {
                return false;
            }
        });
    }

    protected void EnsureOnSignInPage()
    {
        // If on a signed-in screen, sign out first
        try
        {
            var signOutButton = Driver.FindElement(MobileBy.AccessibilityId("dashboard_signOutButton"));
            if (signOutButton.Displayed)
            {
                signOutButton.Click();
                WaitForElement("signin_emailTextBox");
                return;
            }
        }
        catch (NoSuchElementException) { }

        // If on ShellPage but not Dashboard, try navigating to Dashboard first
        try
        {
            var dashTab = Driver.FindElement(By.XPath("//*[@Name='Dashboard']"));
            if (dashTab.Displayed)
            {
                dashTab.Click();
                var signOut = WaitForElement("dashboard_signOutButton", 5);
                signOut.Click();
                WaitForElement("signin_emailTextBox");
                return;
            }
        }
        catch (NoSuchElementException) { }

        // If on verification-sent screen, navigate back to sign-in
        try
        {
            var verificationSignIn = Driver.FindElement(MobileBy.AccessibilityId("signup_verificationGoToSignInButton"));
            if (verificationSignIn.Displayed)
            {
                verificationSignIn.Click();
                WaitForElement("signin_emailTextBox");
                return;
            }
        }
        catch (NoSuchElementException) { }

        // If on sign-up page, navigate back to sign-in
        try
        {
            var signInLink = Driver.FindElement(MobileBy.AccessibilityId("signup_goToSignInButton"));
            if (signInLink.Displayed)
            {
                signInLink.Click();
                WaitForElement("signin_emailTextBox");
            }
        }
        catch (NoSuchElementException) { }
    }
}
