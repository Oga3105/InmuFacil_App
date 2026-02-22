import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/datasources/remote/api_client.dart';
import '../providers/search_provider.dart'; // To access apiClientProvider

/// State classes could be used, but AsyncValue is sufficient for this simple case
class NotFoundNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiClient _apiClient;

  NotFoundNotifier(this._apiClient) : super(const AsyncValue.data(null));

  Future<void> submitInterest(String email) async {
    state = const AsyncValue.loading();
    
    try {
      // POST /leads
      await _apiClient.client.post('/leads', data: {'email': email});
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final notFoundProvider = StateNotifierProvider<NotFoundNotifier, AsyncValue<void>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotFoundNotifier(apiClient);
});
