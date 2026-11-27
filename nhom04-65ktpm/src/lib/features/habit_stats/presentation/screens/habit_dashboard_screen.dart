
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

class HabitDashboardScreen extends StatefulWidget {
  const HabitDashboardScreen({super.key});

  @override
  State<HabitDashboardScreen> createState() =>
      _HabitDashboardScreenState();
}

class _HabitDashboardScreenState extends State<HabitDashboardScreen> {
  int _dailyGoal = 30;

  // Dữ liệu mặc định, sẽ được thay bằng dữ liệu thực ở các commit sau.
  final int _studiedMinutes = 0;
  final int _currentStreak = 0;
  final int _bestStreak = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
        (_studiedMinutes / _dailyGoal).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daily You',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lịch học sẽ được bổ sung ở commit 3.'),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Xin chào! 👋',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hãy duy trì thói quen học tiếng Anh B1 mỗi ngày.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Mục tiêu học tập
          _sectionTitle('Mục tiêu hôm nay'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Thời gian học mục tiêu',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$_dailyGoal phút',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 30,
                        label: Text('30 phút'),
                      ),
                      ButtonSegment(
                        value: 45,
                        label: Text('45 phút'),
                      ),
                      ButtonSegment(
                        value: 60,
                        label: Text('60 phút'),
                      ),
                    ],
                    selected: {_dailyGoal},
                    onSelectionChanged: (values) {
                      setState(() {
                        _dailyGoal = values.first;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tiến độ học tập'),
                      Text(
                        '$_studiedMinutes/$_dailyGoal phút',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(progress * 100).round()}% hoàn thành mục tiêu',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Streak
          _sectionTitle('Thói quen học tập'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  context,
                  icon: Icons.local_fire_department,
                  title: 'Streak hiện tại',
                  value: '$_currentStreak ngày',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  context,
                  icon: Icons.emoji_events_outlined,
                  title: 'Kỷ lục',
                  value: '$_bestStreak ngày',
                  color: Colors.amber.shade800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Study Timer
          // Study Timer
_sectionTitle('Phiên học tập'),
const SizedBox(height: 12),
Consumer<HabitProvider>(
  builder: (context, provider, child) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.timer_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              provider.formattedTime,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 30, label: Text('30 phút')),
                ButtonSegment(value: 45, label: Text('45 phút')),
                ButtonSegment(value: 60, label: Text('60 phút')),
              ],
              selected: {provider.selectedMinutes},
              onSelectionChanged: (values) {
                provider.selectDuration(values.first);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: provider.isRunning
                        ? provider.pauseTimer
                        : provider.startTimer,
                    icon: Icon(
                      provider.isRunning
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    label: Text(
                      provider.isRunning ? 'Tạm dừng' : 'Bắt đầu học',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.outlined(
                  onPressed: provider.resetTimer,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Đặt lại',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  },
),

          // Nhật ký
          _sectionTitle('Nhật ký học tập'),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.edit_note,
                color: theme.colorScheme.primary,
                size: 32,
              ),
              title: const Text('Ghi lại buổi học hôm nay'),
              subtitle: const Text(
                'Lưu từ vựng mới và nội dung bạn đã học.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Nhật ký Daily Log sẽ được triển khai ở commit 3.',
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: Text(
              'TLU B1 Daily • ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
