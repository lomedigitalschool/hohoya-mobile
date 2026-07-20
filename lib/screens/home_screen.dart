import 'package:flutter/material.dart';
import '../widgets/featured_card.dart';
import '../widgets/trending_filters.dart';
import '../widgets/property_card.dart';
import '../widgets/bottom_nav_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.location_on, color: Colors.teal),
            SizedBox(width: 6),
            Text('Rentity',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black), onPressed: () {}),
          IconButton(icon: const Icon(Icons.menu, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: ListView(
          children: const [
            FeaturedCard(
              title: 'Metro City Studio',
              address: '482 Ocean Dr, San Diego',
              price: '\$2,500/m',
              rating: '5.0 | 140 reviews',
              imageUrl: 'https://picsum.photos/400/220',
            ),
            TrendingFilters(
              filters: ['All', 'House', 'Apartment', 'Villa'],
              selectedFilter: 'All',
            ),
            SizedBox(height: 12),
            PropertyCard(
              title: 'Aqua Horizon Estate',
              address: '482 Ocean Dr, San Diego',
              imageUrl: 'https://picsum.photos/80/80',
              beds: 3,
              baths: 2,
              sqft: 1400,
            ),
            SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () {},
        shape: const CircleBorder(),
        child: const Icon(Icons.tune, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}