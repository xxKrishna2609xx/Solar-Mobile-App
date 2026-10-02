import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:solar_pro/core/constants/app_constants.dart';
import 'package:solar_pro/core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<_Notif> _notifications = [
    _Notif(
      'Payment Verified',
      'Rajesh Kumar\'s ₹50,000 advance has been verified by admin.',
      Icons.verified_rounded,
      AppColors.success,
      '2m ago',
      false,
      AppRoutes.payments,
    ),
    _Notif(
      'New Lead Assigned',
      'A new lead (Manoj Patel, 5kW) has been assigned to you.',
      Icons.person_add_rounded,
      AppColors.teal500,
      '1h ago',
      false,
      AppRoutes.leads,
    ),
    _Notif(
      'Work Started',
      'Team A has started Structure work for Sunita Devi.',
      Icons.construction_rounded,
      AppColors.orange500,
      '3h ago',
      true,
      AppRoutes.workAssign,
    ),
    _Notif(
      'KEDL Demand Raised',
      'Demand of ₹12,500 raised for Vikram Joshi\'s Net File.',
      Icons.warning_amber_rounded,
      AppColors.warning,
      '5h ago',
      true,
      AppRoutes.kedl,
    ),
    _Notif(
      'Service Ticket',
      'Priya Sharma raised an Inverter Fault ticket — HIGH priority.',
      Icons.support_agent_rounded,
      AppColors.error,
      '1d ago',
      true,
      AppRoutes.clientTickets,
    ),
    _Notif(
      'Payment Submitted',
      'Client Kavita Singh submitted ₹80,000 (2nd instalment).',
      Icons.payments_rounded,
      AppColors.gold500,
      '2d ago',
      true,
      AppRoutes.payments,
    ),
  ];

  void _markAllRead() {
    setState(() {
      for (var i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: AppColors.teal500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.navy900,
      appBar: AppBar(
        title: Text('Notifications ${unreadCount > 0 ? "($unreadCount unread)" : ""}'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text('Mark all read',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.gold400)),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_none_rounded,
                      size: 48, color: AppColors.grey600),
                  const SizedBox(height: 12),
                  Text('No notifications',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.grey500)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final n = _notifications[i];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _notifications[i] = n.copyWith(isRead: true);
                    });
                    context.push(n.targetRoute);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: n.isRead ? AppColors.navy800 : AppColors.navy700,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: n.isRead
                            ? AppColors.navy600
                            : n.color.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: n.color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(n.icon, color: n.color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(n.title,
                                        style: AppTextStyles.labelLarge),
                                  ),
                                  if (!n.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: n.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(n.body,
                                  style: AppTextStyles.bodySmall
                                      .copyWith(height: 1.4)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(n.time,
                                      style: AppTextStyles.caption
                                          .copyWith(color: AppColors.grey500)),
                                  const Spacer(),
                                  Text('Tap to view →',
                                      style: AppTextStyles.caption.copyWith(
                                          color: AppColors.gold400,
                                          fontSize: 10)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate(delay: Duration(milliseconds: i * 50))
                    .fadeIn(duration: 350.ms)
                    .slideX(begin: 0.05, end: 0);
              },
            ),
    );
  }
}

class _Notif {
  final String title, body, time, targetRoute;
  final IconData icon;
  final Color color;
  final bool isRead;
  const _Notif(this.title, this.body, this.icon, this.color, this.time,
      this.isRead, this.targetRoute);

  _Notif copyWith({bool? isRead}) {
    return _Notif(
      title,
      body,
      icon,
      color,
      time,
      isRead ?? this.isRead,
      targetRoute,
    );
  }
}
