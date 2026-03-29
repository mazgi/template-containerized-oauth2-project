using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;

namespace app.Views;

public sealed partial class SignInPage : Page
{
    public SignInPage()
    {
        InitializeComponent();
        SignInButton.Content = Strings.Get("SignIn");
        MfaVerifyButton.Content = Strings.Get("Verify");
        Loaded += (_, _) => UpdateUI();
    }

    private async void SignInButton_Click(object sender, RoutedEventArgs e)
    {
        var email = EmailBox.Text.Trim();
        var password = PasswordBox.Password;
        if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(password)) return;

        SetLoading(true);
        await App.Auth.SignInAsync(email, password);
        SetLoading(false);
        UpdateUI();
    }

    private async void MfaVerifyButton_Click(object sender, RoutedEventArgs e)
    {
        var code = MfaCodeBox.Text.Trim();
        if (string.IsNullOrEmpty(code)) return;

        SetMfaLoading(true);
        await App.Auth.VerifyMfaAsync(code);
        SetMfaLoading(false);
        UpdateUI();
    }

    private void MfaCodeBox_KeyDown(object sender, KeyRoutedEventArgs e)
    {
        if (e.Key == Windows.System.VirtualKey.Enter)
            MfaVerifyButton_Click(sender, e);
    }

    private void MfaBackButton_Click(object sender, RoutedEventArgs e)
    {
        App.Auth.ClearError();
        App.Auth.MfaToken = null;
        MfaCodeBox.Text = "";
        UpdateUI();
    }

    private async void AppleButton_Click(object sender, RoutedEventArgs e)
    {
        await App.Auth.SignInWithAppleAsync();
    }

    private async void DiscordButton_Click(object sender, RoutedEventArgs e)
    {
        await App.Auth.SignInWithDiscordAsync();
    }

    private async void GitHubButton_Click(object sender, RoutedEventArgs e)
    {
        await App.Auth.SignInWithGithubAsync();
    }

    private async void GoogleButton_Click(object sender, RoutedEventArgs e)
    {
        await App.Auth.SignInWithGoogleAsync();
    }

    private async void TwitterButton_Click(object sender, RoutedEventArgs e)
    {
        await App.Auth.SignInWithTwitterAsync();
    }

    private async void ForgotPasswordLink_Click(object sender, RoutedEventArgs e)
    {
        var email = EmailBox.Text.Trim();
        if (string.IsNullOrEmpty(email))
        {
            App.Auth.ErrorMessage = Strings.Get("ForgotPasswordEnterEmail");
            UpdateUI();
            return;
        }

        ForgotPasswordLink.IsEnabled = false;
        await App.Auth.ForgotPasswordFromSignInAsync(email);
        ForgotPasswordLink.IsEnabled = true;
        UpdateUI();
    }

    private void SignUpLink_Click(object sender, RoutedEventArgs e)
    {
        App.Auth.ClearError();
        Frame.Navigate(typeof(SignUpPage));
    }

    private void PasswordBox_KeyDown(object sender, KeyRoutedEventArgs e)
    {
        if (e.Key == Windows.System.VirtualKey.Enter)
            SignInButton_Click(sender, e);
    }

    private void SetLoading(bool loading)
    {
        SignInButton.IsEnabled = !loading;
        EmailBox.IsEnabled = !loading;
        PasswordBox.IsEnabled = !loading;
        SignInButton.Content = loading ? Strings.Get("SigningIn") : Strings.Get("SignIn");
    }

    private void SetMfaLoading(bool loading)
    {
        MfaVerifyButton.IsEnabled = !loading;
        MfaCodeBox.IsEnabled = !loading;
        MfaVerifyButton.Content = loading ? Strings.Get("Verifying") : Strings.Get("Verify");
    }

    private void UpdateUI()
    {
        var hasMfa = App.Auth.MfaToken is not null;
        SignInPanel.Visibility = hasMfa ? Visibility.Collapsed : Visibility.Visible;
        MfaPanel.Visibility = hasMfa ? Visibility.Visible : Visibility.Collapsed;

        ResetSentText.Visibility = App.Auth.PasswordResetSent ? Visibility.Visible : Visibility.Collapsed;

        if (hasMfa)
        {
            if (App.Auth.ErrorMessage is { } mfaMsg)
            {
                MfaErrorText.Text = mfaMsg;
                MfaErrorText.Visibility = Visibility.Visible;
            }
            else
            {
                MfaErrorText.Visibility = Visibility.Collapsed;
            }
        }
        else
        {
            if (App.Auth.ErrorMessage is { } msg)
            {
                ErrorText.Text = msg;
                ErrorText.Visibility = Visibility.Visible;
            }
            else
            {
                ErrorText.Visibility = Visibility.Collapsed;
            }
        }
    }
}
