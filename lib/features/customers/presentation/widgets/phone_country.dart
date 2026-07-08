class PhoneCountry {
  final String name;
  final String iso2;
  final String dialCode; // without '+'
  final String flag;
  final int minLength;
  final int maxLength;
  final List<int> groups; // local digit group sizes for display

  const PhoneCountry({
    required this.name,
    required this.iso2,
    required this.dialCode,
    required this.flag,
    required this.minLength,
    required this.maxLength,
    required this.groups,
  });

  String get dialCodeLabel => '+$dialCode';

  static const us = PhoneCountry(
    name: 'United States',
    iso2: 'US',
    dialCode: '1',
    flag: '🇺🇸',
    minLength: 10,
    maxLength: 10,
    groups: [3, 3, 4],
  );

  static const List<PhoneCountry> all = [
    us,
    PhoneCountry(
      name: 'Canada',
      iso2: 'CA',
      dialCode: '1',
      flag: '🇨🇦',
      minLength: 10,
      maxLength: 10,
      groups: [3, 3, 4],
    ),
    PhoneCountry(
      name: 'United Kingdom',
      iso2: 'GB',
      dialCode: '44',
      flag: '🇬🇧',
      minLength: 10,
      maxLength: 10,
      groups: [4, 3, 3],
    ),
    PhoneCountry(
      name: 'Ethiopia',
      iso2: 'ET',
      dialCode: '251',
      flag: '🇪🇹',
      minLength: 9,
      maxLength: 9,
      groups: [2, 3, 4],
    ),
    PhoneCountry(
      name: 'United Arab Emirates',
      iso2: 'AE',
      dialCode: '971',
      flag: '🇦🇪',
      minLength: 9,
      maxLength: 9,
      groups: [2, 3, 4],
    ),
    PhoneCountry(
      name: 'Saudi Arabia',
      iso2: 'SA',
      dialCode: '966',
      flag: '🇸🇦',
      minLength: 9,
      maxLength: 9,
      groups: [2, 3, 4],
    ),
    PhoneCountry(
      name: 'Germany',
      iso2: 'DE',
      dialCode: '49',
      flag: '🇩🇪',
      minLength: 10,
      maxLength: 11,
      groups: [3, 3, 4],
    ),
    PhoneCountry(
      name: 'France',
      iso2: 'FR',
      dialCode: '33',
      flag: '🇫🇷',
      minLength: 9,
      maxLength: 9,
      groups: [1, 2, 2, 2, 2],
    ),
    PhoneCountry(
      name: 'Italy',
      iso2: 'IT',
      dialCode: '39',
      flag: '🇮🇹',
      minLength: 9,
      maxLength: 10,
      groups: [3, 3, 4],
    ),
    PhoneCountry(
      name: 'Spain',
      iso2: 'ES',
      dialCode: '34',
      flag: '🇪🇸',
      minLength: 9,
      maxLength: 9,
      groups: [3, 3, 3],
    ),
    PhoneCountry(
      name: 'Australia',
      iso2: 'AU',
      dialCode: '61',
      flag: '🇦🇺',
      minLength: 9,
      maxLength: 9,
      groups: [3, 3, 3],
    ),
    PhoneCountry(
      name: 'India',
      iso2: 'IN',
      dialCode: '91',
      flag: '🇮🇳',
      minLength: 10,
      maxLength: 10,
      groups: [5, 5],
    ),
    PhoneCountry(
      name: 'Nigeria',
      iso2: 'NG',
      dialCode: '234',
      flag: '🇳🇬',
      minLength: 10,
      maxLength: 10,
      groups: [3, 3, 4],
    ),
    PhoneCountry(
      name: 'Kenya',
      iso2: 'KE',
      dialCode: '254',
      flag: '🇰🇪',
      minLength: 9,
      maxLength: 9,
      groups: [3, 3, 3],
    ),
    PhoneCountry(
      name: 'South Africa',
      iso2: 'ZA',
      dialCode: '27',
      flag: '🇿🇦',
      minLength: 9,
      maxLength: 9,
      groups: [2, 3, 4],
    ),
    PhoneCountry(
      name: 'Brazil',
      iso2: 'BR',
      dialCode: '55',
      flag: '🇧🇷',
      minLength: 10,
      maxLength: 11,
      groups: [2, 5, 4],
    ),
    PhoneCountry(
      name: 'Mexico',
      iso2: 'MX',
      dialCode: '52',
      flag: '🇲🇽',
      minLength: 10,
      maxLength: 10,
      groups: [3, 3, 4],
    ),
    PhoneCountry(
      name: 'Turkey',
      iso2: 'TR',
      dialCode: '90',
      flag: '🇹🇷',
      minLength: 10,
      maxLength: 10,
      groups: [3, 3, 4],
    ),
    PhoneCountry(
      name: 'Egypt',
      iso2: 'EG',
      dialCode: '20',
      flag: '🇪🇬',
      minLength: 10,
      maxLength: 10,
      groups: [3, 3, 4],
    ),
    PhoneCountry(
      name: 'Netherlands',
      iso2: 'NL',
      dialCode: '31',
      flag: '🇳🇱',
      minLength: 9,
      maxLength: 9,
      groups: [2, 3, 4],
    ),
    PhoneCountry(
      name: 'Sweden',
      iso2: 'SE',
      dialCode: '46',
      flag: '🇸🇪',
      minLength: 9,
      maxLength: 10,
      groups: [2, 3, 4],
    ),
    PhoneCountry(
      name: 'Norway',
      iso2: 'NO',
      dialCode: '47',
      flag: '🇳🇴',
      minLength: 8,
      maxLength: 8,
      groups: [3, 2, 3],
    ),
    PhoneCountry(
      name: 'Denmark',
      iso2: 'DK',
      dialCode: '45',
      flag: '🇩🇰',
      minLength: 8,
      maxLength: 8,
      groups: [2, 2, 2, 2],
    ),
    PhoneCountry(
      name: 'Switzerland',
      iso2: 'CH',
      dialCode: '41',
      flag: '🇨🇭',
      minLength: 9,
      maxLength: 9,
      groups: [2, 3, 4],
    ),
    PhoneCountry(
      name: 'Japan',
      iso2: 'JP',
      dialCode: '81',
      flag: '🇯🇵',
      minLength: 10,
      maxLength: 10,
      groups: [2, 4, 4],
    ),
    PhoneCountry(
      name: 'South Korea',
      iso2: 'KR',
      dialCode: '82',
      flag: '🇰🇷',
      minLength: 9,
      maxLength: 10,
      groups: [2, 4, 4],
    ),
    PhoneCountry(
      name: 'China',
      iso2: 'CN',
      dialCode: '86',
      flag: '🇨🇳',
      minLength: 11,
      maxLength: 11,
      groups: [3, 4, 4],
    ),
    PhoneCountry(
      name: 'Philippines',
      iso2: 'PH',
      dialCode: '63',
      flag: '🇵🇭',
      minLength: 10,
      maxLength: 10,
      groups: [3, 3, 4],
    ),
    PhoneCountry(
      name: 'Singapore',
      iso2: 'SG',
      dialCode: '65',
      flag: '🇸🇬',
      minLength: 8,
      maxLength: 8,
      groups: [4, 4],
    ),
    PhoneCountry(
      name: 'New Zealand',
      iso2: 'NZ',
      dialCode: '64',
      flag: '🇳🇿',
      minLength: 8,
      maxLength: 10,
      groups: [2, 3, 4],
    ),
  ];

  static PhoneCountry byIso2(String iso2) {
    return all.firstWhere(
      (c) => c.iso2 == iso2.toUpperCase(),
      orElse: () => us,
    );
  }

  static PhoneCountry detectFromE164(String? phone) {
    final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return us;

    // Prefer longer dial codes first to avoid `1` matching before `44`, etc.
    final sorted = [...all]
      ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));

    for (final country in sorted) {
      if (!digits.startsWith(country.dialCode)) continue;
      final local = digits.substring(country.dialCode.length);
      if (local.length >= country.minLength &&
          local.length <= country.maxLength) {
        return country;
      }
    }

    // Fallback: match dial code alone
    for (final country in sorted) {
      if (digits.startsWith(country.dialCode)) return country;
    }
    return us;
  }

  String formatLocal(String rawDigits) {
    final digits = rawDigits.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    final clipped = digits.length > maxLength
        ? digits.substring(0, maxLength)
        : digits;

    final parts = <String>[];
    var index = 0;
    for (final size in groups) {
      if (index >= clipped.length) break;
      final end = (index + size).clamp(0, clipped.length);
      parts.add(clipped.substring(index, end));
      index = end;
    }
    if (index < clipped.length) {
      parts.add(clipped.substring(index));
    }
    return parts.join(' ');
  }

  String localDigitsFromE164(String? phone) {
    var digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith(dialCode)) {
      digits = digits.substring(dialCode.length);
    }
    if (digits.length > maxLength) {
      digits = digits.substring(0, maxLength);
    }
    return digits;
  }

  String? composeE164(String localRaw) {
    final digits = localRaw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return '+$dialCode$digits';
  }

  String? validateLocal(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null; // optional
    if (digits.length < minLength || digits.length > maxLength) {
      if (minLength == maxLength) {
        return 'Enter a valid $minLength-digit number';
      }
      return 'Enter a valid $minLength–$maxLength digit number';
    }
    return null;
  }

  String get hint {
    final sample = List.generate(maxLength, (i) => '${(i + 1) % 10}').join();
    return formatLocal(sample);
  }

  int get inputMaxChars {
    // digits + spaces between groups (approx)
    return maxLength + groups.length;
  }
}
