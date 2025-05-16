import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:user_fetcher/models/user.dart';

class UserProvider with ChangeNotifier {
  final List<User> _users = [];
  List<User> _filteredUsers = [];
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String _searchQuery = '';

  List<User> get users => _searchQuery.isEmpty ? _users : _filteredUsers;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  Future<void> fetchUsers({bool loadMore = false}) async {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;
    notifyListeners();

    if (!loadMore) {
      _page = 1;
      _users.clear();
      _hasMore = true;
    }

    final response = await http.get(
      Uri.parse('https://reqres.in/api/users?per_page=10&page=$_page'),
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
      }
    } else {
      _hasMore = false;
    }

    _isLoading = false;
    notifyListeners();
    _applySearch();
  }

  void searchUsers(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

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

  User? getUserById(int id) {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }
}
