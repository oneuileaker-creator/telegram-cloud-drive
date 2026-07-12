
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

const _colors = [
  '#4ECDC4', '#FF6B6B', '#45B7D1', '#96CEB4',
  '#A29BFE', '#FFEAA7', '#FD79A8', '#6C63FF',
  '#00D2FF', '#00C896', '#FFB347', '#B2BEC3',
];

class CreateFolderSheet extends StatefulWidget {
  final void Function(String name, String color) onCreated;

  const CreateFolderSheet({super.key, required this.onCreated});

  @override
  State<CreateFolderSheet> createState() => _CreateFolderSheetState();
}

class _CreateFolderSheetState extends State<CreateFolderSheet> {
  final _ctrl = TextEditingController();
  String _selectedColor = _colors[0];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text('New Folder', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 20),

              // Name input
              TextField(
                controller: _ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Folder name',
                  prefixIcon: Icon(Icons.folder_rounded),
                ),
              ),
              const SizedBox(height: 20),

              // Color picker
              Text('Color', style: AppTextStyles.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colors.map((hex) {
                  final color = _hexColor(hex);
                  final selected = _selectedColor == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: selected
                          ? [BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 8, spreadRadius: 2,
                            )]
                          : [],
                      ),
                      child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Create button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_ctrl.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    widget.onCreated(
                      _ctrl.text.trim(),
                      _selectedColor,
                    );
                  },
                  child: const Text('Create Folder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _hexColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }
}
