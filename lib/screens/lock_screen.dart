import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class LockScreen extends StatefulWidget {
  final Widget nextScreen;

  const LockScreen({super.key, required this.nextScreen});

  static const String PREFS_KEY_ENABLED = 'isLockEnabled';
  static const String PREFS_KEY_PIN_HASH = 'lockPinHash';
  static const String PREFS_KEY_HINT = 'lockPinHint';
  static const String PREFS_KEY_RECOVERY_CODE_HASH = 'lockRecoveryCodeHash';

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLockEnabled = false;
  String? _storedPinHash;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadLockState();
  }

  Future<void> _loadLockState() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(LockScreen.PREFS_KEY_ENABLED) ?? false;

    if (!mounted) return;

    setState(() {
      _isLockEnabled = isEnabled;
    });

    if (!isEnabled) {
      // Защита выключена — пропускаем
      _navigateToNext();
      return;
    }

    // Загружаем хэш PIN
    _storedPinHash = prefs.getString(LockScreen.PREFS_KEY_PIN_HASH);
  }

  void _verifyPin(String pin) {
    final pinHash = _hash(pin);
    if (_storedPinHash != null && pinHash == _storedPinHash) {
      _navigateToNext();
    } else {
      setState(() {
        _error = true;
      });
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _error = false;
          });
        }
      });
    }
  }

  String _hash(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _navigateToNext() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => widget.nextScreen),
    );
  }

  Future<void> _showRecoveryCodeDialog(BuildContext context) async {
    final recoveryCodeController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Резервное восстановление"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Введите резервный код из 6 символов:"),
            SizedBox(height: 12),
            TextField(
              controller: recoveryCodeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              decoration: InputDecoration(labelText: "Например: ABC123"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("Отмена")),
          TextButton(
            onPressed: () {
              final code = recoveryCodeController.text.trim().toUpperCase();
              if (code.length == 6) {
                Navigator.pop(ctx, true);
                _verifyRecoveryCode(code);
              }
            },
            child: Text("Проверить"),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyRecoveryCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(LockScreen.PREFS_KEY_RECOVERY_CODE_HASH);

    if (storedHash != null && _hash(code) == storedHash) {
      // Успешно — сбрасываем блокировку
      await prefs.remove(LockScreen.PREFS_KEY_PIN_HASH);
      await prefs.remove(LockScreen.PREFS_KEY_HINT);
      await prefs.remove(LockScreen.PREFS_KEY_RECOVERY_CODE_HASH);
      await prefs.setBool(LockScreen.PREFS_KEY_ENABLED, false);

      // Переходим дальше
      _navigateToNext();

      // Показываем уведомление
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("PIN сброшен. Блокировка отключена.")),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Неверный резервный код.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLockEnabled) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_storedPinHash == null) {
      _navigateToNext(); // На случай ошибки
      return Scaffold(
        body: Center(child: Text("Ошибка загрузки...")),
      );
    }

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final textColor = isDarkMode ? Colors.white : Colors.black;
    final hintColor = isDarkMode ? Colors.grey[400] : Colors.grey;
    final fieldFillColor = isDarkMode ? Colors.grey[800] : Colors.white;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: theme.primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Блокировка приложения',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Введите 4-значный PIN',
                style: theme.textTheme.bodyMedium?.copyWith(color: hintColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Поле PIN — точно как в SignInScreen
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.2),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  onChanged: (value) {
                    if (value.length == 4) {
                      _verifyPin(value);
                    }
                  },
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock, color: theme.primaryColor),
                    labelText: 'PIN-код',
                    labelStyle: GoogleFonts.poppins(color: hintColor),
                    filled: true,
                    fillColor: fieldFillColor,
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
                    ),
                    errorText: _error ? 'Неверный PIN' : null,
                    errorStyle: const TextStyle(color: Colors.red),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: textColor,
                    letterSpacing: 4,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              TextButton(
                onPressed: () => _showRecoveryCodeDialog(context),
                child: Text(
                  'Забыли PIN? Используйте резервный код',
                  style: GoogleFonts.poppins(color: theme.primaryColor),
                ),
              ),
              /*
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove(LockScreen.PREFS_KEY_PIN_HASH);
                  await prefs.remove(LockScreen.PREFS_KEY_HINT);
                  await prefs.remove(LockScreen.PREFS_KEY_RECOVERY_CODE_HASH);
                  await prefs.setBool(LockScreen.PREFS_KEY_ENABLED, false);

                  // Перейти на следующий экран
                  _navigateToNext();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('🔓 PIN сброшен (тест)')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: Text("🔧 Сбросить PIN (для теста)"),
              ),
              */
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}