import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/navigation/app_router.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/entities/unified_search_result.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';

/// Search page with unified search (Spotify/YouTube style grouped results)
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Category';
  String _selectedContentType = 'all';
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSuggestions = false;

  final List<String> _categories = ['Category', 'Sleep', 'Focus', 'Calm', 'Anxiety', 'Stress'];
  final List<String> _contentTypes = ['all', 'video', 'audio', 'podcast'];

  static const Color _accentColor = Color(0xFF8B5CF6);
  static const Color _surfaceColor = Color(0xFF1C1C1E);

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() => _showSuggestions = _searchFocusNode.hasFocus && _searchController.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchBloc(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildFilters(),
              Expanded(child: _buildResults()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Search',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: _searchFocusNode.hasFocus 
                      ? Border.all(color: _accentColor.withAlpha(128), width: 1)
                      : null,
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Search experts, series, content...',
                    hintStyle: TextStyle(
                      color: Colors.white.withAlpha(102),
                      fontSize: 16,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: Icon(
                        Icons.search,
                        color: Colors.white.withAlpha(102),
                        size: 22,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              context.read<SearchBloc>().add(const SearchCleared());
                              setState(() => _showSuggestions = false);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(77),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.black,
                                  size: 14,
                                ),
                              ),
                            ),
                          )
                        : null,
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _showSuggestions = value.isNotEmpty && _searchFocusNode.hasFocus);
                    context.read<SearchBloc>().add(SearchQueryChanged(value));
                  },
                  onSubmitted: (_) {
                    setState(() => _showSuggestions = false);
                  },
                ),
              ),
              // Suggestions dropdown (if available)
              if (_showSuggestions && state.suggestions.isNotEmpty)
                _buildSuggestionsDropdown(state.suggestions),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuggestionsDropdown(List<SearchSuggestion> suggestions) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ListTile(
            dense: true,
            leading: Icon(
              _getSuggestionIcon(suggestion.type),
              color: Colors.white54,
              size: 18,
            ),
            title: Text(
              suggestion.text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            onTap: () {
              _searchController.text = suggestion.text;
              setState(() => _showSuggestions = false);
              _searchFocusNode.unfocus();
              context.read<SearchBloc>().add(SearchQueryChanged(suggestion.text));
              context.read<SearchBloc>().add(const SearchSubmitted());
            },
          );
        },
      ),
    );
  }

  IconData _getSuggestionIcon(String type) {
    switch (type) {
      case 'expert':
        return Icons.person;
      case 'series':
        return Icons.playlist_play;
      case 'content':
        return Icons.play_circle_outline;
      default:
        return Icons.search;
    }
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterDropdown(
            value: _selectedCategory,
            items: _categories,
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCategory = value);
                context.read<SearchBloc>().add(
                      SearchCategoryChanged(value == 'Category' ? null : value),
                    );
              }
            },
          ),
          const SizedBox(width: 8),
          _buildContentTypeDropdown(),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF2C2C2E),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 18),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildContentTypeDropdown() {
    final displayLabels = {
      'all': 'All',
      'video': 'Video',
      'audio': 'Audio',
      'podcast': 'Podcast',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedContentType,
          dropdownColor: const Color(0xFF2C2C2E),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 18),
          items: _contentTypes.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(displayLabels[item] ?? item),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedContentType = value);
              context.read<SearchBloc>().add(SearchContentTypeChanged(value));
            }
          },
        ),
      ),
    );
  }

  Widget _buildResults() {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        if (state is SearchInitial) {
          return _buildEmptyState();
        }

        if (state is SearchLoading) {
          return const Center(
            child: CircularProgressIndicator(color: _accentColor),
          );
        }

        if (state is SearchError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white54, size: 48),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: const TextStyle(color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Unified search results (new)
        if (state is SearchUnifiedLoaded) {
          if (state.unifiedResult.isEmpty) {
            return _buildNoResults();
          }
          return _buildUnifiedResults(state.unifiedResult);
        }

        // Legacy flat results
        if (state is SearchLoaded) {
          if (state.results.isEmpty) {
            return _buildNoResults();
          }
          return _buildLegacyResults(state.results);
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// Build unified search results with grouped sections
  Widget _buildUnifiedResults(UnifiedSearchResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total results summary
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${result.totalResults} results for "${result.query}"',
              style: TextStyle(
                color: Colors.white.withAlpha(128),
                fontSize: 13,
              ),
            ),
          ),
          
          // Experts section
          if (result.hasExperts) ...[
            _buildSectionHeader('Experts', Icons.person, result.experts.length),
            _buildExpertsGrid(result.experts),
            const SizedBox(height: 24),
          ],
          
          // Series section
          if (result.hasSeries) ...[
            _buildSectionHeader('Series', Icons.playlist_play, result.series.length),
            _buildSeriesList(result.series),
            const SizedBox(height: 24),
          ],
          
          // Content section
          if (result.hasContent) ...[
            _buildSectionHeader('Content', Icons.play_circle_outline, result.content.length),
            _buildContentList(result.content),
          ],
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: _accentColor, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _accentColor.withAlpha(51),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: _accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertsGrid(List<UnifiedExpertResult> experts) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: experts.length,
        itemBuilder: (context, index) {
          final expert = experts[index];
          return GestureDetector(
            onTap: () => _onExpertTap(expert),
            child: Container(
              width: 100,
              margin: EdgeInsets.only(right: index < experts.length - 1 ? 12 : 0),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _accentColor, width: 2),
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: expert.imageUrl ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: _surfaceColor,
                          child: const Icon(Icons.person, color: Colors.white24, size: 32),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: _surfaceColor,
                          child: const Icon(Icons.person, color: Colors.white24, size: 32),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    expert.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSeriesList(List<UnifiedSeriesResult> series) {
    return Column(
      children: series.map((s) => _buildSeriesItem(s)).toList(),
    );
  }

  Widget _buildSeriesItem(UnifiedSeriesResult series) {
    return GestureDetector(
      onTap: () => _onSeriesTap(series),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: series.thumbnailUrl ?? '',
                width: 80,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 80,
                  height: 60,
                  color: Colors.black26,
                ),
                errorWidget: (context, url, error) => Container(
                  width: 80,
                  height: 60,
                  color: Colors.black26,
                  child: const Icon(Icons.playlist_play, color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(51),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'SERIES',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    series.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${series.episodeCount ?? 0} episodes${series.expertName != null ? ' • ${series.expertName}' : ''}',
                    style: TextStyle(
                      color: Colors.white.withAlpha(153),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContentList(List<UnifiedContentResult> content) {
    return Column(
      children: content.map((c) => _buildContentItem(c)).toList(),
    );
  }

  Widget _buildContentItem(UnifiedContentResult content) {
    return GestureDetector(
      onTap: () => _onContentTap(content),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            // Thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: content.thumbnailUrl ?? '',
                    width: 80,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 80,
                      height: 60,
                      color: _surfaceColor,
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 80,
                      height: 60,
                      color: _surfaceColor,
                      child: const Icon(Icons.play_circle_outline, color: Colors.white24),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(153),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      content.contentType.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (content.expertName != null) content.expertName!,
                      if (content.formattedDuration != null) content.formattedDuration!,
                    ].join(' • '),
                    style: TextStyle(
                      color: Colors.white.withAlpha(153),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build legacy flat results (fallback)
  Widget _buildLegacyResults(List<SearchResult> results) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return _buildLegacyResultItem(result);
      },
    );
  }

  Widget _buildLegacyResultItem(SearchResult result) {
    return GestureDetector(
      onTap: () => _onLegacyResultTap(result),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            if (result.isSpeaker)
              _buildSpeakerAvatar(result.imageUrl)
            else
              _buildThumbnail(result.imageUrl, result.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (result.subtitle != null) result.subtitle!,
                      if (result.authorName != null) result.authorName!,
                      if (result.formattedDuration != null) result.formattedDuration!,
                    ].join(' • '),
                    style: TextStyle(
                      color: Colors.white.withAlpha(153),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakerAvatar(String imageUrl) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: _surfaceColor),
          errorWidget: (context, url, error) => Container(
            color: _surfaceColor,
            child: const Icon(Icons.person, color: Colors.white24),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(String imageUrl, SearchResultType type) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 80,
        height: 60,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 80,
          height: 60,
          color: _surfaceColor,
        ),
        errorWidget: (context, url, error) => Container(
          width: 80,
          height: 60,
          color: _surfaceColor,
          child: const Icon(Icons.play_circle_outline, color: Colors.white24),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            color: Colors.white.withAlpha(77),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Search for experts, series,\nvideos, and audio',
            style: TextStyle(
              color: Colors.white.withAlpha(128),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            color: Colors.white.withAlpha(77),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              color: Colors.white.withAlpha(128),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Navigation handlers
  void _onExpertTap(UnifiedExpertResult expert) {
    context.push(
      '${AppRouter.speakerProfile}?id=${expert.slug}&name=${Uri.encodeComponent(expert.name)}&imageUrl=${Uri.encodeComponent(expert.imageUrl ?? '')}',
    );
  }

  void _onSeriesTap(UnifiedSeriesResult series) {
    // Navigate to first episode or series page
    context.push('${AppRouter.videoPlayer}?id=${series.id}');
  }

  void _onContentTap(UnifiedContentResult content) {
    if (content.contentType == 'video') {
      context.push('${AppRouter.videoPlayer}?id=${content.id}');
    } else {
      context.push('${AppRouter.audioPlayer}?id=${content.id}');
    }
  }

  void _onLegacyResultTap(SearchResult result) {
    switch (result.type) {
      case SearchResultType.speaker:
        context.push(
          '${AppRouter.speakerProfile}?id=${result.id}&name=${Uri.encodeComponent(result.title)}&imageUrl=${Uri.encodeComponent(result.imageUrl)}',
        );
        break;
      case SearchResultType.video:
        context.push('${AppRouter.videoPlayer}?id=${result.id}');
        break;
      case SearchResultType.audio:
      case SearchResultType.podcast:
        context.push('${AppRouter.audioPlayer}?id=${result.id}');
        break;
    }
  }
}
