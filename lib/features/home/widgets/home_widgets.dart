part of '../home_shell.dart';

class _SimplePage extends StatelessWidget {
  const _SimplePage({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 128),
    children: [
      Text(title, style: Theme.of(context).textTheme.displaySmall),
      const SizedBox(height: 7),
      Text(subtitle, style: const TextStyle(color: UnfoldColors.muted)),
      const SizedBox(height: 28),
      child,
    ],
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) => GlassSurface(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 34),
      child: Column(
        children: [
          Icon(icon, size: 38, color: UnfoldColors.muted),
          const SizedBox(height: 13),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: UnfoldColors.muted),
          ),
        ],
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    this.onAction,
  });
  final String title;
  final String action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ),
      InkWell(
        onTap: onAction,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Text(
            action,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: UnfoldColors.cyan,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ],
  );
}

class _StartupLogo extends StatelessWidget {
  const _StartupLogo({required this.opportunity});

  final Opportunity opportunity;

  static const assets = {
    'Kayko': 'assets/logos/kayko.png',
    'Rwazi': 'assets/logos/rwazi.png',
    'Signvrse': 'assets/logos/signvrse.png',
    'Plastic Venture': 'assets/logos/plastic-venture.png',
    'Starlight': 'assets/logos/starlight.png',
    'Smartel Agri-tech': 'assets/logos/smartel-agritech.png',
  };

  @override
  Widget build(BuildContext context) {
    final asset = assets[opportunity.startup];
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      padding: asset == null ? EdgeInsets.zero : const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: asset == null ? opportunity.color : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: asset != null
          ? Center(
              child: Image.asset(asset, fit: BoxFit.contain, cacheWidth: 128),
            )
          : Center(
              child: Text(
                _ventureMark(opportunity.startup),
                style: const TextStyle(
                  color: UnfoldColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
    );
  }
}

class _CompensationPill extends StatelessWidget {
  const _CompensationPill({required this.opportunity});

  final Opportunity opportunity;

  @override
  Widget build(BuildContext context) {
    final amount = opportunity.monthlyAmount;
    final label = opportunity.isPaid && amount != null
        ? '${opportunity.currency} ${_shortAmount(amount)} / month'
        : opportunity.isVolunteering
        ? 'Volunteer'
        : 'Unpaid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: opportunity.isPaid
            ? UnfoldColors.mint.withValues(alpha: .14)
            : Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: opportunity.isPaid ? UnfoldColors.mint : UnfoldColors.muted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CompensationPanel extends StatelessWidget {
  const _CompensationPanel({required this.opportunity});
  final Opportunity opportunity;

  @override
  Widget build(BuildContext context) {
    final amount = opportunity.monthlyAmount;
    final paid = opportunity.isPaid && amount != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: paid
            ? UnfoldColors.mint.withValues(alpha: .09)
            : UnfoldColors.amber.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (paid ? UnfoldColors.mint : UnfoldColors.amber).withValues(
            alpha: .22,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (paid ? UnfoldColors.mint : UnfoldColors.amber).withValues(
                alpha: .14,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              paid
                  ? Icons.payments_outlined
                  : opportunity.isVolunteering
                  ? Icons.volunteer_activism_outlined
                  : Icons.school_outlined,
              color: paid ? UnfoldColors.mint : UnfoldColors.amber,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paid
                      ? '${opportunity.currency} ${_shortAmount(amount)} per month'
                      : opportunity.isVolunteering
                      ? 'Volunteer opportunity'
                      : 'Unpaid learning opportunity',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  paid ? 'Monthly compensation' : 'No financial compensation',
                  style: const TextStyle(
                    color: UnfoldColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _shortAmount(double amount) {
  if (amount >= 1000 && amount % 1000 == 0) {
    return '${(amount / 1000).toStringAsFixed(0)}K';
  }
  return amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2);
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();
  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.8, -0.75),
          radius: 1.15,
          colors: [Color(0x334f4f57), UnfoldColors.ink],
          stops: [0, 0.72],
        ),
      ),
    ),
  );
}
