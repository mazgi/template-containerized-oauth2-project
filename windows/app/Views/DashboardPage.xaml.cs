using System;
using System.Globalization;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace app.Views;

public sealed partial class DashboardPage : Page
{
    public DashboardPage()
    {
        InitializeComponent();
        Loaded += (_, _) => UpdateUI();
    }

    private void SignOutButton_Click(object sender, RoutedEventArgs e)
    {
        App.Auth.SignOut();
    }

    private void UpdateUI()
    {
        var user = App.Auth.User;
        if (user is null) return;

        EmailText.Text = user.Email;

        if (!string.IsNullOrEmpty(user.Name))
        {
            NameText.Text = user.Name;
            NameText.Visibility = Visibility.Visible;
        }

        IdText.Text = Strings.Format("DashboardIdFormat", user.Id);
        CreatedText.Text = Strings.Format("DashboardCreatedFormat", FormatDate(user.CreatedAt));
        UpdatedText.Text = Strings.Format("DashboardUpdatedFormat", FormatDate(user.UpdatedAt));
    }

    private static string FormatDate(string iso)
    {
        if (DateTimeOffset.TryParse(iso, CultureInfo.InvariantCulture, DateTimeStyles.None, out var dt))
            return dt.LocalDateTime.ToString("g");
        return iso;
    }
}
