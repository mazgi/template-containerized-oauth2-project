using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace app.Views;

public sealed partial class SignUpPage : Page
{
    public SignUpPage()
    {
        InitializeComponent();
        SignUpButton.Content = Strings.Get("SignUp");
        ResendButton.Content = Strings.Get("ResendVerificationEmail");
        Loaded += (_, _) => UpdateUI();
    }

    private async void SignUpButton_Click(object sender, RoutedEventArgs e)
    {
        var email = EmailBox.Text.Trim();
        var password = PasswordBox.Password;

        if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(password)) return;

        SetLoading(true);
        await App.Auth.SignUpAsync(email, password);
        SetLoading(false);
        UpdateUI();
    }

    private async void ResendButton_Click(object sender, RoutedEventArgs e)
    {
        var email = App.Auth.VerificationSentEmail;
        if (string.IsNullOrEmpty(email)) return;

        ResendButton.IsEnabled = false;
        ResendButton.Content = Strings.Get("Sending");
        await App.Auth.ResendVerificationAsync(email);
        ResendButton.Content = Strings.Get("ResendVerificationEmail");
        ResendButton.IsEnabled = true;
    }

    private void SignInLink_Click(object sender, RoutedEventArgs e)
    {
        App.Auth.ClearError();
        if (Frame.CanGoBack)
            Frame.GoBack();
        else
            Frame.Navigate(typeof(SignInPage));
    }

    private void VerificationSignInLink_Click(object sender, RoutedEventArgs e)
    {
        App.Auth.ClearError();
        App.Auth.ClearVerificationSent();
        if (Frame.CanGoBack)
            Frame.GoBack();
        else
            Frame.Navigate(typeof(SignInPage));
    }

    private void SetLoading(bool loading)
    {
        SignUpButton.IsEnabled = !loading;
        EmailBox.IsEnabled = !loading;
        PasswordBox.IsEnabled = !loading;
        SignUpButton.Content = loading ? Strings.Get("SigningUp") : Strings.Get("SignUp");
    }

    private void UpdateUI()
    {
        if (App.Auth.VerificationSentEmail is not null)
        {
            SignUpFormPanel.Visibility = Visibility.Collapsed;
            VerificationSentPanel.Visibility = Visibility.Visible;
            return;
        }

        SignUpFormPanel.Visibility = Visibility.Visible;
        VerificationSentPanel.Visibility = Visibility.Collapsed;

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
