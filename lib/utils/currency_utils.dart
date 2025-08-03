class CurrencyUtils {
  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'UGX': 'UGX',
  };

  static const List<String> availableCurrencies = ['USD', 'EUR', 'UGX'];

  static String getSymbol(String currencyCode) {
    return currencySymbols[currencyCode] ?? currencyCode;
  }

  static String formatAmount(double amount, String currencyCode) {
    final symbol = getSymbol(currencyCode);
    if (currencyCode == 'UGX') {
      return '$symbol ${amount.toStringAsFixed(0)}';
    } else {
      return '$symbol${amount.toStringAsFixed(2)}';
    }
  }
}
