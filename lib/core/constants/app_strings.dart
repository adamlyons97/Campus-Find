/// User-facing strings, including the Shariah-grounded copy that frames the
/// claim and handover flow around the principles of *Amanah* (trust) and
/// *Luqatah* (lawful handling of lost property).
class AppStrings {
  AppStrings._();

  static const String appName = 'CampusFind';
  static const String tagline =
      'Recover what is lost. Return what is found. Built on Amanah.';

  // University domain restriction (Feature 1 — Authentication Hub).
  // Adjust to your institution's email domain(s).
  static const List<String> allowedEmailDomains = [
    'live.iium.edu.my',
    'iium.edu.my',
  ];

  // Shariah guidance shown to a finder before they post a found item.
  static const String luqatahFinderNotice =
      'In Islam, a found item (Luqatah) is an Amanah (trust). By posting it '
      'here you commit to safeguarding it honestly and returning it to its '
      'rightful owner once ownership is verified.';

  // Shariah guidance shown to a claimant before they submit a claim.
  static const String luqatahClaimantNotice =
      'To protect the rightful owner, you must describe a private detail of '
      'the item that only the true owner would reasonably know. Making a '
      'false claim is a betrayal of trust (khiyanah).';

  static const String claimVerificationHint =
      'e.g. a scratch on the back, contents inside, a sticker, the lock '
      'screen, or any hidden marking.';
}
