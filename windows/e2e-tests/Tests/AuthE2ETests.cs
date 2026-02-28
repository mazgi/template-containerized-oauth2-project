using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Appium;
using E2ETests.Helpers;

namespace E2ETests.Tests;

[TestFixture]
[Order(1)]
public class AuthE2ETests : BaseTest
{
    [SetUp]
    public void SetUp()
    {
        EnsureOnSignInPage();
    }

    // --- Sign Up ---

    [Test]
    public void SignUp_Success()
    {
        var email = TestHelpers.UniqueEmail("signup");
        SignUpViaUI(email);

        var userEmail = WaitForElement("dashboard_userEmail", 15);
        Assert.That(userEmail.Text, Is.EqualTo(email));
    }

    [Test]
    public void SignUp_PasswordMismatch_ShowsError()
    {
        NavigateToSignUp();
        FillSignUpForm(TestHelpers.UniqueEmail("mismatch"), TestHelpers.DefaultPassword, "DifferentPassword!");
        FindByAutomationId("signup_submitButton").Click();

        var mismatchError = WaitForElement("signup_mismatchText", 5);
        Assert.That(mismatchError.Displayed, Is.True);
        Assert.That(mismatchError.Text, Is.EqualTo("Passwords do not match"));
    }

    [Test]
    public void SignUp_DuplicateEmail_ShowsError()
    {
        var email = TestHelpers.UniqueEmail("dup");

        // First sign-up
        SignUpViaUI(email);
        SignOut();

        // Second sign-up with same email
        NavigateToSignUp();
        FillSignUpForm(email, TestHelpers.DefaultPassword, TestHelpers.DefaultPassword);
        FindByAutomationId("signup_submitButton").Click();

        // Wait for API call to finish
        WaitForEnabled("signup_submitButton", 15);

        // Should show error
        var errorText = WaitForElement("signup_errorText", 5);
        Assert.That(errorText.Displayed, Is.True);
    }

    // --- Sign In ---

    [Test]
    public void SignIn_Success()
    {
        var email = TestHelpers.UniqueEmail("signin");
        SignUpViaUI(email);
        SignOut();

        SignInViaUI(email, TestHelpers.DefaultPassword);

        var userEmail = WaitForElement("dashboard_userEmail", 15);
        Assert.That(userEmail.Text, Is.EqualTo(email));
    }

    [Test]
    public void SignIn_WrongPassword_ShowsError()
    {
        var email = TestHelpers.UniqueEmail("wrongpw");
        SignUpViaUI(email);
        SignOut();

        SignInViaUI(email, "WrongPassword!");

        WaitForEnabled("signin_submitButton", 15);
        var errorText = WaitForElement("signin_errorText", 5);
        Assert.That(errorText.Displayed, Is.True);
    }

    [Test]
    public void SignIn_NonExistentEmail_ShowsError()
    {
        var email = TestHelpers.UniqueEmail("noexist");
        SignInViaUI(email, TestHelpers.DefaultPassword);

        WaitForEnabled("signin_submitButton", 15);
        var errorText = WaitForElement("signin_errorText", 5);
        Assert.That(errorText.Displayed, Is.True);
    }

    // --- Sign Out ---

    [Test]
    public void SignOut_ReturnsToSignIn()
    {
        SignUpViaUI(TestHelpers.UniqueEmail("signout"));
        SignOut();

        var emailField = WaitForElement("signin_emailTextBox", 10);
        Assert.That(emailField.Displayed, Is.True);
    }

    // --- Navigation ---

    [Test]
    public void Navigation_SignInSignUpLinks()
    {
        // Sign In page has "Sign Up" link (may be off-screen in a ScrollViewer)
        var signUpLink = ScrollToElement("signin_goToSignUpButton", 10);
        Assert.That(signUpLink, Is.Not.Null);
        signUpLink.Click();

        // Sign Up page has "Sign In" link
        var signInLink = WaitForElement("signup_goToSignInButton", 5);
        Assert.That(signInLink.Displayed, Is.True);
        signInLink.Click();

        // Back on Sign In page
        WaitForElement("signin_emailTextBox", 5);
    }

    // --- Helpers ---

    private void NavigateToSignUp()
    {
        var link = ScrollToElement("signin_goToSignUpButton", 10);
        link.Click();
        WaitForElement("signup_emailTextBox", 5);
    }

    private void FillSignUpForm(string email, string password, string confirmPassword)
    {
        var emailBox = FindByAutomationId("signup_emailTextBox");
        emailBox.Clear();
        emailBox.SendKeys(email);

        var passwordBox = FindByAutomationId("signup_passwordBox");
        passwordBox.Clear();
        passwordBox.SendKeys(password);

        var confirmBox = FindByAutomationId("signup_confirmPasswordBox");
        confirmBox.Clear();
        confirmBox.SendKeys(confirmPassword);
    }

    private void SignUpViaUI(string email)
    {
        NavigateToSignUp();
        FillSignUpForm(email, TestHelpers.DefaultPassword, TestHelpers.DefaultPassword);
        FindByAutomationId("signup_submitButton").Click();
        WaitForElement("dashboard_userEmail", 30);
    }

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

    private void SignOut()
    {
        var button = WaitForElement("dashboard_signOutButton", 10);
        button.Click();
        WaitForElement("signin_emailTextBox", 10);
    }
}
