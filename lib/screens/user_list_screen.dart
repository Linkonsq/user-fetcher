import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:user_fetcher/providers/user_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'user_detail_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _setupConnectivityListener();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isConnected) {
        context.read<UserProvider>().fetchUsers();
      } else {
        context.read<UserProvider>().loadCachedUsers();
        _showOfflineToast();
      }
    });

    _scrollController.addListener(() {
      final userProvider = context.read<UserProvider>();

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (userProvider.hasMore && !userProvider.isLoading && _isConnected) {
          userProvider.fetchUsers(loadMore: true);
        }
      }
    });
  }

  void _showOfflineToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('You are offline. Showing cached data.'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () async {
            await _checkConnectivity();
            if (_isConnected) {
              context.read<UserProvider>().fetchUsers();
            }
          },
        ),
      ),
    );
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
    });
  }

  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _isConnected = result != ConnectivityResult.none;
      });
      if (_isConnected) {
        context.read<UserProvider>().fetchUsers();
      } else {
        context.read<UserProvider>().loadCachedUsers();
        _showOfflineToast();
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
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              if (!_isConnected) {
                return IconButton(
                  icon: const Icon(Icons.wifi_off),
                  onPressed: () async {
                    // await _checkConnectivity();
                    // if (_isConnected) {
                    //   userProvider.fetchUsers();
                    // }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
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

          if (userProvider.users.isEmpty && !_isConnected) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No Internet Connection',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please check your connection and try again',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await _checkConnectivity();
                      if (_isConnected) {
                        context.read<UserProvider>().fetchUsers();
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (userProvider.users.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          // if (userProvider.users.isEmpty) {
          //   return Center(
          //     child: Column(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: [
          //         const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
          //         const SizedBox(height: 16),
          //         const Text(
          //           'No Data Available',
          //           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          //         ),
          //         const SizedBox(height: 8),
          //         Text(
          //           userProvider.isOffline
          //               ? 'No cached data found'
          //               : 'Please check your connection and try again',
          //           style: const TextStyle(color: Colors.grey),
          //         ),
          //         const SizedBox(height: 16),
          //         ElevatedButton(
          //           onPressed: () async {
          //             await _checkConnectivity();
          //             if (_isConnected) {
          //               userProvider.fetchUsers();
          //             } else {
          //               userProvider.loadCachedUsers();
          //             }
          //           },
          //           child: const Text('Retry'),
          //         ),
          //       ],
          //     ),
          //   );
          // }

          return Column(
            children: [
              if (!_isConnected)
                Container(
                  color: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const Center(
                    child: Text(
                      'Offline Mode - Showing Cached Data',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
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
                    if (_isConnected) {
                      await userProvider.fetchUsers();
                    } else {
                      await userProvider.loadCachedUsers();
                      _showOfflineToast();
                    }
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
