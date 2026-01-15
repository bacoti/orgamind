import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../models/event_model.dart';
import '../providers/event_provider.dart';
import '../services/auth_service.dart';
import 'event_detail_screen.dart';
import 'event_list_screen.dart';

enum _HistoryFilter { all, hadir, tidakHadir }

class ParticipantHistoryScreen extends StatefulWidget {
  const ParticipantHistoryScreen({super.key});

  @override
  State<ParticipantHistoryScreen> createState() =>
      _ParticipantHistoryScreenState();
}

class _ParticipantHistoryScreenState extends State<ParticipantHistoryScreen> {
  bool _isBootLoading = true;
  String? _loadError;

  final TextEditingController _queryController = TextEditingController();
  String _query = '';
  _HistoryFilter _filter = _HistoryFilter.all;
  DateTime? _lastUpdatedAt;

  @override
  void initState() {
    super.initState();
    _queryController.addListener(() {
      final next = _queryController.text;
      if (next == _query) return;
      setState(() => _query = next);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isBootLoading = true;
      _loadError = null;
    });

    final auth = AuthService();
    await auth.init();
    final token = auth.getToken();

    if (!mounted) return;

    if (token == null) {
      setState(() {
        _isBootLoading = false;
        _loadError = 'Sesi kamu habis. Silakan login ulang.';
      });
      return;
    }

    final ok = await Provider.of<EventProvider>(
      context,
      listen: false,
    ).getParticipatingEvents(token);

    if (!mounted) return;

    setState(() {
      _isBootLoading = false;
      _loadError = ok ? null : 'Gagal memuat riwayat.';
      if (ok) _lastUpdatedAt = DateTime.now();
    });
  }

  bool _isHadir(EventModel e) => (e.status ?? 'registered') == 'registered';

  bool _isTidakHadir(EventModel e) => (e.status ?? '') == 'rejected';

  String _formatDate(DateTime date) {
    return DateFormat('EEE, d MMM yyyy', 'id_ID').format(date);
  }

