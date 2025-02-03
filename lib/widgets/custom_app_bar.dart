import 'package:flutter/material.dart';
import '../services/socket_service.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final SocketService socketService;
  final VoidCallback? onRefresh;
  final bool isLoading;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.socketService,
    this.onRefresh,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          height: 60,
          width: 120,
          child: Image.asset('assets/images/denverbartendersSign.png',
          fit: BoxFit.contain,
         ),
       ),
      ),
      leadingWidth: 150,
      title: Text(title),
      backgroundColor: Colors.black87,
      actions: [
        Icon(
          socketService.isConnected ? Icons.cloud_done : Icons.cloud_off,
          color: socketService.isConnected ? Colors.green : Colors.red,
        ),
        if (onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : onRefresh,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}