import 'package:flutter/material.dart';

import '../../models/admin_feedback.dart';
import '../../widgets/admin_card.dart';
import '../../widgets/tables/feedback_table.dart';

class FeedbacksSection extends StatelessWidget {
  const FeedbacksSection({
    super.key,
    required this.feedbacks,
    required this.onStatusChanged,
  });

  final List<AdminFeedback> feedbacks;
  final void Function(AdminFeedback feedback, String status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Feedbacks e chamados',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          FeedbackTable(feedbacks: feedbacks, onStatusChanged: onStatusChanged),
        ],
      ),
    );
  }
}
