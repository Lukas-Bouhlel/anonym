import 'invoice_model.dart';

class PaymentConfirmationModel {
  const PaymentConfirmationModel({required this.message, this.invoice});

  final String message;
  final InvoiceModel? invoice;

  factory PaymentConfirmationModel.fromJson(Map<String, dynamic> json) {
    final invoiceJson = json['invoice'];

    return PaymentConfirmationModel(
      message: (json['message'] ?? '').toString(),
      invoice: invoiceJson is Map<String, dynamic>
          ? InvoiceModel.fromJson(invoiceJson)
          : null,
    );
  }
}
