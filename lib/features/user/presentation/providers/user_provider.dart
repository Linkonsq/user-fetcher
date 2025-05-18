import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

/// Manages the state and data operations for users in the application
/// Handles fetching, caching and searching user data
class UserProvider with ChangeNotifier {
  final UserRepository _repository;
  final List<User> _users = [];
  List<User> _filteredUsers = [];
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String _searchQuery = '';
  String? _errorMessage;

  UserProvider(this._repository);

  // Getters for public access to private state
  List<User> get users => _searchQuery.isEmpty ? _users : _filteredUsers;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  /// Fetches users from the API with pagination support
  Future<void> fetchUsers({bool loadMore = false}) async {
    if (_isLoading) return;

    // Reset state if this is not a load more request
    if (!loadMore) {
      _page = 1;
      _users.clear();
      _hasMore = true;
    } else if (!_hasMore) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedUsers = await _repository.getUsers(page: _page);

      if (fetchedUsers.isEmpty) {
        _hasMore = false;
      } else {
        _users.addAll(fetchedUsers);
        _page++;
        await _repository.cacheUsers(_users);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _hasMore = false;
      await loadCachedUsers();
    } finally {
      _isLoading = false;
      notifyListeners();
      _applySearch();
    }
  }

  /// Loads cached users from local storage
  Future<void> loadCachedUsers() async {
    try {
      final cachedUsers = await _repository.loadCachedUsers();
      _users.clear();
      _users.addAll(cachedUsers);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cached users: $e');
    }
  }

  /// Updates the search query and filters users accordingly
  void searchUsers(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

  /// Applies the current search query to filter users
  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredUsers = [];
    } else {
      _filteredUsers = _users
          .where(
            (user) => user.fullName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }
  }

  /// Retrieves a specific user by their ID
  User? getUserById(int id) {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }
}
