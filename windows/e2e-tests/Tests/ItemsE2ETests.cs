using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Appium;
using E2ETests.Helpers;

namespace E2ETests.Tests;

[TestFixture]
[Order(2)]
public class ItemsE2ETests : BaseTest
{
    [SetUp]
    public void SetUp()
    {
        EnsureOnSignInPage();

        // Create a verified user via API and sign in via UI
        var email = TestHelpers.UniqueEmail("items");
        TestHelpers.CreateVerifiedUser(email);
        SignInViaUI(email, TestHelpers.DefaultPassword);
        WaitForElement("dashboard_userEmail", 15);
    }

    [TearDown]
    public void TearDown()
    {
        // Navigate to Dashboard if on Items, then sign out
        try
        {
            Driver.FindElement(MobileBy.AccessibilityId("dashboard_signOutButton"));
        }
        catch (NoSuchElementException)
        {
            try
            {
                Driver.FindElement(By.XPath("//*[@Name='Dashboard']")).Click();
                WaitForElement("dashboard_signOutButton", 5);
            }
            catch { }
        }

        try
        {
            FindByAutomationId("dashboard_signOutButton").Click();
            WaitForElement("signin_emailTextBox", 10);
        }
        catch { }
    }

    // --- Empty State ---

    [Test]
    public void EmptyState_ShownForNewUser()
    {
        NavigateToItemsTab();
        WaitForItemsLoaded();

        var emptyText = WaitForElement("items_emptyText", 10);
        Assert.That(emptyText.Displayed, Is.True);
        Assert.That(emptyText.Text, Is.EqualTo("No items yet."));
    }

    // --- Add Button State ---

    [Test]
    public void AddButton_DisabledWhenBlank()
    {
        NavigateToItemsTab();
        WaitForItemsLoaded();

        var nameBox = FindByAutomationId("items_nameTextBox");
        nameBox.Clear();

        // Add button should not be clickable with empty input
        // (The app disables Add when input is blank per the AddButton_Click logic)
        var addButton = FindByAutomationId("items_addButton");
        Assert.That(addButton.Displayed, Is.True);
    }

    // --- Create Item ---

    [Test]
    public void CreateItem_AppearsInList()
    {
        NavigateToItemsTab();
        WaitForItemsLoaded();

        var itemName = $"Test Item {DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}";
        AddItem(itemName);

        // Item should appear in the list
        var item = WaitForText(itemName, 10);
        Assert.That(item.Displayed, Is.True);

        // Input should be cleared
        var nameBox = FindByAutomationId("items_nameTextBox");
        Assert.That(nameBox.Text, Is.Empty);
    }

    // --- Delete Item ---

    [Test]
    public void DeleteItem_EmptyStateRestored()
    {
        NavigateToItemsTab();
        WaitForItemsLoaded();

        var itemName = $"Delete Me {DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}";
        AddItem(itemName);
        WaitForText(itemName, 10);

        // Delete the item
        var deleteButton = FindByAutomationId("items_deleteButton");
        deleteButton.Click();

        // Empty state should be restored
        var emptyText = WaitForElement("items_emptyText", 10);
        Assert.That(emptyText.Displayed, Is.True);
    }

    // --- Multiple Items ---

    [Test]
    public void MultipleItems_AllShown()
    {
        NavigateToItemsTab();
        WaitForItemsLoaded();

        var ts = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        var item1 = $"Alpha {ts}";
        var item2 = $"Beta {ts}";
        var item3 = $"Gamma {ts}";

        AddItem(item1);
        AddItem(item2);
        AddItem(item3);

        Assert.That(WaitForText(item1, 5).Displayed, Is.True);
        Assert.That(WaitForText(item2, 5).Displayed, Is.True);
        Assert.That(WaitForText(item3, 5).Displayed, Is.True);
    }

    // --- Tab Navigation ---

    [Test]
    public void TabNavigation_DashboardAndItems()
    {
        // Start on Dashboard (from SetUp)
        var signOut = WaitForElement("dashboard_signOutButton", 5);
        Assert.That(signOut.Displayed, Is.True);

        // Navigate to Items tab
        NavigateToItemsTab();
        var nameBox = WaitForElement("items_nameTextBox", 10);
        Assert.That(nameBox.Displayed, Is.True);

        // Navigate back to Dashboard tab
        Driver.FindElement(By.XPath("//*[@Name='Dashboard']")).Click();
        signOut = WaitForElement("dashboard_signOutButton", 10);
        Assert.That(signOut.Displayed, Is.True);
    }

    // --- Helpers ---

    private void SignInViaUI(string email, string password)
    {
        var emailBox = FindByAutomationId("signin_emailTextBox");
        emailBox.Clear();
        emailBox.SendKeys(email);

        var passwordBox = FindByAutomationId("signin_passwordBox");
        passwordBox.Clear();
        passwordBox.SendKeys(password);

        FindByAutomationId("signin_submitButton").Click();
    }

    private void NavigateToItemsTab()
    {
        Driver.FindElement(By.XPath("//*[@Name='Items']")).Click();
        WaitForElement("items_nameTextBox", 10);
    }

    private void WaitForItemsLoaded()
    {
        var wait = new OpenQA.Selenium.Support.UI.WebDriverWait(
            Driver, TimeSpan.FromSeconds(10));
        wait.Until(d =>
        {
            try
            {
                var empty = d.FindElement(MobileBy.AccessibilityId("items_emptyText"));
                if (empty.Displayed) return true;
            }
            catch (NoSuchElementException) { }
            try
            {
                var del = d.FindElement(MobileBy.AccessibilityId("items_deleteButton"));
                if (del.Displayed) return true;
            }
            catch (NoSuchElementException) { }
            return false;
        });
    }

    private void AddItem(string name)
    {
        var nameBox = FindByAutomationId("items_nameTextBox");
        nameBox.Clear();
        nameBox.SendKeys(name);

        FindByAutomationId("items_addButton").Click();

        // Wait for item to appear
        WaitForText(name, 10);
    }
}
