import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/app_controller.dart';
import '../routes/app_routes.dart';
import '../theme.dart';
import '../utils/app_date_format.dart';

class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({super.key, required this.sessionId});

  final String? sessionId;

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  bool _loading = true;
  String? _error;
  String? _message;
  int? _amount;
  String? _content;
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _confirm();
  }

  Future<void> _confirm() async {
    final sessionId = widget.sessionId;
    if (sessionId == null || sessionId.trim().isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Session de paiement manquante';
      });
      return;
    }

    final app = context.read<AppController>();
    final result = await app.confirmPayment(sessionId);

    if (!mounted) return;

    if (result == null) {
      setState(() {
        _loading = false;
        _error = app.errorMessage ?? 'Confirmation impossible';
      });
      return;
    }

    setState(() {
      _loading = false;
      _message = result.message;
      _amount = result.invoice?.amount;
      _content = result.invoice?.content;
      _date = result.invoice?.createdAt;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _loading
                    ? const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 10),
                          Text('Confirmation du paiement...'),
                        ],
                      )
                    : _error != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error,
                            color: AppColors.danger,
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => context.go(AppRoutes.app),
                            child: const Text('Retour à l\'app'),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.c9D5EDF,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _message ?? 'Paiement confirmé',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          if (_content != null) Text('Article: $_content'),
                          if (_amount != null) Text('Montant: $_amount €'),
                          if (_date != null)
                            Text('Date: ${AppDateFormat.shortDate(_date)}'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => context.go(AppRoutes.app),
                            child: const Text('Retour à l\'app'),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
