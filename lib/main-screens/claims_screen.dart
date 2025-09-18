import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:insurevis/services/claims_service.dart';
import 'package:insurevis/services/supabase_service.dart';
import 'package:insurevis/models/insurevis_models.dart';

class ClaimsScreen extends StatefulWidget {
  static const routeName = '/claims';

  const ClaimsScreen({Key? key}) : super(key: key);

  @override
  State<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends State<ClaimsScreen> {
  List<ClaimModel> _allClaims = [];
  List<ClaimModel> _filtered = [];
  String _query = '';
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _filtered = List.from(_allClaims);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadClaims());
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    // In a real app you'd re-fetch from API here. We'll just reapply filter.
    await _loadClaims();
  }

  List<ClaimModel> _applyQuery(String q) {
    final lower = q.trim().toLowerCase();
    if (lower.isEmpty) return List.from(_allClaims);
    return _allClaims.where((c) {
      return c.claimNumber.toLowerCase().contains(lower) ||
          c.status.toLowerCase().contains(lower) ||
          c.incidentDescription.toLowerCase().contains(lower) ||
          c.incidentLocation.toLowerCase().contains(lower);
    }).toList();
  }

  void _onSearchChanged(String q) {
    setState(() {
      _query = q;
      _filtered = _applyQuery(q);
    });
  }

  void _showClaimDetails(ClaimModel claim) {
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  claim.claimNumber,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(label: Text(claim.status)),
                    const SizedBox(width: 8),
                    Text(
                      'Amount: \$${claim.estimatedDamageCost?.toStringAsFixed(2) ?? '-'}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Date: ${claim.incidentDate.toIso8601String().split('T').first}',
                ),
                const SizedBox(height: 12),
                Text(claim.incidentDescription),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _loadClaims() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        setState(() {
          _allClaims = [];
          _filtered = [];
          _errorMessage = 'Please sign in to view claims.';
          _loading = false;
        });
        return;
      }

      final claims = await ClaimsService.getUserClaims(user.id);
      setState(() {
        _allClaims = claims;
        _filtered = _applyQuery(_query);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Failed to load claims. Please try again.';
      });
      if (kDebugMode) print('Load claims error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claims'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                key: const Key('claims_search'),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search claims by id, status or text',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon:
                      _query.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _onSearchChanged(''),
                          )
                          : null,
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child:
                    _loading
                        ? ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: 6,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder:
                              (context, index) => const _ClaimSkeletonTile(),
                        )
                        : (_filtered.isEmpty
                            ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const SizedBox(height: 80),
                                Center(
                                  child: Text(
                                    _errorMessage ?? 'No claims found',
                                  ),
                                ),
                              ],
                            )
                            : ListView.separated(
                              itemCount: _filtered.length,
                              separatorBuilder:
                                  (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final claim = _filtered[index];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  title: Text(claim.claimNumber),
                                  subtitle: Text(
                                    '${claim.status} • ${claim.incidentDate.toIso8601String().split('T').first}',
                                  ),
                                  trailing: Text(
                                    '\$${claim.estimatedDamageCost?.toStringAsFixed(2) ?? '-'}',
                                  ),
                                  onTap: () => _showClaimDetails(claim),
                                );
                              },
                            )),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/claim_create');
        },
        icon: const Icon(Icons.add),
        label: const Text('New Claim'),
      ),
    );
  }
}

class _ClaimSkeletonTile extends StatelessWidget {
  const _ClaimSkeletonTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: 180, height: 14),
                SizedBox(height: 8),
                _SkeletonBox(width: 120, height: 12),
              ],
            ),
          ),
          SizedBox(width: 12),
          _SkeletonBox(width: 60, height: 14),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  const _SkeletonBox({Key? key, required this.width, required this.height})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
