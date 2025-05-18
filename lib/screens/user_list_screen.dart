import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:user_fetcher/providers/user_provider.dart';
import 'package:user_fetcher/services/connectivity_service.dart';
import 'user_detail_screen.dart';

/// Main screen that displays a list of users with search and pagination functionality
class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final _connectivityService = ConnectivityService();
  late bool _isConnected;

  /// Fetches user data based on connectivity status
  void _fetchUsersData() {
    final userProvider = context.read<UserProvider>();
    if (_isConnected) {
      userProvider.fetchUsers();
    } else {
      userProvider.loadCachedUsers();
    }
  }

  @override
  void initState() {
    super.initState();
    _isConnected = _connectivityService.isConnected;
    _connectivityService.checkConnectivity();
    _connectivityService.setupConnectivityListener();
    _connectivityService.connectionStatus.addListener(
      _onConnectionStatusChanged,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUsersData();
    });

    // Setup infinite scroll functionality
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

  void _onConnectionStatusChanged() {
    setState(() {
      _isConnected = _connectivityService.isConnected;
    });
    _fetchUsersData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _connectivityService.connectionStatus.removeListener(
      _onConnectionStatusChanged,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Users',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          // Show offline indicator in app bar when disconnected
          if (!_isConnected)
            IconButton(
              icon: const Icon(Icons.wifi_off),
              onPressed: () {
                //_checkConnectivity();
              },
            ),
        ],
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          // Show error message if any
          if (userProvider.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(userProvider.errorMessage!),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            });
          }

          // Show loading indicator while fetching initial data
          if (userProvider.users.isEmpty && userProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading users...'),
                ],
              ),
            );
          }

          // Show offline message when no internet connection
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
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _connectivityService.checkConnectivity();
                      if (_connectivityService.isConnected) {
                        context.read<UserProvider>().fetchUsers();
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Show empty state when no users are found
          if (userProvider.users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No users found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      _fetchUsersData();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Main content: Search bar and user list
          return Column(
            children: [
              // Show offline mode banner when disconnected
              if (!_isConnected)
                Container(
                  color: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Offline Mode - Showing cached data',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        userProvider.searchUsers('');
                      },
                    ),
                  ),
                  onChanged: (value) => userProvider.searchUsers(value),
                ),
              ),
              // Scrollable list of users
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _fetchUsersData();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount:
                        userProvider.users.length +
                        (userProvider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show loading indicator at the bottom while loading more
                      if (index == userProvider.users.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      // Build user list item
                      final user = userProvider.users[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Hero(
                            tag: 'user-avatar-${user.id}',
                            child: CircleAvatar(
                              radius: 30,
                              backgroundImage:
                                  _isConnected
                                      ? NetworkImage(user.avatar)
                                      : const AssetImage(
                                            'assets/images/dummy_avatar.png',
                                          )
                                          as ImageProvider,
                            ),
                          ),
                          title: Text(
                            user.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            user.email,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
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
                        ),
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
