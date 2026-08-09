import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jebby/Views/screens/home/filteredData.dart';
import 'package:jebby/view_model/apiServices.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jebby/Views/helper/colors.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:jebby/Views/widgets/address_autocomplete_field.dart';
import 'package:jebby/utils/google_places_address.dart';
import 'package:jebby/utils/show_snackbar.dart';
import 'package:jebby/res/app_url.dart';

import '../../../res/color.dart';

class FilterScreeen extends StatefulWidget {
  const FilterScreeen({super.key});

  @override
  State<FilterScreeen> createState() => _FilterScreeenState();
}

class _FilterScreeenState extends State<FilterScreeen> {
  var fromDate = null;
  var toDate = null;
  DateTime selectedDate = DateTime.now();
  DateTime selectedDate1 = DateTime.now();
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isSelectingEnd = false;
  bool notSearch = true;
  double _Pvalue = 50;
  double _distanceValue = 10.0;
  var radius = 0;
  bool _ignoreLocationClear = false;
  var price = 50;
  late String url;
  var _locationController = TextEditingController();
  ParsedUsAddress? _resolvedAddress;
  var uuid = new Uuid();
  var Latitiude;
  var Longitude;
  late var sub_length;
  late var sub_name;
  late var sub_id;
  late var name_length;
  late var category_name;
  late var category_id;
  String? dropdownValue;
  String? sub_dropdownvalue;
  String selectedValue = "select";
  String sub_selectedvalue = "select";
  List<String> sub_items = [];
  List sub_items_id = [];
  List<String> items = [];
  List items_id = [];
  late var selected_id;
  late var selected_sub_id = null;
  bool isError = false;
  bool isLoading = true;
  bool sub_categoryLoader = true;
  bool sub_categoryError = false;
  bool subCategoryVisibility = false;
  bool filteredData = false;
  bool filteredError = false;
  bool emptyFilteredData = false;
  bool radiusVisibility = false;

  // Map related variables
  GoogleMapController? _mapController;
  Position? _currentPosition;
  String _currentAddress = '';
  Set<Marker> _markers = {};
  bool _isLocationLoading = true;
  bool _showMap = false;
  List<dynamic> _nearbyProducts = [];
  final Map<String, BitmapDescriptor> _markerIconCache = {};

