import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  static const String _cacheKey = 'cached_users';
  static const String _baseUrl = 'https://reqres.in/api';

  @override
  Future<List<User>> getUsers({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users?per_page=10&page=$page'),
        headers: {'x-api-key': 'reqres-free-v1'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((json) => UserModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to fetch users');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server');
    }
  }

  @override
  Future<void> cacheUsers(List<User> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedData = json.encode(
        users.map((user) => (user as UserModel).toJson()).toList(),
      );
      await prefs.setString(_cacheKey, encodedData);
    } catch (e) {
      throw Exception('Failed to cache users');
    }
  }

  @override
  Future<List<User>> loadCachedUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);

      if (cachedData != null) {
        final List<dynamic> decodedData = json.decode(cachedData);
        return decodedData.map((json) => UserModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load cached users');
    }
  }

  @override
  User? getUserById(int id) {
    return null;
  }
}
