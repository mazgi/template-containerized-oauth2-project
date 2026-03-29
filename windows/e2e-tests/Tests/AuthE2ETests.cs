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
        NavigateToSignUp();
        FillSignUpForm(email, TestHelpers.DefaultPassword);
        FindByAutomationId("signup_submitButton").Click();

        // Should show verification-sent screen, not Dashboard
        var title = WaitForElement("signup_verificationSentTitle", 15);
        Assert.That(title.Text, Is.EqualTo("Check your email"));

        var resendButton = WaitForElement("signup_resendButton", 5);
        Assert.That(resendButton.Displayed, Is.True);
    }

    [Test]
    public void SignUp_DuplicateEmail_ShowsError()
    {
        var email = TestHelpers.UniqueEmail("dup");

        // First: create verified user via API
        TestHelpers.CreateVerifiedUser(email);

        // Second sign-up with same email via UI
        NavigateToSignUp();
        FillSignUpForm(email, TestHelpers.DefaultPassword);
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
        CreateVerifiedUserAndSignIn(email);

        var userEmail = WaitForElement("dashboard_userEmail", 15);
        Assert.That(userEmail.Text, Is.EqualTo(email));
    }

    [Test]
    public void SignIn_WrongPassword_ShowsError()
    {
        var email = TestHelpers.UniqueEmail("wrongpw");
        TestHelpers.CreateVerifiedUser(email);

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
        CreateVerifiedUserAndSignIn(TestHelpers.UniqueEmail("signout"));
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

    // --- Forgot Password from Sign In ---

    [Test]
    public void ForgotPassword_ShowsButtonOnSignInPage()
    {
        var button = ScrollToElement("signin_forgotPasswordButton", 10);
        Assert.That(button, Is.Not.Null);
    }

    [Test]
    public void ForgotPassword_ShowsErrorWithoutEmail()
    {
        var button = ScrollToElement("signin_forgotPasswordButton", 10);
        button.Click();

        var errorText = WaitForElement("signin_errorText", 10);
        Assert.That(errorText.Displayed, Is.True);
    }

    [Test]
    public void ForgotPassword_ShowsSuccessMessage()
    {
        var email = TestHelpers.UniqueEmail("forgotpw");
        TestHelpers.CreateVerifiedUser(email);

        var emailBox = FindByAutomationId("signin_emailTextBox");
        emailBox.Clear();
        emailBox.SendKeys(email);

        var button = ScrollToElement("signin_forgotPasswordButton", 10);
        button.Click();

        var successText = WaitForElement("signin_resetSentText", 15);
        Assert.That(successText.Displayed, Is.True);
    }

    [Test]
    public void ForgotPassword_FullResetFlow()
    {
        var email = TestHelpers.UniqueEmail("forgotflow");
        var newPassword = "ResetFromLogin1!";
        TestHelpers.CreateVerifiedUser(email);

        // Request reset from sign-in page
        var emailBox = FindByAutomationId("signin_emailTextBox");
        emailBox.Clear();
        emailBox.SendKeys(email);

        var button = ScrollToElement("signin_forgotPasswordButton", 10);
        button.Click();

        WaitForElement("signin_resetSentText", 15);

        // Get reset token and reset password via API
        var token = TestHelpers.GetPasswordResetToken(email);
        TestHelpers.PostJson("http://localhost:4000/auth/reset-password",
            $"{{\"token\":\"{token}\",\"password\":\"{newPassword}\"}}");

        // Sign in with new password
        emailBox = FindByAutomationId("signin_emailTextBox");
        emailBox.Clear();
        emailBox.SendKeys(email);

        var passwordBox = FindByAutomationId("signin_passwordBox");
        passwordBox.Clear();
        passwordBox.SendKeys(newPassword);

        FindByAutomationId("signin_submitButton").Click();

        var userEmail = WaitForElement("dashboard_userEmail", 15);
        Assert.That(userEmail.Text, Is.EqualTo(email));
    }

    [Test]
    public void ForgotPassword_SuccessForNonExistentEmail()
    {
        var email = TestHelpers.UniqueEmail("noexist_forgot");

        var emailBox = FindByAutomationId("signin_emailTextBox");
        emailBox.Clear();
        emailBox.SendKeys(email);

        var button = ScrollToElement("signin_forgotPasswordButton", 10);
        button.Click();

        // Should still show success to prevent email enumeration
        var successText = WaitForElement("signin_resetSentText", 15);
        Assert.That(successText.Displayed, Is.True);
    }

    [Test]
    public void SignUpPage_HasForgotPasswordLink()
    {
        NavigateToSignUp();
        var link = ScrollToElement("signup_forgotPasswordButton", 10);
        Assert.That(link, Is.Not.Null);
    }

    // --- Change Email ---

    [Test]
    public void ChangeEmail_UpdatesEmailAndResetsVerification()
    {
        var oldEmail = TestHelpers.UniqueEmail("oldemail");
        var newEmail = TestHelpers.UniqueEmail("newemail");
        CreateVerifiedUserAndSignIn(oldEmail);

        // Navigate to Settings tab
        var settingsTab = WaitForText("Settings", 10);
        settingsTab.Click();

        // Wait for Email section to appear
        ScrollToElement("settings_emailTextField", 15);

        // Enter new email and save
        var emailBox = FindByAutomationId("settings_emailTextField");
        emailBox.Clear();
        emailBox.SendKeys(newEmail);

        FindByAutomationId("settings_saveEmail").Click();

        // Wait for API call to complete
        WaitForEnabled("settings_saveEmail", 15);

        // Verify the new email is displayed as Unverified
        var unverifiedText = WaitForText("Unverified", 10);
        Assert.That(unverifiedText.Displayed, Is.True);
    }

    // --- Password Reset ---

    [Test]
    public void PasswordReset_SendResetLinkFromSettings()
    {
        var email = TestHelpers.UniqueEmail("pwreset");
        CreateVerifiedUserAndSignIn(email);

        // Navigate to Settings tab
        var settingsTab = WaitForText("Settings", 10);
        settingsTab.Click();

        // Click "Send reset link"
        var resetButton = ScrollToElement("settings_passwordReset", 15);
        resetButton.Click();

        // Wait for success message
        WaitForText("Password reset link sent. Please check your inbox.", 15);

        // Verify reset email arrived in Mailpit
        var token = TestHelpers.GetPasswordResetToken(email);
        Assert.That(token, Is.Not.Empty);
    }

    [Test]
    public void PasswordReset_ResetAndSignInWithNewPassword()
    {
        var email = TestHelpers.UniqueEmail("pwresetlogin");
        var newPassword = "NewPassword1!";
        CreateVerifiedUserAndSignIn(email);

        // Request password reset via API
        TestHelpers.PostJson($"http://localhost:4000/auth/forgot-password",
            $"{{\"email\":\"{email}\"}}");

        // Get reset token and reset password via API
        var token = TestHelpers.GetPasswordResetToken(email);
        TestHelpers.PostJson($"http://localhost:4000/auth/reset-password",
            $"{{\"token\":\"{token}\",\"password\":\"{newPassword}\"}}");

        // Sign out
        SignOut();

        // Sign in with new password
        SignInViaUI(email, newPassword);
        var userEmail = WaitForElement("dashboard_userEmail", 15);
        Assert.That(userEmail.Text, Is.EqualTo(email));
    }

    [Test]
    public void PasswordReset_OldPasswordFailsAfterReset()
    {
        var email = TestHelpers.UniqueEmail("pwold");
        var newPassword = "NewPassword1!";
        CreateVerifiedUserAndSignIn(email);

        // Request password reset via API and reset
        TestHelpers.PostJson($"http://localhost:4000/auth/forgot-password",
            $"{{\"email\":\"{email}\"}}");
        var token = TestHelpers.GetPasswordResetToken(email);
        TestHelpers.PostJson($"http://localhost:4000/auth/reset-password",
            $"{{\"token\":\"{token}\",\"password\":\"{newPassword}\"}}");

        // Sign out
        SignOut();

        // Try to sign in with old password — should fail
        SignInViaUI(email, TestHelpers.DefaultPassword);
        WaitForEnabled("signin_submitButton", 15);

        var errorText = WaitForElement("signin_errorText", 5);
        Assert.That(errorText.Displayed, Is.True);
    }

    [Test]
    public void PasswordReset_ButtonDisabledWhenEmailUnverified()
    {
        var oldEmail = TestHelpers.UniqueEmail("pwunverified");
        var newEmail = TestHelpers.UniqueEmail("pwunverifiednew");
        CreateVerifiedUserAndSignIn(oldEmail);

        // Navigate to Settings
        var settingsTab = WaitForText("Settings", 10);
        settingsTab.Click();

        // Change email to reset verification
        ScrollToElement("settings_emailTextField", 15);
        var emailBox = FindByAutomationId("settings_emailTextField");
        emailBox.Clear();
        emailBox.SendKeys(newEmail);
        FindByAutomationId("settings_saveEmail").Click();

        // Wait for "Unverified" to appear
        WaitForText("Unverified", 15);

        // The password reset button should be disabled
        var resetButton = ScrollToElement("settings_passwordReset", 10);
        Assert.That(resetButton.Enabled, Is.False);

        // Verify the description text indicates verification is required
        WaitForText("To use this feature, please verify your email address first.", 10);
    }

    // --- Helpers ---

    private void NavigateToSignUp()
    {
        var link = ScrollToElement("signin_goToSignUpButton", 10);
        link.Click();
        WaitForElement("signup_emailTextBox", 5);
    }

    private void FillSignUpForm(string email, string password)
    {
        var emailBox = FindByAutomationId("signup_emailTextBox");
        emailBox.Clear();
        emailBox.SendKeys(email);

        var passwordBox = FindByAutomationId("signup_passwordBox");
        passwordBox.Clear();
        passwordBox.SendKeys(password);
    }

    private void CreateVerifiedUserAndSignIn(string email)
    {
        TestHelpers.CreateVerifiedUser(email);
        SignInViaUI(email, TestHelpers.DefaultPassword);
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
