using System;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace app;

public sealed partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
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
