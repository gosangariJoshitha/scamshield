import 'scamshield_card.dart';

export 'scamshield_card.dart';

/// Legacy alias for [ScamShieldCard].
/// Preserves backward compatibility across existing screens.
class CyberCard extends ScamShieldCard {
  const CyberCard({
    required super.child,
    super.padding,
    super.borderRadius,
    super.borderColor,
    super.backgroundColor,
    super.onTap,
    super.hoverLift,
    super.key,
  });
}
