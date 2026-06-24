import 'package:flutter/foundation.dart';

import '../models/inventory_item_model.dart';
import '../models/invoice_model.dart';
import '../models/payment_confirmation_model.dart';
import '../models/shop_item_model.dart';
import 'app_providers.dart';

/// Domain provider for shop, inventory, billing and payments.
class CommerceProvider extends ChangeNotifier {
  CommerceProvider(this._app) {
    _listener = notifyListeners;
    _app.commerceListenable.addListener(_listener);
  }

  final AppProvider _app;
  late final VoidCallback _listener;

  List<ShopItemModel> get shopItems => _app.shopItems;
  List<InventoryItemModel> get inventoryItems => _app.inventoryItems;
  List<InvoiceModel> get invoices => _app.invoices;
  String? get errorMessage => _app.errorMessage;

  bool isArticleOwned(int articleId) => _app.isArticleOwned(articleId);

  InventoryItemModel? inventoryByArticleId(int articleId) {
    return _app.inventoryByArticleId(articleId);
  }

  Future<void> refreshShop({bool silent = false}) {
    return _app.refreshShop(silent: silent);
  }

  Future<void> refreshInventory({bool silent = false}) {
    return _app.refreshInventory(silent: silent);
  }

  Future<void> refreshInvoices({bool silent = false}) {
    return _app.refreshInvoices(silent: silent);
  }

  Future<void> activateInventoryItem(int itemId, bool active) {
    return _app.activateInventoryItem(itemId, active);
  }

  Future<String?> startCheckout(int articleId) => _app.startCheckout(articleId);

  Future<PaymentConfirmationModel?> confirmPayment(String sessionId) {
    return _app.confirmPayment(sessionId);
  }

  Future<String?> sendInvoiceByEmail(int invoiceId) {
    return _app.sendInvoiceByEmail(invoiceId);
  }

  @override
  void dispose() {
    _app.commerceListenable.removeListener(_listener);
    super.dispose();
  }
}
