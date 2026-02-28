using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace app.Views;

public sealed partial class SignUpPage : Page
{
    public SignUpPage()
    {
        InitializeComponent();
        Loaded += (_, _) => UpdateUI();
    }

    private async void SignUpButton_Click(object sender, RoutedEventArgs e)
    {
        var email = EmailBox.Text.Trim();
        var password = PasswordBox.Password;
        var confirm = ConfirmPasswordBox.Password;

        if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(password)) return;

        if (password != confirm)
        {
            MismatchText.Visibility = Visibility.Visible;
            return;
        }
        MismatchText.Visibility = Visibility.Collapsed;

        SetLoading(true);
        await App.Auth.SignUpAsync(email, password);
        SetLoading(false);
        UpdateUI();
    }

    private void SignInLink_Click(object sender, RoutedEventArgs e)
    {
        App.Auth.ClearError();
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
        ConfirmPasswordBox.IsEnabled = !loading;
        SignUpButton.Content = loading ? "Signing up..." : "Sign Up";
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
