import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/invoice_model.dart';
import '../providers/app_controller.dart';
import '../theme.dart';
import '../utils/app_date_format.dart';
import '../widgets/chrome/moji_back_button.dart';

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
      context.read<AppController>().refreshInvoices(silent: true);
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
          child: Consumer<AppController>(
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
                onRefresh: () => app.refreshInvoices(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  children: [
                    Row(
                      children: [
                        const MojiBackButton(),
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
    AppController app,
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

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
  }
}

class _InvoiceAccordionTile extends StatelessWidget {
  const _InvoiceAccordionTile({
    required this.invoice,
    required this.expanded,
    required this.isLast,
    required this.onToggle,
    required this.onSend,
  });

  final InvoiceModel invoice;
  final bool expanded;
  final bool isLast;
  final VoidCallback onToggle;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final date = invoice.createdAt != null
        ? AppDateFormat.shortDate(invoice.createdAt)
        : 'N/A';
    final title = invoice.content.isEmpty ? 'Achat' : invoice.content;
    final amount = _formatEuro(invoice.amount);

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          top: BorderSide(color: AppColors.cFCFAFE.withValues(alpha: 0.2)),
          bottom: isLast && !expanded
              ? BorderSide.none
              : BorderSide(color: AppColors.cFCFAFE.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      date,
                      style: const TextStyle(
                        color: AppColors.cFCFAFE,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.cFCFAFE,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(
                      amount,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.cFCFAFE,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 24,
                    child: Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.cFCFAFE,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Divider(
              height: 1,
              color: AppColors.cFCFAFE.withValues(alpha: 0.18),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Détails de l\'achat',
                    style: TextStyle(
                      color: AppColors.cFCFAFE,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DetailLine(
                    label: 'Moyen de paiement',
                    value: invoice.type.isEmpty ? 'N/A' : invoice.type,
                  ),
                  const SizedBox(height: 8),
                  _DetailLine(label: 'ID de paiement', value: '#${invoice.id}'),
                  const SizedBox(height: 8),
                  _DetailLine(label: 'Quantité', value: '${invoice.quantity}'),
                  const SizedBox(height: 8),
                  _DetailLine(label: 'Total', value: amount),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: onSend,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Envoi par email',
                        style: TextStyle(
                          color: AppColors.cDBE7FE,
                          fontSize: 15,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.cDBE7FE,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InvoicesTableHeader extends StatelessWidget {
  const _InvoicesTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: AppGradients.gB1BCFBTo393566,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.22)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Date',
              style: TextStyle(
                color: AppColors.whiteColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              'Description',
              style: TextStyle(
                color: AppColors.whiteColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: Text(
              'Montant',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.whiteColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 4),
          SizedBox(width: 24),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.cDBE7FE, fontSize: 14),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.cFCFAFE,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.start,
    required this.end,
    required this.totalCount,
    required this.onPrev,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final int start;
  final int end;
  final int totalCount;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final visibleStart = totalCount == 0 ? 0 : start + 1;
    return Row(
      children: [
        _PageButton(icon: Icons.chevron_left_rounded, onTap: onPrev),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$visibleStart-$end sur $totalCount • Page ${page + 1}/$totalPages',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.cFCFAFE,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _PageButton(icon: Icons.chevron_right_rounded, onTap: onNext),
      ],
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.whiteColor.withValues(
            alpha: onTap == null ? 0.1 : 0.2,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.28)),
        ),
        child: Icon(
          icon,
          color: AppColors.cFCFAFE.withValues(alpha: onTap == null ? 0.5 : 1),
        ),
      ),
    );
  }
}

class _EmptyInvoiceCard extends StatelessWidget {
  const _EmptyInvoiceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.gB1BCFBTo393566,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.35)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.request_quote_outlined,
            color: AppColors.cFCFAFE,
            size: 28,
          ),
          SizedBox(height: 10),
          Text(
            'Aucune facture.',
            style: TextStyle(
              color: AppColors.cFCFAFE,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tes achats apparaîtront ici.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.cDBE7FE, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

String _formatEuro(int amount) {
  return '$amount €';
}
