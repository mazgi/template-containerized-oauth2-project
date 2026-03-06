using NUnit.Framework;
using OpenQA.Selenium.Appium;
using E2ETests.Helpers;

namespace E2ETests.Tests;

[TestFixture]
[Order(3)]
public class GitShaE2ETests : BaseTest
{
    [Test]
    public void GitShaLabel_IsDisplayed()
    {
        var label = WaitForElement("gitShaLabel", 15);
        Assert.That(label.Displayed, Is.True);
        Assert.That(label.Text, Is.Not.Empty);
    }

    [Test]
    public void GitShaLabel_ShowsCombinedFormat()
    {
        var label = WaitForElement("gitShaLabel", 15);

        // Wait for the backend fetch to update the label
        var wait = new OpenQA.Selenium.Support.UI.WebDriverWait(
            Driver, TimeSpan.FromSeconds(10));
        wait.Until(_ =>
        {
            var el = (AppiumElement)Driver.FindElement(
                OpenQA.Selenium.Appium.MobileBy.AccessibilityId("gitShaLabel"));
            return el.Text.StartsWith("f/b: ") || el.Text.StartsWith("f: ");
        });
    }
}
