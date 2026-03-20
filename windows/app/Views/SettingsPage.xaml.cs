using System;
using System.Linq;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using app.ViewModels;

namespace app.Views;

public sealed partial class SettingsPage : Page
{
    public SettingsPage()
    {
        InitializeComponent();
        Loaded += (_, _) => UpdateUI();
        App.Auth.AuthStateChanged += UpdateUI;
    }

    private void UpdateUI()
    {
        var user = App.Auth.User;
        if (user is null) return;

        // Email section
        var isInvalidEmail = user.Email.EndsWith(".invalid");
        if (isInvalidEmail)
        {
            EmailAddressText.Text = Strings.Get("NotSet");
            EmailAddressText.FontStyle = Windows.UI.Text.FontStyle.Italic;
            EmailAddressText.Foreground = (Brush)Application.Current.Resources["TextFillColorSecondaryBrush"];
            EmailBadge.Visibility = Visibility.Collapsed;
            ResendVerificationButton.Visibility = Visibility.Collapsed;
        }
        else
        {
            EmailAddressText.Text = user.Email;
            EmailAddressText.FontStyle = Windows.UI.Text.FontStyle.Normal;
            EmailAddressText.Foreground = (Brush)Application.Current.Resources["TextFillColorPrimaryBrush"];
            EmailBadge.Visibility = Visibility.Visible;

            if (user.EmailVerified)
            {
                EmailBadgeText.Text = Strings.Get("Verified");
                EmailBadgeText.Foreground = new SolidColorBrush(ColorHelper.FromArgb(255, 22, 163, 74));
                EmailBadge.Background = new SolidColorBrush(ColorHelper.FromArgb(25, 34, 197, 94));
                EmailBadge.BorderBrush = new SolidColorBrush(ColorHelper.FromArgb(76, 34, 197, 94));
                ResendVerificationButton.Visibility = Visibility.Collapsed;
            }
            else
            {
                EmailBadgeText.Text = Strings.Get("Unverified");
                EmailBadgeText.Foreground = new SolidColorBrush(ColorHelper.FromArgb(255, 202, 138, 4));
                EmailBadge.Background = new SolidColorBrush(ColorHelper.FromArgb(25, 234, 179, 8));
                EmailBadge.BorderBrush = new SolidColorBrush(ColorHelper.FromArgb(76, 234, 179, 8));
                ResendVerificationButton.Visibility = Visibility.Visible;
            }
        }

        // Email dropdown with social emails
        var selectableEmails = (user.SocialEmails ?? Array.Empty<string>())
            .Where(e => e != user.Email)
            .ToList();
        EmailMenuFlyout.Items.Clear();
        if (selectableEmails.Count > 0)
        {
            EmailDropdown.Visibility = Visibility.Visible;
            foreach (var email in selectableEmails)
            {
                var item = new MenuFlyoutItem { Text = email };
                item.Click += (_, _) => EmailInput.Text = email;
                EmailMenuFlyout.Items.Add(item);
            }
        }
        else
        {
            EmailDropdown.Visibility = Visibility.Collapsed;
        }

        // Password section
        PasswordResetSuccessText.Visibility = Visibility.Collapsed;
        if (!user.EmailVerified)
        {
            PasswordDescription.Text = Strings.Get("PasswordRequiresVerification");
            PasswordResetButton.Content = user.HasPassword == true
                ? Strings.Get("SendResetLink")
                : Strings.Get("SendSetupLink");
            PasswordResetButton.IsEnabled = false;
        }
        else if (user.HasPassword == true)
        {
            PasswordDescription.Text = Strings.Get("PasswordResetDescription");
            PasswordResetButton.Content = Strings.Get("SendResetLink");
            PasswordResetButton.IsEnabled = true;
        }
        else
        {
            PasswordDescription.Text = Strings.Get("PasswordSetDescription");
            PasswordResetButton.Content = Strings.Get("SendSetupLink");
            PasswordResetButton.IsEnabled = true;
        }

        // MFA section
        UpdateMfaUI(user);

        // Provider buttons
        AppleButton.Content = user.AppleId is not null ? Strings.Get("UnlinkProvider") : Strings.Get("LinkProvider");
        DiscordButton.Content = user.DiscordId is not null ? Strings.Get("UnlinkProvider") : Strings.Get("LinkProvider");
        GithubButton.Content = user.GithubId is not null ? Strings.Get("UnlinkProvider") : Strings.Get("LinkProvider");
        GoogleButton.Content = user.GoogleId is not null ? Strings.Get("UnlinkProvider") : Strings.Get("LinkProvider");
        TwitterButton.Content = user.TwitterId is not null ? Strings.Get("UnlinkProvider") : Strings.Get("LinkProvider");

        UpdateThemeButtons();
        ErrorText.Visibility = Visibility.Collapsed;
    }

