class ProviderIdType {
  static const drivingLicense = 'driving_license';
  static const passport = 'passport';
  static const idCard = 'id_card';

  static const labels = {
    drivingLicense: "Driver's License",
    passport: 'Passport',
    idCard: 'State ID',
  };

  static bool requiresBack(String type) =>
      type == drivingLicense || type == idCard;
}

class ProviderBusinessDefaults {
  static const businessUrl = 'https://jebbylistings.com';
  static const businessMcc = '7394';
  static const statementDescriptor = 'JEBBY';
}

class ProviderMccOption {
  final String code;
  final String label;

  const ProviderMccOption(this.code, this.label);
}

class ProviderOnboardingData {
  static const List<ProviderMccOption> mccOptions = [
    ProviderMccOption('7394', 'Equipment / item rental'),
    ProviderMccOption('7999', 'Recreation services'),
    ProviderMccOption('5999', 'Miscellaneous retail'),
    ProviderMccOption('5734', 'Software / digital goods'),
  ];

  static const List<Map<String, String>> usStates = [
    {'code': 'AL', 'name': 'Alabama'},
    {'code': 'AK', 'name': 'Alaska'},
    {'code': 'AZ', 'name': 'Arizona'},
    {'code': 'AR', 'name': 'Arkansas'},
    {'code': 'CA', 'name': 'California'},
    {'code': 'CO', 'name': 'Colorado'},
    {'code': 'CT', 'name': 'Connecticut'},
    {'code': 'DE', 'name': 'Delaware'},
    {'code': 'DC', 'name': 'District of Columbia'},
    {'code': 'FL', 'name': 'Florida'},
    {'code': 'GA', 'name': 'Georgia'},
    {'code': 'HI', 'name': 'Hawaii'},
    {'code': 'ID', 'name': 'Idaho'},
    {'code': 'IL', 'name': 'Illinois'},
    {'code': 'IN', 'name': 'Indiana'},
    {'code': 'IA', 'name': 'Iowa'},
    {'code': 'KS', 'name': 'Kansas'},
    {'code': 'KY', 'name': 'Kentucky'},
    {'code': 'LA', 'name': 'Louisiana'},
    {'code': 'ME', 'name': 'Maine'},
    {'code': 'MD', 'name': 'Maryland'},
    {'code': 'MA', 'name': 'Massachusetts'},
    {'code': 'MI', 'name': 'Michigan'},
    {'code': 'MN', 'name': 'Minnesota'},
    {'code': 'MS', 'name': 'Mississippi'},
    {'code': 'MO', 'name': 'Missouri'},
    {'code': 'MT', 'name': 'Montana'},
    {'code': 'NE', 'name': 'Nebraska'},
    {'code': 'NV', 'name': 'Nevada'},
    {'code': 'NH', 'name': 'New Hampshire'},
    {'code': 'NJ', 'name': 'New Jersey'},
    {'code': 'NM', 'name': 'New Mexico'},
    {'code': 'NY', 'name': 'New York'},
    {'code': 'NC', 'name': 'North Carolina'},
    {'code': 'ND', 'name': 'North Dakota'},
    {'code': 'OH', 'name': 'Ohio'},
    {'code': 'OK', 'name': 'Oklahoma'},
    {'code': 'OR', 'name': 'Oregon'},
    {'code': 'PA', 'name': 'Pennsylvania'},
    {'code': 'RI', 'name': 'Rhode Island'},
    {'code': 'SC', 'name': 'South Carolina'},
    {'code': 'SD', 'name': 'South Dakota'},
    {'code': 'TN', 'name': 'Tennessee'},
    {'code': 'TX', 'name': 'Texas'},
    {'code': 'UT', 'name': 'Utah'},
    {'code': 'VT', 'name': 'Vermont'},
    {'code': 'VA', 'name': 'Virginia'},
    {'code': 'WA', 'name': 'Washington'},
    {'code': 'WV', 'name': 'West Virginia'},
    {'code': 'WI', 'name': 'Wisconsin'},
    {'code': 'WY', 'name': 'Wyoming'},
  ];

  String firstName;
  String lastName;
  String email;
  String phone;
  int? dobDay;
  int? dobMonth;
  int? dobYear;
  String? ssnLast4;
  String addressLine1;
  String addressCity;
  String addressState;
  String addressPostalCode;
  String businessUrl;
  String businessMcc;
  String statementDescriptor;
  String idType;
  String? frontImagePath;
  String? backImagePath;
  String? frontFileId;
  String? backFileId;
  String accountHolderName;
  String routingNumber;
  String accountNumber;
  String country;
  bool tosAccepted;

