import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';
import '../widgets/property/property_card.dart';
import '../../domain/entities/property.dart';
import 'package:go_router/go_router.dart';

class PropertyListingScreen extends ConsumerWidget {
  const PropertyListingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchProvider);
    final properties = searchState.filteredProperties;

    return Scaffold(
      appBar: AppBar(
        title: Text('${properties.length} Propiedades'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: () {
              // TODO: Toggle Map View or Navigate
               context.go('/'); // Back to Map for now
            },
            tooltip: 'Ver Mapa',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar Placeholder
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Expanded(
                  child: SearchBar(
                    hintText: 'Buscar por zona...',
                    leading: const Icon(Icons.search),
                    onSubmitted: (value) {
                      ref.read(searchProvider.notifier).searchCity(value);
                    },
                    elevation: MaterialStateProperty.all(0),
                    backgroundColor: MaterialStateProperty.all(Colors.grey[100]),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    // TODO: Open Advanced Filters
                  },
                ),
              ],
            ),
          ),
          
          // Results List
          Expanded(
            child: searchState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : properties.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: properties.length,
                        itemBuilder: (context, index) {
                          final property = properties[index];
                          return PropertyCard(
                            property: property,
                            onTap: () => _navigateToDetails(context, property),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
           Icon(Icons.home_work_outlined, size: 64, color: Colors.grey[400]),
           const SizedBox(height: 16),
           Text(
             'No se encontraron propiedades',
             style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
           ),
           const SizedBox(height: 8),
           const Text('Intenta ajustar los filtros o buscar en otra zona'),
        ],
      ),
    );
  }

  void _navigateToDetails(BuildContext context, Property property) {
    context.pushNamed('property-details', pathParameters: {'id': property.id});
  }
}
