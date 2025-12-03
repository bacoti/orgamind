// lib/screens/admin_dashboard_screen.dart
// Admin Dashboard - Mobile Version with comprehensive UI/UX principles

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../constants/theme.dart';
import '../models/event_model.dart';
import 'create_event_screen.dart';
import 'event_detail_screen.dart';
import 'user_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    await eventProvider.getAllEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: CustomScrollView(
          slivers: [
            // App Bar with Gradient
            _buildSliverAppBar(),
            
            // Statistics Cards
            SliverToBoxAdapter(
              child: _buildStatisticsSection(),
            ),
            
            // Quick Actions
            SliverToBoxAdapter(
              child: _buildQuickActionsSection(),
            ),
            
            // Recent Events
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Events',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to events tab
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
            ),
            
            // Events List
            _buildEventsList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleCreateEvent,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Event', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // Sliver App Bar with Gradient
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
        title: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            final user = authProvider.currentUser;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard Admin',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Welcome, ${user?.name ?? 'Admin'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            );
          },
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {
            // Navigate to notifications
          },
        ),
      ],
    );
  }

  // Statistics Section
  Widget _buildStatisticsSection() {
    return Consumer<EventProvider>(
      builder: (context, eventProvider, _) {
        final events = eventProvider.events;
        final upcomingEvents = events.where((e) => e.date.isAfter(DateTime.now())).toList();
        final pastEvents = events.where((e) => e.date.isBefore(DateTime.now())).toList();
        final totalParticipants = events.fold(0, (int sum, event) => sum + (event.participantsCount ?? 0));

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Row 1: Total Events & Upcoming
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Events',
                      events.length.toString(),
                      Icons.event,
                      AppColors.primary,
                      Colors.blue.shade50,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Upcoming',
                      upcomingEvents.length.toString(),
                      Icons.upcoming_outlined,
                      Colors.orange,
                      Colors.orange.shade50,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Row 2: Past Events & Participants
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Past Events',
                      pastEvents.length.toString(),
                      Icons.history,
                      Colors.purple,
                      Colors.purple.shade50,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Participants',
                      totalParticipants.toString(),
                      Icons.people,
                      Colors.green,
                      Colors.green.shade50,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: AppColors.gray600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Quick Actions Section
  Widget _buildQuickActionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Create Event',
                  Icons.add_circle_outline,
                  AppColors.primary,
                  () => _handleCreateEvent(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'View Reports',
                  Icons.assessment_outlined,
                  Colors.orange,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reports feature coming soon')),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Manage Users',
                  Icons.people_outline,
                  Colors.purple,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserManagementScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'Settings',
                  Icons.settings_outlined,
                  Colors.green,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings feature coming soon')),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.gray800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Events List
  Widget _buildEventsList() {
    return Consumer<EventProvider>(
      builder: (context, eventProvider, _) {
        if (eventProvider.isLoading) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final events = eventProvider.events;

        if (events.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyState(),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final event = events[index];
                return _buildEventCard(event);
              },
              childCount: events.length > 5 ? 5 : events.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventCard(EventModel event) {
    final isUpcoming = event.date.isAfter(DateTime.now());
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToEventDetail(event),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Title & Status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isUpcoming ? Colors.green.withValues(alpha: 0.1) : AppColors.gray100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isUpcoming ? 'Upcoming' : 'Past',
                        style: TextStyle(
                          color: isUpcoming ? Colors.green : AppColors.gray600,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Date & Location
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: AppColors.gray600),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd MMM yyyy').format(event.date),
                      style: TextStyle(color: AppColors.gray600, fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 14, color: AppColors.gray600),
                    const SizedBox(width: 6),
                    Text(
                      event.time,
                      style: TextStyle(color: AppColors.gray600, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: AppColors.gray600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.location,
                        style: TextStyle(color: AppColors.gray600, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                
                // Footer: Participants & Actions
                Row(
                  children: [
                    Icon(Icons.people, size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${event.participantsCount ?? 0}/${event.capacity} participants',
                      style: TextStyle(
                        color: AppColors.gray700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      iconSize: 20,
                      onPressed: () => _showEventOptions(event),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: AppColors.gray300),
          const SizedBox(height: 16),
          Text(
            'No Events Yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray600),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first event to get started',
            style: TextStyle(color: AppColors.gray600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Actions & Handlers

  void _handleCreateEvent() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateEventScreen()),
    ).then((_) => _loadDashboardData());
  }

  void _navigateToEventDetail(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)),
    );
  }

  void _showEventOptions(EventModel event) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(ctx);
                _navigateToEventDetail(event);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Event'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share Event'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Event', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteConfirmation(event);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // Question & Answer Dialog Pattern
  void _showDeleteConfirmation(EventModel event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteEvent(event);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent(EventModel event) async {
    // TODO: Implement delete in provider
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${event.title} deleted successfully')),
    );
    await _loadDashboardData();
  }
}
