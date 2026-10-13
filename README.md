# TrustPay app (Flutter)

Flutter version of the TrustPay mobile design: entry and onboarding, sign up,
login, Home, Services, transactions, cards, bills, airtime and data, add money,
bank transfer and POS (38 screens).

## Run it

This folder holds `lib/`, `assets/` and `pubspec.yaml`. Generate the Android and
iOS folders once, then run:

```bash
flutter create .          # adds android/, ios/, etc. (keeps lib/ and pubspec.yaml)
flutter pub get
flutter run
```

## Flow

`/` splash → `/intro` tagline → `/onboarding` (3 pages) → `/welcome` →
`/signup` → `/otp` → `/identity` → `/ready` → `/home`
(`/login` is reachable from Welcome, Sign up and Skip.)

Inside the app (`lib/screens/flows/`), each flow is opened from Home or Services:

| Flow | Screens | Opened from |
| --- | --- | --- |
| Transfer | send, check, authorize (keypad), complete | Home: Send money, Transfer. Services: Send money, Bank transfer |
| Add money | method, account details, money received | Home: Add money. Services: Add money |
| Bills (electricity) | provider, meter, confirm, success with token | Home: Pay bills. Services: Bill payments |
| Airtime & data | service and network, buy airtime, choose plan, success | Home: Airtime/data. Services: Airtime & data |
| Cards | your cards, create virtual card, card ready | Services: Virtual card, Physical card |
| Transactions | history (search and filters), receipt | Home: See all |
| POS | store terminal, settlement, request, review, submitted | POS tab |
| TV & internet bills | provider, number, package, confirm, success | Home: Pay bills. Services: Bill payments |
| Send to a TrustPay user | number, amount, confirm, success | Home: Send money. Services: Send money |
| Fund with a card | amount and card, confirm with bank code, success | Add money: Debit card |
| Fund virtual card | amount, confirm, success | Your card: Fund card |
| Physical card | delivery details, confirm, order placed | Cards: Physical card |
| Reset password | contact, code, new password, done | Login: Forgot password |
| Account | profile card, personal details, security & PIN, notifications | Account tab, menu |
| Help & support | FAQ search, live chat, call / email, send a message | Account tab, menu |
| Admin | dashboard, users, approvals | Account tab (staff), menu |

## Look and feel

- `lib/widgets/motion.dart` has the shared animations: `PressScale` (buttons shrink
  slightly when pressed), `FadeSlideIn` (staggered entrances), `CountUpText`
  (balance counts up) and `AnimatedCheck` (success tick).
- Every page change uses `TpPageTransitionsBuilder` (fade plus slide), set in
  `lib/theme/app_theme.dart` together with the brand gradients and shadows.
- Primary buttons are gradient with a soft glow and a light haptic tap.

## Project layout

- `lib/theme/app_theme.dart` colours and font (Inter via `google_fonts`)
- `lib/widgets/` shared pieces: buttons, fields, banners, header, step layout, OTP/PIN boxes
- `lib/screens/` one file per screen (Home and Services are tabs inside `home_shell.dart`)
- `assets/images/trustpay_logo.png` logo (transparent), `welcome_hero.jpg` welcome photo

## Things to know

- Colours, sizes and spacing were matched by eye from the exported screens.
  Check them against Figma Dev Mode and adjust `app_theme.dart` if needed.
- All data is sample data from the design. Look for the `TODO` comments for
  where to call your API (sign up, OTP, identity check, login, Face ID).
- The "Illustrative data · All amounts in NGN" lines come from the mockups.
  Set `kShowIllustrativeNote = false` in `lib/widgets/common.dart` to remove them.
- The POS tab hub (terminal card, next settlement, request button) was not in the
  exported screens. The POS hub only links the POS screens.
- Account, Help & support and the Admin console are new and not from Figma. Their
  data is sample data. The support phone and email in `sample_data.dart` are
  placeholders.
- The menu button on Home, Services, POS and Account opens the side menu (Home,
  Services, Account, Transactions, POS, Help & support, Admin console, Log out).
- `kIsAdmin` in `lib/data/sample_data.dart` shows the Admin console. Set it from
  your login response, and make your server check the staff role on every admin
  request. Hiding the menu item does not protect the data.
- TV, internet, physical card, card funding, send to a TrustPay user and password
  reset were added without Figma designs, so check them against your design. They
  share the confirm and success steps in `lib/screens/flows/generic_flow.dart`.
- Package prices, fees, customer lookups and bank codes are sample values. In the
  debit card flow, use your payment provider's secure card form for real payments.
- Balances after each payment are calculated from one sample balance
  (`kAccountBalance` in `lib/data/sample_data.dart`), so each flow starts from
  ₦248,500 as in the designs. Connect a real balance and update it after payments.
- The welcome photo was cropped from your screenshot, so it is low resolution.
  Replace `assets/images/welcome_hero.jpg` with the original image.
