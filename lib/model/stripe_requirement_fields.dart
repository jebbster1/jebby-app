import 'package:jebby/model/provider_onboarding_data.dart';

enum StripeFormFieldKind {
  text,
  email,
  phone,
  ssnLast4,
  idNumber,
  dateOfBirth,
  state,
  mcc,
  url,
  bankRouting,
  bankAccount,
  bankHolder,
  idType,
  idFrontImage,
  idBackImage,
}

class StripeFormFieldDef {
  final String id;
  final String label;
  final StripeFormFieldKind kind;
  final String? hint;

  const StripeFormFieldDef({
    required this.id,
    required this.label,
    required this.kind,
    this.hint,
  });
}

class StripeRequirementFields {
  StripeRequirementFields._();

  static const Map<String, List<String>> _stripeKeyToFieldIds = {
    'individual.id_number': ['id_number'],
    'individual.ssn_last_4': ['ssn_last_4'],
    'individual.first_name': ['first_name'],
    'individual.last_name': ['last_name'],
    'individual.email': ['email'],
    'individual.phone': ['phone'],
    'individual.dob.day': ['dob'],
    'individual.dob.month': ['dob'],
    'individual.dob.year': ['dob'],
    'individual.dob': ['dob'],
    'individual.address.line1': ['address_line1'],
    'individual.address.city': ['address_city'],
    'individual.address.state': ['address_state'],
    'individual.address.postal_code': ['address_postal_code'],
    'individual.address': [
      'address_line1',
      'address_city',
      'address_state',
      'address_postal_code',
    ],
    'business_profile.mcc': ['business_mcc'],
    'business_profile.url': ['business_url'],
    'business_profile.name': ['first_name', 'last_name'],
    'external_account': ['bank_holder', 'bank_routing', 'bank_account'],
    'individual.verification.document': ['id_type', 'id_front', 'id_back'],
    'verification.document.front': ['id_front'],
    'verification.document.back': ['id_back'],
    'individual.verification.additional_document': ['id_front'],
  };

  static const Map<String, StripeFormFieldDef> _fieldDefinitions = {
    'first_name': StripeFormFieldDef(
      id: 'first_name',
      label: 'First name',
      kind: StripeFormFieldKind.text,
    ),
    'last_name': StripeFormFieldDef(
      id: 'last_name',
      label: 'Last name',
      kind: StripeFormFieldKind.text,
    ),
    'email': StripeFormFieldDef(
      id: 'email',
      label: 'Email address',
      kind: StripeFormFieldKind.email,
    ),
    'phone': StripeFormFieldDef(
      id: 'phone',
      label: 'Phone number',
      kind: StripeFormFieldKind.phone,
      hint: '+1 (415) 555-2671',
    ),
    'dob': StripeFormFieldDef(
      id: 'dob',
      label: 'Date of birth',
      kind: StripeFormFieldKind.dateOfBirth,
    ),
    'ssn_last_4': StripeFormFieldDef(
      id: 'ssn_last_4',
      label: 'SSN last 4 digits',
      kind: StripeFormFieldKind.ssnLast4,
    ),
    'id_number': StripeFormFieldDef(
      id: 'id_number',
      label: 'Full SSN (9 digits)',
      kind: StripeFormFieldKind.idNumber,
      hint: 'Required for identity verification',
    ),
    'address_line1': StripeFormFieldDef(
      id: 'address_line1',
      label: 'Street address',
      kind: StripeFormFieldKind.text,
    ),
    'address_city': StripeFormFieldDef(
      id: 'address_city',
      label: 'City',
      kind: StripeFormFieldKind.text,
    ),
    'address_state': StripeFormFieldDef(
      id: 'address_state',
      label: 'State',
      kind: StripeFormFieldKind.state,
    ),
    'address_postal_code': StripeFormFieldDef(
      id: 'address_postal_code',
      label: 'ZIP code',
      kind: StripeFormFieldKind.text,
    ),
    'business_mcc': StripeFormFieldDef(
      id: 'business_mcc',
      label: 'Business category (MCC)',
      kind: StripeFormFieldKind.mcc,
    ),
    'business_url': StripeFormFieldDef(
      id: 'business_url',
      label: 'Business website',
      kind: StripeFormFieldKind.url,
    ),
    'bank_holder': StripeFormFieldDef(
      id: 'bank_holder',
      label: 'Account holder name',
      kind: StripeFormFieldKind.bankHolder,
    ),
    'bank_routing': StripeFormFieldDef(
      id: 'bank_routing',
      label: 'Routing number',
      kind: StripeFormFieldKind.bankRouting,
    ),
    'bank_account': StripeFormFieldDef(
      id: 'bank_account',
      label: 'Account number',
      kind: StripeFormFieldKind.bankAccount,
    ),
    'id_type': StripeFormFieldDef(
      id: 'id_type',
      label: 'ID document type',
      kind: StripeFormFieldKind.idType,
    ),
    'id_front': StripeFormFieldDef(
      id: 'id_front',
      label: 'ID front photo',
      kind: StripeFormFieldKind.idFrontImage,
    ),
    'id_back': StripeFormFieldDef(
      id: 'id_back',
      label: 'ID back photo',
      kind: StripeFormFieldKind.idBackImage,
    ),
  };