    private void UpdateThemeButtons()
    {
        var mode = App.Auth.ThemeMode;
        ThemeSystemButton.IsChecked = mode == ThemeMode.System;
        ThemeLightButton.IsChecked = mode == ThemeMode.Light;
        ThemeDarkButton.IsChecked = mode == ThemeMode.Dark;
    }

    private async void SaveEmailButton_Click(object sender, RoutedEventArgs e)
    {
        var newEmail = EmailInput.Text?.Trim();
        if (string.IsNullOrEmpty(newEmail) || newEmail == App.Auth.User?.Email) return;
        ErrorText.Visibility = Visibility.Collapsed;
        try
        {
            await App.Auth.UpdateEmailAsync(newEmail);
            EmailInput.Text = "";
            UpdateUI();
        }
        catch (Exception ex)
        {
            ErrorText.Text = ex.Message;
            ErrorText.Visibility = Visibility.Visible;
        }
    }

    private async void ResendVerificationButton_Click(object sender, RoutedEventArgs e)
    {
        ErrorText.Visibility = Visibility.Collapsed;
        try
        {
            await App.Auth.ResendVerificationFromSettingsAsync();
        }
        catch (Exception ex)
        {
            ErrorText.Text = ex.Message;
            ErrorText.Visibility = Visibility.Visible;
        }
    }

    private async void PasswordResetButton_Click(object sender, RoutedEventArgs e)
    {
        ErrorText.Visibility = Visibility.Collapsed;
        PasswordResetSuccessText.Visibility = Visibility.Collapsed;
        try
        {
            await App.Auth.RequestPasswordResetAsync();
            PasswordResetSuccessText.Visibility = Visibility.Visible;
        }
        catch (Exception ex)
        {
            ErrorText.Text = ex.Message;
            ErrorText.Visibility = Visibility.Visible;
        }
    }

    private async void ThemeButton_Click(object sender, RoutedEventArgs e)
    {
        if (sender is RadioButton rb && rb.Tag is string tag)
        {
            var mode = tag switch
            {
                "Light" => ThemeMode.Light,
                "Dark" => ThemeMode.Dark,
                _ => ThemeMode.System,
            };
            await App.Auth.SetThemeAsync(mode);
        }
    }

    private async void AppleButton_Click(object sender, RoutedEventArgs e)
    {
        await ToggleProviderAsync("apple", App.Auth.User?.AppleId);
    }

    private async void DiscordButton_Click(object sender, RoutedEventArgs e)
    {
        await ToggleProviderAsync("discord", App.Auth.User?.DiscordId);
    }

    private async void GithubButton_Click(object sender, RoutedEventArgs e)
    {
        await ToggleProviderAsync("github", App.Auth.User?.GithubId);
    }

    private async void GoogleButton_Click(object sender, RoutedEventArgs e)
    {
        await ToggleProviderAsync("google", App.Auth.User?.GoogleId);
    }

    private async void TwitterButton_Click(object sender, RoutedEventArgs e)
    {
        await ToggleProviderAsync("twitter", App.Auth.User?.TwitterId);
    }

    private void UpdateMfaUI(Models.UserProfile user)
    {
        var step = App.Auth.MfaStep;
        var totpEnabled = user.TotpEnabled == true;

        MfaIdleNotEnabledPanel.Visibility = step == ViewModels.MfaStep.Idle && !totpEnabled
            ? Visibility.Visible : Visibility.Collapsed;
        MfaIdleEnabledPanel.Visibility = step == ViewModels.MfaStep.Idle && totpEnabled
            ? Visibility.Visible : Visibility.Collapsed;
        MfaSetupPanel.Visibility = step == ViewModels.MfaStep.Setup
            ? Visibility.Visible : Visibility.Collapsed;
        MfaRecoveryPanel.Visibility = step == ViewModels.MfaStep.Recovery
            ? Visibility.Visible : Visibility.Collapsed;
        MfaDisablePanel.Visibility = step == ViewModels.MfaStep.Disable
            ? Visibility.Visible : Visibility.Collapsed;
        MfaRegeneratePanel.Visibility = step == ViewModels.MfaStep.Regenerate
            ? Visibility.Visible : Visibility.Collapsed;

        if (step == ViewModels.MfaStep.Setup && App.Auth.TotpSetupSecret is { } secret)
        {
            MfaSetupSecretText.Text = secret;
        }

        if (step == ViewModels.MfaStep.Recovery && App.Auth.RecoveryCodes is { } codes)
        {
            RecoveryCodesList.Children.Clear();
            foreach (var code in codes)
            {
                RecoveryCodesList.Children.Add(new TextBlock
                {
                    Text = code,
                    FontFamily = new Microsoft.UI.Xaml.Media.FontFamily("Consolas"),
                    IsTextSelectionEnabled = true,
                });
            }
        }
    }

