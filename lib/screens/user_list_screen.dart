import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:user_fetcher/providers/user_provider.dart';
import 'user_detail_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
    });

    _scrollController.addListener(() {
      final userProvider = context.read<UserProvider>();

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (userProvider.hasMore && !userProvider.isLoading) {
          userProvider.fetchUsers(loadMore: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(userProvider.errorMessage!),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: () {
                      userProvider.fetchUsers();
                    },
                  ),
                ),
              );
            });
          }

          if (userProvider.users.isEmpty && userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userProvider.users.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search by name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => userProvider.searchUsers(value),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await userProvider.fetchUsers();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount:
                        userProvider.users.length +
                        (userProvider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == userProvider.users.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final user = userProvider.users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(user.avatar),
                        ),
                        title: Text(user.fullName),
                        subtitle: Text(user.email),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      UserDetailScreen(userId: user.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
