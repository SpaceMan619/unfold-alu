part of '../home_shell.dart';

class _SavedView extends StatelessWidget {
  const _SavedView({
    required this.items,
    required this.onOpen,
    required this.onUnsave,
  });
  final List<Opportunity> items;
  final ValueChanged<Opportunity> onOpen;
  final ValueChanged<String> onUnsave;

  @override
  Widget build(BuildContext context) {
    return _SimplePage(
      title: 'Saved',
      subtitle: 'Keep the possibilities worth returning to.',
      child: items.isEmpty
          ? const _EmptyState(
              icon: Icons.bookmark_border_rounded,
              message: 'Save an opportunity and it will wait for you here.',
            )
          : Column(
              children: items
                  .map(
                    (item) => _SavedOpportunityTile(
                      key: ValueKey('saved-${item.id}'),
                      opportunity: item,
                      onOpen: () => onOpen(item),
                      onUnsave: () => onUnsave(item.id),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _SavedOpportunityTile extends StatefulWidget {
  const _SavedOpportunityTile({
    required this.opportunity,
    required this.onOpen,
    required this.onUnsave,
    super.key,
  });

  final Opportunity opportunity;
  final VoidCallback onOpen;
  final VoidCallback onUnsave;

  @override
  State<_SavedOpportunityTile> createState() => _SavedOpportunityTileState();
}

class _SavedOpportunityTileState extends State<_SavedOpportunityTile> {
  bool visible = true;

  Future<void> remove() async {
    if (!visible) return;
    setState(() => visible = false);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    widget.onUnsave();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOut,
      child: visible
          ? AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Dismissible(
                key: ValueKey(widget.opportunity.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => widget.onUnsave(),
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.only(right: 24),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(Icons.bookmark_remove_rounded),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OpportunityCard(
                    opportunity: widget.opportunity,
                    saved: true,
                    onSave: remove,
                    onTap: widget.onOpen,
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