    private async void MfaEnableButton_Click(object sender, RoutedEventArgs e)
    {
        ErrorText.Visibility = Visibility.Collapsed;
        try
        {
            await App.Auth.SetupTotpAsync();
            UpdateUI();
        }
        catch (Exception ex)
        {
            ErrorText.Text = ex.Message;
            ErrorText.Visibility = Visibility.Visible;
        }
    }

    private async void MfaSetupVerifyButton_Click(object sender, RoutedEventArgs e)
    {
        var code = MfaSetupCodeBox.Text.Trim();
        if (string.IsNullOrEmpty(code)) return;
        ErrorText.Visibility = Visibility.Collapsed;
        try
        {
            await App.Auth.EnableTotpAsync(code);
            MfaSetupCodeBox.Text = "";
            UpdateUI();
        }
        catch (Exception ex)
        {
            ErrorText.Text = ex.Message;
            ErrorText.Visibility = Visibility.Visible;
        }
    }

    private void MfaRecoverySavedButton_Click(object sender, RoutedEventArgs e)
    {
        App.Auth.ClearMfaStep();
        UpdateUI();
    }

    private void MfaDisableButton_Click(object sender, RoutedEventArgs e)
    {
        App.Auth.MfaStep = ViewModels.MfaStep.Disable;
        UpdateUI();
    }

    private async void MfaDisableConfirmButton_Click(object sender, RoutedEventArgs e)
    {
        var code = MfaDisableCodeBox.Text.Trim();
        if (string.IsNullOrEmpty(code)) return;
        ErrorText.Visibility = Visibility.Collapsed;
        try
        {
            await App.Auth.DisableTotpAsync(code);
            MfaDisableCodeBox.Text = "";
            UpdateUI();
        }
        catch (Exception ex)
        {
            ErrorText.Text = ex.Message;
            ErrorText.Visibility = Visibility.Visible;
        }
    }

    private void MfaRegenerateButton_Click(object sender, RoutedEventArgs e)
    {
        App.Auth.MfaStep = ViewModels.MfaStep.Regenerate;
        UpdateUI();
    }

    private async void MfaRegenerateConfirmButton_Click(object sender, RoutedEventArgs e)
    {
        var code = MfaRegenerateCodeBox.Text.Trim();
        if (string.IsNullOrEmpty(code)) return;
        ErrorText.Visibility = Visibility.Collapsed;
        try
        {
            await App.Auth.RegenerateRecoveryCodesAsync(code);
            MfaRegenerateCodeBox.Text = "";
            UpdateUI();
        }
        catch (Exception ex)
        {
            ErrorText.Text = ex.Message;
            ErrorText.Visibility = Visibility.Visible;
        }
    }

    private void MfaCancelButton_Click(object sender, RoutedEventArgs e)
    {
        App.Auth.ClearMfaStep();
        UpdateUI();
    }

    private async void DeleteAccountButton_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new ContentDialog
        {
            Title = Strings.Get("DeleteAccountDialogTitle"),
            Content = Strings.Get("DeleteAccountDialogContent"),
            PrimaryButtonText = Strings.Get("DeleteDialogDelete"),
            CloseButtonText = Strings.Get("DeleteDialogCancel"),
            DefaultButton = ContentDialogButton.Close,
            XamlRoot = this.XamlRoot,
        };

        var result = await dialog.ShowAsync();
        if (result == ContentDialogResult.Primary)
        {
            ErrorText.Visibility = Visibility.Collapsed;
            try
            {
                await App.Auth.DeleteAccountAsync();
            }
            catch (Exception ex)
            {
                ErrorText.Text = ex.Message;
                ErrorText.Visibility = Visibility.Visible;
            }
        }
    }

    private async System.Threading.Tasks.Task ToggleProviderAsync(string provider, string? currentId)
    {
        ErrorText.Visibility = Visibility.Collapsed;
        try
        {
            if (currentId is not null)
            {
                await App.Auth.UnlinkProviderAsync(provider);
            }
            else
            {
                await App.Auth.LinkProviderAsync(provider);
            }
        }
        catch (Exception ex)
        {
            ErrorText.Text = ex.Message;
            ErrorText.Visibility = Visibility.Visible;
        }
    }
}
