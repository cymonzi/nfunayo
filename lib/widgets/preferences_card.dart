import 'package:flutter/material.dart';

class PreferencesCard extends StatelessWidget {
  final bool notificationsEnabled;
  final String selectedCurrency;
  final String selectedLanguage;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<String?> onCurrencyChanged;
  final ValueChanged<String?> onLanguageChanged;

  const PreferencesCard({
    super.key,
    required this.notificationsEnabled,
    required this.selectedCurrency,
    required this.selectedLanguage,
    required this.onNotificationsChanged,
    required this.onCurrencyChanged,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           
            const Divider(thickness: 1, height: 20),
            _buildSectionHeader('Preferences'),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Currency',
                prefixIcon: const Icon(Icons.monetization_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              value: selectedCurrency,
              items: const ['USD', 'EUR', 'UGX'].map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onCurrencyChanged,
            ),
          
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}
