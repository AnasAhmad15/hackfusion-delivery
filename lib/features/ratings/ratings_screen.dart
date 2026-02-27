import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pharmaco_delivery_partner/core/services/ratings_service.dart';
import 'package:intl/intl.dart';
import 'package:pharmaco_delivery_partner/core/providers/language_provider.dart';

class RatingsScreen extends StatefulWidget {
  const RatingsScreen({super.key});

  @override
  State<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<RatingsScreen> with TickerProviderStateMixin {
  final RatingsService _ratingsService = RatingsService();
  late Future<Map<String, dynamic>> _ratingsDataFuture;
  AnimationController? _animationController;
  Animation<double>? _ratingAnimation;

  @override
  void initState() {
    super.initState();
    _ratingsDataFuture = _loadRatingsData();
  }

  Future<Map<String, dynamic>> _loadRatingsData() async {
    final summary = await _ratingsService.getRatingsSummary();
    final feedback = await _ratingsService.getFeedbackList();
    _setupAnimation(summary['average_rating'] as double? ?? 0.0);
    return {'summary': summary, 'feedback': feedback};
  }

  void _setupAnimation(double endRating) {
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _ratingAnimation = Tween<double>(begin: 0.0, end: endRating).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );
    _animationController!.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      _ratingsDataFuture = _loadRatingsData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _ratingsDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _RatingsSkeleton();
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                TextButton(
                  onPressed: _refreshData,
                  child: Text(lp.translate('retry')),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data ?? {'summary': {'average_rating': 0.0, 'total_ratings': 0}, 'feedback': []};
        final summary = data['summary'] as Map<String, dynamic>? ?? {};
        final feedback = data['feedback'] as List<Map<String, dynamic>>? ?? [];
        final totalRatings = (summary['total_ratings'] as int?) ?? 0;

        if (totalRatings == 0 && feedback.isEmpty) {
          return _EmptyState(onRefresh: _refreshData);
        }

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSummaryCard(totalRatings, lp),
              const SizedBox(height: 24),
              _buildRatingInfoCard(lp),
              const SizedBox(height: 24),
              _buildImprovementTipsCard(lp),
              const SizedBox(height: 32),
              _buildFeedbackSection(feedback, lp),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(int totalRatings, LanguageProvider lp) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              flex: 2,
              child: AspectRatio(
                aspectRatio: 1,
                child: AnimatedBuilder(
                  animation: _ratingAnimation!,
                  builder: (context, child) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: _ratingAnimation!.value / 5.0,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                        ),
                        Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _ratingAnimation!.value.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 24),
            Flexible(
              flex: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(lp.translate('total_ratings'), style: Theme.of(context).textTheme.titleLarge),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      totalRatings.toString(),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection(List<Map<String, dynamic>> feedback, LanguageProvider lp) {
    if (feedback.isEmpty) {
      return _EmptyState(onRefresh: _refreshData, isNested: true);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lp.translate('customer_feedback'), style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: feedback.length,
          itemBuilder: (context, index) {
            return _FeedbackCard(item: feedback[index], lp: lp);
          },
        ),
      ],
    );
  }

  Widget _buildRatingInfoCard(LanguageProvider lp) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                lp.translate('rating_info'),
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovementTipsCard(LanguageProvider lp) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lp.translate('how_to_improve'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTipRow(Icons.timer, lp.translate('be_on_time'), lp.translate('be_on_time_desc')),
            const Divider(height: 24),
            _buildTipRow(Icons.chat_bubble_outline, lp.translate('communicate_clearly'), lp.translate('communicate_clearly_desc')),
            const Divider(height: 24),
            _buildTipRow(Icons.sentiment_satisfied_alt, lp.translate('be_professional'), lp.translate('be_professional_desc')),
          ],
        ),
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(subtitle, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final LanguageProvider lp;
  const _FeedbackCard({required this.item, required this.lp});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rating = item['rating'] as int? ?? 0;
    final date = item['created_at'] != null ? DateFormat('MMM d, yyyy').format(DateTime.parse(item['created_at'])) : '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lp.translate('customer'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(date, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                  ],
                ),
                const Spacer(),
                Row(
                  children: List.generate(5, (i) => Icon(i < rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 20)),
                )
              ],
            ),
            const SizedBox(height: 16),
            Text(item['feedback'] as String? ?? lp.translate('no_comment'), style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final bool isNested;
  const _EmptyState({required this.onRefresh, this.isNested = false});

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isNested) const SizedBox(height: 48),
        const Icon(Icons.star_outline, size: 100, color: Colors.grey),
        const SizedBox(height: 16),
        Text(lp.translate('no_ratings_yet'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
        Text(lp.translate('customer_ratings_appear_here'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
      ],
    );

    if (isNested) return content;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(children: [SizedBox(height: MediaQuery.of(context).size.height * 0.2, child: content)]),
    );
  }
}

class _RatingsSkeleton extends StatelessWidget {
  const _RatingsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: const [
        _Skeleton(height: 170),
        SizedBox(height: 32),
        _Skeleton(height: 40, width: 200),
        SizedBox(height: 16),
        _Skeleton(height: 120),
        SizedBox(height: 16),
        _Skeleton(height: 120),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  final double height;
  final double width;

  const _Skeleton({this.height = double.infinity, this.width = double.infinity});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
    );
  }
}