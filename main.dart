// ============================================================
//  MedCare Reminder — Complete DartPad-Compatible Flutter App
//  Single-file, no external packages, runs fully in DartPad.
//  Background: SVG-style health illustration via CustomPainter
// ============================================================
import 'package:flutter/material.dart';
import 'dart:math' as math;
void main() => runApp(const MedCareApp());

// ─────────────────────────────────────────────
//  Root App
// ─────────────────────────────────────────────
class MedCareApp extends StatelessWidget {
  const MedCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedCare Reminder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1976D2),
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

// ─────────────────────────────────────────────
//  Medicine Type Enum
// ─────────────────────────────────────────────
enum MedicineType { tablet, syrup, injection }

extension MedicineTypeExtension on MedicineType {
  String get label {
    switch (this) {
      case MedicineType.tablet:    return 'Tablet';
      case MedicineType.syrup:     return 'Syrup';
      case MedicineType.injection: return 'Injection';
    }
  }

  IconData get icon {
    switch (this) {
      case MedicineType.tablet:    return Icons.medication_rounded;
      case MedicineType.syrup:     return Icons.local_drink_rounded;
      case MedicineType.injection: return Icons.colorize_rounded;
    }
  }

  Color get color {
    switch (this) {
      case MedicineType.tablet:    return const Color(0xFF1976D2); // Blue
      case MedicineType.syrup:     return const Color(0xFF388E3C); // Green
      case MedicineType.injection: return const Color(0xFFE53935); // Red
    }
  }
}

// ─────────────────────────────────────────────
//  Medicine Model
// ─────────────────────────────────────────────
class Medicine {
  final String id;
  final String name;
  final MedicineType type;
  final TimeOfDay time;
  final String dosage;
  bool isTaken;

  Medicine({
    required this.id,
    required this.name,
    required this.type,
    required this.time,
    required this.dosage,
    this.isTaken = false,
  });

