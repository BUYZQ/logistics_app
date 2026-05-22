import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:logistics_app/app/theme.dart';
import 'package:logistics_app/core/models/order.dart';
import 'package:logistics_app/core/services/geocoding_service.dart';
import 'package:logistics_app/core/services/order_service.dart';
import 'package:logistics_app/core/widgets/status_badge.dart';

// Центр Нерюнгри
const _neryungriCenter = Point(latitude: 56.6596, longitude: 124.7154);
const _samePointThreshold = 0.00015;
const _cameraMinSpan = 0.01;
const _fallbackMinOffsetMeters = 180;
const _fallbackMaxOffsetMeters = 520;

class MapScreen extends StatefulWidget {
  final String orderId;
  const MapScreen({super.key, required this.orderId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Order? _order;
  _ResolvedRoutePoints? _routePoints;
  bool _showInfo = false;
  YandexMapController? _mapCtrl;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final orders = await OrderService.getOrders();
      final order = orders.where((o) => o.id == widget.orderId).firstOrNull;
      if (!mounted) return;

      setState(() {
        _order = order;
        _routePoints = order == null ? null : _buildFallbackRoutePoints(order);
      });
      _updateCamera();

      if (order != null) {
        _loadRealRoutePoints(order);
      }
    } catch (e) {
      // Ignored for now
    }
  }

  @override
  void dispose() {
    _mapCtrl?.dispose();
    super.dispose();
  }

  void _onMapCreated(YandexMapController ctrl) {
    _mapCtrl = ctrl;
    _updateCamera();
  }

  void _updateCamera() {
    final ctrl = _mapCtrl;
    final o = _order;
    if (ctrl == null || o == null) return;

    final routePoints = _displayRoutePoints(o);
    ctrl.moveCamera(
      CameraUpdate.newGeometry(
        Geometry.fromBoundingBox(
          _buildBounds(routePoints.from, routePoints.to),
        ),
      ),
      animation: const MapAnimation(
        type: MapAnimationType.smooth,
        duration: 0.8,
      ),
    );
  }

  List<MapObject> _buildMapObjects(Order o) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final accentColor = isDark ? AppTheme.accent : AppTheme.lAccent;
    final successColor = isDark ? AppTheme.success : AppTheme.lSuccess;

    final routePoints = _displayRoutePoints(o);
    final from = routePoints.from;
    final to = routePoints.to;

