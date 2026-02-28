using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using app.ViewModels;

namespace app.Views;

public sealed partial class ItemsPage : Page
{
    private readonly ItemsViewModel _vm = new();

    public ItemsPage()
    {
        InitializeComponent();
        Loaded += async (_, _) =>
        {
            if (App.Auth.AccessToken is { } token)
            {
                LoadingRing.IsActive = true;
                await _vm.LoadItemsAsync(token);
                LoadingRing.IsActive = false;
            }
            ItemsList.ItemsSource = _vm.Items;
            UpdateUI();
            _vm.Items.CollectionChanged += (_, _) => UpdateUI();
        };
    }

    private async void AddButton_Click(object sender, RoutedEventArgs e)
    {
        if (App.Auth.AccessToken is not { } token) return;

        _vm.NewName = NewNameBox.Text;
        AddButton.IsEnabled = false;
        NewNameBox.IsEnabled = false;
        await _vm.AddItemAsync(token);
        NewNameBox.Text = _vm.NewName;
        NewNameBox.IsEnabled = true;
        AddButton.IsEnabled = true;
        UpdateUI();
    }

    private async void DeleteButton_Click(object sender, RoutedEventArgs e)
    {
        if (App.Auth.AccessToken is not { } token) return;
        if (sender is Button btn && btn.Tag is string id)
        {
            await _vm.DeleteItemAsync(token, id);
            UpdateUI();
        }
    }

    private void NewNameBox_KeyDown(object sender, KeyRoutedEventArgs e)
    {
        if (e.Key == Windows.System.VirtualKey.Enter)
            AddButton_Click(sender, e);
    }

    private void UpdateUI()
    {
        var hasItems = _vm.Items.Count > 0;
        ItemsList.Visibility = hasItems ? Visibility.Visible : Visibility.Collapsed;
        EmptyText.Visibility = hasItems || _vm.IsLoading ? Visibility.Collapsed : Visibility.Visible;

        if (_vm.ErrorMessage is { } msg)
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
