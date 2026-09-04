import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:jebby/models/provider_onboarding_data.dart';

class ParsedUsAddress {
  final String line1;
  final String city;
  final String state;
  final String postalCode;
  final String formattedAddress;
  final double? latitude;
  final double? longitude;

  const ParsedUsAddress({
    this.line1 = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
    this.formattedAddress = '',
    this.latitude,
    this.longitude,
  });

  bool get hasLine1 => line1.trim().isNotEmpty;
  bool get hasCity => city.trim().isNotEmpty;
  bool get hasState => ProviderOnboardingData.isValidUsStateCode(state);
  bool get hasPostalCode =>
      ProviderOnboardingData.isValidUsPostalCode(postalCode);

  bool get isComplete => hasLine1 && hasCity && hasState && hasPostalCode;

  String get displaySummary {
    final line = line1.trim();
    final tail = [
      if (city.trim().isNotEmpty) city.trim(),
      if (state.trim().isNotEmpty) state.trim().toUpperCase(),
      if (postalCode.trim().isNotEmpty) postalCode.trim(),
    ].join(', ');

    if (line.isNotEmpty && tail.isNotEmpty) return '$line · $tail';
    if (line.isNotEmpty) return line;
    return tail;
  }

  String get displayLine {
    if (formattedAddress.trim().isNotEmpty) return formattedAddress.trim();
    return displaySummary;
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  /// Complete structured address confirmed from Places (includes coordinates).
  bool get isVerified => isComplete && hasCoordinates;

  /// Map coordinates tied to a resolved address line (Places, draft, or saved profile).
  bool get hasResolvedMapLocation =>
      hasCoordinates && displayLine.trim().isNotEmpty;

  static const selectFromSuggestionsMessage =
      'Please select an address from the suggestions.';

  /// Returns an error message when map/search location was not confirmed from Places.
  static String? mapLocationValidationError(ParsedUsAddress? address) {
    if (address?.hasResolvedMapLocation != true) {
      return selectFromSuggestionsMessage;
    }
    return null;
  }

  ParsedUsAddress copyWith({
    String? line1,
    String? city,
    String? state,
    String? postalCode,
    String? formattedAddress,
    double? latitude,
    double? longitude,
  }) {
    return ParsedUsAddress(
      line1: line1 ?? this.line1,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  static ParsedUsAddress fromStored({
    required String line1,
    required String city,
    required String state,
    required String postalCode,
    String formattedAddress = '',
    double? latitude,
    double? longitude,
  }) {
    return ParsedUsAddress(
      line1: line1,
      city: city,
      state: state.toUpperCase(),
      postalCode: postalCode.replaceAll(RegExp(r'\D'), ''),
      formattedAddress: formattedAddress,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

class GooglePlacesAddressService {
  GooglePlacesAddressService({String? sessionToken})
      : _sessionToken = sessionToken ?? _newSessionToken();

  String _sessionToken;

  static String _newSessionToken() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  String get _apiKey => dotenv.env['kPLACES_API_KEY'] ?? '';

  void resetSession() {
    _sessionToken = _newSessionToken();
  }

  Future<List<Map<String, dynamic>>> fetchPredictions(String input) async {
    if (input.trim().isEmpty || _apiKey.isEmpty) return [];

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': input.trim(),
        'key': _apiKey,
        'sessiontoken': _sessionToken,
        'components': 'country:us',
        'types': 'address',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return [];

    final body = json.decode(response.body) as Map<String, dynamic>;
    if (body['status'] != 'OK' && body['status'] != 'ZERO_RESULTS') {
      return [];
    }

    final predictions = body['predictions'];
    if (predictions is! List) return [];

    return predictions
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<ParsedUsAddress?> resolvePlace(String placeId) async {
    if (placeId.isEmpty || _apiKey.isEmpty) return null;

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'place_id': placeId,
        'fields': 'address_components,formatted_address,geometry',
        'key': _apiKey,
        'sessiontoken': _sessionToken,
      },
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final body = json.decode(response.body) as Map<String, dynamic>;
      if (body['status'] != 'OK') return null;

      final result = body['result'];
      if (result is! Map) return null;

      var parsed = parsePlaceResult(Map<String, dynamic>.from(result));
      if (parsed == null) return null;

      final formattedAddress = result['formatted_address']?.toString() ?? '';
      final coordinates = _readCoordinates(result);
      parsed = parsed.copyWith(
        formattedAddress: formattedAddress,
        latitude: coordinates?.$1,
        longitude: coordinates?.$2,
      );

      if (!parsed.hasPostalCode) {
        final zipFromCoords = await _lookupZipFromGeometry(result);
        if (zipFromCoords != null) {
          parsed = parsed.copyWith(postalCode: zipFromCoords);
        }
      }

      return parsed;
    } finally {
      resetSession();
    }
  }

  (double, double)? _readCoordinates(Map<dynamic, dynamic> result) {
    final geometry = result['geometry'];
    if (geometry is! Map) return null;

    final location = geometry['location'];
    if (location is! Map) return null;

    final lat = (location['lat'] as num?)?.toDouble();
    final lng = (location['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return (lat, lng);
  }

  Future<String?> _lookupZipFromGeometry(Map<dynamic, dynamic> result) async {
    final geometry = result['geometry'];
    if (geometry is! Map) return null;

    final location = geometry['location'];
    if (location is! Map) return null;

    final lat = (location['lat'] as num?)?.toDouble();
    final lng = (location['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      final zip = placemarks.first.postalCode?.trim() ?? '';
      if (zip.isEmpty) return null;
      return zip.replaceAll(RegExp(r'\D'), '');
    } catch (_) {
      return null;
    }
  }

  static ParsedUsAddress? parsePlaceResult(Map<String, dynamic> result) {
    final components = result['address_components'];
    if (components is! List) return null;

    var parsed = parseAddressComponents(components);
    if (parsed.hasPostalCode) return parsed;

    final formattedAddress = result['formatted_address']?.toString() ?? '';
    final zipFromFormatted = extractUsZipFromText(formattedAddress);
    if (zipFromFormatted != null) {
      parsed = parsed.copyWith(postalCode: zipFromFormatted);
    }

    return parsed;
  }

  static String? extractUsZipFromText(String text) {
    if (text.trim().isEmpty) return null;

    final matches = RegExp(r'\b(\d{5})(?:-(\d{4}))?\b').allMatches(text);
    if (matches.isEmpty) return null;

    final last = matches.last;
    final zip5 = last.group(1);
    if (zip5 == null) return null;

    final plus4 = last.group(2);
    return plus4 != null ? '$zip5$plus4' : zip5;
  }

  static ParsedUsAddress parseAddressComponents(List<dynamic> components) {
    String? streetNumber;
    String? route;
    String? city;
    String? state;
    String? postalCode;
    String? postalSuffix;

    for (final raw in components) {
      if (raw is! Map) continue;
      final types = List<String>.from(raw['types'] ?? const []);
      final longName = raw['long_name']?.toString() ?? '';
      final shortName = raw['short_name']?.toString() ?? '';

      if (types.contains('street_number')) {
        streetNumber = longName;
      } else if (types.contains('route')) {
        route = longName;
      } else if (types.contains('locality')) {
        city ??= longName;
      } else if (types.contains('postal_town')) {
        city ??= longName;
      } else if (types.contains('administrative_area_level_3')) {
        city ??= longName;
      } else if (types.contains('sublocality') ||
          types.contains('sublocality_level_1') ||
          types.contains('neighborhood')) {
        city ??= longName;
      } else if (types.contains('administrative_area_level_1')) {
        state = shortName.toUpperCase();
      } else if (types.contains('postal_code')) {
        postalCode = longName;
      } else if (types.contains('postal_code_suffix')) {
        postalSuffix = longName;
      }
    }

    final line1 = streetNumber != null && route != null
        ? '$streetNumber $route'
        : route ?? streetNumber ?? '';

    var normalizedPostal = postalCode?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (normalizedPostal.length == 5 &&
        postalSuffix != null &&
        postalSuffix.replaceAll(RegExp(r'\D'), '').length == 4) {
      normalizedPostal =
          '$normalizedPostal${postalSuffix.replaceAll(RegExp(r'\D'), '')}';
    }

    return ParsedUsAddress(
      line1: line1.trim(),
      city: city?.trim() ?? '',
      state: state?.trim().toUpperCase() ?? '',
      postalCode: normalizedPostal,
    );
  }
}
