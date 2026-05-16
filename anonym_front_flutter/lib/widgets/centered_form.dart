import 'package:flutter/material.dart';

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
