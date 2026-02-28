import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pharmaco_delivery_partner/core/services/ratings_service.dart';
import 'package:intl/intl.dart';
import 'package:pharmaco_delivery_partner/core/providers/language_provider.dart';
import 'package:pharmaco_delivery_partner/theme/design_tokens.dart';

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
  void initState() { super.initState(); _ratingsDataFuture = _loadRatingsData(); }

  Future<Map<String, dynamic>> _loadRatingsData() async {
    final summary = await _ratingsService.getRatingsSummary();
    final feedback = await _ratingsService.getFeedbackList();
    _setupAnimation(summary['average_rating'] as double? ?? 0.0);
    return {'summary': summary, 'feedback': feedback};
  }

  void _setupAnimation(double endRating) {
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _ratingAnimation = Tween<double>(begin: 0.0, end: endRating).animate(CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut));
    _animationController!.forward();
  }

  @override
  void dispose() { _animationController?.dispose(); super.dispose(); }

  Future<void> _refreshData() async { setState(() { _ratingsDataFuture = _loadRatingsData(); }); }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    final theme = Theme.of(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _ratingsDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const _RatingsSkeleton();
        if (snapshot.hasError) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: PharmacoTokens.error),
            const SizedBox(height: PharmacoTokens.space16),
            Text('Error: ${snapshot.error}'),
            TextButton(onPressed: _refreshData, child: Text(lp.translate('retry'))),
          ]));
        }

        final data = snapshot.data ?? {'summary': {'average_rating': 0.0, 'total_ratings': 0}, 'feedback': []};
        final summary = data['summary'] as Map<String, dynamic>? ?? {};
        final feedback = data['feedback'] as List<Map<String, dynamic>>? ?? [];
        final totalRatings = (summary['total_ratings'] as int?) ?? 0;

        if (totalRatings == 0 && feedback.isEmpty) return _EmptyState(onRefresh: _refreshData);

        return RefreshIndicator(
          color: PharmacoTokens.primaryBase,
          onRefresh: _refreshData,
          child: ListView(
            padding: const EdgeInsets.all(PharmacoTokens.space16),
            children: [
              _buildSummaryCard(totalRatings, lp, theme),
              const SizedBox(height: PharmacoTokens.space24),
              _buildRatingInfoCard(lp, theme),
              const SizedBox(height: PharmacoTokens.space24),
              _buildImprovementTipsCard(lp, theme),
              const SizedBox(height: PharmacoTokens.space32),
              _buildFeedbackSection(feedback, lp, theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(int totalRatings, LanguageProvider lp, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: PharmacoTokens.space16, vertical: PharmacoTokens.space24),
      decoration: BoxDecoration(color: PharmacoTokens.white, borderRadius: PharmacoTokens.borderRadiusCard, boxShadow: PharmacoTokens.shadowZ1()),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            flex: 2,
            child: AspectRatio(
              aspectRatio: 1,
              child: AnimatedBuilder(
                animation: _ratingAnimation!,
                builder: (context, child) => Stack(fit: StackFit.expand, children: [
                  CircularProgressIndicator(value: _ratingAnimation!.value / 5.0, strokeWidth: 8, backgroundColor: PharmacoTokens.neutral100, valueColor: const AlwaysStoppedAnimation<Color>(PharmacoTokens.primaryBase)),
                  Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(_ratingAnimation!.value.toStringAsFixed(1), style: theme.textTheme.displaySmall?.copyWith(fontWeight: PharmacoTokens.weightBold)))),
                ]),
              ),
            ),
          ),
          const SizedBox(width: PharmacoTokens.space24),
          Flexible(
            flex: 3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(fit: BoxFit.scaleDown, child: Text(lp.translate('total_ratings'), style: theme.textTheme.titleLarge)),
                const SizedBox(height: 4),
                FittedBox(fit: BoxFit.scaleDown, child: Text(totalRatings.toString(), style: theme.textTheme.displayMedium?.copyWith(fontWeight: PharmacoTokens.weightBold, color: PharmacoTokens.primaryBase))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(List<Map<String, dynamic>> feedback, LanguageProvider lp, ThemeData theme) {
    if (feedback.isEmpty) return _EmptyState(onRefresh: _refreshData, isNested: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lp.translate('customer_feedback'), style: theme.textTheme.headlineSmall),
        const SizedBox(height: PharmacoTokens.space16),
        ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: feedback.length, itemBuilder: (context, index) => _FeedbackCard(item: feedback[index], lp: lp)),
      ],
    );
  }

  Widget _buildRatingInfoCard(LanguageProvider lp, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(PharmacoTokens.space16),
      decoration: BoxDecoration(color: PharmacoTokens.primarySurface, borderRadius: PharmacoTokens.borderRadiusMedium),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: PharmacoTokens.primaryBase),
          const SizedBox(width: PharmacoTokens.space16),
          Expanded(child: Text(lp.translate('rating_info'), style: theme.textTheme.bodySmall?.copyWith(color: PharmacoTokens.neutral600))),
        ],
      ),
    );
  }

  Widget _buildImprovementTipsCard(LanguageProvider lp, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(PharmacoTokens.space16),
      decoration: BoxDecoration(color: PharmacoTokens.white, borderRadius: PharmacoTokens.borderRadiusCard, boxShadow: PharmacoTokens.shadowZ1()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lp.translate('how_to_improve'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: PharmacoTokens.weightBold)),
          const SizedBox(height: PharmacoTokens.space16),
          _buildTipRow(Icons.timer_rounded, lp.translate('be_on_time'), lp.translate('be_on_time_desc'), theme),
          const Divider(height: PharmacoTokens.space24),
          _buildTipRow(Icons.chat_bubble_outline_rounded, lp.translate('communicate_clearly'), lp.translate('communicate_clearly_desc'), theme),
          const Divider(height: PharmacoTokens.space24),
          _buildTipRow(Icons.sentiment_satisfied_alt_rounded, lp.translate('be_professional'), lp.translate('be_professional_desc'), theme),
        ],
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String title, String subtitle, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, color: PharmacoTokens.primaryBase, size: 32),
        const SizedBox(width: PharmacoTokens.space16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: PharmacoTokens.weightBold)),
          Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: PharmacoTokens.neutral500)),
        ])),
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: PharmacoTokens.space8),
      padding: const EdgeInsets.all(PharmacoTokens.space16),
      decoration: BoxDecoration(color: PharmacoTokens.white, borderRadius: PharmacoTokens.borderRadiusCard, boxShadow: PharmacoTokens.shadowZ1()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(backgroundColor: PharmacoTokens.primarySurface, child: const Icon(Icons.person_rounded, color: PharmacoTokens.primaryBase)),
            const SizedBox(width: PharmacoTokens.space16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(lp.translate('customer'), style: theme.textTheme.titleSmall?.copyWith(fontWeight: PharmacoTokens.weightBold)),
              Text(date, style: theme.textTheme.bodySmall?.copyWith(color: PharmacoTokens.neutral400)),
            ]),
            const Spacer(),
            Row(children: List.generate(5, (i) => Icon(i < rating ? Icons.star_rounded : Icons.star_border_rounded, color: PharmacoTokens.warning, size: 20))),
          ]),
          const SizedBox(height: PharmacoTokens.space16),
          Text(item['feedback'] as String? ?? lp.translate('no_comment'), style: theme.textTheme.bodyLarge),
        ],
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
    final theme = Theme.of(context);
    final content = Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (isNested) const SizedBox(height: PharmacoTokens.space48),
      const Icon(Icons.star_outline_rounded, size: 100, color: PharmacoTokens.neutral300),
      const SizedBox(height: PharmacoTokens.space16),
      Text(lp.translate('no_ratings_yet'), textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
      Text(lp.translate('customer_ratings_appear_here'), textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: PharmacoTokens.neutral500)),
    ]);
    if (isNested) return content;
    return RefreshIndicator(color: PharmacoTokens.primaryBase, onRefresh: onRefresh, child: ListView(children: [SizedBox(height: MediaQuery.of(context).size.height * 0.2, child: content)]));
  }
}

class _RatingsSkeleton extends StatelessWidget {
  const _RatingsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(PharmacoTokens.space16),
      children: const [_Skeleton(height: 170), SizedBox(height: PharmacoTokens.space32), _Skeleton(height: 40, width: 200), SizedBox(height: PharmacoTokens.space16), _Skeleton(height: 120), SizedBox(height: PharmacoTokens.space16), _Skeleton(height: 120)],
    );
  }
}

class _Skeleton extends StatelessWidget {
  final double height;
  final double width;
  const _Skeleton({this.height = double.infinity, this.width = double.infinity});

  @override
  Widget build(BuildContext context) {
    return Container(height: height, width: width, decoration: BoxDecoration(color: PharmacoTokens.neutral100, borderRadius: PharmacoTokens.borderRadiusCard));
  }
}