import 'package:flutter/material.dart';

/// Centers a form-like layout with a maximum readable width.
///
/// {@tool snippet}
/// CenteredForm(
///   child: Column(
///     mainAxisSize: MainAxisSize.min,
///     children: const [
///       Text('Sign in'),
///       SizedBox(height: 16),
///       TextField(),
///     ],
///   ),
/// )
/// {@end-tool}
///
/// Error cases:
/// - If [child] has an unconstrained scrollable, Flutter can throw layout
///   overflow exceptions. Wrap it with `SingleChildScrollView` if needed.
class CenteredForm extends StatelessWidget {
  const CenteredForm({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    );
  }
}
