import 'package:intl/intl.dart';

// Main response model from the API
class MarketDataResponse {
  final int totalCount;
  final int count;
  final int limit;
  final int offset;
  final List<MarketRecord> records;

  MarketDataResponse({
    required this.totalCount,
    required this.count,
    required this.limit,
    required this.offset,
    required this.records,
  });

  factory MarketDataResponse.fromJson(Map<String, dynamic> json) {
    final recordsJson = json['records'] as List<dynamic>;
    final records = recordsJson
        .map((recordJson) => MarketRecord.fromJson(recordJson))
        .toList();

    return MarketDataResponse(
      totalCount: int.tryParse(json['total'].toString()) ?? 0,
      count: int.tryParse(json['count'].toString()) ?? 0,
      limit: int.tryParse(json['limit'].toString()) ?? 0,
      offset: int.tryParse(json['offset'].toString()) ?? 0,
      records: records,
    );
  }
}

// Individual market record from API
class MarketRecord {
  final String state;
  final String district;
  final String market;
  final String commodity;
  final String variety;
  final String grade;
  final DateTime arrivalDate;
  final double minPrice;
  final double maxPrice;
  final double modalPrice;
  final double quantity;
  final double arrivalQuantity;

  // Getter for formatted arrival date as string
  String get arrivalDateFormatted =>
      DateFormat('dd/MM/yyyy').format(arrivalDate);

  MarketRecord({
    required this.state,
    required this.district,
    required this.market,
    required this.commodity,
    required this.variety,
    required this.grade,
    required this.arrivalDate,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
    required this.quantity,
    required this.arrivalQuantity,
  });

  factory MarketRecord.fromJson(Map<String, dynamic> json) {
    // Parse date from dd/MM/yyyy format
    DateTime arrivalDate;
    try {
      arrivalDate = DateFormat('dd/MM/yyyy').parse(json['arrival_date'] ?? '');
    } catch (e) {
      arrivalDate = DateTime.now(); // Fallback to today
    }

    return MarketRecord(
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      market: json['market'] ?? '',
      commodity: json['commodity'] ?? '',
      variety: json['variety'] ?? '',
      grade: json['grade'] ?? 'Standard',
      arrivalDate: arrivalDate,
      minPrice: _parsePrice(json['min_price']),
      maxPrice: _parsePrice(json['max_price']),
      modalPrice: _parsePrice(json['modal_price']),
      quantity: _parseQuantity(json['arrival_quantity']),
      arrivalQuantity: _parseQuantity(json['arrival_quantity']),
    );
  }

  // Helper to parse price values that may be strings
  static double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Helper to parse quantity values
  static double _parseQuantity(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}

// Price trend for a commodity over time
class PriceTrend {
  final DateTime date;
  final double price;
  final double quantity;

  PriceTrend({
    required this.date,
    required this.price,
    required this.quantity,
  });
}

// Summary for daily market dashboard
class DailyMarketSummary {
  final String date;
  final List<CommoditySummary> topCommodities;
  final List<MarketVolatility> topVolatileMarkets;
  final List<StateArrival> stateArrivals;

  DailyMarketSummary({
    required this.date,
    required this.topCommodities,
    required this.topVolatileMarkets,
    required this.stateArrivals,
  });
}

// Market comparison model
class CommoditySummary {
  final String commodity;
  final double averagePrice;
  final int priceCount;

  CommoditySummary({
    required this.commodity,
    required this.averagePrice,
    required this.priceCount,
  });
}

// Market volatility for dashboard
class MarketVolatility {
  final String state;
  final String district;
  final String market;
  final String commodity;
  final double minPrice;
  final double maxPrice;
  final double volatility;

  MarketVolatility({
    required this.state,
    required this.district,
    required this.market,
    required this.commodity,
    required this.minPrice,
    required this.maxPrice,
    required this.volatility,
  });

  String get marketName => '$market, $district';
}

// State arrival for dashboard
class StateArrival {
  final String state;
  final double totalQuantity;

  StateArrival({
    required this.state,
    required this.totalQuantity,
  });
}

// Commodity price map for heatmap
class CommodityPriceMap {
  final String state;
  final double averagePrice;
  final int count;

  CommodityPriceMap({
    required this.state,
    required this.averagePrice,
    required this.count,
  });
}

// Crop recommendation model
class CropRecommendation {
  final String commodity;
  final double growthPercent;
  final double startPrice;
  final double endPrice;
  final List<PriceTrend> trend;

