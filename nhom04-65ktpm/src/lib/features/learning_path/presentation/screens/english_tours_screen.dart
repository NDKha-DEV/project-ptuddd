import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../../data/models/english_tour_model.dart';
import '../providers/learning_path_provider.dart';
import 'tour_detail_screen.dart';

/// M4 - Danh sách Tour dẫn tiếng Anh và CLB giao lưu tại Hà Nội.
class EnglishToursScreen extends StatefulWidget {
  const EnglishToursScreen({super.key, this.onOpenTour});

  final ValueChanged<EnglishTour>? onOpenTour;

  @override
  State<EnglishToursScreen> createState() => _EnglishToursScreenState();
}

class _EnglishToursScreenState extends State<EnglishToursScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<LearningPathProvider>();
      if (provider.tours.isEmpty && !provider.isLoading) {
        provider.loadInitialData();
      }
    });
  }

  void _openDetail(BuildContext context, EnglishTour tour) {
    if (widget.onOpenTour != null) {
      widget.onOpenTour!(tour);
      return;
    }
    if (GoRouter.maybeOf(context) != null) {
      context.push(AppRoutes.learningPathTourDetail(tour.tourId));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TourDetailScreen(tour: tour),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LearningPathProvider>();
    final tours = provider.filteredTours;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tour dẫn tiếng Anh & CLB')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Chỉ cuối tuần'),
                  selected: provider.weekendToursOnly,
                  onSelected: provider.setWeekendToursOnly,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${tours.length} gợi ý · Đã lưu ${provider.savedTourIds.length}',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading && tours.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : tours.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Chưa có tour hoặc CLB phù hợp với bộ lọc hiện tại.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    itemCount: tours.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tour = tours[index];
                      final isSaved = provider.isTourSaved(tour.tourId);
                      return _TourListCard(
                        tour: tour,
                        isSaved: isSaved,
                        onToggleSave: () =>
                            provider.toggleSavedTour(tour.tourId),
                        onTap: () => _openDetail(context, tour),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TourListCard extends StatelessWidget {
  const _TourListCard({
    required this.tour,
    required this.isSaved,
    required this.onToggleSave,
    required this.onTap,
  });

  final EnglishTour tour;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Trình độ ${tour.levelRecommended}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tour.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: isSaved ? 'Bỏ lưu quan tâm' : 'Lưu quan tâm',
                    onPressed: onToggleSave,
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                tour.organizer,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tour.scheduleText,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tour.location,
                      style: theme.textTheme.bodySmall,
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