    return [
      // Маршрутная линия А→Б
      PolylineMapObject(
        mapId: const MapObjectId('route'),
        polyline: Polyline(points: [from, to]),
        strokeColor: accentColor,
        strokeWidth: 4.0,
      ),
      // Маркер «А» — точка отправки
      PlacemarkMapObject(
        mapId: const MapObjectId('marker_from'),
        point: from,
        opacity: 1.0,
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: BitmapDescriptor.fromAssetImage(
                'packages/yandex_mapkit/lib/assets/icons/ic_dots_orange.png'),
            scale: 2.5,
          ),
        ),
        text: PlacemarkText(
          text: 'А — Отправка',
          style: PlacemarkTextStyle(
            color: accentColor,
            size: 11,
            offset: 14,
          ),
        ),
      ),
      // Маркер «Б» — точка доставки
      PlacemarkMapObject(
        mapId: const MapObjectId('marker_to'),
        point: to,
        opacity: 1.0,
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: BitmapDescriptor.fromAssetImage(
                'packages/yandex_mapkit/lib/assets/icons/ic_dots_orange.png'),
            scale: 2.5,
          ),
        ),
        text: PlacemarkText(
          text: 'Б — Доставка',
          style: PlacemarkTextStyle(
            color: successColor,
            size: 11,
            offset: 14,
          ),
        ),
      ),
    ];
  }

  _ResolvedRoutePoints _displayRoutePoints(Order order) {
    return _routePoints ?? _buildFallbackRoutePoints(order);
  }

  Future<void> _loadRealRoutePoints(Order order) async {
    if (!_needsAddressLookup(order)) return;

    final fallbackRoute = _buildFallbackRoutePoints(order);
    final results = await Future.wait<GeocodedAddress?>([
      GeocodingService.geocodeAddress(order.fromAddress),
      GeocodingService.geocodeAddress(order.toAddress),
    ]);

    if (!mounted || _order?.id != order.id) return;

    final from = results[0]?.point ??
        (_isValidPoint(order.fromLat, order.fromLng)
            ? Point(latitude: order.fromLat, longitude: order.fromLng)
            : fallbackRoute.from);
    final to = results[1]?.point ??
        (_isValidPoint(order.toLat, order.toLng)
            ? Point(latitude: order.toLat, longitude: order.toLng)
            : fallbackRoute.to);

    final routePoints = _stabilizeRoutePoints(
      from: from,
      to: to,
      order: order,
    );

    setState(() {
      _routePoints = routePoints;
    });
    _updateCamera();
  }

  bool _needsAddressLookup(Order order) {
    if (GeocodingService.hasKnownPoint(order.fromAddress) ||
        GeocodingService.hasKnownPoint(order.toAddress)) {
      return true;
    }

    final hasValidFrom = _isValidPoint(order.fromLat, order.fromLng);
    final hasValidTo = _isValidPoint(order.toLat, order.toLng);
    if (!hasValidFrom || !hasValidTo) return true;

    return _pointsTooClose(
      Point(latitude: order.fromLat, longitude: order.fromLng),
      Point(latitude: order.toLat, longitude: order.toLng),
    );
  }

  _ResolvedRoutePoints _buildFallbackRoutePoints(Order order) {
    final knownFrom = GeocodingService.knownPointForAddress(order.fromAddress);
    final knownTo = GeocodingService.knownPointForAddress(order.toAddress);

    var from = knownFrom ??
        _resolvePoint(
          latitude: order.fromLat,
          longitude: order.fromLng,
          seed: 'from:${order.id}:${order.fromAddress}',
          anchor: _neryungriCenter,
        );
    var to = knownTo ??
        _resolvePoint(
          latitude: order.toLat,
          longitude: order.toLng,
          seed: 'to:${order.id}:${order.toAddress}',
          anchor: _neryungriCenter,
        );

    return _stabilizeRoutePoints(from: from, to: to, order: order);
  }

  _ResolvedRoutePoints _stabilizeRoutePoints({
    required Point from,
    required Point to,
    required Order order,
  }) {
    var safeFrom = from;
    var safeTo = to;

    if (_pointsTooClose(safeFrom, safeTo)) {
      final anchor = Point(
        latitude: (safeFrom.latitude + safeTo.latitude) / 2,
        longitude: (safeFrom.longitude + safeTo.longitude) / 2,
      );
      safeFrom = _pointFromSeed(
        'from:${order.id}:${order.fromAddress}',
        anchor: anchor,
      );
      safeTo = _pointFromSeed(
        'to:${order.id}:${order.toAddress}',
        anchor: anchor,
      );
    }

    if (_pointsTooClose(safeFrom, safeTo)) {
      final anchor = Point(
        latitude: (safeFrom.latitude + safeTo.latitude) / 2,
        longitude: (safeFrom.longitude + safeTo.longitude) / 2,
      );
      safeFrom = _pointFromSeed('from:${order.id}', anchor: anchor);
      safeTo = _pointFromSeed('to:${order.id}', anchor: anchor);
    }

    return _ResolvedRoutePoints(from: safeFrom, to: safeTo);
  }

  Point _resolvePoint({
    required double latitude,
    required double longitude,
    required String seed,
    required Point anchor,
  }) {
    if (_isValidPoint(latitude, longitude)) {
      return Point(latitude: latitude, longitude: longitude);
    }
    return _pointFromSeed(seed, anchor: anchor);
  }

  bool _isValidPoint(double latitude, double longitude) {
    final isInRange = latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
    final isZeroPoint = latitude == 0 && longitude == 0;
    return isInRange && !isZeroPoint;
  }

  bool _pointsTooClose(Point a, Point b) {
    return (a.latitude - b.latitude).abs() < _samePointThreshold &&
        (a.longitude - b.longitude).abs() < _samePointThreshold;
  }

  Point _pointFromSeed(String seed, {required Point anchor}) {
    final hash = _hashSeed(seed);
    final angle = (hash % 360) * math.pi / 180;
    final distanceMeters = (_fallbackMinOffsetMeters +
            (hash % (_fallbackMaxOffsetMeters - _fallbackMinOffsetMeters + 1)))
        .toDouble();
    final latOffset = _metersToLat(distanceMeters * math.sin(angle));
    final lngOffset = _metersToLng(
      distanceMeters * math.cos(angle),
      anchor.latitude,
    );

    return Point(
      latitude: anchor.latitude + latOffset,
      longitude: anchor.longitude + lngOffset,
    );
  }

  int _hashSeed(String value) {
    var hash = 0;
    for (final rune in value.runes) {
      hash = ((hash * 31) + rune) & 0x7fffffff;
    }
    return hash;
  }

  double _metersToLat(double meters) => meters / 111320;

  double _metersToLng(double meters, double latitude) {
    final safeCosine = math.max(0.2, math.cos(latitude * math.pi / 180).abs());
    return meters / (111320 * safeCosine);
  }

  BoundingBox _buildBounds(Point from, Point to) {
    final north = math.max(from.latitude, to.latitude);
    final south = math.min(from.latitude, to.latitude);
    final east = math.max(from.longitude, to.longitude);
    final west = math.min(from.longitude, to.longitude);

    final latPadding = math.max((north - south) * 0.18, _cameraMinSpan / 2);
    final lngPadding = math.max((east - west) * 0.18, _cameraMinSpan / 2);

    return BoundingBox(
      northEast: Point(
        latitude: north + latPadding,
        longitude: east + lngPadding,
      ),
      southWest: Point(
        latitude: south - latPadding,
        longitude: west - lngPadding,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_order == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final o = _order!;
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;
    final bgColor = isDark ? AppTheme.background : AppTheme.lBackground;
    final cardBorderColor = isDark ? AppTheme.cardBorder : AppTheme.lCardBorder;
    final surfaceColor = isDark ? AppTheme.surface : AppTheme.lSurface;
    final secondaryText =
        isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;
    final accentColor = isDark ? AppTheme.accent : AppTheme.lAccent;
    final successColor = isDark ? AppTheme.success : AppTheme.lSuccess;
    final dividerColor = isDark ? AppTheme.divider : AppTheme.lDivider;

    return Scaffold(
      body: Stack(
        children: [
          // ── Яндекс карта ──────────────────────────────────────────
          YandexMap(
            mapObjects: _buildMapObjects(o),
            onMapCreated: _onMapCreated,
            nightModeEnabled: isDark,
            mapType: MapType.map,
          ),

          // ── Верхняя панель ────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _GlassBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => context.pop(),
                    isDark: isDark,
                    bgColor: bgColor,
                    borderColor: cardBorderColor,
                  ),
                  const Spacer(),
                  _GlassBtn(
                    icon: Icons.info_outline_rounded,
                    onTap: () => setState(() => _showInfo = !_showInfo),
                    active: _showInfo,
                    isDark: isDark,
                    bgColor: bgColor,
                    borderColor: cardBorderColor,
                    accentColor: accentColor,
                  ),
                ],
              ),
            ),
          ),

          // ── Нижняя шторка с инфо ──────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            bottom: _showInfo ? 0 : -280,
            left: 0,
            right: 0,
            child: _OrderInfoSheet(
              order: o,
              surfaceColor: surfaceColor,
              borderColor: cardBorderColor,
              primaryText: primaryText,
              secondaryText: secondaryText,
              dividerColor: dividerColor,
            ),
          ),

          // ── Чип маршрута ──────────────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            bottom: _showInfo ? 280 : 20,
            left: 16,
            child: _RouteChip(
              from: o.fromAddress,
              to: o.toAddress,
              bgColor: bgColor,
              borderColor: cardBorderColor,
              primaryText: primaryText,
              accentColor: accentColor,
              successColor: successColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Кнопка с glassmorphism эффектом ─────────────────────────────────────────

class _ResolvedRoutePoints {
  final Point from;
  final Point to;

  const _ResolvedRoutePoints({
    required this.from,
    required this.to,
  });
}

class _GlassBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final bool isDark;
  final Color bgColor;
  final Color borderColor;
  final Color? accentColor;

  const _GlassBtn({
    required this.icon,
    required this.onTap,
    required this.isDark,
    required this.bgColor,
    required this.borderColor,
    this.active = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active
              ? (accentColor ?? bgColor)
              : bgColor.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(
          icon,
          color:
              active ? Colors.white : (isDark ? Colors.white : Colors.black87),
          size: 18,
        ),
      ),
    );
  }
}

