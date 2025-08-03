import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../utils/currency_utils.dart';
import '../utils/error_handler.dart';

class AddTransactionForm extends StatefulWidget {
  final Transaction? initialTransaction;
  final void Function(Transaction) onSubmit;
  final List<String> categories;

  const AddTransactionForm({
    super.key,
    this.initialTransaction,
    required this.onSubmit,
    required this.categories,
  });

  @override
  // ignore: library_private_types_in_public_api
  _AddTransactionFormState createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _dateController;
  String _category = '';
  DateTime _selectedDate = DateTime.now();
  bool _isIncome = true; // Track whether the transaction is income or expense
  String _selectedCurrency = 'USD';
  String _suggestedCategory = '';
  bool _isAutoCategory = true;
  bool _showCategoryPreview = false;

  @override
  void initState() {
    super.initState();
    _isIncome = widget.initialTransaction?.type == 'Income' ||
        widget.initialTransaction == null;
    _category = widget.initialTransaction?.category ??
        (widget.categories.isNotEmpty ? widget.categories.first : '');
    _amountController = TextEditingController(
      text: widget.initialTransaction?.amount.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialTransaction?.description ?? '',
    );
    _dateController = TextEditingController(
      text: widget.initialTransaction != null
          ? DateFormat.yMd().format(widget.initialTransaction!.date)
          : DateFormat.yMd().format(DateTime.now()),
    );
    _selectedDate = widget.initialTransaction?.date ?? DateTime.now();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    if (widget.initialTransaction != null) {
      // Use the transaction's existing currency when editing
      setState(() {
        _selectedCurrency = widget.initialTransaction!.currency;
      });
    } else {
      // Load default currency from preferences for new transactions
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _selectedCurrency = prefs.getString('selectedCurrency') ?? 'USD';
      });
    }
  }

  void _onDescriptionChanged(String value) {
    if (_isAutoCategory && value.isNotEmpty) {
      final suggestion = Transaction.autoCategorize(value, isIncome: _isIncome);
      setState(() {
        _suggestedCategory = suggestion;
        _showCategoryPreview = true;
        if (_isAutoCategory) {
          _category = suggestion;
        }
      });
    } else {
      setState(() {
        _showCategoryPreview = false;
        _suggestedCategory = '';
      });
    }
  }

  void _toggleAutoCategory() {
    setState(() {
      _isAutoCategory = !_isAutoCategory;
      if (_isAutoCategory && _descriptionController.text.isNotEmpty) {
        _onDescriptionChanged(_descriptionController.text);
      } else {
        _showCategoryPreview = false;
        // Reset to first category when turning off auto
        final filteredCategories = _isIncome
            ? Transaction.incomeCategories
            : Transaction.expenseCategories;
        _category = filteredCategories.isNotEmpty ? filteredCategories.first : '';
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Final category determination
      String finalCategory = _category;
      if (_isAutoCategory && _descriptionController.text.isNotEmpty) {
        finalCategory = Transaction.autoCategorize(
          _descriptionController.text,
          isIncome: _isIncome,
        );
      }

      final newTransaction = Transaction(
        id: widget.initialTransaction?.id ??
            DateTime.now().millisecondsSinceEpoch,
        date: _selectedDate,
        category: finalCategory,
        amount: double.parse(_amountController.text),
        type: _isIncome ? 'Income' : 'Expense',
        description: _descriptionController.text,
        currency: _selectedCurrency,
      );
      
      widget.onSubmit(newTransaction);
      
      // Show success feedback
      ErrorHandler.showSuccessSnackBar(
        context,
        'Transaction ${widget.initialTransaction != null ? 'updated' : 'added'} under $finalCategory'
      );
      
      Navigator.pop(context); // Close the modal after saving
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat.yMd().format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use static lists from the Transaction model
    final filteredCategories = _isIncome
        ? Transaction.incomeCategories
        : Transaction.expenseCategories;

    // Ensure _category is valid
    if (!filteredCategories.contains(_category) &&
        filteredCategories.isNotEmpty) {
      _category = filteredCategories.first;
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ChoiceChip(
                      label: const Text('Income'),
                      selected: _isIncome,
                      onSelected: (selected) {
                        setState(() {
                          _isIncome = true;
                          _category = filteredCategories.isNotEmpty
                              ? filteredCategories.first
                              : '';
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Expense'),
                      selected: !_isIncome,
                      onSelected: (selected) {
                        setState(() {
                          _isIncome = false;
                          _category = filteredCategories.isNotEmpty
                              ? filteredCategories.first
                              : '';
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Smart Category Selection with Auto mode
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Category',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _toggleAutoCategory,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isAutoCategory ? Colors.blue.shade50 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isAutoCategory ? Colors.blue.shade300 : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isAutoCategory ? Icons.auto_awesome : Icons.category,
                                  size: 14,
                                  color: _isAutoCategory ? Colors.blue.shade700 : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isAutoCategory ? 'Auto' : 'Manual',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _isAutoCategory ? Colors.blue.shade700 : Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!_isAutoCategory) ...[
                          const SizedBox(width: 8),
                          Tooltip(
                            message: "We'll categorize based on your description.",
                            child: Icon(
                              Icons.help_outline,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isAutoCategory && _showCategoryPreview)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 16, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Suggested: $_suggestedCategory',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _toggleAutoCategory,
                              child: Text(
                                'Change',
                                style: TextStyle(
                                  color: Colors.blue.shade600,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!_isAutoCategory)
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: filteredCategories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _category = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Enhanced Amount Field with Real-time Formatting
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: CurrencyUtils.getSymbol(_selectedCurrency),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    labelStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Enhanced Description Field with Smart Hints
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: Transaction.descriptionExample,
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    suffixIcon: _descriptionController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _descriptionController.clear();
                              _onDescriptionChanged('');
                            },
                          )
                        : null,
                  ),
                  onChanged: _onDescriptionChanged,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Enhanced Currency Field (Auto-detect but allow override)
                DropdownButtonFormField<String>(
                  value: _selectedCurrency,
                  decoration: InputDecoration(
                    labelText: 'Currency',
                    prefixIcon: const Icon(Icons.monetization_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  items: CurrencyUtils.availableCurrencies.map((currency) {
                    return DropdownMenuItem(
                      value: currency,
                      child: Text('$currency (${CurrencyUtils.getSymbol(currency)})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCurrency = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a currency';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Enhanced Date Field with Modern Calendar
                TextFormField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: 'Date',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    suffixIcon: _selectedDate.day == DateTime.now().day &&
                            _selectedDate.month == DateTime.now().month &&
                            _selectedDate.year == DateTime.now().year
                        ? Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Today',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : null,
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 24),
                // Enhanced Save Button with Animation
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save),
                        const SizedBox(width: 8),
                        Text(
                          widget.initialTransaction != null ? 'Update Transaction' : 'Save Transaction',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
