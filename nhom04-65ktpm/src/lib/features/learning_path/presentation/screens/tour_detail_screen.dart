import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/english_tour_model.dart';
import '../providers/learning_path_provider.dart';

/// M4 - Màn hình chi tiết một Tour dẫn tiếng Anh / CLB giao lưu và mẫu câu gợi ý.
class TourDetailScreen extends StatefulWidget {
  const TourDetailScreen({super.key, this.tour, this.tourId})
    : assert(tour != null || tourId != null);

  final EnglishTour? tour;
  final String? tourId;

  @override
  State<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends State<TourDetailScreen> {
  String? _reminderNote;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.tour != null) return;
      final provider = context.read<LearningPathProvider>();
      if (provider.tours.isEmpty && !provider.isLoading) {
        provider.loadInitialData();
      }
    });
  }

  EnglishTour? _resolveTour(LearningPathProvider provider) {
    if (widget.tour != null) return widget.tour;
    for (final item in provider.tours) {
      if (item.tourId == widget.tourId) return item;
    }
    return null;
  }

  Future<void> _copyPhrase(BuildContext context, String phrase) async {
    await Clipboard.setData(ClipboardData(text: phrase));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép mẫu câu giao tiếp')),
    );
  }

  Future<void> _pickReminder(BuildContext context, EnglishTour tour) async {
    final chosen = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('Đặt nhắc lịch tham gia'),
          children: [
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.of(dialogContext).pop('Nhắc trước 1 giờ'),
              child: const Text('Nhắc trước giờ diễn ra 1 giờ'),
            ),
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.of(dialogContext).pop('Nhắc tối hôm trước (20:00)'),
              child: const Text('Nhắc tối hôm trước (20:00)'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );

    if (chosen != null && mounted) {
      setState(() => _reminderNote = chosen);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã đặt lịch "$chosen" cho ${tour.title}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LearningPathProvider>();
    final tour = _resolveTour(provider);

    if (tour == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết Tour & CLB')),
        body: const Center(child: Text('Không tìm thấy thông tin tour.')),
      );
    }

    final isSaved = provider.isTourSaved(tour.tourId);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Tour & CLB'),
        actions: [
          IconButton(
            tooltip: isSaved ? 'Bỏ lưu quan tâm' : 'Lưu quan tâm',
            onPressed: () => provider.toggleSavedTour(tour.tourId),
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: isSaved ? scheme.primary : null,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Trình độ khuyến nghị: ${tour.levelRecommended}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tour.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.groups_outlined,
                    label: 'Đơn vị tổ chức',
                    value: tour.organizer,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.schedule,
                    label: 'Lịch hoạt động',
                    value: tour.scheduleText,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Địa điểm tập trung',
                    value: tour.location,
                  ),
                  if (tour.sourceUrl.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.link,
                      label: 'Nguồn tham khảo',
                      value: tour.sourceUrl,
                    ),
                  ],
                  if (_reminderNote != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_active_outlined,
                            size: 18,
                            color: scheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Nhắc lịch: $_reminderNote',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Mẫu câu giao tiếp dẫn tour gợi ý',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (tour.samplePhrases.isEmpty)
            const Text('Chưa có mẫu câu gợi ý cho hoạt động này.')
          else
            for (var i = 0; i < tour.samplePhrases.length; i++) ...[
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 14,
                    child: Text('${i + 1}'),
                  ),
                  title: Text(tour.samplePhrases[i]),
                  trailing: IconButton(
                    tooltip: 'Sao chép mẫu câu',
                    onPressed: () =>
                        _copyPhrase(context, tour.samplePhrases[i]),
                    icon: const Icon(Icons.copy_outlined, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => provider.toggleSavedTour(tour.tourId),
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                  ),
                  label: Text(isSaved ? 'Đã lưu quan tâm' : 'Lưu quan tâm'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickReminder(context, tour),
                  icon: const Icon(Icons.alarm_add_outlined),
                  label: const Text('Đặt nhắc lịch'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              SelectableText(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
