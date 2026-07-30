import 'admin_company.dart';
import 'admin_feedback.dart';
import 'admin_message.dart';
import 'admin_payment.dart';
import 'admin_plan.dart';
import 'admin_user.dart';

class AdminData {
  const AdminData({
    required this.companies,
    required this.plans,
    required this.payments,
    required this.feedbacks,
    required this.messages,
    required this.users,
  });

  final List<AdminCompany> companies;
  final List<AdminPlan> plans;
  final List<AdminPayment> payments;
  final List<AdminFeedback> feedbacks;
  final List<AdminMessage> messages;
  final List<AdminUser> users;

  factory AdminData.fromMaps(
    Map<String, dynamic> companyMap,
    Map<String, dynamic> planMap,
    Map<String, dynamic> paymentMap,
    Map<String, dynamic> feedbackMap,
    Map<String, dynamic> messageMap,
    Map<String, dynamic> userMap,
  ) {
    final companyRows = (companyMap['companies'] as List? ?? const [])
        .map((row) => AdminCompany.fromMap(Map<String, dynamic>.from(row)))
        .toList();
    final planRows = (planMap['plans'] as List? ?? const [])
        .map((row) => AdminPlan.fromMap(Map<String, dynamic>.from(row)))
        .toList();
    final paymentRows = (paymentMap['payments'] as List? ?? const [])
        .map((row) => AdminPayment.fromMap(Map<String, dynamic>.from(row)))
        .toList();
    final feedbackRows = (feedbackMap['feedbacks'] as List? ?? const [])
        .map((row) => AdminFeedback.fromMap(Map<String, dynamic>.from(row)))
        .toList();
    final messageRows = (messageMap['messages'] as List? ?? const [])
        .map((row) => AdminMessage.fromMap(Map<String, dynamic>.from(row)))
        .toList();
    final userRows = (userMap['users'] as List? ?? const [])
        .map((row) => AdminUser.fromMap(Map<String, dynamic>.from(row)))
        .toList();
    return AdminData(
      companies: companyRows,
      plans: planRows,
      payments: paymentRows,
      feedbacks: feedbackRows,
      messages: messageRows,
      users: userRows,
    );
  }
}
