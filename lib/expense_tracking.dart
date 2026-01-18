import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ExpenseTrackingPage extends StatefulWidget {
  const ExpenseTrackingPage({super.key});

  @override
  State<ExpenseTrackingPage> createState() => _ExpenseTrackingPageState();
}

class _ExpenseTrackingPageState extends State<ExpenseTrackingPage> {
  final _supabase = Supabase.instance.client;

  // Controllers
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  // State
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isSaving = false;
  double _monthlyBudget = 1000.0;

  Stream<List<Map<String, dynamic>>> get _expenseStream => _supabase
      .from('pet_expenses')
      .stream(primaryKey: ['id'])
      .order('expense_date', ascending: false);

  bool _isSameMonth(String dateStr) {
    DateTime date = DateTime.parse(dateStr);
    return date.year == _focusedMonth.year && date.month == _focusedMonth.month;
  }

  // --- DELETE RECORD ---
  Future<void> _deleteExpense(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Record?"),
        content: const Text("Are you sure you want to remove this expense?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _supabase.from('pet_expenses').delete().eq('id', id);
    }
  }

  // --- SAVE / UPDATE RECORD ---
  Future<void> _saveExpense({int? id}) async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) return;

    setState(() => _isSaving = true);
    final data = {
      'title': _titleController.text.trim(),
      'amount': double.tryParse(_amountController.text) ?? 0.0,
      'category': _selectedCategory,
      'expense_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
    };

    try {
      if (id == null) {
        await _supabase.from('pet_expenses').insert(data);
      } else {
        await _supabase.from('pet_expenses').update(data).eq('id', id);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- FORM SHEET (FOR ADD & EDIT) ---
  void _showExpenseSheet({Map<String, dynamic>? existingData}) {
    if (existingData != null) {
      _titleController.text = existingData['title'];
      _amountController.text = existingData['amount'].toString();
      _selectedCategory = existingData['category'];
      _selectedDate = DateTime.parse(existingData['expense_date']);
    } else {
      _titleController.clear();
      _amountController.clear();
      _selectedCategory = 'Food';
      _selectedDate = DateTime.now();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(existingData == null ? "Add Expense" : "Edit Expense", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Expense Title")),
              TextField(controller: _amountController, decoration: const InputDecoration(labelText: "Amount (RM)"), keyboardType: TextInputType.number),
              DropdownButtonFormField(
                value: _selectedCategory,
                items: ['Food', 'Medical', 'Grooming', 'Toys', 'Others'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setModalState(() => _selectedCategory = val!),
                decoration: const InputDecoration(labelText: "Category"),
              ),
              const SizedBox(height: 20),
              _isSaving ? const CircularProgressIndicator() : ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                onPressed: () => _saveExpense(id: existingData?['id']),
                child: Text(existingData == null ? "Save Expense" : "Update Expense"),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(DateFormat('MMMM yyyy').format(_focusedMonth)),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.settings), onPressed: _showBudgetSettings)],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _expenseStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final expenses = snapshot.data!.where((e) => _isSameMonth(e['expense_date'])).toList();
          double totalSpent = expenses.fold(0.0, (sum, item) => sum + (item['amount'] ?? 0.0));

          return SingleChildScrollView(
            child: Column(
              children: [
                if (expenses.isNotEmpty) _buildPieChart(expenses),
                _buildBudgetCard(totalSpent),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Align(alignment: Alignment.centerLeft, child: Text("Transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final item = expenses[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: ListTile(
                        leading: Icon(_getIcon(item['category']), color: _getColor(item['category'])),
                        title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(item['expense_date']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("RM ${item['amount']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            // EDIT ICON
                            IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20), onPressed: () => _showExpenseSheet(existingData: item)),
                            // DELETE ICON
                            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _deleteExpense(item['id'])),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showExpenseSheet(),
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // --- HELPERS (STYLING) ---
  Color _getColor(String cat) {
    switch (cat) {
      case 'Food': return Colors.blue;
      case 'Medical': return Colors.red;
      case 'Grooming': return Colors.purple;
      case 'Toys': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getIcon(String cat) {
    switch (cat) {
      case 'Food': return Icons.restaurant;
      case 'Medical': return Icons.medical_services;
      case 'Grooming': return Icons.content_cut;
      case 'Toys': return Icons.toys;
      default: return Icons.payments;
    }
  }

  // --- BUDGET & CHART WIDGETS ---
  Widget _buildPieChart(List<Map<String, dynamic>> expenses) {
    Map<String, double> dataMap = {};
    for (var item in expenses) {
      String cat = item['category'] ?? 'Others';
      dataMap[cat] = (dataMap[cat] ?? 0) + (item['amount'] ?? 0);
    }
    return Container(height: 200, padding: const EdgeInsets.all(20), child: PieChart(PieChartData(centerSpaceRadius: 40, sections: dataMap.entries.map((e) => PieChartSectionData(color: _getColor(e.key), value: e.value, title: '${(e.value / dataMap.values.fold(0, (a, b) => a + b) * 100).toInt()}%', radius: 50, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))).toList())));
  }

  Widget _buildBudgetCard(double totalSpent) {
    double progress = (totalSpent / _monthlyBudget).clamp(0.0, 1.0);
    return Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Spent vs Budget", style: TextStyle(color: Colors.grey)), Text("RM ${totalSpent.toStringAsFixed(2)} / RM ${_monthlyBudget.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold))]), const SizedBox(height: 12), LinearProgressIndicator(value: progress, minHeight: 10, borderRadius: BorderRadius.circular(10), color: totalSpent > _monthlyBudget ? Colors.red : Colors.green, backgroundColor: Colors.grey[200])]));
  }

  void _showBudgetSettings() {
    final controller = TextEditingController(text: _monthlyBudget.toString());
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text("Settings"), content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Monthly Budget")), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")), ElevatedButton(onPressed: () { setState(() => _monthlyBudget = double.tryParse(controller.text) ?? 1000.0); Navigator.pop(context); }, child: const Text("Update"))]));
  }
}