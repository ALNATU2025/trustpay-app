import 'package:flutter/material.dart';

import 'merchant_pay_screens.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/app_state.dart';
import '../../services/trustpay_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/debounce.dart';
import '../../utils/format.dart';
import '../../utils/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/menu_widgets.dart';
import '../../widgets/step_scaffold.dart';
import 'generic_flow.dart';
import 'mobile_money_screens.dart';
import 'transfer_screens.dart';

/// Bottom sheet that asks where the money is going.
void showSendOptions(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 6, bottom: 12),
              child: Text('Send money', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ),
            MenuTile(
              icon: Icons.phone_android_outlined,
              title: 'To mobile money',
              subtitle: appState.cat.mobileMoney.join(', '),
              onTap: () {
                Navigator.pop(sheetContext);
                openScreen(context, const MobileMoneyScreen(send: true));
              },
            ),
            MenuTile(
              icon: Icons.storefront_outlined,
              title: 'To a merchant',
              subtitle: 'Scan a QR code or enter a merchant code',
              onTap: () {
                Navigator.pop(sheetContext);
                openScreen(context, const PayMerchantScreen());
              },
            ),
            MenuTile(
              icon: Icons.account_balance_outlined,
              title: 'To a bank account',
              subtitle: 'Any Sierra Leone bank',
              onTap: () {
                Navigator.pop(sheetContext);
                openScreen(context, const SendBankScreen());
              },
            ),
          ],
        ),
      ),
    ),
  );
}
