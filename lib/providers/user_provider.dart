import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_fetcher/models/user.dart';

/// Manages the state and data operations for users in the application
/// Handles fetching, caching and searching user data
class UserProvider with ChangeNotifier {
  final List<User> _users = [];
  List<User> _filteredUsers = [];
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String _searchQuery = '';
  String? _errorMessage;
  static const String _cacheKey = 'cached_users';

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
      final response = await http.get(
        Uri.parse('https://reqres.in/api/users?per_page=10&page=$_page'),
        headers: {'x-api-key': 'reqres-free-v1'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<User> fetchedUsers =
            (data['data'] as List).map((json) => User.fromJson(json)).toList();

        if (fetchedUsers.isEmpty) {
          _hasMore = false;
        } else {
          _users.addAll(fetchedUsers);
          _page++;
          await _cacheUsers();
        }
      } else {
        final errorData = json.decode(response.body);
        _errorMessage =
            errorData['error'] ?? 'An error occurred while fetching users';
        _hasMore = false;
      }
    } catch (e) {
      _errorMessage = 'Failed to connect to the server. Try again later';
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
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);

      if (cachedData != null) {
        final List<dynamic> decodedData = json.decode(cachedData);
        _users.clear();
        _users.addAll(decodedData.map((json) => User.fromJson(json)).toList());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cached users: $e');
    }
  }

  /// Caches the current user list to local storage
  Future<void> _cacheUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedData = json.encode(
        _users
            .map(
              (user) => {
                'id': user.id,
                'email': user.email,
                'first_name': user.firstName,
                'last_name': user.lastName,
                'avatar': user.avatar,
              },
            )
            .toList(),
      );
      await prefs.setString(_cacheKey, encodedData);
    } catch (e) {
      debugPrint('Error caching users: $e');
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
      _filteredUsers =
          _users
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
