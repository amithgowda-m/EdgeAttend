// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  // Firestore Collection Names
  static const String membersCollection = 'members';
  static const String eventsCollection  = 'events';
  static const String sessionsCollection = 'sessions';

  // Member Document Fields
  static const String fieldMemberId      = 'member_id';
  static const String fieldName          = 'name';
  static const String fieldSessionStatus = 'session_status';
  static const String fieldIsFlagged     = 'is_flagged';

  // Event Document Fields
  static const String fieldTimestamp = 'timestamp';
  static const String fieldStatus    = 'status';
  static const String fieldAction    = 'action';

  // Session Status Values
  static const String statusPresent = 'Present';
  static const String statusAbsent  = 'Absent';

  // Event Status Values
  static const String statusAccessGranted  = 'Access_Granted';
  static const String statusUnknownEntity  = 'Unknown_Entity';
  static const String statusAccessDenied   = 'Access_Denied';

  // FCM
  static const String fcmTopicAlerts = 'security_alerts';

  // Analytics
  static const int analyticsLookbackDays = 30;

  // Navigation
  static const String routeLogin     = '/login';
  static const String routeDashboard = '/dashboard';
  static const String routeRegistry  = '/registry';
  static const String routeAnalytics = '/analytics';

  // Event Feed
  static const int eventFeedLimit = 50;
}
