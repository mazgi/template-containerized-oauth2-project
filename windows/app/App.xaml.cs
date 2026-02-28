using System;
using System.Linq;
using Microsoft.UI.Xaml;
using Microsoft.Windows.AppLifecycle;
using app.ViewModels;
using app.Views;

namespace app;

public partial class App : Application
{
    private MainWindow? _window;

    public static AuthViewModel Auth { get; } = new();

    public App()
    {
        InitializeComponent();
    }

    protected override async void OnLaunched(LaunchActivatedEventArgs args)
    {
        // Handle protocol activation for OAuth2 callback
        var activationArgs = AppInstance.GetCurrent().GetActivatedEventArgs();
        Uri? protocolUri = null;
        if (activationArgs.Kind == ExtendedActivationKind.Protocol
            && activationArgs.Data is Windows.ApplicationModel.Activation.IProtocolActivatedEventArgs protocolArgs)
        {
            protocolUri = protocolArgs.Uri;
        }

        // Clear stored tokens when launched with --uitesting (mirrors iOS pattern)
        if (Environment.GetCommandLineArgs().Contains("--uitesting"))
        {
            Windows.Storage.ApplicationData.Current.LocalSettings.Values.Remove("auth_tokens");
        }

        _window = new MainWindow();
        _window.Activate();

        // Listen for future protocol activations (app already running)
        AppInstance.GetCurrent().Activated += OnAppActivated;

        // Subscribe to auth state changes
        Auth.AuthStateChanged += OnAuthStateChanged;

        // Restore session
        await Auth.InitializeAsync();

        // If launched via protocol, handle the callback
        if (protocolUri is not null)
        {
            await Auth.HandleOAuthCallbackAsync(protocolUri);
        }

        // Navigate based on auth state
        NavigateBasedOnAuthState();
    }

    private async void OnAppActivated(object? sender, AppActivationArguments e)
    {
        if (e.Kind == ExtendedActivationKind.Protocol
            && e.Data is Windows.ApplicationModel.Activation.IProtocolActivatedEventArgs protocolArgs)
        {
            _window?.DispatcherQueue.TryEnqueue(async () =>
            {
                await Auth.HandleOAuthCallbackAsync(protocolArgs.Uri);
            });
        }
    }

    private void OnAuthStateChanged()
    {
        _window?.DispatcherQueue.TryEnqueue(NavigateBasedOnAuthState);
    }

    private void NavigateBasedOnAuthState()
    {
        if (Auth.IsAuthenticated)
        {
            _window?.NavigateToPage(typeof(ShellPage));
        }
        else
        {
            _window?.NavigateToPage(typeof(SignInPage));
        }
    }
}
