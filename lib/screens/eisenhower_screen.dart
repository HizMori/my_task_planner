import 'package:flutter/material.dart';

class EisenhowerScreen extends StatelessWidget {
  const EisenhowerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Матрица Эйзенхауэра')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  // Квадрант 1: Важно и срочно
                  Expanded(
                    child: _buildQuadrant(
                      context,
                      title: 'Важно и срочно',
                      color: const Color(0xFFFF3B30), // Красный
                      tasks: ['Задача 1', 'Задача 2'],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Квадрант 2: Важно, но не срочно
                  Expanded(
                    child: _buildQuadrant(
                      context,
                      title: 'Важно, но не срочно',
                      color: const Color(0xFFFFCC00), // Жёлтый
                      tasks: ['Планирование', 'Обучение'],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  // Квадрант 3: Не важно, но срочно
                  Expanded(
                    child: _buildQuadrant(
                      context,
                      title: 'Не важно, но срочно',
                      color: const Color(0xFF007AFF), // Синий
                      tasks: ['Звонки', 'Письма'],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Квадрант 4: Не важно и не срочно
                  Expanded(
                    child: _buildQuadrant(
                      context,
                      title: 'Не важно и не срочно',
                      color: const Color(0xFF34C759), // Зелёный
                      tasks: ['Социальные сети', 'Игры'],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Метод для создания квадранта
  Widget _buildQuadrant(
    BuildContext context, {
    required String title,
    required Color color,
    required List<String> tasks,
  }) {
    return Container(
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: false,
                        onChanged: (value) {}, // Заглушка для чекбокса
                      ),
                      Text(
                        tasks[index],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
