import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/property.dart';
import '../services/property_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/property_card.dart';
import '../widgets/search_bar.dart';
import 'property_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = PropertyService();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _properties = <Property>[];
  Timer? _searchDebounce;
  List<String> _recentSearches = [];
  int _requestId = 0;
  String _type = 'Tous';
  String _selectedCity = 'Lome';
  String _filterCity = '';
  String _filterNeighborhood = '';
  double? _minPrice;
  double? _maxPrice;
  int _page = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadNextPageIfNeeded);
    _loadRecentSearches();
    _loadProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadProperties({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _hasError = false;
      setState(() => _isLoading = true);
    }
    try {
      final requestId = ++_requestId;
      final result = await _service.fetchProperties(search: _searchController.text, city: _filterCity, neighborhood: _filterNeighborhood, type: _type, minPrice: _minPrice, maxPrice: _maxPrice, page: _page);
      if (!mounted) return;
      if (requestId != _requestId) return;
      setState(() {
        if (_page == 1) _properties.clear();
        _properties.addAll(result);
        _hasMore = result.length == PropertyService.pageSize;
        _isLoading = false;
        _isLoadingMore = false;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _isLoading = false; _isLoadingMore = false; _hasError = true; });
    }
  }

  Future<void> _loadRecentSearches() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _recentSearches = preferences.getStringList('recent_searches') ?? []);
  }

  Future<void> _saveSearch(String value) async {
    final search = value.trim();
    if (search.isEmpty) return;
    final searches = [search, ..._recentSearches.where((item) => item.toLowerCase() != search.toLowerCase())].take(6).toList();
    setState(() => _recentSearches = searches);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList('recent_searches', searches);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    setState(() => _isLoading = true);
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      _page = 1;
      _hasMore = true;
      _loadProperties(refresh: true);
    });
  }

  void _submitSearch(String value) {
    _searchDebounce?.cancel();
    _saveSearch(value);
    _page = 1;
    _hasMore = true;
    _loadProperties(refresh: true);
  }

  void _selectSuggestion(String value) {
    _searchController.text = value;
    _searchController.selection = TextSelection.collapsed(offset: value.length);
    _submitSearch(value);
  }

  List<String> get _suggestions {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _recentSearches;
    return {
      ..._recentSearches,
      ..._properties.expand((property) => [property.title, property.city, property.neighborhood]),
    }.where((value) => value.toLowerCase().contains(query)).toList();
  }

  void _loadNextPageIfNeeded() {
    if (_scrollController.position.pixels < _scrollController.position.maxScrollExtent - 240 || _isLoadingMore || !_hasMore || _isLoading) return;
    setState(() => _isLoadingMore = true);
    _page++;
    _loadProperties();
  }

  void _openFilters() {
    var city = _filterCity;
    var neighborhood = _filterNeighborhood;
    var type = _type;
    var minPrice = _minPrice ?? 0;
    var maxPrice = _maxPrice ?? 1500000;
    final neighborhoods = {
      '': <String>[],
      'Lome': ['Tokoin', 'Agoe', 'Bè', 'Adidogome', 'Cacaveli'],
      'Kara': ['Chateau', 'Tomdè'],
      'Aneho': ['Centre-ville'],
      'Sokode': ['Komah'],
    };
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(builder: (context, setSheetState) {
        final availableNeighborhoods = neighborhoods[city] ?? [];
        if (!availableNeighborhoods.contains(neighborhood)) neighborhood = '';
        return SingleChildScrollView(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Filtrer les biens', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(initialValue: city, decoration: const InputDecoration(labelText: 'Ville'), items: [const DropdownMenuItem(value: '', child: Text('Toutes les villes')), ...['Lome', 'Kara', 'Aneho', 'Sokode'].map((value) => DropdownMenuItem(value: value, child: Text(value)))], onChanged: (value) => setSheetState(() { city = value ?? ''; neighborhood = ''; })),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(initialValue: neighborhood, decoration: const InputDecoration(labelText: 'Quartier'), items: [const DropdownMenuItem(value: '', child: Text('Tous les quartiers')), ...availableNeighborhoods.map((value) => DropdownMenuItem(value: value, child: Text(value)))], onChanged: (value) => setSheetState(() => neighborhood = value ?? '')),
            const SizedBox(height: 12),
            const Text('Type de bien'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, children: ['Tous', 'Appartement', 'Maison', 'Villa', 'Terrain', 'Bureau', 'Commerce'].map((value) => ChoiceChip(label: Text(value), selected: type == value, onSelected: (_) => setSheetState(() => type = value))).toList()),
            const SizedBox(height: 18),
            Text('Budget : ${minPrice.toStringAsFixed(0)} - ${maxPrice.toStringAsFixed(0)} FCFA'),
            RangeSlider(min: 0, max: 1500000, divisions: 30, values: RangeValues(minPrice, maxPrice), labels: RangeLabels(minPrice.toStringAsFixed(0), maxPrice.toStringAsFixed(0)), onChanged: (values) => setSheetState(() { minPrice = values.start; maxPrice = values.end; })),
            Row(children: [
              TextButton(onPressed: () { Navigator.pop(context); _resetFilters(); }, child: const Text('Réinitialiser')),
              const Spacer(),
              FilledButton(onPressed: () { setState(() { _filterCity = city; _filterNeighborhood = neighborhood; _type = type; _minPrice = minPrice == 0 ? null : minPrice; _maxPrice = maxPrice == 1500000 ? null : maxPrice; }); Navigator.pop(context); _loadProperties(refresh: true); }, child: const Text('Appliquer')),
            ]),
          ]),
        ));
      }),
    );
  }

  void _resetFilters() {
    setState(() { _filterCity = ''; _filterNeighborhood = ''; _type = 'Tous'; _minPrice = null; _maxPrice = null; });
    _loadProperties(refresh: true);
  }

  int get _activeFilterCount => [_filterCity, _filterNeighborhood, _type == 'Tous' ? '' : _type, _minPrice == null ? '' : 'min', _maxPrice == null ? '' : 'max'].where((value) => value.isNotEmpty).length;

  Future<void> _toggleFavorite(Property property) async {
    setState(() => property.isFavorite = !property.isFavorite);
    try {
      if (property.isFavorite) {
        await _service.addFavorite(property.id);
      } else {
        await _service.removeFavorite(property.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => property.isFavorite = !property.isFavorite);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de modifier le favori')));
    }
  }

  void _changeCity() {
    const cities = ['Lome', 'Kara', 'Aneho', 'Sokode'];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: cities.map((city) => ListTile(
        leading: const Icon(Icons.location_city_outlined),
        title: Text(city),
        trailing: city == _selectedCity ? const Icon(Icons.check, color: Colors.teal) : null,
        onTap: () { Navigator.pop(context); setState(() => _selectedCity = city); _searchController.text = city; _loadProperties(refresh: true); },
      )).toList())),
    );
  }

  void _openProperty(Property property) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: property)));

  PropertyCard _card(Property property) => PropertyCard(property: property, onTap: () => _openProperty(property), onFavoriteTap: () => _toggleFavorite(property));

  @override
  Widget build(BuildContext context) {
    final featured = _properties.take(3).toList();
    final newest = _properties.reversed.take(4).toList();
    final popular = _properties.where((property) => property.bedrooms >= 3).take(4).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      appBar: AppBar(title: const Text('Hohaya')),
      body: RefreshIndicator(
        onRefresh: () => _loadProperties(refresh: true),
        child: CustomScrollView(controller: _scrollController, slivers: [
          SliverToBoxAdapter(child: PropertySearchBar(controller: _searchController, onChanged: _onSearchChanged, onSubmitted: _submitSearch, suggestions: _suggestions, onSuggestionTap: _selectSuggestion, onFilterTap: _openFilters, activeFilterCount: _activeFilterCount)),
          if (_activeFilterCount > 0)
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: Align(alignment: Alignment.centerLeft, child: Chip(avatar: const Icon(Icons.filter_alt, size: 16), label: Text('$_activeFilterCount filtres actifs'), onDeleted: _resetFilters)))),
          SliverToBoxAdapter(child: _LocationHeader(city: _selectedCity, onChange: _changeCity)),
          if (_isLoading) const SliverToBoxAdapter(child: _SkeletonList()),
          if (_hasError && !_isLoading) const SliverFillRemaining(hasScrollBody: false, child: _ErrorState()),
          if (!_isLoading && !_hasError && _properties.isEmpty) const SliverFillRemaining(hasScrollBody: false, child: _EmptyState()),
          if (!_isLoading && !_hasError && _properties.isNotEmpty) ...[
            const SliverToBoxAdapter(child: _PromoBanner()),
            SliverToBoxAdapter(child: _CategoryRow(selectedType: _type, onSelected: (type) { setState(() => _type = type); _loadProperties(refresh: true); })),
            SliverToBoxAdapter(child: _SectionTitle(title: 'Biens en vedette', action: 'Voir tout')),
            SliverToBoxAdapter(child: _HorizontalProperties(properties: featured, cardBuilder: _card)),
            SliverToBoxAdapter(child: _SectionTitle(title: 'Nouveautés', action: 'Voir tout')),
            SliverToBoxAdapter(child: _HorizontalProperties(properties: newest, cardBuilder: _card)),
            SliverToBoxAdapter(child: _SectionTitle(title: 'Biens populaires', action: 'Les plus consultés')),
            SliverToBoxAdapter(child: _HorizontalProperties(properties: popular.isEmpty ? _properties : popular, cardBuilder: _card)),
            SliverList(delegate: SliverChildBuilderDelegate((context, index) {
              if (index == _properties.length) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
              return _card(_properties[index]);
            }, childCount: _properties.length + (_isLoadingMore ? 1 : 0))),
          ],
        ]),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}

