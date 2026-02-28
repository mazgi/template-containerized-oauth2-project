using System;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

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

        AppleButton.Content = user.AppleId is not null ? "Unlink" : "Link";
        DiscordButton.Content = user.DiscordId is not null ? "Unlink" : "Link";
        GithubButton.Content = user.GithubId is not null ? "Unlink" : "Link";
        GoogleButton.Content = user.GoogleId is not null ? "Unlink" : "Link";
        TwitterButton.Content = user.TwitterId is not null ? "Unlink" : "Link";

        ErrorText.Visibility = Visibility.Collapsed;
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