  // Default center on US if location not available
  CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(37.0902, -95.7129),
    zoom: 4.0,
  );

  void dispose() {
    _locationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _setLocationText(String text) {
    _ignoreLocationClear = true;
    _locationController.text = text;
    _ignoreLocationClear = false;
  }

  void _clearResolvedAddress() {
    if (_ignoreLocationClear) return;
    setState(() {
      _resolvedAddress = const ParsedUsAddress();
      Latitiude = null;
      Longitude = null;
    });
  }

  bool get _hasSearchLocation =>
      _searchLatitude != null && _searchLongitude != null;

  double? get _searchLatitude =>
      _toDouble(Latitiude) ?? _resolvedAddress?.latitude;

  double? get _searchLongitude =>
      _toDouble(Longitude) ?? _resolvedAddress?.longitude;

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  int get _effectiveSearchRadius {
    if (!_hasSearchLocation) return 0;
    return radius > 0 ? radius : _distanceValue.round();
  }

  double? get _mapCenterLatitude =>
      _searchLatitude ?? _currentPosition?.latitude;

  double? get _mapCenterLongitude =>
      _searchLongitude ?? _currentPosition?.longitude;

  bool get _hasMapCenter =>
      _mapCenterLatitude != null && _mapCenterLongitude != null;

  double get _mapRadiusMiles =>
      radius > 0 ? radius.toDouble() : _distanceValue;

  Future<void> _moveMapToCenter() async {
    final lat = _mapCenterLatitude;
    final lng = _mapCenterLongitude;
    if (lat == null || lng == null) return;

    setState(() {
      _initialCameraPosition = CameraPosition(
        target: LatLng(lat, lng),
        zoom: 11,
      );
    });

    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 11),
      );
    }
  }

  String _urlParam(dynamic value) {
    if (value == null) return 'null';
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return 'null';
    return text;
  }

  String _priceUrlParam() {
    final maxPrice = _Pvalue.round();
    if (maxPrice <= 0 || maxPrice >= 1000) return 'null';
    return maxPrice.toString();
  }

  String _buildSearchUrl(String baseUrl, {required bool useLocationSearch}) {
    final startDateParam =
        fromDate != null ? _urlParam(fromDate) : 'null';
    final endDateParam = fromDate != null
        ? _urlParam(toDate ?? selectedDate1)
        : 'null';
    final latParam =
        useLocationSearch ? _urlParam(_searchLatitude) : 'null';
    final lngParam =
        useLocationSearch ? _urlParam(_searchLongitude) : 'null';
    final milesParam = useLocationSearch
        ? _urlParam(_effectiveSearchRadius)
        : 'null';
    final subCategoryParam = _urlParam(selected_sub_id);
    final priceParam = _priceUrlParam();

    return '$baseUrl/getProductSearching/$startDateParam/$endDateParam/$latParam/$lngParam/$milesParam/$subCategoryParam/$priceParam';
  }

  Future<bool> _ensureSearchCoordinates() async {
    if (_hasSearchLocation) {
      final lat = _searchLatitude!;
      final lng = _searchLongitude!;
      if (_toDouble(Latitiude) == null || _toDouble(Longitude) == null) {
        setState(() {
          Latitiude = lat;
          Longitude = lng;
        });
      }
      return true;
    }

    return false;
  }

  Future<void> _applySelectedAddress(ParsedUsAddress address) async {
    ParsedUsAddress resolved = address;
    if (!address.hasCoordinates) {
      for (final query in [
        address.formattedAddress.trim(),
        address.displayLine.trim(),
        address.displaySummary.trim(),
      ].where((value) => value.isNotEmpty)) {
        try {
          final locations = await locationFromAddress(query);
          if (locations.isEmpty) continue;
          resolved = address.copyWith(
            latitude: locations.first.latitude,
            longitude: locations.first.longitude,
          );
          break;
        } catch (_) {}
      }
    }

    if (!mounted) return;
    setState(() {
      _resolvedAddress = resolved;
      if (resolved.hasCoordinates) {
        Latitiude = resolved.latitude;
        Longitude = resolved.longitude;
        _initialCameraPosition = CameraPosition(
          target: LatLng(resolved.latitude!, resolved.longitude!),
          zoom: 12.0,
        );
        if (radius == 0) {
          radius = _distanceValue.round();
        }
      }
    });
    await _moveMapToCenter();
    _loadNearbyProducts();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLocationLoading = true;
      });

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationDisabledDialog();
        setState(() {
          _isLocationLoading = false;
        });
        return;
      }

      // Check for location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDeniedDialog();
          setState(() {
            _isLocationLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDeniedDialog();
        setState(() {
          _isLocationLoading = false;
        });
        return;
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        Latitiude = position.latitude;
        Longitude = position.longitude;
        if (radius == 0) {
          radius = _distanceValue.round();
        }
        _initialCameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 12.0,
        );
        _isLocationLoading = false;
      });

      // Get address from the location
      _getAddressFromLatLng(position);

      // Load nearby products
      _loadNearbyProducts();
    } catch (e) {
      setState(() {
        _isLocationLoading = false;
      });
      _showErrorDialog('Could not get your location. Please try again.');
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress =
              '${place.street}, ${place.locality}, ${place.administrativeArea} ${place.postalCode}';
          _setLocationText(_currentAddress);
          _resolvedAddress = ParsedUsAddress(
            formattedAddress: _currentAddress,
            latitude: position.latitude,
            longitude: position.longitude,
            line1: place.street ?? '',
            city: place.locality ?? '',
            state: place.administrativeArea ?? '',
            postalCode: place.postalCode ?? '',
          );
        });
      }
    } catch (e) {}
  }

  void _loadNearbyProducts() {
    if (!_hasMapCenter) return;

    ApiRepository.shared.allProducts(
      (List) {
        if (!mounted) return;

        if (List.data == null || List.data!.isEmpty) {
          setState(() {
            _nearbyProducts = [];
          });
          _addProductMarkers();
          return;
        }

        setState(() {
          _nearbyProducts =
              List.data!.map((product) {
                return {
                  'id': product.id.toString(),
                  'name': product.name ?? 'Unknown Product',
                  'price': product.price?.toString() ?? '0',
                  'image': product.image ?? '',
                  'stars': product.stars ?? '0',
                  'length': product.length ?? '0',
                  'latitude': product.latitude ?? '',
                  'longitude': product.longitude ?? '',
                };
              }).toList();
        });
        _addProductMarkers();
      },
      (error) {
        if (!mounted) return;
        setState(() {
          _nearbyProducts = [];
        });
        _addProductMarkers();
      },
    );
  }

  String _productImageUrl(dynamic imagePath) {
    final path = imagePath?.toString().trim() ?? '';
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return AppUrl.baseUrlM + path;
  }

  Future<BitmapDescriptor> _getProductMarker(
    String productName,
    String imagePath,
  ) async {
    final cacheKey = imagePath.trim().isNotEmpty ? imagePath.trim() : productName;
    final cached = _markerIconCache[cacheKey];
    if (cached != null) return cached;

    final imageUrl = _productImageUrl(imagePath);
    if (imageUrl.isEmpty) {
      final fallback = BitmapDescriptor.defaultMarkerWithHue(
        (productName.hashCode % 360).toDouble(),
      );
      _markerIconCache[cacheKey] = fallback;
      return fallback;
    }

    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('marker image request failed');
      }

      final codec = await ui.instantiateImageCodec(
        response.bodyBytes,
        targetWidth: 120,
        targetHeight: 120,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      const double size = 96;
      const double border = 3;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final center = Offset(size / 2, size / 2);

      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(center.translate(0, 2), size / 2 - 2, shadowPaint);

      canvas.drawCircle(
        center,
        size / 2 - 2,
        Paint()..color = Colors.white,
      );

      final clipPath = Path()
        ..addOval(Rect.fromCircle(
          center: center,
          radius: size / 2 - border - 2,
        ));
      canvas.save();
      canvas.clipPath(clipPath);
      paintImage(
        canvas: canvas,
        rect: Rect.fromCircle(
          center: center,
          radius: size / 2 - border - 2,
        ),
        image: image,
        fit: BoxFit.cover,
      );
      canvas.restore();

      canvas.drawCircle(
        center,
        size / 2 - border - 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.primaryColor,
      );

      final picture = recorder.endRecording();
      final markerImage = await picture.toImage(size.toInt(), size.toInt());
      final byteData =
          await markerImage.toByteData(format: ui.ImageByteFormat.png);
      final icon = BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
      _markerIconCache[cacheKey] = icon;
      return icon;
    } catch (_) {
      final fallback = BitmapDescriptor.defaultMarkerWithHue(
        (productName.hashCode % 360).toDouble(),
      );
      _markerIconCache[cacheKey] = fallback;
      return fallback;
    }
  }

  void _addProductMarkers() async {
    if (!_hasMapCenter) return;

    final centerLat = _mapCenterLatitude!;
    final centerLng = _mapCenterLongitude!;
    final maxDistanceMiles = _mapRadiusMiles;
    final searchLabel =
        _resolvedAddress?.displayLine.trim().isNotEmpty == true
            ? _resolvedAddress!.displayLine
            : 'Search area';

    Set<Marker> newMarkers = {};

    newMarkers.add(
      Marker(
        markerId: const MarkerId('searchCenter'),
        position: LatLng(centerLat, centerLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: 'Search location',
          snippet: searchLabel,
        ),
      ),
    );

    for (var product in _nearbyProducts) {
      if (product['latitude'] == null || product['longitude'] == null) {
        continue;
      }

      final lat = double.tryParse(product['latitude'].toString());
      final lng = double.tryParse(product['longitude'].toString());

      if (lat == null || lng == null || (lat == 0.0 && lng == 0.0)) {
        continue;
      }

      final distanceMiles =
          Geolocator.distanceBetween(centerLat, centerLng, lat, lng) /
          1609.344;

      if (distanceMiles > maxDistanceMiles) {
        continue;
      }

      BitmapDescriptor markerIcon = await _getProductMarker(
        product['name'],
        product['image'] ?? '',
      );

      newMarkers.add(
        Marker(
          markerId: MarkerId(product['id'].toString()),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: product['name'],
            snippet: '\$${product['price']}',
          ),
          icon: markerIcon,
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _markers = newMarkers;
    });
  }

  void _showLocationDisabledDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Services Disabled'),
          content: Text('Please enable location services to use this feature.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Permission Required'),
          content: Text(
            'This app needs location permission to show nearby rentals.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3F1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        color: Color(0xFFE05848),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Error',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1B1B1F),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF72747A),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'OK',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFullScreenMap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                title: Text('Map View'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.black),
                actions: [
                  IconButton(
                    icon: Icon(Icons.my_location, color: darkBlue),
                    onPressed: () {
                      final lat = _mapCenterLatitude;
                      final lng = _mapCenterLongitude;
                      if (_mapController != null && lat != null && lng != null) {
                        _mapController!.animateCamera(
                          CameraUpdate.newLatLng(LatLng(lat, lng)),
                        );
                      }
                    },
                    tooltip: 'My Location',
                  ),
                ],
              ),
              body: Stack(
                children: [
                  Container(
                    child:
                        _isLocationLoading
                            ? Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
                            : GoogleMap(
                              initialCameraPosition: _initialCameraPosition,
                              onMapCreated: (GoogleMapController controller) {
                                _mapController = controller;
                              },
                              markers: _markers,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: false,
                              // Disable default to use custom
                              zoomControlsEnabled: false,
                              // Disable default to use custom
                              mapToolbarEnabled: true,
                            ),
                  ),
                  // Custom zoom controls
                  Positioned(
                    right: 16,
                    top: 100,
                    child: Column(
                      children: [
                        // Zoom in button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(Icons.add, color: darkBlue),
                            onPressed: () {
                              if (_mapController != null) {
                                _mapController!.animateCamera(
                                  CameraUpdate.zoomIn(),
                                );
                              }
                            },
                            tooltip: 'Zoom In',
                          ),
                        ),
                        SizedBox(height: 8),
                        // Zoom out button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(Icons.remove, color: darkBlue),
                            onPressed: () {
                              if (_mapController != null) {
                                _mapController!.animateCamera(
                                  CameraUpdate.zoomOut(),
                                );
                              }
                            },
                            tooltip: 'Zoom Out',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Custom my location button
                  Positioned(
                    right: 16,
                    bottom: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.my_location, color: darkBlue),
                        onPressed: () {
                          if (_mapController != null &&
                              _currentPosition != null) {
                            _mapController!.animateCamera(
                              CameraUpdate.newLatLng(
                                LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                              ),
                            );
                          }
                        },
                        tooltip: 'My Location',
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  // ... existing methods (getCategory, getSubCategory, etc.) remain the same
  getCategory() {
    ApiRepository.shared.getCategoryList(
      (List) => {
        if (this.mounted)
          {
            if (List.data!.length == 0)
              {
                setState(() {
                  isError = true;
                  isLoading = false;
                }),
              }
            else
              {
                setState(() {
                  // Ensure unique items by using a Map to remove duplicates
                  Map<String, String> uniqueItems = {};
                  for (int i = 0; i < List.data!.length; i++) {
                    String name = List.data![i].name.toString();
                    String id = List.data![i].id.toString();
                    if (!uniqueItems.containsKey(name)) {
                      uniqueItems[name] = id;
                    }
                  }
                  items = uniqueItems.keys.toList();
                  items_id = uniqueItems.values.toList();
                  isLoading = false;
                  isError = false;
                }),
              },
          },
      },
      (error) => {
        if (this.mounted)
          {
            if (error != null)
              {
                setState(() {
                  isError = true;
                  isLoading = false;
                }),
              },
          },
      },
    );
  }

  getSubCategory(id) {
    setState(() {
      sub_categoryLoader = true;
      sub_categoryError = false;
      subCategoryVisibility = false;
    });

    ApiRepository.shared.getSubCategoryList(
      (List) => {
        if (this.mounted)
          {
            if (List.data!.length == 0)
              {
                setState(() {
                  sub_categoryError = true;
                  sub_categoryLoader = false;
                  subCategoryVisibility = false;
                }),
              }
            else
              {
                setState(() {
                  // Ensure unique sub-items by using a Map to remove duplicates
                  Map<String, String> uniqueSubItems = {};
                  for (int i = 0; i < List.data!.length; i++) {
                    String name = List.data![i].name.toString();
                    String id = List.data![i].id.toString();
                    if (!uniqueSubItems.containsKey(name)) {
                      uniqueSubItems[name] = id;
                    }
                  }
                  sub_items = uniqueSubItems.keys.toList();
                  sub_items_id = uniqueSubItems.values.toList();
                  sub_categoryLoader = false;
                  sub_categoryError = false;
                  subCategoryVisibility = true;
                }),
              },
          },
      },
      (error) => {
        if (this.mounted)
          {
            if (error != null)
              {
                setState(() {
                  sub_categoryError = true;
                  sub_categoryLoader = false;
                  subCategoryVisibility = false;
                }),
              },
          },
      },
      id,
    );
  }

  getData(url) {
    setState(() {
      filteredData = true;
    });
    ApiRepository.shared.filteredData(
      (List) => {
        if (this.mounted)
          {
            if (List.data!.length == 0)
              {
                setState(() {
                  emptyFilteredData = true;
                  filteredData = false;
                  filteredError = false;
                }),
                showAppSnackbar('No results', 'No data found'),
              }
            else
              {
                setState(() {
                  emptyFilteredData = false;
                  filteredData = false;
                  filteredError = false;
                }),
                Get.to(() => FilteredData(subCatname: sub_dropdownvalue)),
              },
          },
      },
      (error) => {
        if (error != null)
          {
            setState(() {
              filteredError = true;
            }),
            showAppErrorSnackbar('Error occurred'),
          },
      },
      url,
    );
    setState(() {
      filteredData = false;
    });
  }

  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _rangeTitleFormat = DateFormat('MMM d');

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isWithinSelectedRange(DateTime day) {
    final d = _dateOnly(day);
    final start = _dateOnly(selectedDate);
    final end = _dateOnly(selectedDate1);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  DateTime _lastAllowedDate() {
    final now = DateTime.now();
    return DateTime(now.year + 1, now.month, now.day);
  }

  void _selectCalendarDay(DateTime day) {
    final today = _dateOnly(DateTime.now());
    final last = _dateOnly(_lastAllowedDate());
    if (day.isBefore(today) || day.isAfter(last)) return;

    setState(() {
      if (!_isSelectingEnd) {
        selectedDate = day;
        selectedDate1 = day;
        fromDate = _apiDateFormat.format(day);
        toDate = _apiDateFormat.format(day);
        _isSelectingEnd = true;
        return;
      }

      if (day.isBefore(_dateOnly(selectedDate))) {
        selectedDate = day;
        selectedDate1 = day;
      } else {
        selectedDate1 = day;
        _isSelectingEnd = false;
      }
      fromDate = _apiDateFormat.format(selectedDate);
      toDate = _apiDateFormat.format(selectedDate1);
    });
  }

  void _shiftCalendarMonth(int delta) {
    final now = DateTime.now();
    final earliest = DateTime(now.year, now.month);
    final latest = DateTime(_lastAllowedDate().year, _lastAllowedDate().month);
    final next = DateTime(_calendarMonth.year, _calendarMonth.month + delta);
    if (next.isBefore(earliest) || next.isAfter(latest)) return;
    setState(() => _calendarMonth = next);
  }

  void initState() {
    getCategory();
    _getCurrentLocation();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var res_height = MediaQuery.of(context).size.height;
    var res_width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Find Rentals',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              children: [
                //   "Reset",
                //   style: TextStyle(color: Colors.grey, fontSize: 18),
                // ),
                SizedBox(width: 5),
                Container(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        Latitiude = null;
                        Longitude = null;
                        _resolvedAddress = const ParsedUsAddress();
                        _locationController.text = "";
                        radius = 0;
                        price = 50;
                        toDate = null;
                        fromDate = null;
                        _Pvalue = 50;
                        _distanceValue = 10.0;
                        selectedDate = DateTime.now();
                        selectedDate1 = DateTime.now();
                        _calendarMonth = DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                        );
                        _isSelectingEnd = false;
                        _showMap = false;
                        dropdownValue = null;
                        sub_dropdownvalue = null;
                        selected_sub_id = null;
                        sub_items = [];
                        sub_items_id = [];
                        subCategoryVisibility = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: Image.asset(
                      'assets/images/refresh.png',
                      color: Colors.black,
                      width: 25,
                      height: 25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body:
          notSearch
              ? Container(
                width: double.infinity,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(left: 15, right: 15, bottom: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: res_height * 0.015),

                        // Location Section with Map Toggle
                        _buildLocationSection(res_width, res_height),

                        SizedBox(height: res_height * 0.02),

                        // Map View (if enabled)


                        // Distance Filter
                        _buildDistanceFilter(res_width, res_height),

                        SizedBox(height: res_height * 0.02),

                        // Date Range Section
                        _buildDateRangeSection(res_width, res_height),

                        SizedBox(height: res_height * 0.02),

                        // Category Section
                        _buildCategorySection(res_width, res_height),

                        SizedBox(height: res_height * 0.02),

                        // Price Range Section
                        _buildPriceRangeSection(res_width, res_height),

                        SizedBox(height: res_height * 0.03),

                        // Search Button
                        _buildSearchButton(res_width, res_height),

                        SizedBox(height: res_height * 0.04),
                      ],
                    ),
                  ),
                ),
              )
              : Container(child: Text("Searched")),
    );
  }

  Widget _buildLocationSection(double res_width, double res_height) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Location',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Row(
                  children: [
                    Icon(Icons.my_location, color: darkBlue, size: 20),
                    SizedBox(width: 8),
                    Switch(
                      value: _showMap,
                      onChanged: (value) {
                        setState(() {
                          _showMap = value;
                        });
                      },
                      activeColor: AppColors.primaryColor,
                    ),
                    Text('Map', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            AddressAutocompleteField(
              controller: _locationController,
              resolvedAddress: _resolvedAddress,
              onEditingStarted: _clearResolvedAddress,
              onAddressSelected: _applySelectedAddress,
              hint: 'Enter location or use current location',
              promptForMissingFields: false,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.location_pin,
                  color: AppColors.primaryColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.darkGreyColor,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.primaryColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                hintText: 'Enter location or use current location',
              ),
            ),
            if (_showMap) SizedBox(height: 15),
            if (_showMap) _buildMapSection(res_width, res_height),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection(double res_width, double res_height) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 225,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              _isLocationLoading
                  ? Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
                  : GoogleMap(
                    key: ValueKey('map_${_markers.length}'),
                    // Force rebuild when markers change
                    initialCameraPosition: _initialCameraPosition,
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                      print(
                        'DEBUG: Map created with ${_markers.length} markers',
                      );
                    },
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                    onCameraMove: (position) {
                      print(
                        'DEBUG: Camera moved to: ${position.target.latitude}, ${position.target.longitude}',
                      );
                    },
                  ),
              // Full screen button
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.fullscreen, color: darkBlue),
                    onPressed: () {
                      _showFullScreenMap();
                    },
                    tooltip: 'Full Screen Map',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistanceFilter(double res_width, double res_height) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Distance Filter',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Row(
                  children: [
                    Icon(Icons.radar, color: darkBlue),
                    SizedBox(width: 8),
                    Text(
                      '${_distanceValue.toStringAsFixed(1)} miles radius',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Slider(
              value: _distanceValue,
              min: 1.0,
              max: 50.0,
              divisions: 49,
              activeColor: AppColors.primaryColor,
              inactiveColor: AppColors.darkGreyColor,
              onChanged: (value) {
                setState(() {
                  _distanceValue = value;
                  radius = value.toInt();
                });
                _addProductMarkers();
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1 mile',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  '50 miles',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSection(double res_width, double res_height) {
    final today = _dateOnly(DateTime.now());
    final lastAllowed = _lastAllowedDate();
    final start = _dateOnly(selectedDate);
    final end = _dateOnly(selectedDate1);
    final monthFirst = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final int leadingEmpty = monthFirst.weekday % 7;
    final int daysInMonth =
        DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    final bool isSingleDaySelection = _isSameDay(start, end);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rental Period',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: const Color(0xFF1B1B1F),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: Color(0xFF0A143D),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${_rangeTitleFormat.format(start)} - ${_rangeTitleFormat.format(end)}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0A143D),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _monthButton(Icons.chevron_left, () => _shiftCalendarMonth(-1)),
                      Expanded(
                        child: Center(
                          child: Text(
                            DateFormat('MMMM yyyy').format(_calendarMonth),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0A143D),
                            ),
                          ),
                        ),
                      ),
                      _monthButton(
                        Icons.chevron_right,
                        () => _shiftCalendarMonth(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: const ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                        .map(
                          (d) => Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF59689A),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 4),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: leadingEmpty + daysInMonth,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 0,
                      childAspectRatio: 1.3,
                    ),
                    itemBuilder: (context, index) {
                      if (index < leadingEmpty) return const SizedBox.shrink();
                      final dayNum = index - leadingEmpty + 1;
                      final day = DateTime(
                        _calendarMonth.year,
                        _calendarMonth.month,
                        dayNum,
                      );
                      final disabled = day.isBefore(today) || day.isAfter(lastAllowed);
                      final isStart = _isSameDay(day, start);
                      final isEnd = _isSameDay(day, end);
                      final inRange = _isWithinSelectedRange(day);
                      final row = index ~/ 7;

                      bool hasLeftInRange = false;
                      if (index > 0 && (index - 1) ~/ 7 == row) {
                        final prev = dayNum - 1;
                        if (prev >= 1) {
                          final prevDay = DateTime(
                            _calendarMonth.year,
                            _calendarMonth.month,
                            prev,
                          );
                          final prevDisabled =
                              prevDay.isBefore(today) || prevDay.isAfter(lastAllowed);
                          hasLeftInRange = !prevDisabled && _isWithinSelectedRange(prevDay);
                        }
                      }

                      bool hasRightInRange = false;
                      if ((index + 1) ~/ 7 == row) {
                        final next = dayNum + 1;
                        if (next <= daysInMonth) {
                          final nextDay = DateTime(
                            _calendarMonth.year,
                            _calendarMonth.month,
                            next,
                          );
                          final nextDisabled =
                              nextDay.isBefore(today) || nextDay.isAfter(lastAllowed);
                          hasRightInRange = !nextDisabled && _isWithinSelectedRange(nextDay);
                        }
                      }

                      Color textColor = const Color(0xFF0A143D);
                      BoxDecoration? rangeDeco;
                      BoxDecoration? dayDeco;
                      Alignment dayAlignment = Alignment.center;
                      if (disabled) {
                        textColor = const Color(0xFFB8BED1);
                      } else if (inRange && !isSingleDaySelection) {
                        rangeDeco = BoxDecoration(
                          color: const Color(0xFFDCE1EB),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(hasLeftInRange ? 0 : 10),
                            bottomLeft: Radius.circular(hasLeftInRange ? 0 : 10),
                            topRight: Radius.circular(hasRightInRange ? 0 : 10),
                            bottomRight: Radius.circular(hasRightInRange ? 0 : 10),
                          ),
                        );
                      }
                      if (!disabled && (isStart || isEnd)) {
                        dayDeco = BoxDecoration(
                          color: const Color(0xFF0A143D),
                          borderRadius: BorderRadius.circular(10),
                        );
                        textColor = Colors.white;
                        if (isStart && hasRightInRange) {
                          dayAlignment = Alignment.centerLeft;
                        } else if (isEnd && hasLeftInRange) {
                          dayAlignment = Alignment.centerRight;
                        }
                      }

                      const double dayExtent = 30;
                      return GestureDetector(
                        onTap: disabled ? null : () => _selectCalendarDay(day),
                        child: Container(
                          decoration: rangeDeco,
                          alignment: dayAlignment,
                          child: Container(
                            width: dayExtent,
                            height: dayExtent,
                            decoration: dayDeco,
                            alignment: Alignment.center,
                            child: Text(
                              '$dayNum',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight:
                                    (isStart || isEnd) ? FontWeight.w700 : FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isSelectingEnd
                        ? 'Select an end date'
                        : 'Select a start date to adjust your range',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF72747A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'From: ${DateFormat('MM/dd/yyyy').format(selectedDate)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF72747A),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'To: ${DateFormat('MM/dd/yyyy').format(selectedDate1)}',
                    textAlign: TextAlign.end,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF72747A),
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

  Widget _buildCategorySection(double res_width, double res_height) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Please select category',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 5),

            Container(
              height: 50,
              child:
                  isLoading
                      ? Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
                      : _buildDropdownField(
                        value: dropdownValue,
                        hint: "Select Category",
                        items: items,
                        onChanged: (String? value) {
                          setState(() {
                            dropdownValue = value;
                            sub_dropdownvalue = null;
                            selected_sub_id = null;
                            sub_items = [];
                            sub_items_id = [];
                            subCategoryVisibility = false;

                            if (value != null && items.contains(value)) {
                              selected_id = items_id[items.indexOf(value)];
                              getSubCategory(selected_id);
                            }
                          });
                        },
                      ),
            ),
            SizedBox(height: 16),
            Visibility(
              visible: subCategoryVisibility,
              child: Container(
                height: 50,
                child:
                    sub_categoryLoader
                        ? Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Please select a category first",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        )
                        : _buildDropdownField(
                          value: sub_dropdownvalue,
                          hint: "Select Sub Category",
                          items: sub_items,
                          onChanged: (String? value) {
                            setState(() {
                              sub_dropdownvalue = value;
                              if (value != null && sub_items.contains(value)) {
                                selected_sub_id =
                                    sub_items_id[sub_items.indexOf(value)];
                              } else {
                                selected_sub_id = null;
                              }
                            });
                          },
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRangeSection(double res_width, double res_height) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Price Range',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Row(
                  children: [
                    Icon(Icons.attach_money, color: darkBlue),
                    SizedBox(width: 8),
                    Text(
                      'Up to \$${_Pvalue.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Slider(
              value: _Pvalue,
              min: 0,
              max: 1000,
              divisions: 100,
              activeColor: AppColors.primaryColor,
              inactiveColor: AppColors.darkGreyColor,
              onChanged: (value) {
                setState(() {
                  _Pvalue = value;
                  price = int.parse(value.toStringAsFixed(0));
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$0',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$1000',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 22, color: const Color(0xFF0A143D)),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F9),
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          style: GoogleFonts.inter(
            color: const Color(0xFF1B1B1F),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          hint: Text(
            hint,
            style: GoogleFonts.inter(
              color: const Color(0xFF8F9098),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          onChanged: onChanged,
          items: items
              .map<DropdownMenuItem<String>>(
                (String item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1B1B1F),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSearchButton(double res_width, double res_height) {
    return Center(
      child: GestureDetector(
        onTap: () async {
          setState(() {
            filteredData = true;
          });
          String Url = dotenv.env['baseUrlM'] ?? 'No url found';

          if (DateTime.parse(
                selectedDate.toString(),
              ).compareTo(DateTime.parse(selectedDate1.toString())) >
              0) {
            showAppErrorSnackbar('Please select a valid end date', title: 'Required');
            setState(() {
              filteredData = false;
            });
            return;
          }

          final wantsDistance = radius > 0;
          final hasResolvedAddress =
              _resolvedAddress?.hasResolvedMapLocation == true;
          final typedLocation = _locationController.text.trim().isNotEmpty;

          if (typedLocation && !hasResolvedAddress) {
            showAppErrorSnackbar(
              ParsedUsAddress.selectFromSuggestionsMessage,
              title: 'Required',
            );
            setState(() {
              filteredData = false;
            });
            return;
          }

          if (wantsDistance || hasResolvedAddress) {
            final located = await _ensureSearchCoordinates();
            if (wantsDistance && !located) {
              showAppErrorSnackbar(
                hasResolvedAddress
                    ? 'Could not locate that address. Try selecting it again from the list.'
                    : 'Select a location from the suggestions list to use the distance filter',
              );
              setState(() {
                filteredData = false;
              });
              return;
            }
          }

          final searchRadius = _effectiveSearchRadius;
          final useLocationSearch = _hasSearchLocation && searchRadius > 0;

          if (dropdownValue != null && sub_dropdownvalue == null) {
            showAppErrorSnackbar('Please select a sub category', title: 'Required');
            setState(() {
              filteredData = false;
            });
            return;
          }

          url = _buildSearchUrl(Url, useLocationSearch: useLocationSearch);
          getData(url);
        },
        child: Container(
          height: 58,
          width: 380,
          child: Center(
            child: Text(
              filteredData ? "Loading" : 'Find Rentals',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ... existing helper methods remain the same
  Fields() {
    return Container(
      child: TextFormField(
        autocorrect: false,
        style: TextStyle(color: Colors.grey),
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0)),
          enabledBorder: const OutlineInputBorder(
            borderSide: const BorderSide(color: kprimaryColor, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: const BorderSide(color: kprimaryColor, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
          filled: true,
          hintStyle: TextStyle(color: Colors.grey),
          hintText: "United State Of America",
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Brands(img) {
    return Container(
      width: 71,
      height: 71,
      decoration: BoxDecoration(
        border: Border.all(color: kprimaryColor),
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      child: Image.asset(img, scale: 2.3),
    );
  }

}