class _LocationHeader extends StatelessWidget {
  final String city;
  final VoidCallback onChange;
  const _LocationHeader({required this.city, required this.onChange});

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 12), child: Row(children: [
    const Icon(Icons.location_on, color: Colors.teal),
    const SizedBox(width: 6),
    const Text('Localisation', style: TextStyle(color: Colors.grey, fontSize: 12)),
    const SizedBox(width: 6),
    Text(city, style: const TextStyle(fontWeight: FontWeight.bold)),
    const Spacer(),
    TextButton(onPressed: onChange, child: const Text('Changer')),
  ]));
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.fromLTRB(16, 4, 16, 18), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF0E7568), borderRadius: BorderRadius.circular(18)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Découvrez les meilleures offres du mois', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
    SizedBox(height: 8),
    Text('Nouveaux biens disponibles', style: TextStyle(color: Colors.white70)),
  ]));
}

class _CategoryRow extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onSelected;
  const _CategoryRow({required this.selectedType, required this.onSelected});
  @override
  Widget build(BuildContext context) {
    const types = ['Tous', 'Appartement', 'Maison', 'Villa', 'Terrain', 'Bureau', 'Commerce'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Catégories'),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: types.map((type) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(type),
                selected: selectedType == type,
                onSelected: (_) => onSelected(type),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  const _SectionTitle({required this.title, this.action});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Row(children: [Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const Spacer(), if (action != null) Text(action!, style: const TextStyle(color: Colors.teal, fontSize: 12))]));
}

class _HorizontalProperties extends StatelessWidget {
  final List<Property> properties;
  final PropertyCard Function(Property) cardBuilder;
  const _HorizontalProperties({required this.properties, required this.cardBuilder});
  @override
  Widget build(BuildContext context) => SizedBox(height: 300, child: ListView(scrollDirection: Axis.horizontal, children: properties.map((property) => SizedBox(width: 300, child: cardBuilder(property))).toList()));
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          height: 260,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Center(child: Text('Aucun bien trouvé', style: TextStyle(color: Colors.grey, fontSize: 16)));
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Une erreur réseau est survenue'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.findAncestorStateOfType<_HomeScreenState>()?._loadProperties(refresh: true),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
