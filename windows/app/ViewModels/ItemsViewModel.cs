using System;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using app.Models;
using app.Services;

namespace app.ViewModels;

public partial class ItemsViewModel : ObservableObject
{
    private readonly ApiClient _api = ApiClient.Shared;

    [ObservableProperty]
    private ObservableCollection<ItemResponse> _items = new();

    [ObservableProperty]
    private string _newName = "";

    [ObservableProperty]
    private bool _isLoading;

    [ObservableProperty]
    private bool _isSubmitting;

    [ObservableProperty]
    private string? _errorMessage;

    public async Task LoadItemsAsync(string accessToken)
    {
        IsLoading = true;
        ErrorMessage = null;
        try
        {
            var items = await _api.GetItemsAsync(accessToken);
            Items = new ObservableCollection<ItemResponse>(items);
        }
        catch (ApiException e)
        {
            ErrorMessage = e.Message;
        }
        catch (Exception e)
        {
            ErrorMessage = e.Message;
        }
        finally
        {
            IsLoading = false;
        }
    }

    public async Task AddItemAsync(string accessToken)
    {
        var name = NewName.Trim();
        if (string.IsNullOrEmpty(name)) return;

        IsSubmitting = true;
        ErrorMessage = null;
        try
        {
            var item = await _api.CreateItemAsync(accessToken, name);
            Items.Insert(0, item);
            NewName = "";
        }
        catch (ApiException e)
        {
            ErrorMessage = e.Message;
        }
        catch (Exception e)
        {
            ErrorMessage = e.Message;
        }
        finally
        {
            IsSubmitting = false;
        }
    }

    public async Task DeleteItemAsync(string accessToken, string id)
    {
        ErrorMessage = null;
        try
        {
            await _api.DeleteItemAsync(accessToken, id);
            var toRemove = Items.FirstOrDefault(i => i.Id == id);
            if (toRemove is not null) Items.Remove(toRemove);
        }
        catch (ApiException e)
        {
            ErrorMessage = e.Message;
        }
        catch (Exception e)
        {
            ErrorMessage = e.Message;
        }
    }
}
