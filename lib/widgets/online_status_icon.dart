import 'dart:io';
import 'package:flutter/material.dart';

class OnlineStatusIcon extends StatefulWidget {
  const OnlineStatusIcon({super.key});

  @override
  State<OnlineStatusIcon> createState() => _OnlineStatusIconState();
}

class _OnlineStatusIconState extends State<OnlineStatusIcon> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkOnline();
    // Опционально: обновлять раз в 30 секунд
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      final online = await _lookup();
      if (mounted && _isOnline != online) {
        setState(() {
          _isOnline = online;
        });
      }
      return mounted;
    });
  }

  Future<bool> _lookup() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<void> _checkOnline() async {
    final online = await _lookup();
    if (mounted) {
      setState(() {
        _isOnline = online;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Icon(
      _isOnline ? Icons.wifi : Icons.wifi_off,
      color: _isOnline ? Colors.green : Colors.red,
      size: 20,
    );
  }
}