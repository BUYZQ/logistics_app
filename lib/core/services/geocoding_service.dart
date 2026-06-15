import 'dart:async';

import 'package:yandex_mapkit/yandex_mapkit.dart';

class GeocodedAddress {
  final String query;
  final String formattedAddress;
  final Point point;

  const GeocodedAddress({
    required this.query,
    required this.formattedAddress,
    required this.point,
  });
}

class GeocodedRoute {
  final GeocodedAddress? from;
  final GeocodedAddress? to;

  const GeocodedRoute({
    required this.from,
    required this.to,
  });
}

class GeocodingService {
  static const String _city = 'Нерюнгри';
  static const String _region = 'Республика Саха (Якутия)';
  static const String _country = 'Россия';

  static const Point defaultCenter =
      Point(latitude: 56.6596, longitude: 124.7154);

  static const BoundingBox _neryungriBounds = BoundingBox(
    southWest: Point(latitude: 56.60, longitude: 124.62),
    northEast: Point(latitude: 56.72, longitude: 124.80),
  );

  static const Map<String, Point> _knownAddressPoints = {
    'амгинская 6': Point(latitude: 56.653244, longitude: 124.728539),
    'улица амгинская 6': Point(latitude: 56.653244, longitude: 124.728539),
    'амгинская улица 6': Point(latitude: 56.653244, longitude: 124.728539),
    'ленина 17': Point(latitude: 56.658928, longitude: 124.711894),
    'проспект ленина 17': Point(latitude: 56.658928, longitude: 124.711894),
    'ленина 17/2': Point(latitude: 56.658928, longitude: 124.711894),
    'проспект ленина 17/2': Point(latitude: 56.658928, longitude: 124.711894),
    'карла маркса 17': Point(latitude: 56.662707, longitude: 124.708412),
    'улица карла маркса 17': Point(latitude: 56.662707, longitude: 124.708412),
    'карла маркса улица 17': Point(latitude: 56.662707, longitude: 124.708412),
  };

  static Future<GeocodedRoute> geocodeRoute({
    required String fromAddress,
    required String toAddress,
  }) async {
    final results = await Future.wait<GeocodedAddress?>([
      geocodeAddress(fromAddress),
      geocodeAddress(toAddress),
    ]);

    return GeocodedRoute(
      from: results[0],
      to: results[1],
    );
  }

  static Future<GeocodedAddress?> geocodeAddress(String address) async {
    final normalized = address.trim();
    if (normalized.isEmpty) return null;

    final knownPoint = knownPointForAddress(normalized);
    if (knownPoint != null) {
      return GeocodedAddress(
        query: normalized,
        formattedAddress: _formatKnownAddress(normalized),
        point: knownPoint,
      );
    }

    for (final query in _buildQueries(normalized)) {
      final result = await _searchFirst(query);
      if (result != null) return result;
    }

    return null;
  }

  static List<String> _buildQueries(String address) {
    final lower = address.toLowerCase();
    final queries = <String>[];
    final variants = _buildAddressVariants(address);

    for (final variant in variants) {
      queries.add(variant);

      if (!_containsRegionHint(lower)) {
        queries.add('$variant, $_city');
        queries.add('$_city, $variant');
        queries.add('$variant, $_city, $_region');
        queries.add('$_region, $_city, $variant');
        queries.add('$variant, $_city, $_region, $_country');
      }
    }

    return queries.toSet().toList();
  }

  static Point? knownPointForAddress(String address) {
    return _knownAddressPoints[_normalizeAddress(address)];
  }

  static bool hasKnownPoint(String address) {
    return knownPointForAddress(address) != null;
  }

  static String _formatKnownAddress(String address) {
    final normalized = _normalizeAddress(address);
    if (normalized.contains('амгинская')) {
      return 'улица Амгинская, 6, Нерюнгри';
    }
    if (normalized.contains('ленина')) {
      return 'проспект Ленина, 17, $_city';
    }
    if (normalized.contains('карла маркса')) {
      return 'улица Карла Маркса, 17, $_city';
    }
    return address.trim();
  }

  static String _normalizeAddress(String address) {
    var normalized = address.toLowerCase().trim();
    normalized = normalized.replaceAll(',', ' ');
    normalized = normalized.replaceAll('.', ' ');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    normalized = normalized.replaceAll('проспект', '');
    normalized = normalized.replaceAll('пр-кт', '');
    normalized = normalized.replaceAll('пр.', '');
    normalized = normalized.replaceAll('пр ', '');
    normalized = normalized.replaceAll('улица', '');
    normalized = normalized.replaceAll('ул', '');
    normalized = normalized.replaceAll(RegExp(r'\bг\b'), '');
    normalized = normalized.replaceAll(RegExp(r'\bд\b'), '');
    normalized = normalized.replaceAll('дом', '');
    normalized = normalized.replaceAll('нерюнгри', '');
    normalized = normalized.replaceAll('республика саха якутия', '');
    normalized = normalized.replaceAll('саха якутия', '');
    normalized = normalized.replaceAll('якутия', '');
    normalized = normalized.replaceAll('россия', '');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    return normalized.trim();
  }

  static List<String> _buildAddressVariants(String address) {
    final compact = address.trim().replaceAll(RegExp(r'\s+'), ' ');
    final expanded = compact
        .replaceAll(RegExp(r'\bул\.?\s+', caseSensitive: false), 'улица ')
        .replaceAll(RegExp(r'\bд\.?\s+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final withHouseComma = expanded.replaceFirst(
      RegExp(r'\s+(\d+[а-яa-z]?(/\d+[а-яa-z]?)?)$', caseSensitive: false),
      ', \$1',
    );

    return [
      compact,
      expanded,
      withHouseComma,
    ].where((value) => value.isNotEmpty).toSet().toList();
  }

  static bool _containsRegionHint(String address) {
    const hints = [
      'нерюнгри',
      'якут',
      'саха',
      'россия',
      'республика',
      'область',
      'край',
    ];

    return hints.any(address.contains);
  }

  static Future<GeocodedAddress?> _searchFirst(String query) async {
    SearchSession? session;

    try {
      final resultWithSession = await YandexSearch.searchByText(
        searchText: query,
        geometry: Geometry.fromBoundingBox(_neryungriBounds),
        searchOptions: const SearchOptions(
          searchType: SearchType.geo,
          geometry: false,
          resultPageSize: 5,
          userPosition: defaultCenter,
        ),
      );
      session = resultWithSession.$1;

      final result = await resultWithSession.$2.timeout(
        const Duration(seconds: 10),
      );

      if (result.error != null) return null;

      for (final item in result.items ?? const <SearchItem>[]) {
        final meta = item.toponymMetadata;
        if (meta == null) continue;
        if (!_isInsideNeryungri(meta.balloonPoint)) continue;
        return GeocodedAddress(
          query: query,
          formattedAddress: meta.address.formattedAddress,
          point: meta.balloonPoint,
        );
      }
    } catch (_) {
      return null;
    } finally {
      if (session != null) {
        try {
          await session.close();
        } catch (_) {}
      }
    }

    return null;
  }

  static bool _isInsideNeryungri(Point point) {
    return point.latitude >= _neryungriBounds.southWest.latitude &&
        point.latitude <= _neryungriBounds.northEast.latitude &&
        point.longitude >= _neryungriBounds.southWest.longitude &&
        point.longitude <= _neryungriBounds.northEast.longitude;
  }
}
