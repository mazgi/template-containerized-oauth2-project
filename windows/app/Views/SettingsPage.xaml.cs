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
            EmailAddressText.Text = "Not set";
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
                EmailBadgeText.Text = "Verified";
                EmailBadgeText.Foreground = new SolidColorBrush(ColorHelper.FromArgb(255, 22, 163, 74));
                EmailBadge.Background = new SolidColorBrush(ColorHelper.FromArgb(25, 34, 197, 94));
                EmailBadge.BorderBrush = new SolidColorBrush(ColorHelper.FromArgb(76, 34, 197, 94));
                ResendVerificationButton.Visibility = Visibility.Collapsed;
            }
            else
            {
                EmailBadgeText.Text = "Unverified";
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

        // Provider buttons
        AppleButton.Content = user.AppleId is not null ? "Unlink" : "Link";
        DiscordButton.Content = user.DiscordId is not null ? "Unlink" : "Link";
        GithubButton.Content = user.GithubId is not null ? "Unlink" : "Link";
        GoogleButton.Content = user.GoogleId is not null ? "Unlink" : "Link";
        TwitterButton.Content = user.TwitterId is not null ? "Unlink" : "Link";

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

    private async void DeleteAccountButton_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new ContentDialog
        {
            Title = "Delete Account",
            Content = "Are you sure you want to delete your account? This cannot be undone.",
            PrimaryButtonText = "Delete",
            CloseButtonText = "Cancel",
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
