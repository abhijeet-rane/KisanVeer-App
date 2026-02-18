import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/services/connectivity_service.dart';
import 'package:kisan_veer/services/sync_manager.dart';

/// Offline indicator widget that shows connectivity status
/// Displays a banner when offline with pending sync count
class OfflineIndicator extends StatefulWidget {
  final Widget child;
  
  const OfflineIndicator({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator>
    with SingleTickerProviderStateMixin {
  final ConnectivityService _connectivity = ConnectivityService();
  final SyncManager _syncManager = SyncManager();
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  bool _isOffline = false;
  int _pendingCount = 0;
  
  @override
  void initState() {
    super.initState();
    _initAnimation();
    _listenToConnectivity();
    _updatePendingCount();
  }
  
  void _initAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: -50, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }
  
  void _listenToConnectivity() {
    _isOffline = _connectivity.isOffline;
    if (_isOffline) _animationController.forward();
    
    _connectivity.statusStream.listen((status) {
      final isOffline = status == ConnectivityStatus.offline;
      
      if (isOffline != _isOffline) {
        setState(() => _isOffline = isOffline);
        
        if (isOffline) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      }
      
      _updatePendingCount();
    });
  }
  
  void _updatePendingCount() {
    final count = _syncManager.pendingCount;
    if (count != _pendingCount) {
      setState(() => _pendingCount = count);
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Offline banner
        AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: child,
            );
          },
          child: _isOffline ? _buildOfflineBanner() : const SizedBox.shrink(),
        ),
        
        // Main content
        Expanded(child: widget.child),
      ],
    );
  }
  
  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade700,
            Colors.orange.shade800,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'You\'re offline',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (_pendingCount > 0)
                    Text(
                      '$_pendingCount changes will sync when you\'re back online',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (_pendingCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_pendingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Small connectivity indicator for app bar
class ConnectivityIndicator extends StatefulWidget {
  const ConnectivityIndicator({Key? key}) : super(key: key);

  @override
  State<ConnectivityIndicator> createState() => _ConnectivityIndicatorState();
}

class _ConnectivityIndicatorState extends State<ConnectivityIndicator> {
  final ConnectivityService _connectivity = ConnectivityService();
  ConnectivityStatus _status = ConnectivityStatus.unknown;
  
  @override
  void initState() {
    super.initState();
    _status = _connectivity.currentStatus;
    _connectivity.statusStream.listen((status) {
      if (mounted) setState(() => _status = status);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_status == ConnectivityStatus.online) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off,
            size: 14,
            color: Colors.orange.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            'Offline',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
