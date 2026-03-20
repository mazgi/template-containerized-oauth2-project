using System;
using System.Text.Json;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using app.Services;
using app.ViewModels;

namespace app;

public sealed partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        Title = Strings.Get("AppTitle");
        GitSHAText.Text = BuildConfig.GitSHA;
        FetchBackendSha();
        App.Auth.ThemeChanged += ApplyTheme;
        ApplyTheme();
#if DEBUG
        DebugButton.Visibility = Visibility.Visible;
#endif
    }

    private async void DebugButton_Click(object sender, RoutedEventArgs e)
    {
#if DEBUG
        var textBox = new TextBox
        {
            Text = Services.DebugSettings.ApiBaseUrl ?? "",
            PlaceholderText = "http://localhost:4000",
            Margin = new Thickness(0, 8, 0, 0),
        };
        var panel = new StackPanel();
        panel.Children.Add(new TextBlock { Text = Strings.Get("DebugApiBaseUrl") });
        panel.Children.Add(textBox);
        panel.Children.Add(new TextBlock
        {
            Text = Strings.Get("DebugLeaveEmpty"),
            FontSize = 12,
            Foreground = (Microsoft.UI.Xaml.Media.Brush)Application.Current.Resources["TextFillColorSecondaryBrush"],
            Margin = new Thickness(0, 8, 0, 0),
        });

        var dialog = new ContentDialog
        {
            Title = Strings.Get("DebugSettingsTitle"),
            Content = panel,
            PrimaryButtonText = Strings.Get("DebugSave"),
            CloseButtonText = Strings.Get("DebugCancel"),
            XamlRoot = Content.XamlRoot,
        };

        if (await dialog.ShowAsync() == ContentDialogResult.Primary)
        {
            var trimmed = textBox.Text?.Trim();
            Services.DebugSettings.ApiBaseUrl = string.IsNullOrEmpty(trimmed) ? null : trimmed;
        }
#endif
    }

    public void ApplyTheme()
    {
        if (Content is FrameworkElement root)
        {
            root.RequestedTheme = App.Auth.ThemeMode switch
            {
                ThemeMode.Light => ElementTheme.Light,
                ThemeMode.Dark => ElementTheme.Dark,
                _ => ElementTheme.Default,
            };
        }
    }

    private async void FetchBackendSha()
    {
        var front = BuildConfig.GitSHA;
        try
        {
            using var http = new System.Net.Http.HttpClient { Timeout = TimeSpan.FromSeconds(3) };
            var response = await http.GetAsync($"{ApiClient.Shared.BaseUrl}/health");
            if (!response.IsSuccessStatusCode) return;
            var text = await response.Content.ReadAsStringAsync();
            using var doc = JsonDocument.Parse(text);
            if (!doc.RootElement.TryGetProperty("gitSha", out var shaEl)) return;
            var back = shaEl.GetString();
            if (string.IsNullOrEmpty(back)) return;
            DispatcherQueue.TryEnqueue(() =>
            {
                GitSHAText.Text = front == back ? $"f/b: {front}" : $"f: {front}, b: {back}";
            });
        }
        catch { }
    }

    public void NavigateToPage(Type pageType)
    {
        LoadingRing.IsActive = false;
        LoadingRing.Visibility = Visibility.Collapsed;
        RootFrame.Visibility = Visibility.Visible;
        RootFrame.Navigate(pageType);
    }

    public void ShowLoading()
    {
        LoadingRing.IsActive = true;
        LoadingRing.Visibility = Visibility.Visible;
        RootFrame.Visibility = Visibility.Collapsed;
    }
}
