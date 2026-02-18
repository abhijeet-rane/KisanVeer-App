import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:kisan_veer/models/market_models.dart';
import 'package:kisan_veer/services/market_history_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarketService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _baseUrl =
      'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070';
  final MarketHistoryService _historyService = MarketHistoryService();

  // Fetch API key from Supabase secrets table
  Future<String> _getApiKey() async {
    try {
      final response = await _supabase
          .from('secrets')
          .select('key_value')
          .eq('key_name', 'agmarknet_api_key')
          .single();

      return response['key_value'] as String;
    } catch (e) {
      print('Error fetching API key: $e');
      throw Exception('Failed to fetch API key');
    }
  }

  // Build URL with filters
  String _buildUrl({
    required String apiKey,
    required Map<String, String> filters,
    int limit = 100,
    int offset = 0,
  }) {
    String url =
        '$_baseUrl?api-key=$apiKey&format=json&limit=$limit&offset=$offset';

    filters.forEach((key, value) {
      if (value.isNotEmpty) {
        url += '&filters[$key]=$value';
      }
    });

    return url;
  }

  // Fetch market data with filters
  Future<MarketDataResponse> fetchMarketData({
    required Map<String, String> filters,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final apiKey = await _getApiKey();
      final url = _buildUrl(
        apiKey: apiKey,
        filters: filters,
        limit: limit,
        offset: offset,
      );

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MarketDataResponse.fromJson(data);
      } else {
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchMarketData: $e');
      throw Exception('Failed to fetch market data: $e');
    }
  }

  // Get daily market summary
  Future<DailyMarketSummary> getDailyMarketSummary() async {
    try {
      // Get today's date in format YYYY-MM-DD
      final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

      final data = await fetchMarketData(
        filters: {
          'arrival_date': today,
        },
        limit: 6000, // Larger limit to get enough data for analysis
      );

      if (data.records.isEmpty) {
        throw Exception('No market data available for today');
      }

      // Calculate top commodities by price
      final commodityPrices = <String, List<double>>{};
      for (var record in data.records) {
        if (!commodityPrices.containsKey(record.commodity)) {
          commodityPrices[record.commodity] = [];
        }
        if (record.modalPrice > 0) {
          commodityPrices[record.commodity]!.add(record.modalPrice);
        }
      }

      // Calculate average price for each commodity
      final commodityAvgPrices = <CommoditySummary>[];
      commodityPrices.forEach((commodity, prices) {
        if (prices.isNotEmpty) {
          final avgPrice = prices.reduce((a, b) => a + b) / prices.length;
          commodityAvgPrices.add(CommoditySummary(
            commodity: commodity,
            averagePrice: avgPrice,
            priceCount: prices.length,
          ));
        }
      });

      // Sort by average price, descending
      commodityAvgPrices
          .sort((a, b) => b.averagePrice.compareTo(a.averagePrice));

      // Calculate market volatility
      final marketVolatility = <MarketVolatility>[];
      final marketMap = <String, Map<String, List<MarketRecord>>>{};

      // Group by market and commodity
      for (var record in data.records) {
        final key = '${record.state}-${record.district}-${record.market}';
        if (!marketMap.containsKey(key)) {
          marketMap[key] = {};
        }
        if (!marketMap[key]!.containsKey(record.commodity)) {
          marketMap[key]![record.commodity] = [];
        }
        marketMap[key]![record.commodity]!.add(record);
      }

      // Calculate volatility for each market-commodity pair
      marketMap.forEach((marketKey, commodities) {
        commodities.forEach((commodity, records) {
          if (records.length > 1) {
            final prices = records.map((r) => r.modalPrice).toList();
            final minPrice = prices.reduce((a, b) => a < b ? a : b);
            final maxPrice = prices.reduce((a, b) => a > b ? a : b);
            final volatility = maxPrice - minPrice;

            if (volatility > 0) {
              final parts = marketKey.split('-');
              marketVolatility.add(MarketVolatility(
                state: parts[0],
                district: parts[1],
                market: parts[2],
                commodity: commodity,
                minPrice: minPrice,
                maxPrice: maxPrice,
                volatility: volatility,
              ));
            }
          }
        });
      });

      // Sort by volatility, descending
      marketVolatility.sort((a, b) => b.volatility.compareTo(a.volatility));

      // Calculate arrivals by state
      final stateArrivals = <StateArrival>[];
      final stateMap = <String, double>{};

      for (var record in data.records) {
        if (!stateMap.containsKey(record.state)) {
          stateMap[record.state] = 0;
        }
        stateMap[record.state] = stateMap[record.state]! + record.quantity;
      }

      stateMap.forEach((state, quantity) {
        stateArrivals.add(StateArrival(
          state: state,
          totalQuantity: quantity,
        ));
      });

      // Sort by quantity, descending
      stateArrivals.sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));

      return DailyMarketSummary(
        date: today,
        topCommodities: commodityAvgPrices.take(5).toList(),
        topVolatileMarkets: marketVolatility.take(5).toList(),
        stateArrivals: stateArrivals,
      );
    } catch (e, stacktrace) {
      print('Error in getDailyMarketSummary: $e');
      print('❌ Error parsing record: $json');
      print('❌ Exception: $e');
      print('❌ Stacktrace: $stacktrace');
      throw Exception('Failed to fetch daily market summary: $e');
    }
  }

  // Get price trends for a commodity in a market over days
  Future<List<PriceTrend>> getPriceTrends({
    required String commodity,
    required String state,
    String? district,
    String? market,
    required int days,
  }) async {
    try {
      // Use historical data service instead of making multiple API calls
      final records = await _historyService.fetchHistoricalData(
        commodity: commodity,
        state: state,
        district: district,
        market: market,
        days: days,
      );

      if (records.isEmpty) {
        // Fallback to mock data if no historical data
        return _generateMockPriceTrends(commodity, days);
      }

      // Group by date and calculate average prices
      final Map<String, List<MarketRecord>> recordsByDate = {};
      for (var record in records) {
        final dateStr = DateFormat('yyyy-MM-dd').format(record.arrivalDate);
        if (!recordsByDate.containsKey(dateStr)) {
          recordsByDate[dateStr] = [];
        }
        recordsByDate[dateStr]!.add(record);
      }

      // Convert to PriceTrend objects
      final trends = <PriceTrend>[];
      recordsByDate.forEach((dateStr, dateRecords) {
        // Calculate average modal price for this date
        final validPrices =
            dateRecords.map((r) => r.modalPrice).where((p) => p > 0).toList();

        if (validPrices.isNotEmpty) {
          final avgPrice =
              validPrices.reduce((a, b) => a + b) / validPrices.length;
          final avgQuantity = dateRecords
              .map((r) => r.quantity)
              .where((q) => q > 0)
              .fold(0.0, (a, b) => a + b);

          trends.add(PriceTrend(
            date: DateTime.parse(dateStr),
            price: avgPrice,
            quantity: avgQuantity,
          ));
        }
      });

      // Sort by date
      trends.sort((a, b) => a.date.compareTo(b.date));

      // If we don't have enough data points, pad with mock data
      if (trends.length < days) {
        final existingDates =
            trends.map((t) => DateFormat('yyyy-MM-dd').format(t.date)).toSet();
        final today = DateTime.now();

        for (int i = 0; i < days; i++) {
          final date = today.subtract(Duration(days: i));
          final dateStr = DateFormat('yyyy-MM-dd').format(date);

          if (!existingDates.contains(dateStr)) {
            // Only add mock data for dates we don't have real data
            // Use the last real price if available as a starting point
            double basePrice = trends.isNotEmpty ? trends.last.price : 5000.0;

            // Add a small random variation
            final random = Random();
            final variation =
                (random.nextBool() ? 1 : -1) * random.nextDouble() * 100;

            trends.add(PriceTrend(
              date: date,
              price: basePrice + variation,
              quantity: 100.0 + random.nextDouble() * 50,
            ));
          }
        }

        // Re-sort after adding mock data
        trends.sort((a, b) => a.date.compareTo(b.date));

        // Take only the most recent 'days' trends
        if (trends.length > days) {
          trends.removeRange(0, trends.length - days);
        }
      }

      return trends;
    } catch (e) {
      print('Error in getPriceTrends: $e');
      // Fallback to mock data in case of error
      return _generateMockPriceTrends(commodity, days);
    }
  }

  // Helper method to generate mock price trends when needed
  List<PriceTrend> _generateMockPriceTrends(String commodity, int days) {
    final trends = <PriceTrend>[];
    final now = DateTime.now();
    final random = Random();

    // Base price that varies by commodity
    double basePrice = 5000.0;

    // Adjust base price based on commodity
    if (commodity.toLowerCase().contains('rice')) basePrice = 3000.0;
    if (commodity.toLowerCase().contains('wheat')) basePrice = 2200.0;
    if (commodity.toLowerCase().contains('onion')) basePrice = 1500.0;
    if (commodity.toLowerCase().contains('potato')) basePrice = 1200.0;
    if (commodity.toLowerCase().contains('tomato')) basePrice = 1800.0;

    for (var i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: days - i - 1));
      // Create a slight upward or downward trend with small variations
      final variation =
          (random.nextBool() ? 1 : -1) * (i * 10 + (random.nextInt(30)));
      final price = basePrice + variation;

      trends.add(PriceTrend(
        date: date,
        price: price,
        quantity: 100.0 + (random.nextInt(50)),
      ));
    }

    return trends;
  }

  // Get commodity prices across states for heatmap
  Future<List<CommodityPriceMap>> getCommodityPriceMap(String commodity) async {
    try {
      final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

      final data = await fetchMarketData(
        filters: {
          'commodity': commodity,
          'arrival_date': today,
        },
        limit: 1000,
      );

      final stateMap = <String, List<double>>{};

      // Group prices by state
      for (var record in data.records) {
        if (!stateMap.containsKey(record.state)) {
          stateMap[record.state] = [];
        }
        if (record.modalPrice > 0) {
          stateMap[record.state]!.add(record.modalPrice);
        }
      }

      // Calculate average price for each state
      final result = <CommodityPriceMap>[];
      stateMap.forEach((state, prices) {
        if (prices.isNotEmpty) {
          final avgPrice = prices.reduce((a, b) => a + b) / prices.length;
          result.add(CommodityPriceMap(
            state: state,
            averagePrice: avgPrice,
            count: prices.length,
          ));
        }
      });

      return result;
    } catch (e) {
      print('Error in getCommodityPriceMap: $e');
      throw Exception('Failed to fetch commodity price map: $e');
    }
  }

  // Get smart recommendations based on price trends
  Future<List<CropRecommendation>> getSmartRecommendations({
    required String state,
    String? district,
  }) async {
    try {
      // Get list of common commodities
      final commonCommodities = [
        'Wheat',
        'Rice',
        'Maize',
        'Jowar',
        'Bajra',
        'Tur',
        'Moong',
        'Urad',
        'Masur',
        'Gram',
        'Potato',
        'Onion',
        'Tomato',
        'Brinjal',
        'Cabbage',
        'Cauliflower',
        'Okra',
        'Peas',
        'Ginger',
        'Garlic',
        'Cotton',
        'Sugarcane',
        'Soyabean',
        'Groundnut',
        'Mustard',
      ];

      final recommendations = <CropRecommendation>[];

      // For each commodity, check price trend
      for (var commodity in commonCommodities) {
        try {
          final trends = await getPriceTrends(
            commodity: commodity,
            state: state,
            district: district,
            days: 7,
          );

          if (trends.length >= 5) {
            // Enough data points
            // Calculate growth
            final startPrice = trends.first.price;
            final endPrice = trends.last.price;
            final growthPercent = ((endPrice - startPrice) / startPrice) * 100;

            // If growth is positive, add to recommendations
            if (growthPercent > 5) {
              recommendations.add(CropRecommendation(
                commodity: commodity,
                growthPercent: growthPercent,
                startPrice: startPrice,
                endPrice: endPrice,
                trend: trends,
              ));
            }
          }
        } catch (e) {
          // Skip this commodity if there's an error
          print('Error processing $commodity: $e');
          continue;
        }
      }

      // Sort by growth percent descending
      recommendations
          .sort((a, b) => b.growthPercent.compareTo(a.growthPercent));

      return recommendations.take(5).toList();
    } catch (e) {
      print('Error in getSmartRecommendations: $e');
      throw Exception('Failed to generate recommendations: $e');
    }
  }

  // Save a pinned commodity for a user
  Future<void> pinCommodity({
    required String commodity,
    required String state,
    String? district,
    String? market,
    double? currentPrice,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get current price if not provided
      double initialPrice = currentPrice ?? 0.0;
      if (initialPrice == 0.0) {
        try {
          // Try to get from historical data first
          final records = await _historyService.fetchHistoricalData(
            commodity: commodity,
            state: state,
            district: district,
            market: market,
            days: 1, // Just get the most recent day
          );

          if (records.isNotEmpty) {
            final prices =
                records.map((r) => r.modalPrice).where((p) => p > 0).toList();
            if (prices.isNotEmpty) {
              initialPrice = prices.reduce((a, b) => a + b) / prices.length;
            }
          } else {
            // Fallback to AGMARKNET API if no historical data
            final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
            final marketData = await fetchMarketData(
              filters: {
                'commodity': commodity,
                'state': state,
                'district': district ?? '',
                'market': market ?? '',
                'arrival_date': today,
              },
            );

            if (marketData.records.isNotEmpty) {
              final prices = marketData.records
                  .map((r) => r.modalPrice)
                  .where((p) => p > 0)
                  .toList();
              if (prices.isNotEmpty) {
                initialPrice = prices.reduce((a, b) => a + b) / prices.length;
              }
            }
          }
        } catch (e) {
          print('Error fetching initial price: $e');
          // Continue with initialPrice = 0 if there's an error
        }
      }

      await _supabase.from('pinned_commodities').upsert({
        'user_id': userId,
        'commodity': commodity,
        'state': state,
        'district': district,
        'market': market,
        'initial_price': initialPrice,
        'current_price': initialPrice,
        'pinned_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error in pinCommodity: $e');
      throw Exception('Failed to pin commodity: $e');
    }
  }

  // Get user's pinned commodities
  Future<List<PinnedCommodity>> getPinnedCommodities() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('pinned_commodities')
          .select()
          .eq('user_id', userId);

      final pinnedList = (response as List)
          .map((json) => PinnedCommodity.fromJson(json))
          .toList();

      // Fetch historical price data for each pinned commodity
      for (var pinned in pinnedList) {
        try {
          // Get historical data for this commodity
          final records = await _historyService.fetchHistoricalData(
            commodity: pinned.commodity,
            state: pinned.state,
            district: pinned.district,
            market: pinned.market,
            days: 7, // Get a week of data to compare
          );

          if (records.isNotEmpty) {
            // Sort by date, most recent first
            records.sort((a, b) => b.arrivalDate.compareTo(a.arrivalDate));

            // Get most recent price (today or latest available)
            double todayPrice = 0;
            if (records.isNotEmpty) {
              final latestRecords = records
                  .where((r) =>
                      r.arrivalDate.difference(records[0].arrivalDate).inDays ==
                      0)
                  .toList();

              final prices = latestRecords
                  .map((r) => r.modalPrice)
                  .where((p) => p > 0)
                  .toList();

              if (prices.isNotEmpty) {
                todayPrice = prices.reduce((a, b) => a + b) / prices.length;
              }
            }

            // Get price from when this commodity was pinned or the oldest available
            double initialPrice = pinned.initialPrice;

            // If we don't have an initial price stored or it's 0, get it from historical data
            if (initialPrice <= 0 && records.length > 1) {
              // Try to get price closest to when the commodity was pinned
              final pinnedDate = pinned.pinnedAt ??
                  DateTime.now().subtract(const Duration(days: 7));

              // Find records closest to pinned date
              final sortedByProximity = List<MarketRecord>.from(records);
              sortedByProximity.sort((a, b) =>
                  (a.arrivalDate.difference(pinnedDate).inDays.abs()).compareTo(
                      b.arrivalDate.difference(pinnedDate).inDays.abs()));

              // Get the closest match
              if (sortedByProximity.isNotEmpty) {
                final closestDate = sortedByProximity[0].arrivalDate;
                final closestRecords = records
                    .where((r) =>
                        r.arrivalDate.difference(closestDate).inDays == 0)
                    .toList();

                final initialPrices = closestRecords
                    .map((r) => r.modalPrice)
                    .where((p) => p > 0)
                    .toList();

                if (initialPrices.isNotEmpty) {
                  initialPrice = initialPrices.reduce((a, b) => a + b) /
                      initialPrices.length;

                  // Store this initial price in the database for future reference
                  try {
                    await _supabase.from('pinned_commodities').update(
                        {'initial_price': initialPrice}).eq('id', pinned.id);
                  } catch (e) {
                    print('Error updating initial price: $e');
                  }
                }
              }
            }

            // Calculate percentage change
            double percentChange = 0;
            if (initialPrice > 0 && todayPrice > 0) {
              percentChange =
                  ((todayPrice - initialPrice) / initialPrice) * 100;
            }

            pinned.currentPrice = todayPrice;
            pinned.initialPrice = initialPrice;
            pinned.priceChange = percentChange;

            // Update current price in database
            try {
              await _supabase
                  .from('pinned_commodities')
                  .update({'current_price': todayPrice}).eq('id', pinned.id);
            } catch (e) {
              print('Error updating current price: $e');
            }
          }
        } catch (e) {
          print('Error fetching price for ${pinned.commodity}: $e');
          // Keep default values if there's an error
        }
      }

      return pinnedList;
    } catch (e) {
      print('Error in getPinnedCommodities: $e');
      throw Exception('Failed to get pinned commodities: $e');
    }
  }

  // Unpin a commodity
  Future<void> unpinCommodity(String pinnedId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('pinned_commodities')
          .delete()
          .eq('id', pinnedId)
          .eq('user_id', userId);
    } catch (e) {
      print('Error in unpinCommodity: $e');
      throw Exception('Failed to unpin commodity: $e');
    }
  }

  // Create a price alert
  Future<void> createPriceAlert({
    required String commodity,
    required String state,
    String? district,
    String? market,
    required double thresholdPrice,
    required String alertCondition,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase.from('price_alerts').insert({
        'user_id': userId,
        'commodity': commodity,
        'state': state,
        'district': district,
        'market': market,
        'threshold_price': thresholdPrice,
        'condition_type':
            alertCondition, // Changed from alert_condition to condition_type to match DB schema
      });
    } catch (e) {
      print('Error in createPriceAlert: $e');
      throw Exception('Failed to create price alert: $e');
    }
  }

  // Get user's price alerts
  Future<List<PriceAlert>> getPriceAlerts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response =
          await _supabase.from('price_alerts').select().eq('user_id', userId);

      return (response as List)
          .map((json) => PriceAlert.fromJson(json))
          .toList();
    } catch (e) {
      print('Error in getPriceAlerts: $e');
      throw Exception('Failed to get price alerts: $e');
    }
  }

  // Delete a price alert
  Future<void> deletePriceAlert(String alertId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('price_alerts')
          .delete()
          .eq('id', alertId)
          .eq('user_id', userId);
    } catch (e) {
      print('Error in deletePriceAlert: $e');
      throw Exception('Failed to delete price alert: $e');
    }
  }

  // Get unique states from the API
  Future<List<String>> getStates() async {
    try {
      final data = await fetchMarketData(
        filters: {},
        limit: 1000,
      );

      final states = <String>{};
      for (var record in data.records) {
        states.add(record.state);
      }

      return states.toList()..sort();
    } catch (e) {
      print('Error in getStates: $e');
      throw Exception('Failed to get states: $e');
    }
  }

  // Get districts for a state
  Future<List<String>> getDistricts(String state) async {
    try {
      final data = await fetchMarketData(
        filters: {'state': state},
        limit: 1000,
      );

      final districts = <String>{};
      for (var record in data.records) {
        districts.add(record.district);
      }

      return districts.toList()..sort();
    } catch (e) {
      print('Error in getDistricts: $e');
      throw Exception('Failed to get districts: $e');
    }
  }

  // Get markets for a specific commodity
  Future<List<String>> getMarketsForCommodity(String commodity) async {
    try {
      final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

      final data = await fetchMarketData(
        filters: {
          'commodity': commodity,
          'arrival_date': today,
        },
        limit: 1000,
      );

      // Extract unique markets
      final markets = <String>{};
      for (var record in data.records) {
        if (record.market.isNotEmpty) {
          markets.add(record.market);
        }
      }

      return markets.toList()..sort();
    } catch (e) {
      print('Error in getMarketsForCommodity: $e');
      throw Exception('Failed to fetch markets for commodity: $e');
    }
  }

  // Get markets for a district
  Future<List<String>> getMarkets(String state, String district) async {
    try {
      final data = await fetchMarketData(
        filters: {
          'state': state,
          'district': district,
        },
        limit: 1000,
      );

      final markets = <String>{};
      for (var record in data.records) {
        markets.add(record.market);
      }

      return markets.toList()..sort();
    } catch (e) {
      print('Error in getMarkets: $e');
      throw Exception('Failed to get markets: $e');
    }
  }

  // Get commodities traded in a market
  Future<List<String>> getCommodities({
    String? state,
    String? district,
    String? market,
  }) async {
    try {
      final filters = <String, String>{};

      if (state != null && state.isNotEmpty) {
        filters['state'] = state;
      }

      if (district != null && district.isNotEmpty) {
        filters['district'] = district;
      }

      if (market != null && market.isNotEmpty) {
        filters['market'] = market;
      }

      final data = await fetchMarketData(
        filters: filters,
        limit: 1000,
      );

      final commodities = <String>{};
      for (var record in data.records) {
        commodities.add(record.commodity);
      }

      return commodities.toList()..sort();
    } catch (e) {
      print('Error in getCommodities: $e');
      throw Exception('Failed to get commodities: $e');
    }
  }

  // Compare prices of a commodity across different markets
  Future<List<MarketComparison>> compareMarkets({
    required String commodity,
    required List<String> markets,
    required String state,
  }) async {
    try {
      final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
      final result = <MarketComparison>[];

      // Process each market, even if data is not available
      for (var market in markets) {
        try {
          final data = await fetchMarketData(
            filters: {
              'commodity': commodity,
              'state': state,
              'market': market,
              'arrival_date': today,
            },
          );

          if (data.records.isNotEmpty) {
            // Calculate average modal price
            final prices = data.records
                .map((r) => r.modalPrice)
                .where((p) => p > 0)
                .toList();

            if (prices.isNotEmpty) {
              final avgPrice = prices.reduce((a, b) => a + b) / prices.length;
              final totalQuantity = data.records
                  .fold(0.0, (sum, record) => sum + record.quantity);

              // Get min and max prices for this market
              final minPrice = prices.reduce((a, b) => a < b ? a : b);
              final maxPrice = prices.reduce((a, b) => a > b ? a : b);

              result.add(MarketComparison(
                market: market,
                state: state,
                price: avgPrice,
                quantity: totalQuantity,
                modalPrice: avgPrice,
                minPrice: minPrice,
                maxPrice: maxPrice,
                hasData: true,
              ));
            } else {
              // Add market with no price data
              result.add(MarketComparison(
                market: market,
                state: state,
                price: 0,
                quantity: 0,
                modalPrice: 0,
                minPrice: 0,
                maxPrice: 0,
                hasData: false,
              ));
            }
          } else {
            // Add market with no records
            result.add(MarketComparison(
              market: market,
              state: state,
              price: 0,
              quantity: 0,
              modalPrice: 0,
              minPrice: 0,
              maxPrice: 0,
              hasData: false,
            ));
          }
        } catch (e) {
          print('Error processing market $market: $e');
          // Still add the market even if there was an error
          result.add(MarketComparison(
            market: market,
            state: state,
            price: 0,
            quantity: 0,
            modalPrice: 0,
            minPrice: 0,
            maxPrice: 0,
            hasData: false,
          ));
        }
      }

      // Sort by price descending, but put markets with no data at the end
      result.sort((a, b) {
        if (!a.hasData && !b.hasData) return 0;
        if (!a.hasData) return 1;
        if (!b.hasData) return -1;
        return b.price.compareTo(a.price);
      });

      return result;
    } catch (e) {
      print('Error in compareMarkets: $e');
      throw Exception('Failed to compare markets: $e');
    }
  }

  // Get user preferences for market recommendations
  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Use limit(1) instead of single() to avoid errors with multiple rows
      final response = await _supabase
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .limit(1);

      // Check if we got any results
      if (response.isNotEmpty) {
        return response[0];
      } else {
        // Return default values if no preferences found
        return {
          'user_id': userId,
          'preferred_state': '',
          'preferred_crops': [],
          'price_sensitivity': 'medium',
        };
      }
    } catch (e) {
      print('Error in getUserPreferences: $e');
      // Return default values on error
      return {
        'user_id': _supabase.auth.currentUser?.id,
        'preferred_state': '',
        'preferred_crops': [],
        'price_sensitivity': 'medium',
      };
    }
  }

  // Update user preferences for market recommendations
  Future<void> updateUserPreferences({
    required String preferredState,
    required List<String> preferredCrops,
    String priceSensitivity = 'medium',
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if preferences exist
      final existingPrefs = await _supabase
          .from('user_preferences')
          .select('id')
          .eq('user_id', userId);

      final data = {
        'user_id': userId,
        'preferred_state': preferredState,
        'preferred_crops': preferredCrops,
        'price_sensitivity': priceSensitivity,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existingPrefs.isEmpty) {
        // Create new preferences
        await _supabase.from('user_preferences').insert(data);
      } else {
        // Update existing preferences
        await _supabase
            .from('user_preferences')
            .update(data)
            .eq('user_id', userId);
      }
    } catch (e) {
      print('Error in updateUserPreferences: $e');
      throw Exception('Failed to update user preferences: $e');
    }
  }

  // Get crop recommendations based on user preferences
  Future<List<CropRecommendation>> getCropRecommendations({
    required String state,
    required List<String> userCrops,
  }) async {
    try {
      final recommendations = <CropRecommendation>[];

      // If user crops list is empty, use some common crops
      if (userCrops.isEmpty) {
        userCrops = [
          'Wheat',
          'Rice',
          'Potato',
          'Onion',
          'Tomato',
        ];
      }

      // For each crop, check price trend
      for (var commodity in userCrops) {
        try {
          final trends = await getPriceTrends(
            commodity: commodity,
            state: state,
            days: 14,
          );

          if (trends.length >= 5) {
            // Calculate growth over the period
            final startPrice = trends.first.price;
            final endPrice = trends.last.price;
            final growthPercent = ((endPrice - startPrice) / startPrice) * 100;

            // Generate recommendation based on price trend
            String recommendation = '';
            String recommendationText = '';
            String reasoningText = '';
            double confidenceScore = 0.0;

            if (growthPercent > 15) {
              recommendation = 'sell';
              recommendationText = 'Sell Now';
              reasoningText =
                  'Prices have increased significantly by ${growthPercent.toStringAsFixed(1)}% over the last 14 days. This may be a good time to sell.';
              confidenceScore = 85.0;
            } else if (growthPercent > 5) {
              recommendation = 'hold';
              recommendationText = 'Hold';
              reasoningText =
                  'Prices are rising moderately by ${growthPercent.toStringAsFixed(1)}%. Consider holding for potential further increases.';
              confidenceScore = 70.0;
            } else if (growthPercent < -15) {
              recommendation = 'buy';
              recommendationText = 'Buy Now';
              reasoningText =
                  'Prices have decreased significantly by ${growthPercent.abs().toStringAsFixed(1)}%. This may be a good opportunity to buy.';
              confidenceScore = 85.0;
            } else if (growthPercent < -5) {
              recommendation = 'watch';
              recommendationText = 'Watch';
              reasoningText =
                  'Prices are declining by ${growthPercent.abs().toStringAsFixed(1)}%. Monitor the market for potential buying opportunities.';
              confidenceScore = 65.0;
            } else {
              recommendation = 'stable';
              recommendationText = 'Stable';
              reasoningText =
                  'Prices are relatively stable with ${growthPercent.abs().toStringAsFixed(1)}% change. No immediate action recommended.';
              confidenceScore = 60.0;
            }

            final cropRecommendation = CropRecommendation(
              commodity: commodity,
              growthPercent: growthPercent,
              startPrice: startPrice,
              endPrice: endPrice,
              trend: trends,
            );

            // Add additional properties via extension
            cropRecommendation
              ..priceTrend = growthPercent > 0
                  ? 'up'
                  : (growthPercent < 0 ? 'down' : 'stable')
              ..recommendation = recommendation
              ..recommendationText = recommendationText
              ..reasoningText = reasoningText
              ..confidenceScore = confidenceScore
              ..currentPrice = endPrice
              ..commodityName = commodity
              ..priceHistory = trends.map((t) => t.price).toList();

            recommendations.add(cropRecommendation);
          }
        } catch (e) {
          print('Error processing crop $commodity: $e');
          continue;
        }
      }

      // Sort by confidence score descending
      recommendations.sort(
          (a, b) => (b.confidenceScore ?? 0).compareTo(a.confidenceScore ?? 0));

      return recommendations;
    } catch (e) {
      print('Error in getCropRecommendations: $e');
      throw Exception('Failed to generate crop recommendations: $e');
    }
  }

  // Update prices for all pinned commodities
  Future<void> updatePinnedCommodityPrices() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get all pinned commodities
      final response = await _supabase
          .from('pinned_commodities')
          .select()
          .eq('user_id', userId);

      final pinnedList =
          response.map((json) => PinnedCommodity.fromJson(json)).toList();

      if (pinnedList.isEmpty) {
        return; // No pinned commodities to update
      }

      final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

      // Update each pinned commodity
      for (var pinnedCommodity in pinnedList) {
        try {
          // Fetch current price
          final filters = <String, String>{
            'commodity': pinnedCommodity.commodity,
            'state': pinnedCommodity.state,
            'arrival_date': today,
          };

          if (pinnedCommodity.district != null) {
            filters['district'] = pinnedCommodity.district!;
          }

          if (pinnedCommodity.market != null) {
            filters['market'] = pinnedCommodity.market!;
          }

          final data = await fetchMarketData(filters: filters);

          if (data.records.isNotEmpty) {
            // Calculate average modal price
            final prices = data.records
                .map((r) => r.modalPrice)
                .where((p) => p > 0)
                .toList();

            if (prices.isNotEmpty) {
              final avgPrice = prices.reduce((a, b) => a + b) / prices.length;

              // Update pinned commodity
              double priceChange = 0.0;
              if (pinnedCommodity.initialPrice > 0) {
                priceChange = ((avgPrice - pinnedCommodity.initialPrice) /
                        pinnedCommodity.initialPrice) *
                    100;
              } else {
                // If this is the first update, set initial price
                await _supabase.from('pinned_commodities').update({
                  'initial_price': avgPrice,
                }).eq('id', pinnedCommodity.id);
              }

              // Update current price and last updated
              await _supabase.from('pinned_commodities').update({
                'current_price': avgPrice,
                'last_updated': DateTime.now().toIso8601String(),
              }).eq('id', pinnedCommodity.id);
            }
          }
        } catch (e) {
          print(
              'Error updating pinned commodity ${pinnedCommodity.commodity}: $e');
          // Continue with next commodity
          continue;
        }
      }
    } catch (e) {
      print('Error in updatePinnedCommodityPrices: $e');
      throw Exception('Failed to update pinned commodity prices: $e');
    }
  }

  // Update a price alert
  Future<void> updatePriceAlert({
    required String alertId,
    double? thresholdPrice,
    String? alertCondition,
    bool? isActive,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Prepare update data
      final Map<String, dynamic> updateData = {};

      if (thresholdPrice != null) {
        updateData['threshold_price'] = thresholdPrice;
      }

      if (alertCondition != null) {
        updateData['alert_condition'] = alertCondition;
      }

      if (isActive != null) {
        updateData['is_active'] = isActive;
      }

      if (updateData.isNotEmpty) {
        // Add update timestamp
        updateData['updated_at'] = DateTime.now().toIso8601String();

        // Update the alert
        await _supabase
            .from('price_alerts')
            .update(updateData)
            .eq('id', alertId)
            .eq('user_id',
                userId); // Ensure user can only update their own alerts
      }
    } catch (e) {
      print('Error in updatePriceAlert: $e');
      throw Exception('Failed to update price alert: $e');
    }
  }
}