  static const List<String> _fieldOrder = [
    'first_name',
    'last_name',
    'email',
    'phone',
    'dob',
    'ssn_last_4',
    'id_number',
    'address_line1',
    'address_city',
    'address_state',
    'address_postal_code',
    'business_mcc',
    'business_url',
    'bank_holder',
    'bank_routing',
    'bank_account',
    'id_type',
    'id_front',
    'id_back',
  ];

  static List<String> collectDueKeys(Map<String, dynamic>? requirements) {
    if (requirements == null) return const [];

    final keys = <String>{};
    for (final bucket in ['currently_due', 'past_due']) {
      final value = requirements[bucket];
      if (value is List) {
        for (final item in value) {
          final key = item?.toString().trim();
          if (key != null && key.isNotEmpty) keys.add(key);
        }
      }
    }
    return keys.toList();
  }

  static List<String> collectEventuallyDueKeys(
    Map<String, dynamic>? requirements,
  ) {
    if (requirements == null) return const [];
    final value = requirements['eventually_due'];
    if (value is! List) return const [];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static List<StripeFormFieldDef> resolveFields(List<String> dueKeys) {
    final fieldIds = <String>{};
    final unmapped = <String>[];

    for (final stripeKey in dueKeys) {
      final mapped = _stripeKeyToFieldIds[stripeKey];
      if (mapped != null) {
        fieldIds.addAll(mapped);
      } else {
        final partial = _matchPartialStripeKey(stripeKey);
        if (partial.isNotEmpty) {
          fieldIds.addAll(partial);
        } else {
          unmapped.add(stripeKey);
        }
      }
    }

    if (unmapped.isNotEmpty && fieldIds.isEmpty) {
      fieldIds.add('id_number');
    }

    final fields = _fieldOrder
        .where(fieldIds.contains)
        .map((id) => _fieldDefinitions[id]!)
        .toList();

    if (fields.any((field) => field.id == 'id_front') &&
        !fields.any((field) => field.id == 'id_type')) {
      fields.insert(
        fields.indexWhere((field) => field.id == 'id_front'),
        _fieldDefinitions['id_type']!,
      );
    }

    if (fields.any((field) => field.id == 'id_front') &&
        !fields.any((field) => field.id == 'id_back')) {
      fields.add(_fieldDefinitions['id_back']!);
    }

    return fields;
  }

  static List<String> _matchPartialStripeKey(String stripeKey) {
    if (stripeKey.contains('address')) {
      return _stripeKeyToFieldIds['individual.address']!;
    }
    if (stripeKey.contains('verification') || stripeKey.contains('document')) {
      return _stripeKeyToFieldIds['individual.verification.document']!;
    }
    if (stripeKey.contains('external_account') || stripeKey.contains('bank')) {
      return _stripeKeyToFieldIds['external_account']!;
    }
    if (stripeKey.contains('ssn') || stripeKey.contains('id_number')) {
      return stripeKey.contains('last_4')
          ? ['ssn_last_4']
          : ['id_number'];
    }
    return const [];
  }

  static String humanizeStripeKey(String key) {
    return key.replaceAll('.', ' · ').replaceAll('_', ' ');
  }

  static Map<String, dynamic> seedValuesFromProviderData(
    ProviderOnboardingData data,
  ) {
    return {
      'first_name': data.firstName,
      'last_name': data.lastName,
      'email': data.email,
      'phone': data.phone,
      if (data.dobDay != null && data.dobMonth != null && data.dobYear != null)
        'dob': DateTime(data.dobYear!, data.dobMonth!, data.dobDay!),
      'ssn_last_4': data.ssnLast4 ?? '',
      'address_line1': data.addressLine1,
      'address_city': data.addressCity,
      'address_state': data.addressState,
      'address_postal_code': data.addressPostalCode,
      'business_mcc': data.businessMcc,
      'business_url': data.businessUrl,
      'bank_holder': data.accountHolderName,
      'bank_routing': data.routingNumber,
      'bank_account': data.accountNumber,
      'id_type': data.idType,
      'id_front_path': data.frontImagePath,
      'id_back_path': data.backImagePath,
      'id_front_file_id': data.frontFileId,
      'id_back_file_id': data.backFileId,
    };
  }

  static bool dueKeysNeedBank(List<String> dueKeys) {
    return dueKeys.any((key) {
      final lower = key.toLowerCase();
      return lower.contains('external_account') ||
          lower.startsWith('bank.') ||
          lower.contains('bank_account');
    });
  }

  static bool dueKeysNeedBusiness(List<String> dueKeys) {
    return dueKeys.any((key) {
      final lower = key.toLowerCase();
      return lower.startsWith('business_profile.');
    });
  }

  static bool dueKeysNeedIdentity(List<String> dueKeys) {
    return dueKeys.any((key) {
      final lower = key.toLowerCase();
      return lower.contains('verification') || lower.contains('document');
    });
  }

  static bool _includesField(List<String>? fieldIds, String id) {
    return fieldIds == null || fieldIds.contains(id);
  }

  static bool _includesAnyField(List<String>? fieldIds, List<String> ids) {
    return fieldIds == null || ids.any(fieldIds.contains);
  }

  static String? _nonEmptyValue(Map<String, dynamic> values, String key) {
    final raw = values[key];
    if (raw == null) return null;
    final text = raw.toString().trim();
    return text.isEmpty ? null : text;
  }

  static Map<String, dynamic> buildSubmitBody({
    required String userId,
    required List<String> dueKeys,
    required Map<String, dynamic> values,
    List<String>? fieldIds,
  }) {
    final body = <String, dynamic>{
      'user_id': userId,
      'requirements': dueKeys,
    };

    final personal = <String, dynamic>{};
    final address = <String, dynamic>{};
    final businessProfile = <String, dynamic>{};
    final identity = <String, dynamic>{};

    final includeBank =
        dueKeysNeedBank(dueKeys) ||
        _includesAnyField(fieldIds, ['bank_holder', 'bank_routing', 'bank_account']);
    final includeBusiness =
        dueKeysNeedBusiness(dueKeys) ||
        _includesAnyField(fieldIds, ['business_mcc', 'business_url']);
    final includeIdentity =
        dueKeysNeedIdentity(dueKeys) ||
        _includesAnyField(fieldIds, ['id_type', 'id_front', 'id_back']);

    void setPersonal(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      personal[key] = value;
    }

    if (_includesField(fieldIds, 'first_name')) {
      setPersonal('first_name', _nonEmptyValue(values, 'first_name'));
    }
    if (_includesField(fieldIds, 'last_name')) {
      setPersonal('last_name', _nonEmptyValue(values, 'last_name'));
    }
    if (_includesField(fieldIds, 'email')) {
      setPersonal('email', _nonEmptyValue(values, 'email'));
    }
    if (_includesField(fieldIds, 'phone')) {
      final phone = _nonEmptyValue(values, 'phone');
      if (phone != null) {
        setPersonal('phone', ProviderOnboardingData.formatPhoneE164(phone));
      }
    }
    if (_includesField(fieldIds, 'dob') && values['dob'] is DateTime) {
      final dob = values['dob'] as DateTime;
      personal['dob'] = {
        'day': dob.day,
        'month': dob.month,
        'year': dob.year,
      };
    }
    if (_includesField(fieldIds, 'ssn_last_4')) {
      setPersonal('ssn_last_4', _nonEmptyValue(values, 'ssn_last_4'));
    }
    if (_includesField(fieldIds, 'id_number')) {
      setPersonal('id_number', _nonEmptyValue(values, 'id_number'));
    }

    final includeAddress = _includesAnyField(fieldIds, [
      'address_line1',
      'address_city',
      'address_state',
      'address_postal_code',
    ]);
    if (includeAddress) {
      if (_includesField(fieldIds, 'address_line1')) {
        address['line1'] = _nonEmptyValue(values, 'address_line1');
      }
      if (_includesField(fieldIds, 'address_city')) {
        address['city'] = _nonEmptyValue(values, 'address_city');
      }
      if (_includesField(fieldIds, 'address_state')) {
        final state = _nonEmptyValue(values, 'address_state');
        if (state != null) address['state'] = state.toUpperCase();
      }
      if (_includesField(fieldIds, 'address_postal_code')) {
        final postal = _nonEmptyValue(values, 'address_postal_code');
        if (postal != null) {
          address['postal_code'] = postal.replaceAll(RegExp(r'\D'), '');
        }
      }
      address.removeWhere((_, value) => value == null);
      if (address.isNotEmpty) {
        address['country'] = 'US';
        personal['address'] = address;
      }
    }

    if (includeBusiness) {
      if (_includesField(fieldIds, 'business_mcc')) {
        final mcc = _nonEmptyValue(values, 'business_mcc');
        if (mcc != null) businessProfile['mcc'] = mcc;
      }
      if (_includesField(fieldIds, 'business_url')) {
        final url = _nonEmptyValue(values, 'business_url');
        if (url != null) businessProfile['url'] = url;
      }
    }

    Map<String, dynamic>? bank;
    if (includeBank) {
      bank = {'country': 'US', 'currency': 'usd'};
      final holder = _nonEmptyValue(values, 'bank_holder');
      final routing =
          _nonEmptyValue(values, 'bank_routing')?.replaceAll(RegExp(r'\D'), '');
      final account =
          _nonEmptyValue(values, 'bank_account')?.replaceAll(RegExp(r'\D'), '');

      if (holder != null) bank['account_holder_name'] = holder;
      if (routing != null && routing.isNotEmpty) bank['routing_number'] = routing;
      if (account != null && account.isNotEmpty) bank['account_number'] = account;
    }

    if (includeIdentity) {
      final idType = _nonEmptyValue(values, 'id_type');
      final frontFileId = _nonEmptyValue(values, 'id_front_file_id');
      final backFileId = _nonEmptyValue(values, 'id_back_file_id');
      if (idType != null) identity['document_type'] = idType;
      if (frontFileId != null) identity['front_file_id'] = frontFileId;
      if (backFileId != null) identity['back_file_id'] = backFileId;
    }

    if (personal.isNotEmpty) body['personal'] = personal;
    if (businessProfile.isNotEmpty) body['business_profile'] = businessProfile;
    if (bank != null && bank.length > 2) body['bank'] = bank;
    if (identity.isNotEmpty) body['identity'] = identity;

    return body;
  }
}
