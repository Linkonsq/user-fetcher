import '../entities/user.dart';

abstract class UserRepository {
  Future<List<User>> getUsers({int page = 1});
  Future<void> cacheUsers(List<User> users);
  Future<List<User>> loadCachedUsers();
  User? getUserById(int id);
}
