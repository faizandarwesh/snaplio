/// Shared-preference keys used by both the app and background engines.
abstract final class PrefsKeys {
  static const defaultCurrency = 'default_currency';
  static const currencyManual = 'default_currency_manual';
  static const spendBackfillDone = 'spend_backfill_done_v1';
  static const spendCelebration = 'spend_celebration';

  static const excludedAlbums = 'excluded_albums';

  // Smart Actions
  static const smartEnabled = 'smart_actions';
  static const smartOtp = 'smart_otp';
  static const smartReceipts = 'smart_receipts';
  static const smartLinks = 'smart_links';
  static const smartAddresses = 'smart_addresses';
  static const smartPhones = 'smart_phones';
  static const smartCardDismissed = 'smart_home_card_dismissed';
  static const smartSheetShown = 'smart_sheet_shown';
  static const burstLog = 'notif_burst_log';
  static const lastNewScanAt = 'last_new_scan_at';

  // Weekly recap
  static const recapEnabled = 'recap_enabled';
  static const recapWeekday = 'recap_weekday';
  static const recapHour = 'recap_hour';
  static const recapMinute = 'recap_minute';
  static const recapLastOccurrence = 'recap_last_occurrence';
}