  ProviderOnboardingData({
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.phone = '',
    this.dobDay,
    this.dobMonth,
    this.dobYear,
    this.ssnLast4,
    this.addressLine1 = '',
    this.addressCity = '',
    this.addressState = '',
    this.addressPostalCode = '',
    this.businessUrl = ProviderBusinessDefaults.businessUrl,
    this.businessMcc = ProviderBusinessDefaults.businessMcc,
    this.statementDescriptor = ProviderBusinessDefaults.statementDescriptor,
    this.idType = ProviderIdType.drivingLicense,
    this.frontImagePath,
    this.backImagePath,
    this.frontFileId,
    this.backFileId,
    this.accountHolderName = '',
    this.routingNumber = '',
    this.accountNumber = '',
    this.country = 'US',
    this.tosAccepted = false,
  });

  String get legalFullName => '$firstName $lastName'.trim();

  DateTime? get dateOfBirth {
    if (dobDay == null || dobMonth == null || dobYear == null) return null;
    return DateTime(dobYear!, dobMonth!, dobDay!);
  }

  bool get isAdult {
    final dob = dateOfBirth;
    if (dob == null) return false;
    final today = DateTime.now();
    var age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age >= 18;
  }

  ProviderOnboardingData copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    int? dobDay,
    int? dobMonth,
    int? dobYear,
    String? ssnLast4,
    String? addressLine1,
    String? addressCity,
    String? addressState,
    String? addressPostalCode,
    String? businessUrl,
    String? businessMcc,
    String? statementDescriptor,
    String? idType,
    String? frontImagePath,
    String? backImagePath,
    String? frontFileId,
    String? backFileId,
    String? accountHolderName,
    String? routingNumber,
    String? accountNumber,
    String? country,
    bool? tosAccepted,
    bool clearSsnLast4 = false,
    bool clearAccountNumber = false,
    bool clearFrontFileId = false,
    bool clearBackFileId = false,
  }) {
    return ProviderOnboardingData(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dobDay: dobDay ?? this.dobDay,
      dobMonth: dobMonth ?? this.dobMonth,
      dobYear: dobYear ?? this.dobYear,
      ssnLast4: clearSsnLast4 ? null : (ssnLast4 ?? this.ssnLast4),
      addressLine1: addressLine1 ?? this.addressLine1,
      addressCity: addressCity ?? this.addressCity,
      addressState: addressState ?? this.addressState,
      addressPostalCode: addressPostalCode ?? this.addressPostalCode,
      businessUrl: businessUrl ?? this.businessUrl,
      businessMcc: businessMcc ?? this.businessMcc,
      statementDescriptor: statementDescriptor ?? this.statementDescriptor,
      idType: idType ?? this.idType,
      frontImagePath: frontImagePath ?? this.frontImagePath,
      backImagePath: backImagePath ?? this.backImagePath,
      frontFileId: clearFrontFileId ? null : (frontFileId ?? this.frontFileId),
      backFileId: clearBackFileId ? null : (backFileId ?? this.backFileId),
      accountHolderName: accountHolderName ?? this.accountHolderName,
      routingNumber: routingNumber ?? this.routingNumber,
      accountNumber:
          clearAccountNumber ? '' : (accountNumber ?? this.accountNumber),
      country: country ?? this.country,
      tosAccepted: tosAccepted ?? this.tosAccepted,
    );
  }

  Map<String, dynamic> toPersistedJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      if (dobDay != null) 'dob_day': dobDay,
      if (dobMonth != null) 'dob_month': dobMonth,
      if (dobYear != null) 'dob_year': dobYear,
      if (ssnLast4 != null && ssnLast4!.isNotEmpty) 'ssn_last_4': ssnLast4,
      'address_line1': addressLine1,
      'address_city': addressCity,
      'address_state': addressState,
      'address_postal_code': addressPostalCode,
      'business_url': businessUrl,
      'business_mcc': businessMcc,
      'statement_descriptor': statementDescriptor,
      'id_type': idType,
      if (frontImagePath != null) 'front_image_path': frontImagePath,
      if (backImagePath != null) 'back_image_path': backImagePath,
      if (frontFileId != null) 'front_file_id': frontFileId,
      if (backFileId != null) 'back_file_id': backFileId,
      'account_holder_name': accountHolderName,
      'routing_number': routingNumber,
      if (accountNumber.isNotEmpty) 'account_number': accountNumber,
      'country': country,
      'tos_accepted': tosAccepted,
    };
  }

  factory ProviderOnboardingData.fromPersistedJson(Map<String, dynamic> json) {
    return ProviderOnboardingData(
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      dobDay: _parseOptionalInt(json['dob_day']),
      dobMonth: _parseOptionalInt(json['dob_month']),
      dobYear: _parseOptionalInt(json['dob_year']),
      ssnLast4: json['ssn_last_4']?.toString(),
      addressLine1: json['address_line1']?.toString() ?? '',
      addressCity: json['address_city']?.toString() ?? '',
      addressState: json['address_state']?.toString() ?? '',
      addressPostalCode: json['address_postal_code']?.toString() ?? '',
      businessUrl:
          json['business_url']?.toString() ?? ProviderBusinessDefaults.businessUrl,
      businessMcc:
          json['business_mcc']?.toString() ?? ProviderBusinessDefaults.businessMcc,
      statementDescriptor: json['statement_descriptor']?.toString() ??
          ProviderBusinessDefaults.statementDescriptor,
      idType: json['id_type']?.toString() ?? ProviderIdType.drivingLicense,
      frontImagePath: json['front_image_path']?.toString(),
      backImagePath: json['back_image_path']?.toString(),
      frontFileId: json['front_file_id']?.toString(),
      backFileId: json['back_file_id']?.toString(),
      accountHolderName: json['account_holder_name']?.toString() ?? '',
      routingNumber: json['routing_number']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? '',
      country: json['country']?.toString() ?? 'US',
      tosAccepted: json['tos_accepted'] == true,
    );
  }

  Map<String, dynamic> toSubmitJson({required String userId, String? ip}) {
    return {
      'user_id': userId,
      'personal': {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': formatPhoneE164(phone),
        'dob': {
          'day': dobDay,
          'month': dobMonth,
          'year': dobYear,
        },
        if (ssnLast4 != null && ssnLast4!.isNotEmpty) 'ssn_last_4': ssnLast4,
        'address': {
          'line1': addressLine1,
          'city': addressCity,
          'state': addressState,
          'postal_code': addressPostalCode,
          'country': country,
        },
      },
      'identity': {
        'document_type': idType,
        'front_file_id': frontFileId,
        if (backFileId != null) 'back_file_id': backFileId,
      },
      'bank': {
        'country': country,
        'currency': 'usd',
        'account_holder_name': accountHolderName,
        'routing_number': routingNumber,
        'account_number': accountNumber,
      },
      'tos': {
        'accepted': true,
        'ip': ip ?? 'mobile_client',
        'date': DateTime.now().toUtc().toIso8601String(),
      },
    };
  }

  void clearSensitiveFields() {
    ssnLast4 = null;
  }

  /// Stripe requires E.164 format (e.g. +14155552671).
  static String formatPhoneE164(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (phone.trim().startsWith('+')) return '+$digits';
    if (digits.length == 10) return '+1$digits';
    if (digits.length == 11 && digits.startsWith('1')) return '+$digits';
    return '+$digits';
  }

  static bool isValidUsPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final tenDigit = digits.length == 11 && digits.startsWith('1')
        ? digits.substring(1)
        : digits.length == 10
            ? digits
            : null;
    if (tenDigit == null) return false;
    if (RegExp(r'^(\d)\1{9}$').hasMatch(tenDigit)) return false;
    if (tenDigit.startsWith('0') || tenDigit.startsWith('1')) return false;
    if (tenDigit[3] == '0' || tenDigit[3] == '1') return false;
    return true;
  }

  static bool isValidUsPostalCode(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length == 5 || digits.length == 9;
  }

  static bool isValidUsStateCode(String value) {
    final code = value.trim().toUpperCase();
    return usStates.any((state) => state['code'] == code);
  }

  static bool isValidBusinessUrl(String value) {
    final trimmed = value.trim();
    return RegExp(r'^https?://[^\s]+$').hasMatch(trimmed);
  }

  static bool isValidStatementDescriptor(String value) {
    final trimmed = value.trim().toUpperCase();
    if (trimmed.length < 5 || trimmed.length > 22) return false;
    if (!RegExp(r'[A-Z]').hasMatch(trimmed)) return false;
    const forbidden = ['<', '>', "'", '"', r'\', '*'];
    return !forbidden.any(trimmed.contains);
  }

  static String mccLabel(String code) {
    return mccOptions
        .firstWhere(
          (option) => option.code == code,
          orElse: () => ProviderMccOption(code, 'MCC $code'),
        )
        .label;
  }

  static String stateName(String code) {
    final match = usStates.firstWhere(
      (state) => state['code'] == code.toUpperCase(),
      orElse: () => {'code': code, 'name': code},
    );
    return match['name'] ?? code;
  }

  static int? _parseOptionalInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
