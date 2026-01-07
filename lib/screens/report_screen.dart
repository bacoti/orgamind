import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import '../constants/theme.dart';
import '../models/event_model.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _selectedPeriod = 'month';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Report Data
  Map<String, dynamic> _eventStats = {};
  Map<String, dynamic> _participantStats = {};
  List<Map<String, dynamic>> _categoryBreakdown = [];
  List<Map<String, dynamic>> _monthlyTrends = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);

    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    await eventProvider.getAllEvents();

    _calculateStatistics(eventProvider.events);

    setState(() => _isLoading = false);
  }

  void _calculateStatistics(List<EventModel> events) {
    final now = DateTime.now();

    // Filter events by selected period
    List<EventModel> filteredEvents = events.where((e) {
      return e.date.isAfter(_startDate) && e.date.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    // Event Statistics
    final upcomingEvents =
        filteredEvents.where((e) => e.date.isAfter(now)).toList();
    final completedEvents =
        filteredEvents.where((e) => e.date.isBefore(now)).toList();
    final totalCapacity =
        filteredEvents.fold(0, (sum, e) => sum + e.capacity);
    final totalParticipants =
        filteredEvents.fold(0, (sum, e) => sum + (e.participantsCount ?? 0));

    _eventStats = {
      'total': filteredEvents.length,
      'upcoming': upcomingEvents.length,
      'completed': completedEvents.length,
      'totalCapacity': totalCapacity,
      'totalParticipants': totalParticipants,
      'averageAttendance': filteredEvents.isEmpty
          ? 0.0
          : (totalParticipants / filteredEvents.length).toStringAsFixed(1),
      'fillRate': totalCapacity > 0
          ? ((totalParticipants / totalCapacity) * 100).toStringAsFixed(1)
          : '0.0',
    };

    // Participant Statistics
    _participantStats = {
      'total': totalParticipants,
      'averagePerEvent': filteredEvents.isEmpty
          ? 0
          : (totalParticipants / filteredEvents.length).round(),
      'maxCapacity': totalCapacity,
      'utilizationRate': totalCapacity > 0
          ? ((totalParticipants / totalCapacity) * 100).toStringAsFixed(1)
          : '0.0',
    };

    // Category Breakdown
    Map<String, int> categoryCount = {};
    Map<String, int> categoryParticipants = {};

    for (var event in filteredEvents) {
      final category = event.category ?? 'Uncategorized';
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      categoryParticipants[category] =
          (categoryParticipants[category] ?? 0) + (event.participantsCount ?? 0);
    }

    _categoryBreakdown = categoryCount.entries.map((e) {
      return {
        'category': e.key,
        'count': e.value,
        'participants': categoryParticipants[e.key] ?? 0,
        'percentage': filteredEvents.isEmpty
            ? 0.0
            : (e.value / filteredEvents.length * 100),
      };
    }).toList();

    _categoryBreakdown.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    // Monthly Trends (last 6 months)
    _monthlyTrends = [];
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 0);

      final monthEvents = events.where((e) {
        return e.date.isAfter(month.subtract(const Duration(days: 1))) &&
            e.date.isBefore(monthEnd.add(const Duration(days: 1)));
      }).toList();

      final monthParticipants =
          monthEvents.fold(0, (sum, e) => sum + (e.participantsCount ?? 0));

      _monthlyTrends.add({
        'month': DateFormat('MMM').format(month),
        'year': month.year,
        'events': monthEvents.length,
        'participants': monthParticipants,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(innerBoxIsScrolled),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadReportData,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildEventsTab(),
                    _buildParticipantsTab(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.analytics_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Laporan & Analitik',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Periode: ${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.date_range, color: Colors.white, size: 20),
          ),
          tooltip: 'Pilih Periode',
          onPressed: _showPeriodSelector,
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.share, color: Colors.white, size: 20),
          ),
          tooltip: 'Bagikan Laporan',
          onPressed: _shareReport,
        ),
        const SizedBox(width: 8),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Events'),
          Tab(text: 'Peserta'),
        ],
      ),
    );
  }

  // ==================== OVERVIEW TAB ====================
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selector Chips
          _buildPeriodChips(),
          const SizedBox(height: 20),

          // Summary Cards
          _buildSummaryCards(),
          const SizedBox(height: 24),

          // Monthly Trends Chart
          _buildSectionHeader(
            'Tren Bulanan',
            Icons.trending_up,
            'Statistik 6 bulan terakhir',
          ),
          const SizedBox(height: 12),
          _buildMonthlyTrendsChart(),
          const SizedBox(height: 24),

          // Category Distribution
          _buildSectionHeader(
            'Distribusi Kategori',
            Icons.pie_chart_outline,
            'Event berdasarkan kategori',
          ),
          const SizedBox(height: 12),
          _buildCategoryDistribution(),
          const SizedBox(height: 24),

          // Quick Insights
          _buildSectionHeader(
            'Insight Cepat',
            Icons.lightbulb_outline,
            'Rekomendasi berdasarkan data',
          ),
          const SizedBox(height: 12),
          _buildQuickInsights(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPeriodChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPeriodChip('7 Hari', 'week', 7),
          const SizedBox(width: 8),
          _buildPeriodChip('30 Hari', 'month', 30),
          const SizedBox(width: 8),
          _buildPeriodChip('3 Bulan', 'quarter', 90),
          const SizedBox(width: 8),
          _buildPeriodChip('6 Bulan', 'half', 180),
          const SizedBox(width: 8),
          _buildPeriodChip('1 Tahun', 'year', 365),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value, int days) {
    final isSelected = _selectedPeriod == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPeriod = value;
            _startDate = DateTime.now().subtract(Duration(days: days));
            _endDate = DateTime.now();
          });
          final eventProvider =
              Provider.of<EventProvider>(context, listen: false);
          _calculateStatistics(eventProvider.events);
        }
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Event',
                _eventStats['total']?.toString() ?? '0',
                Icons.event,
                AppColors.primary,
                '+${_eventStats['upcoming'] ?? 0} mendatang',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Peserta',
                _participantStats['total']?.toString() ?? '0',
                Icons.people,
                Colors.green,
                'Avg: ${_eventStats['averageAttendance'] ?? 0}/event',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Fill Rate',
                '${_eventStats['fillRate'] ?? 0}%',
                Icons.analytics,
                Colors.orange,
                '${_participantStats['total'] ?? 0}/${_eventStats['totalCapacity'] ?? 0}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Selesai',
                _eventStats['completed']?.toString() ?? '0',
                Icons.check_circle_outline,
                Colors.blue,
                'dari ${_eventStats['total'] ?? 0} event',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(Icons.trending_up, color: Colors.green[400], size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyTrendsChart() {
    final maxEvents = _monthlyTrends.isEmpty
        ? 1
        : _monthlyTrends.map((e) => e['events'] as int).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Chart Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Events', AppColors.primary),
              const SizedBox(width: 24),
              _buildLegendItem('Peserta', Colors.orange),
            ],
          ),
          const SizedBox(height: 20),

          // Bar Chart
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _monthlyTrends.map((data) {
                final eventHeight =
                    maxEvents > 0 ? (data['events'] as int) / maxEvents * 120 : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Event count label
                        Text(
                          data['events'].toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Bar
                        Container(
                          height: eventHeight.toDouble(),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Month label
                        Text(
                          data['month'],
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        // Participant count
                        Text(
                          '${data['participants']}p',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.orange[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDistribution() {
    if (_categoryBreakdown.isEmpty) {
      return _buildEmptyState(
        'Tidak ada data kategori',
        'Event akan muncul setelah ada data',
        Icons.category_outlined,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: _categoryBreakdown.take(5).map((category) {
          final percentage = category['percentage'] as double;
          final colors = [
            AppColors.primary,
            Colors.orange,
            Colors.green,
            Colors.purple,
            Colors.teal,
          ];
          final colorIndex =
              _categoryBreakdown.indexOf(category) % colors.length;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors[colorIndex],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              category['category'],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${category['count']} event (${percentage.toStringAsFixed(0)}%)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colors[colorIndex]),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickInsights() {
    List<Map<String, dynamic>> insights = [];

    // Generate insights based on data
    final fillRate = double.tryParse(_eventStats['fillRate']?.toString() ?? '0') ?? 0;
    final avgAttendance =
        double.tryParse(_eventStats['averageAttendance']?.toString() ?? '0') ?? 0;
    final completedEvents = _eventStats['completed'] ?? 0;
    final totalEvents = _eventStats['total'] ?? 0;

    if (fillRate < 50) {
      insights.add({
        'icon': Icons.warning_amber_rounded,
        'color': Colors.orange,
        'title': 'Fill Rate Rendah',
        'description':
            'Fill rate ${fillRate.toStringAsFixed(0)}% di bawah target. Pertimbangkan promosi lebih intensif.',
      });
    } else if (fillRate >= 80) {
      insights.add({
        'icon': Icons.thumb_up,
        'color': Colors.green,
        'title': 'Fill Rate Bagus!',
        'description':
            'Fill rate ${fillRate.toStringAsFixed(0)}% sangat baik. Pertahankan strategi ini!',
      });
    }

    if (_categoryBreakdown.isNotEmpty) {
      final topCategory = _categoryBreakdown.first;
      insights.add({
        'icon': Icons.star,
        'color': Colors.amber,
        'title': 'Kategori Populer',
        'description':
            '"${topCategory['category']}" adalah kategori paling populer dengan ${topCategory['count']} event.',
      });
    }

    if (avgAttendance > 0) {
      insights.add({
        'icon': Icons.people,
        'color': Colors.blue,
        'title': 'Rata-rata Peserta',
        'description':
            'Rata-rata ${avgAttendance.toStringAsFixed(0)} peserta per event. Target optimal: 30-50 peserta.',
      });
    }

    if (completedEvents > 0 && totalEvents > 0) {
      final completionRate = (completedEvents / totalEvents * 100);
      insights.add({
        'icon': Icons.check_circle,
        'color': Colors.teal,
        'title': 'Tingkat Penyelesaian',
        'description':
            '${completionRate.toStringAsFixed(0)}% event telah selesai dilaksanakan.',
      });
    }

    if (insights.isEmpty) {
      return _buildEmptyState(
        'Belum ada insight',
        'Insight akan muncul setelah ada data event',
        Icons.lightbulb_outline,
      );
    }

    return Column(
      children: insights
          .map((insight) => _buildInsightCard(
                insight['icon'],
                insight['color'],
                insight['title'],
                insight['description'],
              ))
          .toList(),
    );
  }

  Widget _buildInsightCard(
    IconData icon,
    Color color,
    String title,
    String description,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== EVENTS TAB ====================
  Widget _buildEventsTab() {
    return Consumer<EventProvider>(
      builder: (context, eventProvider, _) {
        final events = eventProvider.events;

        if (events.isEmpty) {
          return _buildEmptyState(
            'Belum ada event',
            'Event akan muncul di sini setelah dibuat',
            Icons.event_outlined,
          );
        }

        // Group events by status
        final upcomingEvents =
            events.where((e) => e.date.isAfter(DateTime.now())).toList();
        final completedEvents =
            events.where((e) => e.date.isBefore(DateTime.now())).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Summary Cards
              _buildEventSummaryCards(events.length, upcomingEvents.length,
                  completedEvents.length),
              const SizedBox(height: 24),

              // Upcoming Events
              if (upcomingEvents.isNotEmpty) ...[
                _buildSectionHeader(
                  'Event Mendatang',
                  Icons.upcoming_outlined,
                  '${upcomingEvents.length} event dijadwalkan',
                ),
                const SizedBox(height: 12),
                ...upcomingEvents.take(5).map((e) => _buildEventCard(e, true)),
                const SizedBox(height: 24),
              ],

              // Completed Events
              if (completedEvents.isNotEmpty) ...[
                _buildSectionHeader(
                  'Event Selesai',
                  Icons.check_circle_outline,
                  '${completedEvents.length} event telah dilaksanakan',
                ),
                const SizedBox(height: 12),
                ...completedEvents.take(5).map((e) => _buildEventCard(e, false)),
              ],

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventSummaryCards(int total, int upcoming, int completed) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniStatCard(
            'Total',
            total.toString(),
            Icons.event,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniStatCard(
            'Mendatang',
            upcoming.toString(),
            Icons.schedule,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniStatCard(
            'Selesai',
            completed.toString(),
            Icons.done_all,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventModel event, bool isUpcoming) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date Badge
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isUpcoming
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('dd').format(event.date),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isUpcoming ? AppColors.primary : Colors.grey,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(event.date),
                  style: TextStyle(
                    fontSize: 11,
                    color: isUpcoming ? AppColors.primary : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Event Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people_outline,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${event.participantsCount ?? 0}/${event.capacity} peserta',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isUpcoming ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isUpcoming ? 'Aktif' : 'Selesai',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isUpcoming ? Colors.green : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PARTICIPANTS TAB ====================
  Widget _buildParticipantsTab() {
    return Consumer<EventProvider>(
      builder: (context, eventProvider, _) {
        final events = eventProvider.events;
        final totalParticipants =
            events.fold(0, (sum, e) => sum + (e.participantsCount ?? 0));
        final totalCapacity = events.fold(0, (sum, e) => sum + e.capacity);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Participant Overview
              _buildParticipantOverview(totalParticipants, totalCapacity),
              const SizedBox(height: 24),

              // Utilization Gauge
              _buildSectionHeader(
                'Tingkat Utilisasi',
                Icons.speed,
                'Perbandingan peserta vs kapasitas',
              ),
              const SizedBox(height: 12),
              _buildUtilizationGauge(totalParticipants, totalCapacity),
              const SizedBox(height: 24),

              // Top Events by Participants
              _buildSectionHeader(
                'Event Terpopuler',
                Icons.emoji_events,
                'Berdasarkan jumlah peserta',
              ),
              const SizedBox(height: 12),
              _buildTopEventsList(events),
              const SizedBox(height: 24),

              // Participation Rate by Category
              _buildSectionHeader(
                'Partisipasi per Kategori',
                Icons.category,
                'Rata-rata peserta berdasarkan kategori',
              ),
              const SizedBox(height: 12),
              _buildParticipationByCategory(),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParticipantOverview(int total, int capacity) {
    final avgPerEvent = _eventStats['total'] != null && _eventStats['total'] > 0
        ? (total / _eventStats['total']).toStringAsFixed(1)
        : '0';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green,
            Colors.green.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewItem(
                total.toString(),
                'Total Peserta',
                Icons.people,
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildOverviewItem(
                avgPerEvent,
                'Rata-rata/Event',
                Icons.trending_up,
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildOverviewItem(
                capacity.toString(),
                'Total Kapasitas',
                Icons.groups,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUtilizationGauge(int participants, int capacity) {
    final utilization = capacity > 0 ? (participants / capacity * 100) : 0.0;
    final utilizationColor = utilization >= 80
        ? Colors.green
        : utilization >= 50
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Circular Progress
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: utilization / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(utilizationColor),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${utilization.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: utilizationColor,
                        ),
                      ),
                      Text(
                        'Utilisasi',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Status Text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: utilizationColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              utilization >= 80
                  ? '🎉 Excellent! Kapasitas terisi dengan baik'
                  : utilization >= 50
                      ? '👍 Good! Masih ada ruang untuk ditingkatkan'
                      : '⚠️ Perlu perhatian! Tingkatkan promosi event',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: utilizationColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopEventsList(List<EventModel> events) {
    final sortedEvents = List<EventModel>.from(events)
      ..sort((a, b) =>
          (b.participantsCount ?? 0).compareTo(a.participantsCount ?? 0));

    if (sortedEvents.isEmpty) {
      return _buildEmptyState(
        'Belum ada event',
        'Event akan muncul di sini',
        Icons.emoji_events,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: sortedEvents.take(5).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final event = entry.value;
          final medals = ['🥇', '🥈', '🥉', '4️⃣', '5️⃣'];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text(
                  medals[index],
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        event.category ?? 'Uncategorized',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${event.participantsCount ?? 0} peserta',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildParticipationByCategory() {
    if (_categoryBreakdown.isEmpty) {
      return _buildEmptyState(
        'Belum ada data',
        'Data akan muncul setelah ada event',
        Icons.category,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: _categoryBreakdown.map((category) {
          final avgParticipants = category['count'] > 0
              ? (category['participants'] / category['count']).toStringAsFixed(1)
              : '0';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.category,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category['category'],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${category['count']} event • ${category['participants']} total peserta',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      avgParticipants,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'avg/event',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================
  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== ACTIONS ====================
  void _showPeriodSelector() async {
    final result = await showModalBottomSheet<Map<String, DateTime>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PeriodSelectorSheet(
        startDate: _startDate,
        endDate: _endDate,
      ),
    );

    if (result != null) {
      setState(() {
        _startDate = result['start']!;
        _endDate = result['end']!;
        _selectedPeriod = 'custom';
      });
      final eventProvider =
          Provider.of<EventProvider>(context, listen: false);
      _calculateStatistics(eventProvider.events);
    }
  }

  void _shareReport() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('Fitur export laporan akan segera hadir!')),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// Period Selector Bottom Sheet
class _PeriodSelectorSheet extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;

  const _PeriodSelectorSheet({
    required this.startDate,
    required this.endDate,
  });

  @override
  State<_PeriodSelectorSheet> createState() => _PeriodSelectorSheetState();
}

class _PeriodSelectorSheetState extends State<_PeriodSelectorSheet> {
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _start = widget.startDate;
    _end = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.date_range, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              const Text(
                'Pilih Periode Laporan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Start Date
          _buildDateSelector(
            'Tanggal Mulai',
            _start,
            (date) => setState(() => _start = date),
          ),
          const SizedBox(height: 16),

          // End Date
          _buildDateSelector(
            'Tanggal Akhir',
            _end,
            (date) => setState(() => _end = date),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {'start': _start, 'end': _end});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Terapkan'),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildDateSelector(
    String label,
    DateTime date,
    Function(DateTime) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppColors.primary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMMM yyyy').format(date),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}
