import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rentmuss/services/api_service.dart';

import 'package:rentmuss/screens/login.dart';
import 'package:rentmuss/screens/home.dart';
import 'package:rentmuss/screens/register.dart';
import 'package:rentmuss/screens/forgot_password.dart';
import 'package:rentmuss/services/api_service.dart';

class MockApiService extends Mock {}

void main() {
  setUp(() {
    when(
      () => ApiService.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => {'success': true});
  });

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
  }

  Finder usernameField() => find.byType(TextFormField).first;
  Finder passwordField() => find.byType(TextFormField).last;

  /// ---------- UI ----------
  testWidgets('1. Экран отображается', (tester) async {
    await pumpLogin(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('2. Заголовок RentMus отображается', (tester) async {
    await pumpLogin(tester);
    expect(find.text('RentMus'), findsOneWidget);
  });

  testWidgets('3. Поле username есть', (tester) async {
    await pumpLogin(tester);
    expect(usernameField(), findsOneWidget);
  });

  testWidgets('4. Поле password есть', (tester) async {
    await pumpLogin(tester);
    expect(passwordField(), findsOneWidget);
  });

  testWidgets('5. Кнопка входа отображается', (tester) async {
    await pumpLogin(tester);
    expect(find.text('Кіру'), findsOneWidget);
  });

  testWidgets('6. Кнопка активна по умолчанию', (tester) async {
    await pumpLogin(tester);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);
  });

  /// ---------- Validation ----------
  testWidgets('7. Пустой username → ошибка', (tester) async {
    await pumpLogin(tester);
    await tester.tap(find.text('Кіру'));
    await tester.pump();
    expect(find.text('Пайдаланушы атын енгізіңіз'), findsOneWidget);
  });

  testWidgets('8. Пустой password → ошибка', (tester) async {
    await pumpLogin(tester);
    await tester.enterText(usernameField(), 'user');
    await tester.tap(find.text('Кіру'));
    await tester.pump();
    expect(find.text('Құпия сөзді енгізіңіз'), findsOneWidget);
  });

  testWidgets('9. Оба поля пустые → две ошибки', (tester) async {
    await pumpLogin(tester);
    await tester.tap(find.text('Кіру'));
    await tester.pump();
    expect(find.text('Пайдаланушы атын енгізіңіз'), findsOneWidget);
    expect(find.text('Құпия сөзді енгізіңіз'), findsOneWidget);
  });

  testWidgets('10. Валидная форма проходит', (tester) async {
    await pumpLogin(tester);
    await tester.enterText(usernameField(), 'user');
    await tester.enterText(passwordField(), '1234');
    await tester.tap(find.text('Кіру'));
    await tester.pump();
    verify(
      () => ApiService.login(username: 'user', password: '1234'),
    ).called(1);
  });

  /// ---------- Loading ----------
  testWidgets('11. Loader показывается при запросе', (tester) async {
    when(
      () => ApiService.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      return {'success': true};
    });

    await pumpLogin(tester);
    await tester.enterText(usernameField(), 'user');
    await tester.enterText(passwordField(), '1234');
    await tester.tap(find.text('Кіру'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('12. Кнопка блокируется во время загрузки', (tester) async {
    await pumpLogin(tester);
    await tester.enterText(usernameField(), 'user');
    await tester.enterText(passwordField(), '1234');
    await tester.tap(find.text('Кіру'));
    await tester.pump();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('13. Повторный тап не вызывает API дважды', (tester) async {
    await pumpLogin(tester);
    await tester.enterText(usernameField(), 'user');
    await tester.enterText(passwordField(), '1234');
    await tester.tap(find.text('Кіру'));
    await tester.tap(find.text('Кіру'));
    await tester.pump();

    verify(
      () => ApiService.login(username: 'user', password: '1234'),
    ).called(1);
  });

  /// ---------- API ----------
  testWidgets('14. Username передаётся с trim()', (tester) async {
    await pumpLogin(tester);
    await tester.enterText(usernameField(), ' user ');
    await tester.enterText(passwordField(), '1234');
    await tester.tap(find.text('Кіру'));
    await tester.pump();

    verify(
      () => ApiService.login(username: 'user', password: '1234'),
    ).called(1);
  });

  testWidgets('15. Password передаётся без изменений', (tester) async {
    await pumpLogin(tester);
    await tester.enterText(usernameField(), 'user');
    await tester.enterText(passwordField(), ' pass ');
    await tester.tap(find.text('Кіру'));
    await tester.pump();

    verify(
      () => ApiService.login(username: 'user', password: ' pass '),
    ).called(1);
  });

  /// ---------- Success ----------
  testWidgets('16. Успешный логин → HomeScreen', (tester) async {
    await pumpLogin(tester);
    await tester.enterText(usernameField(), 'user');
    await tester.enterText(passwordField(), '1234');
    await tester.tap(find.text('Кіру'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('17. Используется pushReplacement', (tester) async {
    await pumpLogin(tester);
    await tester.enterText(usernameField(), 'user');
    await tester.enterText(passwordField(), '1234');
    await tester.tap(find.text('Кіру'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('18. SnackBar не показывается при success', (tester) async {
    await pumpLogin(tester);
    await tester.enterText(usernameField(), 'user');
    await tester.enterText(passwordField(), '1234');
    await tester.tap(find.text('Кіру'));
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
  });

  /// ---------- Error ----------
  testWidgets('19. Ошибка логина → SnackBar', (tester) async {
    when(
      () => ApiService.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => {'success': false, 'message': 'Ошибка'});

    await pumpLogin(tester);
    await tester.enterText(usernameField(), 'user');
    await tester.enterText(passwordField(), '1234');
    await tester.tap(find.text('Кіру'));
    await tester.pump();

    expect(find.text('Ошибка'), findsOneWidget);
  });

  testWidgets('20. Навигация не выполняется при ошибке', (tester) async {
    await pumpLogin(tester);
    await tester.enterText(usernameField(), 'user');
    await tester.enterText(passwordField(), '1234');
    await tester.tap(find.text('Кіру'));
    await tester.pump();

    expect(find.byType(HomeScreen), findsNothing);
  });

  /// ---------- Password ----------
  testWidgets('21. Пароль скрыт по умолчанию', (tester) async {
    await pumpLogin(tester);
    final field = tester.widget<TextFormField>(passwordField());
    expect(field.obscureText, true);
  });

  testWidgets('22. Переключение видимости пароля', (tester) async {
    await pumpLogin(tester);
    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();

    final field = tester.widget<TextFormField>(passwordField());
    expect(field.obscureText, false);
  });

  /// ---------- Navigation ----------
  testWidgets('23. Переход ForgotPassword', (tester) async {
    await pumpLogin(tester);
    await tester.tap(find.text('Құпия сөзді ұмыттыңыз ба?'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
  });

  testWidgets('24. Переход Register', (tester) async {
    await pumpLogin(tester);
    await tester.tap(find.text('Дереу тіркел!'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  /// ---------- State ----------
  testWidgets('25. Loader исчезает после запроса', (tester) async {
    await pumpLogin(tester);
    await tester.enterText(usernameField(), 'user');
    await tester.enterText(passwordField(), '1234');
    await tester.tap(find.text('Кіру'));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('26. Повторный логин после ошибки возможен', (tester) async {
    when(
      () => ApiService.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => {'success': false, 'message': 'err'});

    await pumpLogin(tester);
    await tester.enterText(usernameField(), 'user');
    await tester.enterText(passwordField(), '1234');
    await tester.tap(find.text('Кіру'));
    await tester.pump();

    when(
      () => ApiService.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => {'success': true});

    await tester.tap(find.text('Кіру'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('27. Form существует', (tester) async {
    await pumpLogin(tester);
    expect(find.byType(Form), findsOneWidget);
  });

  testWidgets('28. SafeArea используется', (tester) async {
    await pumpLogin(tester);
    expect(find.byType(SafeArea), findsOneWidget);
  });

  testWidgets('29. SingleChildScrollView используется', (tester) async {
    await pumpLogin(tester);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('30. Dispose не вызывает ошибок', (tester) async {
    await pumpLogin(tester);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}

extension on TextFormField {
  get obscureText => null;
}