  String _formatTimeRange(EventModel e) {
    String hhmm(String t) {
      final parts = t.split(':');
      if (parts.length < 2) return t;
      return '${parts[0]}:${parts[1]}';
    }

    final start = hhmm(e.time);
    final end = (e.endTime == null || e.endTime!.isEmpty)
        ? null
        : hhmm(e.endTime!);
    if (end == null || end == start) return '$start WIB';
    return '$start - $end WIB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        child: Consumer<EventProvider>(
          builder: (context, events, _) {
            final allRaw = events.participatingEvents;
            final q = _query.trim().toLowerCase();

            final all = q.isEmpty
                ? allRaw
                : allRaw.where((e) {
                    final hay = [
                      e.title,
                      e.location,
                      e.organizerName ?? '',
                      e.category ?? '',
                    ].join(' ').toLowerCase();
                    return hay.contains(q);
                  }).toList();

            final hadirAll = all.where(_isHadir).toList()
              ..sort((a, b) => b.date.compareTo(a.date));
            final tidakHadirAll = all.where(_isTidakHadir).toList()
              ..sort((a, b) => b.date.compareTo(a.date));

            final hadir = _filter == _HistoryFilter.tidakHadir
                ? <EventModel>[]
                : hadirAll;
            final tidakHadir = _filter == _HistoryFilter.hadir
                ? <EventModel>[]
                : tidakHadirAll;

            final totalAll = all.length;
            final hadirCount = hadirAll.length;
            final tidakHadirCount = tidakHadirAll.length;

            return RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: _HistoryHeader(
                        total: totalAll,
                        hadir: hadirCount,
                        tidakHadir: tidakHadirCount,
                      ),
                    ),
                  ),

                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyControlsDelegate(
                      minExtent: 164,
                      maxExtent: 164,
                      child: _StickyControls(
                        theme: theme,
                        queryController: _queryController,
                        total: totalAll,
                        filter: _filter,
                        lastUpdatedAt: _lastUpdatedAt,
                        onFilterChanged: (f) {
                          setState(() => _filter = f);
                        },
                        onClearQuery: () {
                          _queryController.clear();
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    ),
                  ),

                  if (_isBootLoading)
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 20),
                      sliver: SliverToBoxAdapter(child: _HistorySkeleton()),
                    )
                  else if (_loadError != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _ErrorState(message: _loadError!, onRetry: _load),
                    )
                  else if (all.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(),
                    )
                  else ...[
                    if (_filter != _HistoryFilter.tidakHadir &&
                        hadir.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Text(
                            'Hadir',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.gray900,
                            ),
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      sliver: SliverList.separated(
                        itemCount: hadir.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final e = hadir[index];
                          return _HistoryCard(
                            event: e,
                            dateText: _formatDate(e.date),
                            timeText: _formatTimeRange(e),
                            isHadir: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EventDetailScreen(event: e),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    if (_filter != _HistoryFilter.hadir &&
                        tidakHadir.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                          child: Text(
                            'Tidak Hadir',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.gray900,
                            ),
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList.separated(
                        itemCount: tidakHadir.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final e = tidakHadir[index];
                          return _HistoryCard(
                            event: e,
                            dateText: _formatDate(e.date),
                            timeText: _formatTimeRange(e),
                            isHadir: false,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EventDetailScreen(event: e),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StickyControlsDelegate extends SliverPersistentHeaderDelegate {
  _StickyControlsDelegate({
    required this.minExtent,
    required this.maxExtent,
    required this.child,
  });

  @override
  final double minExtent;

  @override
  final double maxExtent;

  final Widget child;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _StickyControlsDelegate oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.minExtent != minExtent ||
        oldDelegate.maxExtent != maxExtent;
  }
}

class _StickyControls extends StatelessWidget {
  const _StickyControls({
    required this.theme,
    required this.queryController,
    required this.total,
    required this.filter,
    required this.lastUpdatedAt,
    required this.onFilterChanged,
    required this.onClearQuery,
  });

  final ThemeData theme;
  final TextEditingController queryController;
  final int total;
  final _HistoryFilter filter;
  final DateTime? lastUpdatedAt;
  final ValueChanged<_HistoryFilter> onFilterChanged;
  final VoidCallback onClearQuery;

  String _formatUpdatedAt(DateTime dt) {
    return DateFormat('HH:mm', 'id_ID').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.gray50,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.gray200.withValues(alpha: 0.70),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: queryController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari event, lokasi, organizer…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: queryController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: onClearQuery,
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Hapus',
                        ),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.gray50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _FancyFilterPills(value: filter, onChanged: onFilterChanged),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '$total hasil',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.gray800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '•',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lastUpdatedAt == null
                          ? 'Tarik untuk refresh'
                          : 'Update ${_formatUpdatedAt(lastUpdatedAt!)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.gray600,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FancyFilterPills extends StatelessWidget {
  const _FancyFilterPills({required this.value, required this.onChanged});

  final _HistoryFilter value;
  final ValueChanged<_HistoryFilter> onChanged;

  int _index(_HistoryFilter v) {
    switch (v) {
      case _HistoryFilter.all:
        return 0;
      case _HistoryFilter.hadir:
        return 1;
      case _HistoryFilter.tidakHadir:
        return 2;
    }
  }

  _HistoryFilter _fromIndex(int i) {
    switch (i) {
      case 0:
        return _HistoryFilter.all;
      case 1:
        return _HistoryFilter.hadir;
      default:
        return _HistoryFilter.tidakHadir;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIndex = _index(value);

    const height = 46.0;
    const padding = 6.0;
    const radius = 16.0;

    Widget item({
      required int index,
      required String label,
      required IconData icon,
    }) {
      final isSelected = selectedIndex == index;
      final fg = isSelected ? Colors.white : AppColors.gray700;

      return Expanded(
        child: Semantics(
          button: true,
          selected: isSelected,
          label: label,
          child: InkWell(
            onTap: () => onChanged(_fromIndex(index)),
            borderRadius: BorderRadius.circular(radius),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 160),
                style: theme.textTheme.labelLarge!.copyWith(
                  fontWeight: FontWeight.w900,
                  color: fg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: 8),
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final segmentW = (w - (padding * 2)) / 3;

        return Container(
          height: height,
          padding: const EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.gray200.withValues(alpha: 0.70),
            ),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: selectedIndex * segmentW,
                top: 0,
                bottom: 0,
                width: segmentW,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  item(index: 0, label: 'Semua', icon: Icons.grid_view_rounded),
                  item(
                    index: 1,
                    label: 'Hadir',
                    icon: Icons.check_circle_rounded,
                  ),
                  item(
                    index: 2,
                    label: 'Tidak Hadir',
                    icon: Icons.cancel_rounded,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  _HistoryHeader({
    required this.total,
    required this.hadir,
    required this.tidakHadir,
  });

  final int total;
  final int hadir;
  final int tidakHadir;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget metric(String label, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.90),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.history_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat Kehadiran',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rekap hadir/tidak hadir untuk event yang sudah selesai.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.90),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              metric('Total', total.toString()),
              const SizedBox(width: 10),
              metric('Hadir', hadir.toString()),
              const SizedBox(width: 10),
              metric('Tidak Hadir', tidakHadir.toString()),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  _HistoryCard({
    required this.event,
    required this.dateText,
    required this.timeText,
    required this.isHadir,
    required this.onTap,
  });

  final EventModel event;
  final String dateText;
  final String timeText;
  final bool isHadir;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasImage = event.imageUrl != null && event.imageUrl!.isNotEmpty;
    final category = event.category;

    final participants = event.participantsCount ?? 0;
    final capacity = event.capacity <= 0 ? 0 : event.capacity;
    final double progress = capacity > 0
        ? (participants / capacity).clamp(0.0, 1.0).toDouble()
        : 0.0;

    final statusColor = isHadir ? AppColors.success : AppColors.error;
    final statusLabel = isHadir ? 'Hadir' : 'Tidak Hadir';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.gray200.withValues(alpha: 0.70)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EventThumbnail(
                imageUrl: hasImage ? event.imageUrl : null,
                isHadir: isHadir,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Pill(text: statusLabel, color: statusColor),
                        if (category != null && category.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _Pill(text: category, color: AppColors.secondaryDark),
                        ],
                        const Spacer(),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.gray500,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _MetaRow(
                      icon: Icons.calendar_today_rounded,
                      text: dateText,
                    ),
                    const SizedBox(height: 4),
                    _MetaRow(icon: Icons.schedule_rounded, text: timeText),
                    const SizedBox(height: 4),
                    _MetaRow(
                      icon: Icons.location_on_rounded,
                      text: event.location,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (event.organizerName != null &&
                                  event.organizerName!.isNotEmpty)
                                _MetaRow(
                                  icon: Icons.verified_user_rounded,
                                  text: event.organizerName!,
                                )
                              else
                                const SizedBox.shrink(),
                              if (capacity > 0) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          minHeight: 7,
                                          backgroundColor: AppColors.gray100,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                statusColor,
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '$participants/$capacity',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.gray700,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventThumbnail extends StatelessWidget {
  _EventThumbnail({required this.imageUrl, required this.isHadir});

  final String? imageUrl;
  final bool isHadir;

  @override
  Widget build(BuildContext context) {
    final bg = isHadir ? AppColors.success : AppColors.error;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 76,
        height: 76,
        color: bg.withValues(alpha: 0.10),
        child: imageUrl == null
            ? Center(
                child: Icon(
                  Icons.event_rounded,
                  color: bg.withValues(alpha: 0.85),
                ),
              )
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(
                    Icons.event_rounded,
                    color: bg.withValues(alpha: 0.85),
                  ),
                ),
              ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.gray600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.gray700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_available_rounded,
                size: 34,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Belum ada riwayat kehadiran',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Riwayat muncul setelah event selesai dan kehadiran tercatat.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.gray700,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EventListScreen()),
                );
              },
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Jelajahi Acara'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    Widget shimmerLine({required double width, required double height}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.gray200.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    Widget item() {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.gray200.withValues(alpha: 0.70)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 76,
                  height: 76,
                  color: AppColors.gray200.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        shimmerLine(width: 72, height: 22),
                        const SizedBox(width: 8),
                        shimmerLine(width: 88, height: 22),
                        const Spacer(),
                        shimmerLine(width: 18, height: 18),
                      ],
                    ),
                    const SizedBox(height: 10),
                    shimmerLine(width: double.infinity, height: 16),
                    const SizedBox(height: 6),
                    shimmerLine(width: 220, height: 14),
                    const SizedBox(height: 6),
                    shimmerLine(width: 160, height: 14),
                    const SizedBox(height: 12),
                    shimmerLine(width: double.infinity, height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        item(),
        const SizedBox(height: 10),
        item(),
        const SizedBox(height: 10),
        item(),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.gray500,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
