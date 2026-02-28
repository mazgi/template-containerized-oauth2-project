using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;

namespace app.Views;

public sealed partial class SignInPage : Page
{
    public SignInPage()
    {
        InitializeComponent();
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
        SignInButton.Content = loading ? "Signing in..." : "Sign In";
    }

    private void UpdateUI()
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
