import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/app_providers.dart';
import '../routes/app_routes.dart';
import '../theme.dart';
import '../utils/app_date_format.dart';
import '../widgets/app_remote_image.dart';


part '../widgets/payment_success_screen_widgets.dart';

/// Écran de confirmation de paiement réussi/échoué.
class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({super.key, required this.sessionId});

  final String? sessionId;

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _cardController;
  late final AnimationController _confettiController;
  late final Animation<double> _cardOffset;

  bool _loading = true;
  String? _error;
  int? _amount;
  String? _content;
  String? _articleImageUrl;
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _cardOffset = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutCubic,
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _confirm();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final sessionId = widget.sessionId?.trim();

    if (sessionId == null || sessionId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Session de paiement manquante';
      });
      return;
    }

    final app = context.read<AppProvider>();
    final result = await app.confirmPayment(sessionId);

    if (!mounted) return;

    if (result == null) {
      setState(() {
        _loading = false;
        _error = app.errorMessage ?? 'Confirmation impossible';
      });
      return;
    }

    String? articleImageUrl = _findArticleImageUrl(app, result.invoice?.articleId);
    if (articleImageUrl == null) {
      await app.refreshShop(silent: true);
      if (!mounted) return;
      articleImageUrl = _findArticleImageUrl(app, result.invoice?.articleId);
    }

    setState(() {
      _loading = false;
      _amount = result.invoice?.amount;
      _content = result.invoice?.content;
      _articleImageUrl = articleImageUrl;
      _date = result.invoice?.createdAt;
    });
    _cardController.forward(from: 0);
  }

  String? _findArticleImageUrl(AppProvider app, int? articleId) {
    if (articleId == null || articleId <= 0) return null;
    for (final item in app.shopItems) {
      if (item.articleId == articleId) return item.content;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.gB1BCFBTo393566),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = math.min(constraints.maxWidth - 10, 320.0);

              return Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: _LogoMark(),
                    ),
                  ),
                  if (_loading)
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF88CD7D)),
                          SizedBox(height: 10),
                          Text(
                            'Confirmation du paiement...',
                            style: TextStyle(color: AppColors.whiteColor),
                          ),
                        ],
                      ),
                    ),
                  if (!_loading && _error != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: _ErrorCard(
                            message: _error!,
                            onBack: () => context.go(AppRoutes.app),
                          ),
                        ),
                      ),
                    ),
                  if (!_loading && _error == null)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedBuilder(
                        animation: _cardOffset,
                        builder: (context, child) {
                          final translateY = (1 - _cardOffset.value) * 120;
                          return Transform.translate(
                            offset: Offset(0, translateY),
                            child: child,
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.zero,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: cardWidth),
                            child: _SuccessCard(
                              content: _content ?? 'Article',
                              articleImageUrl: _articleImageUrl,
                              amount: _amount,
                              date: _date,
                              onBack: () => context.go(AppRoutes.app),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (!_loading && _error == null)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _confettiController,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: _ConfettiPainter(
                                progress: _confettiController.value,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
