class AppEvents {
  AppEvents._();

  static const fcmReceived = 'fcm_received';
  static const bookingCreated = 'booking_created';
  static const bookingCancelled = 'booking_cancelled';
  static const bookingRescheduled = 'booking_rescheduled';
  static const bookingCompleted = 'booking_completed';
  static const bookingAccepted = 'booking_accepted';
  static const paymentDone = 'payment_done';
  static const profileUpdated = 'profile_updated';
  static const favoriteChanged = 'favorite_changed';
  static const reviewAdded = 'review_added';
}
