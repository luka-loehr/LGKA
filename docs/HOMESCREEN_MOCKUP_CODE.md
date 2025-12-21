# Homescreen Mockup - Code Structure

## Visual Layout

```
┌─────────────────────────────────────────────┐
│  [🏥]          LGKA+              [⚙️]       │  AppBar
├─────────────────────────────────────────────┤
│                                              │
│  ┌───────────────────────────────────────┐  │
│  │  [📅]  Vertretungsplan               │  │  Primary Card
│  │        Heute & Morgen                │  │  (Full width, large)
│  │        [Status: Heute verfügbar]     │  │
│  │                              [→]      │  │
│  └───────────────────────────────────────┘  │
│                                              │
│  ┌──────────────────┐  ┌──────────────────┐ │
│  │  [📋]            │  │  [☀️]            │ │
│  │  Stundenplan    │  │  Wetter          │ │  Grid Cards
│  │  Klassen 5-10 &  │  │  22°C            │ │  (2 columns)
│  │  Oberstufe       │  │  Live Daten      │ │
│  │           [→]     │  │           [→]    │ │
│  └──────────────────┘  └──────────────────┘ │
│                                              │
│  ┌───────────────────────────────────────┐  │
│  │  [📰]  Neuigkeiten                    │  │  News Card
│  │        Aktuelle Nachrichten           │  │  (Full width)
│  │        [3 neue]                       │  │
│  │                              [→]      │  │
│  └───────────────────────────────────────┘  │
│                                              │
│              [App Footer]                   │
└─────────────────────────────────────────────┘
```

## Code Structure Example

```dart
class NewHomeScreen extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24),
            
            // Primary Card: Vertretungsplan
            _VertretungsplanCard(),
            
            SizedBox(height: 16),
            
            // Grid: Stundenplan & Wetter
            Row(
              children: [
                Expanded(child: _StundenplanCard()),
                SizedBox(width: 16),
                Expanded(child: _WetterCard()),
              ],
            ),
            
            SizedBox(height: 16),
            
            // News Card
            _NeuigkeitenCard(),
            
            SizedBox(height: 32),
            
            // Footer
            AppFooter(),
          ],
        ),
      ),
    );
  }
}

// Primary Card Component
class _VertretungsplanCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfRepo = ref.watch(pdfRepositoryProvider);
    
    return _HomeCard(
      height: 180,
      onTap: () => _navigateToSubstitutions(context),
      child: Row(
        children: [
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calendar_today, color: Colors.white, size: 32),
          ),
          SizedBox(width: 20),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Vertretungsplan',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Heute & Morgen',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                if (pdfRepo.hasAnyData) ...[
                  SizedBox(height: 8),
                  _buildStatusIndicator(context, pdfRepo),
                ],
              ],
            ),
          ),
          
          // Arrow
          Icon(Icons.arrow_forward_ios, 
               color: AppColors.secondaryText.withValues(alpha: 0.6),
               size: 20),
        ],
      ),
    );
  }
}

// Grid Card Component (Stundenplan)
class _StundenplanCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _HomeCard(
      height: 140,
      onTap: () => context.push(AppRouter.schedule),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.schedule, color: Colors.white, size: 24),
          ),
          Spacer(),
          
          // Title
          Text(
            'Stundenplan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          
          // Subtitle
          Text(
            'Klassen 5-10 & Oberstufe',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.secondaryText,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Arrow (bottom right)
          Align(
            alignment: Alignment.bottomRight,
            child: Icon(Icons.arrow_forward_ios,
                        color: AppColors.secondaryText.withValues(alpha: 0.6),
                        size: 16),
          ),
        ],
      ),
    );
  }
}

// Grid Card Component (Wetter)
class _WetterCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherState = ref.watch(weatherDataProvider);
    final currentTemp = weatherState.latestData?.temperature;
    
    return _HomeCard(
      height: 140,
      onTap: () => context.push(AppRouter.weather),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 24),
          ),
          Spacer(),
          
          // Title
          Text(
            'Wetter',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          
          // Subtitle with temperature
          Text(
            currentTemp != null 
              ? '${currentTemp.toStringAsFixed(1)}°C'
              : 'Live Daten',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          
          // Arrow (bottom right)
          Align(
            alignment: Alignment.bottomRight,
            child: Icon(Icons.arrow_forward_ios,
                        color: AppColors.secondaryText.withValues(alpha: 0.6),
                        size: 16),
          ),
        ],
      ),
    );
  }
}

// News Card Component
class _NeuigkeitenCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsState = ref.watch(newsProvider);
    final unreadCount = newsState.events.length;
    
    return _HomeCard(
      height: 140,
      onTap: () => context.push(AppRouter.news),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.newspaper_outlined, color: Colors.white, size: 28),
          ),
          SizedBox(width: 20),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Neuigkeiten',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (unreadCount > 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Aktuelle Nachrichten',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          
          // Arrow
          Icon(Icons.arrow_forward_ios,
               color: AppColors.secondaryText.withValues(alpha: 0.6),
               size: 20),
        ],
      ),
    );
  }
}

// Reusable Card Widget
class _HomeCard extends StatefulWidget {
  final double height;
  final VoidCallback onTap;
  final Widget child;

  const _HomeCard({
    required this.height,
    required this.onTap,
    required this.child,
  });

  @override
  State<_HomeCard> createState() => _HomeCardState();
}

class _HomeCardState extends State<_HomeCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _scaleController.forward();
        HapticService.subtle();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _scaleController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? _scaleAnimation.value : 1.0,
            child: Container(
              width: double.infinity,
              height: widget.height,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.appSurface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: _isPressed ? [] : [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}
```

## Key Features

1. **Primary Card**: Vertretungsplan gets prominent placement with larger size
2. **Grid Layout**: Stundenplan and Wetter share a row for efficient space usage
3. **News Card**: Full-width card for better readability
4. **Interactive**: All cards have tap animations and haptic feedback
5. **Data-Driven**: Cards show real-time status and data when available
6. **Consistent Styling**: All cards use the same base component with variations

## Benefits Over Current Design

- **Single Screen**: No need to swipe between pages
- **Quick Overview**: See all main features at once
- **Faster Navigation**: Direct access to each section
- **Better Discoverability**: All features visible immediately
- **Cleaner UX**: Less cognitive load, clearer hierarchy

