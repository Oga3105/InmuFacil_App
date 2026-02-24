import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/api_client.dart';
import '../providers/search_provider.dart'; // To access apiClientProvider

/// State classes could be used, but AsyncValue is sufficient for this simple case
class NotFoundNotifier extends Notifier<AsyncValue<void>> {
  late ApiClient _apiClient;

  @override
  AsyncValue<void> build() {
    _apiClient = ref.watch(apiClientProvider);
    return const AsyncValue.data(null);
  }

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

final notFoundProvider = NotifierProvider<NotFoundNotifier, AsyncValue<void>>(NotFoundNotifier.new);
