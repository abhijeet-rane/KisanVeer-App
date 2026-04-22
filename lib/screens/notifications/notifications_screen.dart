import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_motion.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/notification_model.dart';
import 'package:kisan_veer/services/notification_service.dart';
import 'package:kisan_veer/utils/app_logger.dart';
import 'package:kisan_veer/widgets/ui/ui.dart';

/// V2 notifications screen.
///
/// Elevated card rows with type-coloured icon badges, dismiss-to-delete,
/// and an inline action row for bulk operations. Empty and error
/// states use the shared [AppEmptyState] / [AppErrorState].
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notifications = await _notificationService.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e(
        'Error loading notifications',
        tag: 'Notifications',
        error: e,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'We could not load your notifications.';
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      await _loadNotifications();
      if (!mounted) return;
      _toast('All marked as read', color: AppColors.primary);
    } catch (e) {
      AppLogger.e('Mark-all-read failed', tag: 'Notifications', error: e);
      if (!mounted) return;
      _toast('Could not mark as read', color: AppColors.danger);
    }
  }

  Future<void> _clearAll() async {
    try {
      await _notificationService.clearAllNotifications();
      if (!mounted) return;
      setState(() => _notifications = []);
      _toast('Notifications cleared', color: AppColors.primary);
    } catch (e) {
      AppLogger.e('Clear-all failed', tag: 'Notifications', error: e);
      if (!mounted) return;
      _toast('Could not clear notifications', color: AppColors.danger);
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    try {
      await _notificationService.markAsRead(notification.id);
      if (!mounted) return;
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification.copyWith(read: true);
        }
      });
    } catch (e) {
      AppLogger.e('Mark-read failed', tag: 'Notifications', error: e);
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    try {
      await _notificationService.deleteNotification(notification.id);
      if (!mounted) return;
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
      });
    } catch (e) {
      AppLogger.e('Delete notification failed', tag: 'Notifications', error: e);
      if (!mounted) return;
      _toast('Could not delete notification', color: AppColors.danger);
    }
  }

  void _toast(String message, {required Color color}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  _TypeStyle _styleFor(String type) {
    switch (type) {
      case 'weather':
        return const _TypeStyle(
          icon: Icons.cloud_rounded,
          tint: Color(0xFF1976D2),
          bg: Color(0xFFE3F2FD),
        );
      case 'market':
        return const _TypeStyle(
          icon: Icons.trending_up_rounded,
          tint: Color(0xFF2E7D32),
          bg: Color(0xFFE8F5E9),
        );
      case 'community':
        return const _TypeStyle(
          icon: Icons.people_alt_rounded,
          tint: Color(0xFFEF6C00),
          bg: Color(0xFFFFF3E0),
        );
      default:
        return _TypeStyle(
          icon: Icons.notifications_rounded,
          tint: AppColors.onSurfaceVariant,
          bg: AppColors.surfaceContainerHigh,
        );
    }
  }

  String _formatTimestamp(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inDays > 0) return DateFormat('MMM d, y').format(t);
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Notifications', showBack: true),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        color: AppColors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AppLoadingState(message: 'Loading your notifications…');
    }
    if (_errorMessage != null) {
      return AppErrorState(
        message: _errorMessage!,
        onRetry: _loadNotifications,
      );
    }
    if (_notifications.isEmpty) {
      return const _EmptyBody();
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space16,
            AppSpacing.space8,
            AppSpacing.space16,
            AppSpacing.space4,
          ),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Mark all as read',
                  variant: AppButtonVariant.tertiary,
                  size: AppButtonSize.sm,
                  leadingIcon: Icons.done_all_rounded,
                  onPressed: _markAllAsRead,
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              AppButton(
                label: 'Clear all',
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.sm,
                leadingIcon: Icons.delete_outline_rounded,
                onPressed: _clearAll,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space16,
              vertical: AppSpacing.space8,
            ),
            itemCount: _notifications.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.space8),
            itemBuilder: (context, index) {
              final notification = _notifications[index];
              final style = _styleFor(notification.type);

              return Dismissible(
                key: Key(notification.id),
                background: Container(
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: AppRadii.brLg,
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: AppSpacing.space24),
                  child: const Icon(Icons.delete_rounded, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _deleteNotification(notification),
                child:
                    AppCard(
                      onTap: notification.read
                          ? null
                          : () => _markAsRead(notification),
                      padding: const EdgeInsets.all(AppSpacing.space12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: style.bg,
                              borderRadius: AppRadii.brMd,
                            ),
                            child: Icon(
                              style.icon,
                              color: style.tint,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        style: AppTextStyles.titleSmall
                                            .copyWith(
                                              color: AppColors.onSurface,
                                              fontWeight: notification.read
                                                  ? FontWeight.w500
                                                  : FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    if (!notification.read)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: AppRadii.brFull,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification.body,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.space8),
                                Text(
                                  _formatTimestamp(notification.timestamp),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(
                      duration: AppMotion.base,
                      delay: Duration(milliseconds: 50 * index.clamp(0, 6)),
                    ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TypeStyle {
  const _TypeStyle({required this.icon, required this.tint, required this.bg});
  final IconData icon;
  final Color tint;
  final Color bg;
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 96),
        AppEmptyState(
          icon: Icons.notifications_off_outlined,
          title: 'All caught up',
          message: 'No new notifications right now. Check back later.',
        ),
      ],
    );
  }
}
