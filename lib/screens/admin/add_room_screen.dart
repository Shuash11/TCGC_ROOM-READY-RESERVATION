// lib/screens/admin/add_room_screen.dart
// ─────────────────────────────────────────────
// Admin creates a new room/facility.
// Fills in building, room name, capacity.
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaye/data/app_data.dart';
import 'package:kaye/theme/app_theme.dart';

class AddRoomScreen extends StatefulWidget {
  const AddRoomScreen({super.key});

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final _formKey          = GlobalKey<FormState>();
  final _nameController   = TextEditingController();
  final _capacityController = TextEditingController();

  String _selectedBuilding = 'Annex';
  bool   _isSubmitting     = false;

  final List<String> _buildings = ['Annex', 'Main', 'Tab'];

  // ── Submit ────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 500));

    AppData.addRoom(
      building: _selectedBuilding,
      name:     _nameController.text.trim(),
      capacity: int.parse(_capacityController.text.trim()),
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    // Show success snackbar then pop back
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Room "${_nameController.text.trim()}" added to $_selectedBuilding!',
        ),
        backgroundColor: AppColors.available,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.pop(context, true); // true = room was added
  }

  // ── Build ─────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Add Room / Facility',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha :0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha :0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.primary, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Rooms added here will be visible to students and available for reservation requests.',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Building selector
                const Text('Building',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                Row(
                  children: _buildings.map((b) {
                    final active = _selectedBuilding == b;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: b != _buildings.last ? 8 : 0),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedBuilding = b),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.primary
                                  : AppColors.surfaceDim,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: active
                                      ? AppColors.primary
                                      : AppColors.border),
                            ),
                            child: Text(
                              b,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: active
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Room name
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Room Name',
                    hintText: 'e.g. A-301, Lab 2, AVR',
                    prefixIcon:
                        Icon(Icons.meeting_room_outlined, size: 20),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter a room name'
                      : null,
                ),

                const SizedBox(height: 16),

                // Capacity
                TextFormField(
                  controller: _capacityController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Capacity',
                    hintText: 'e.g. 40',
                    prefixIcon: Icon(Icons.people_outline, size: 20),
                    suffixText: 'students',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter a capacity';
                    }
                    final n = int.tryParse(v.trim());
                    if (n == null || n <= 0) {
                      return 'Enter a valid number greater than 0';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Submit button
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.add, size: 20),
                  label: Text(
                      _isSubmitting ? 'Adding...' : 'Add Room'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }
}