  // Format time to readable AM/PM string
  String get formattedTime {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

// ─────────────────────────────────────────────
//  Home Screen (StatefulWidget — state manager)
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Dynamic list — no hardcoded data
  final List<Medicine> _medicines = [];

  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  // ── Open Add Medicine bottom sheet ──────────
  void _openAddMedicineSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMedicineSheet(
        onAdd: (medicine) {
          setState(() => _medicines.add(medicine));
          _showSnackbar('✅ ${medicine.name} reminder added!', Colors.green);
        },
      ),
    );
  }

  // ── Mark medicine as taken ───────────────────
  void _markAsTaken(String id) {
    setState(() {
      final med = _medicines.firstWhere((m) => m.id == id);
      med.isTaken = !med.isTaken;
      _showSnackbar(
        med.isTaken ? '💊 ${med.name} marked as Taken!' : '🔔 ${med.name} marked as Pending.',
        med.isTaken ? Colors.teal : Colors.orange,
      );
    });
  }

  // ── Confirm & delete medicine ────────────────
  void _confirmDelete(Medicine med) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Reminder'),
        content: Text('Remove "${med.name}" from your reminders?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _medicines.removeWhere((m) => m.id == med.id));
              _showSnackbar('🗑️ ${med.name} removed.', Colors.red);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Show snackbar helper ─────────────────────
  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Counts for summary ───────────────────────
  int get _takenCount => _medicines.where((m) => m.isTaken).length;
  int get _pendingCount => _medicines.where((m) => !m.isTaken).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5), Color(0xFFE3F2FD)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── App Header ──────────────────────
              _buildHeader(),
              // ── Summary chips ───────────────────
              if (_medicines.isNotEmpty) _buildSummaryRow(),
              // ── Medicine list or empty state ─────
              Expanded(
                child: _medicines.isEmpty
                    ? const EmptyStateWidget()
                    : _buildMedicineList(),
              ),
            ],
          ),
        ),
      ),
      // FAB to add medicine
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddMedicineSheet,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 26),
        label: const Text(
          'Add Medicine',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        elevation: 6,
      ),
    );
  }

  // ── Header widget ────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.health_and_safety_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MedCare Reminder',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Stay on track with your doses',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Summary row (Taken / Pending chips) ──────
  Widget _buildSummaryRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _SummaryChip(
            label: '$_takenCount Taken',
            color: Colors.teal,
            icon: Icons.check_circle_rounded,
          ),
          const SizedBox(width: 10),
          _SummaryChip(
            label: '$_pendingCount Pending',
            color: Colors.orange,
            icon: Icons.access_time_rounded,
          ),
          const Spacer(),
          Text(
            '${_medicines.length} total',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Scrollable medicine list ──────────────────
  Widget _buildMedicineList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: _medicines.length,
      itemBuilder: (context, index) {
        final med = _medicines[index];
        return MedicineCard(
          medicine: med,
          onTaken: () => _markAsTaken(med.id),
          onDelete: () => _confirmDelete(med),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  Summary Chip Widget
// ─────────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _SummaryChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Medicine Card Widget
// ─────────────────────────────────────────────
class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onTaken;
  final VoidCallback onDelete;

  const MedicineCard({
    super.key,
    required this.medicine,
    required this.onTaken,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = medicine.type.color;
    // Card turns green-tinted when taken
    final cardColor = medicine.isTaken
        ? const Color(0xFFE8F5E9)
        : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: medicine.isTaken
              ? Colors.teal.withOpacity(0.4)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: icon + name + delete ───
            Row(
              children: [
                // Medicine type icon badge
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(medicine.type.icon, color: typeColor, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: medicine.isTaken
                              ? Colors.grey.shade600
                              : Colors.grey.shade900,
                          decoration: medicine.isTaken
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              medicine.type.label,
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Delete button
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: Colors.red.shade300,
                  tooltip: 'Delete',
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // ── Bottom row: time + dosage + status ─
            Row(
              children: [
                // Time
                _InfoBadge(
                  icon: Icons.access_time_rounded,
                  label: medicine.formattedTime,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 10),
                // Dosage
                _InfoBadge(
                  icon: Icons.medical_information_outlined,
                  label: medicine.dosage,
                  color: Colors.purple.shade600,
                ),
                const Spacer(),
                // Taken / Pending toggle button
                GestureDetector(
                  onTap: onTaken,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: medicine.isTaken
                          ? Colors.teal
                          : Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (medicine.isTaken ? Colors.teal : Colors.blue)
                              .withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          medicine.isTaken
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          medicine.isTaken ? 'Taken' : 'Pending',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Small info badge (time / dosage)
// ─────────────────────────────────────────────
class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Empty State Widget
// ─────────────────────────────────────────────
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medication_outlined,
              size: 70,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Reminders Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tap the button below to add\nyour first medicine reminder.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          // Animated arrow hint
          const Icon(
            Icons.arrow_downward_rounded,
            color: Colors.white70,
            size: 28,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Add Medicine Bottom Sheet
// ─────────────────────────────────────────────
class AddMedicineSheet extends StatefulWidget {
  final void Function(Medicine) onAdd;

  const AddMedicineSheet({super.key, required this.onAdd});

  @override
  State<AddMedicineSheet> createState() => _AddMedicineSheetState();
}

class _AddMedicineSheetState extends State<AddMedicineSheet> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  final _nameController    = TextEditingController();
  final _dosageController  = TextEditingController();

  MedicineType _selectedType = MedicineType.tablet;
  TimeOfDay _selectedTime    = TimeOfDay.now();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  // ── Open Flutter time picker ─────────────────
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'Select Reminder Time',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // ── Format the currently selected time ───────
  String get _timeLabel {
    final hour = _selectedTime.hourOfPeriod == 0
        ? 12
        : _selectedTime.hourOfPeriod;
    final min  = _selectedTime.minute.toString().padLeft(2, '0');
    final ampm = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $ampm';
  }

  // ── Validate and save ─────────────────────────
  void _save() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // Create new Medicine object with unique ID
    final medicine = Medicine(
      id:     DateTime.now().millisecondsSinceEpoch.toString(),
      name:   _nameController.text.trim(),
      type:   _selectedType,
      time:   _selectedTime,
      dosage: _dosageController.text.trim(),
    );

    widget.onAdd(medicine);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ──────────────────
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // ── Sheet title ──────────────────
              const Text(
                'Add Medicine',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Fill in the details for your reminder',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // ── Medicine Name field ───────────
              _buildLabel('Medicine Name'),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(
                  hint: 'e.g. Paracetamol 500mg',
                  icon: Icons.medication_rounded,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter medicine name' : null,
              ),
              const SizedBox(height: 18),

              // ── Medicine Type selector ────────
              _buildLabel('Medicine Type'),
              Row(
                children: MedicineType.values.map((type) {
                  final selected = _selectedType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? type.color
                              : type.color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? type.color
                                : type.color.withOpacity(0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              type.icon,
                              color: selected ? Colors.white : type.color,
                              size: 24,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              type.label,
                              style: TextStyle(
                                color: selected ? Colors.white : type.color,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // ── Time Picker ───────────────────
              _buildLabel('Reminder Time'),
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Text(
                        _timeLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Change',
                        style: TextStyle(
                          color: Colors.blue.shade400,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ── Dosage field ──────────────────
              _buildLabel('Dosage Details'),
              TextFormField(
                controller: _dosageController,
                decoration: _inputDecoration(
                  hint: 'e.g. 1 tablet after meals',
                  icon: Icons.medical_information_outlined,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter dosage details' : null,
              ),
              const SizedBox(height: 28),

              // ── Save Button ───────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFF1565C0).withOpacity(0.4),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_alarm_rounded, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Save Reminder',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Label helper ─────────────────────────────
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ── Input decoration helper ───────────────────
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.blue.shade700),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: Color(0xFF1565C0), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}
