import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/event_model.dart';
import '../../../data/repositories/event_repository.dart';
import '../../widgets/event_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  const SearchScreen({super.key, this.initialCategory});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String? _category;
  List<EventModel> _results = [];
  bool _loading = false;

  Future<void> _search() async {
    setState(() => _loading = true);
    final results = await ref.read(eventRepositoryProvider).getPublishedEvents(
          search:
              _controller.text.trim().isEmpty ? null : _controller.text.trim(),
          category: _category,
        );
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  List<String> get _otherCategories {
    const all = AppConstants.eventCategories;
    if (_category == null) return all;
    return all.where((c) => c != _category).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          _category != null ? _category! : 'Recherche',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Rechercher un événement, une ville...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),

          // Catégorie active + suggestions d'autres
          if (_category != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  const Text(
                    'Catégorie : ',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary),
                  ),
                  Chip(
                    label: Text(_category!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                    backgroundColor: AppColors.primary,
                    deleteIcon:
                        const Icon(Icons.close, size: 16, color: Colors.white),
                    onDeleted: () {
                      setState(() => _category = null);
                      _search();
                    },
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(
                'Autres catégories',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _otherCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = _otherCategories[i];
                  return ActionChip(
                    label: Text(cat),
                    onPressed: () {
                      setState(() => _category = cat);
                      _search();
                    },
                  );
                },
              ),
            ),
          ] else ...[
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: AppConstants.eventCategories.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return FilterChip(
                      label: const Text('Tous'),
                      selected: _category == null,
                      onSelected: (_) {
                        setState(() => _category = null);
                        _search();
                      },
                    );
                  }
                  final cat = AppConstants.eventCategories[i - 1];
                  return FilterChip(
                    label: Text(cat),
                    selected: _category == cat,
                    onSelected: (_) {
                      setState(() => _category = cat);
                      _search();
                    },
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _loading
                  ? 'Recherche…'
                  : '${_results.length} événement(s)${_category != null ? ' · $_category' : ''}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.event_busy_rounded,
                                  size: 48, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                _category != null
                                    ? 'Aucun événement dans « $_category »'
                                    : 'Aucun événement trouvé',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              if (_otherCategories.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const Text('Essayez une autre catégorie :'),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: _otherCategories.take(4).map((c) {
                                    return ActionChip(
                                      label: Text(c),
                                      onPressed: () {
                                        setState(() => _category = c);
                                        _search();
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final e = _results[i];
                          return EventCard(
                            event: e,
                            onTap: () => context.push('/event/${e.id}'),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