  // Additional properties for recommendation data
  String? priceTrend; // 'up', 'down', or 'stable'
  String? recommendation; // 'buy', 'sell', 'hold', 'watch', or 'stable'
  String? recommendationText; // User-friendly text of recommendation
  String? reasoningText; // Explanation for the recommendation
  double? confidenceScore; // 0-100 confidence score
  double? currentPrice; // Latest price
  String? commodityName; // Commodity name for display
  List<double>? priceHistory; // Historical price points

  CropRecommendation({
    required this.commodity,
    required this.growthPercent,
    required this.startPrice,
    required this.endPrice,
    required this.trend,
    this.priceTrend,
    this.recommendation,
    this.recommendationText,
    this.reasoningText,
    this.confidenceScore,
    this.currentPrice,
    this.commodityName,
    this.priceHistory,
  });
}

// Market comparison model
class MarketComparison {
  final String market;
  final String state;
  final double price;
  final double quantity;
  final double modalPrice;
  final double minPrice;
  final double maxPrice;
  final bool hasData; // Indicates if price data is available for this market

  MarketComparison({
    required this.market,
    required this.state,
    required this.price,
    required this.quantity,
    required this.modalPrice,
    required this.minPrice,
    required this.maxPrice,
    this.hasData = true, // Default to true for backward compatibility
  });
}

// Pinned commodity model
class PinnedCommodity {
  final String id;
  final String userId;
  final String commodity;
  final String state;
  final String? district;
  final String? market;
  final DateTime createdAt;
  final DateTime? pinnedAt; // When the commodity was pinned
  double currentPrice;
  double priceChange;
  double initialPrice;
  DateTime lastUpdated;

  PinnedCommodity({
    required this.id,
    required this.userId,
    required this.commodity,
    required this.state,
    this.district,
    this.market,
    required this.createdAt,
    this.pinnedAt,
    this.currentPrice = 0.0,
    this.priceChange = 0.0,
    this.initialPrice = 0.0,
    DateTime? lastUpdated,
  }) : this.lastUpdated = lastUpdated ?? DateTime.now();

  factory PinnedCommodity.fromJson(Map<String, dynamic> json) {
    return PinnedCommodity(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      commodity: json['commodity'] ?? '',
      state: json['state'] ?? '',
      district: json['district'],
      market: json['market'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      pinnedAt: json['pinned_at'] != null
          ? DateTime.parse(json['pinned_at'])
          : null,
      currentPrice: json['current_price'] != null && json['current_price'] is num
          ? (json['current_price'] as num).toDouble()
          : 0.0,
      initialPrice: json['initial_price'] != null && json['initial_price'] is num
          ? (json['initial_price'] as num).toDouble()
          : 0.0,
      priceChange: 0.0, // Will be calculated later
    );
  }
}

// Price alert model
class PriceAlert {
  final String id;
  final String userId;
  final String commodity;
  final String state;
  final String? district;
  final String? market;
  final double thresholdPrice;
  final String alertCondition;
  final bool isActive;
  final DateTime? lastTriggeredAt;
  final DateTime createdAt;

  // Aliases for compatibility
  String get condition => alertCondition;
  double get targetPrice => thresholdPrice;
  DateTime? get lastNotified => lastTriggeredAt;

  PriceAlert({
    required this.id,
    required this.userId,
    required this.commodity,
    required this.state,
    this.district,
    this.market,
    required this.thresholdPrice,
    required this.alertCondition,
    required this.isActive,
    this.lastTriggeredAt,
    required this.createdAt,
    lastNotified,
  });

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    // Handle id and user_id as either int or String
    String parseId(dynamic value) => value == null ? '' : value.toString();
    String parseString(dynamic value) => value == null ? '' : value.toString();
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    return PriceAlert(
      id: parseId(json['id']),
      userId: parseId(json['user_id']),
      commodity: parseString(json['commodity']),
      state: parseString(json['state']),
      district: json['district'] != null ? parseString(json['district']) : null,
      market: json['market'] != null ? parseString(json['market']) : null,
      thresholdPrice: parseDouble(json['threshold_price']),
      alertCondition: json['alert_condition'] ?? json['condition_type'] ?? 'above',
      isActive: json['is_active'] is bool ? json['is_active'] : true,
      lastTriggeredAt: json['last_triggered_at'] != null
          ? DateTime.tryParse(json['last_triggered_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
