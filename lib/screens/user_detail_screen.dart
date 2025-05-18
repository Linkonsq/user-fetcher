import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:user_fetcher/providers/user_provider.dart';
import 'package:user_fetcher/services/connectivity_service.dart';

/// Screen that displays detailed information about a specific user
class UserDetailScreen extends StatefulWidget {
  final int userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final _connectivityService = ConnectivityService();
  late bool _isConnected;

  @override
  void initState() {
    super.initState();
    _isConnected = _connectivityService.isConnected;
    _connectivityService.checkConnectivity();
    _connectivityService.setupConnectivityListener();
    _connectivityService.connectionStatus.addListener(
      _onConnectionStatusChanged,
    );
  }

  void _onConnectionStatusChanged() {
    setState(() {
      _isConnected = _connectivityService.isConnected;
    });
  }

  @override
  void dispose() {
    _connectivityService.connectionStatus.removeListener(
      _onConnectionStatusChanged,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get specific user data from the provider
    final user = Provider.of<UserProvider>(
      context,
      listen: false,
    ).getUserById(widget.userId);

    // Show error state if user is not found
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('User Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'User not found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Main content with user details
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsing app bar with user's avatar as background
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                user.fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _isConnected
                      ? Image.network(user.avatar, fit: BoxFit.cover)
                      : Image.asset(
                        'assets/images/dummy_avatar_background.jpg',
                      ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // User details content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Hero animation for smooth avatar transition
                  Hero(
                    tag: 'user-avatar-${user.id}',
                    child: Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            _isConnected
                                ? NetworkImage(user.avatar)
                                : AssetImage('assets/images/dummy_avatar.png')
                                    as ImageProvider,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoCard(
                    context,
                    title: 'Contact Information',
                    children: [_buildInfoRow(Icons.email, 'Email', user.email)],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    context,
                    title: 'User Details',
                    children: [
                      _buildInfoRow(Icons.person, 'Full Name', user.fullName),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an information card with a title and a list of information rows
  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  /// Builds a row of information with an icon, label and value
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
