import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/invoice_model.dart';
import '../providers/app_providers.dart';
import '../theme.dart';
import '../utils/app_date_format.dart';
import '../widgets/dialogs/anonym_confirm_dialog.dart';
import '../widgets/navigation/anonym_back_button.dart';


part '../widgets/invoices_screen_widgets.dart';

/// Écran d historique des factures et achats.
class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  static const int _pageSize = 10;
  int _page = 0;
  int? _expandedInvoiceId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().refreshInvoices(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.gB1BCFBTo393566),
        child: SafeArea(
          child: Consumer<AppProvider>(
            builder: (context, app, _) {
              final invoices = app.invoices;
              final totalPages = invoices.isEmpty
                  ? 1
                  : ((invoices.length - 1) ~/ _pageSize) + 1;
              if (_page >= totalPages) _page = totalPages - 1;

              final start = _page * _pageSize;
              final end = (start + _pageSize).clamp(0, invoices.length);
              final pageItems = invoices.sublist(start, end);

              return RefreshIndicator(
                color: AppColors.whiteColor,
                backgroundColor: AppColors.primary,
                onRefresh: () => app.refreshInvoices(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  children: [
                    Row(
                      children: [
                        const AnonymBackButton(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Facturation',
                            style: t.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Historique des transactions',
                      style: TextStyle(
                        color: AppColors.cFCFAFE,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.c393566.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.cFCFAFE.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        'Les modes de paiement sont chiffrés et conservés avec un service tiers de traitement sécurisé.',
                        style: TextStyle(
                          color: AppColors.cDBE7FE,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (invoices.isEmpty)
                      const _EmptyInvoiceCard()
                    else ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppGradients.gB1BCFBTo393566,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.cFCFAFE.withValues(alpha: 0.32),
                            ),
                          ),
                          child: Column(
                            children: [
                              const _InvoicesTableHeader(),
                              ...pageItems.asMap().entries.map(
                                (entry) => _InvoiceAccordionTile(
                                  invoice: entry.value,
                                  expanded:
                                      _expandedInvoiceId == entry.value.id,
                                  isLast: entry.key == pageItems.length - 1,
                                  onToggle: () {
                                    setState(() {
                                      _expandedInvoiceId =
                                          _expandedInvoiceId == entry.value.id
                                          ? null
                                          : entry.value.id;
                                    });
                                  },
                                  onSend: () => _sendInvoice(
                                    context,
                                    app,
                                    entry.value.id,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (invoices.length > _pageSize) ...[
                        const SizedBox(height: 14),
                        _PaginationBar(
                          page: _page,
                          totalPages: totalPages,
                          start: start,
                          end: end,
                          totalCount: invoices.length,
                          onPrev: _page > 0
                              ? () => setState(() => _page--)
                              : null,
                          onNext: _page < totalPages - 1
                              ? () => setState(() => _page++)
                              : null,
                        ),
                      ],
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _sendInvoice(
    BuildContext context,
    AppProvider app,
    int invoiceId,
  ) async {
    final result = await app.sendInvoiceByEmail(invoiceId);
    if (!context.mounted) return;

    if (result == null || result.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(app.errorMessage ?? 'Envoi impossible')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AnonymConfirmDialog(
        type: AnonymConfirmDialogType.success,
        title: 'Facture envoyée',
        description: 'La facture a bien été envoyée par email.',
        confirmLabel: 'Super',
        cancelLabel: 'Fermer',
        onConfirm: () => Navigator.of(dialogContext).pop(),
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }
}