// ─── Чип с адресами маршрута ─────────────────────────────────────────────────

class _RouteChip extends StatelessWidget {
  final String from;
  final String to;
  final Color bgColor;
  final Color borderColor;
  final Color primaryText;
  final Color accentColor;
  final Color successColor;

  const _RouteChip({
    required this.from,
    required this.to,
    required this.bgColor,
    required this.borderColor,
    required this.primaryText,
    required this.accentColor,
    required this.successColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: accentColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(from,
                    style: TextStyle(fontSize: 11, color: primaryText),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: successColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(to,
                    style: TextStyle(fontSize: 11, color: primaryText),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Нижняя шторка с деталями заявки ─────────────────────────────────────────

class _OrderInfoSheet extends StatelessWidget {
  final Order order;
  final Color surfaceColor;
  final Color borderColor;
  final Color primaryText;
  final Color secondaryText;
  final Color dividerColor;

  const _OrderInfoSheet({
    required this.order,
    required this.surfaceColor,
    required this.borderColor,
    required this.primaryText,
    required this.secondaryText,
    required this.dividerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: borderColor, width: 1)),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 24),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(order.number,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: primaryText)),
              const Spacer(),
              StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 12),
          _SheetRow(
              Icons.inventory_2_outlined,
              '${order.cargoName} · ${order.cargoWeight}',
              secondaryText,
              primaryText),
          const SizedBox(height: 8),
          _SheetRow(Icons.location_on_outlined, order.fromAddress,
              secondaryText, primaryText),
          const SizedBox(height: 8),
          _SheetRow(
              Icons.flag_outlined, order.toAddress, secondaryText, primaryText),
          if (order.expeditorName != null) ...[
            const SizedBox(height: 8),
            _SheetRow(Icons.delivery_dining_rounded, order.expeditorName!,
                secondaryText, primaryText),
          ],
        ],
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;
  final Color textColor;

  const _SheetRow(this.icon, this.text, this.iconColor, this.textColor);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 13, color: textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
