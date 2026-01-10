import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/navigation/app_router.dart';
import '../../domain/entities/search_result.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';

/// Search page matching the provided mockup design
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Category';
  String _selectedContentType = 'all';

  final List<String> _categories = ['Category', 'Sleep', 'Focus', 'Calm', 'Anxiety', 'Stress'];
  final List<String> _contentTypes = ['all', 'video', 'audio', 'podcast'];

  @override
  void dispose() {
    _searchController.dispose();
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
          // Back button
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
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
          // Spacer to balance the back button
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
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search content, speakers...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 16,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(
                    Icons.search,
                    color: Colors.white.withOpacity(0.4),
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
                          setState(() {});
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
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
                setState(() {}); // Rebuild to show/hide clear button
                context.read<SearchBloc>().add(SearchQueryChanged(value));
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Category dropdown
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
          // Content type dropdown
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
        color: const Color(0xFF1C1C1E),
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
        color: const Color(0xFF1C1C1E),
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
            child: CircularProgressIndicator(
              color: Color(0xFF4CAF50),
            ),
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

        if (state is SearchLoaded) {
          if (state.results.isEmpty) {
            return _buildNoResults();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: state.results.length,
            itemBuilder: (context, index) {
              final result = state.results[index];
              return _buildResultItem(result);
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            color: Colors.white.withOpacity(0.3),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Search for speakers, videos,\naudio, and podcasts',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
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
            color: Colors.white.withOpacity(0.3),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(SearchResult result) {
    return GestureDetector(
      onTap: () => _onResultTap(result),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            // Thumbnail/Avatar
            if (result.isSpeaker)
              _buildSpeakerAvatar(result)
            else
              _buildContentThumbnail(result),
            const SizedBox(width: 12),
            // Content info
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
                  _buildSubtitleRow(result),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakerAvatar(SearchResult result) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: result.imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: const Color(0xFF282828),
          ),
          errorWidget: (context, url, error) => Container(
            color: const Color(0xFF282828),
            child: const Icon(Icons.person, color: Colors.white24),
          ),
        ),
      ),
    );
  }

  Widget _buildContentThumbnail(SearchResult result) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: result.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: const Color(0xFF282828),
              ),
              errorWidget: (context, url, error) => Container(
                color: const Color(0xFF282828),
                child: const Icon(Icons.play_circle_outline, color: Colors.white24),
              ),
            ),
          ),
        ),
        // Play icon overlay for video/audio
        if (result.type == SearchResultType.video || result.type == SearchResultType.audio)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                result.type == SearchResultType.video ? Icons.play_arrow : Icons.headphones,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubtitleRow(SearchResult result) {
    final parts = <String>[];

    if (result.subtitle != null && result.subtitle!.isNotEmpty) {
      parts.add(result.subtitle!);
    }

    if (!result.isSpeaker) {
      if (result.authorName != null && result.authorName!.isNotEmpty) {
        parts.add(result.authorName!);
      }
      if (result.formattedDuration != null) {
        parts.add(result.formattedDuration!);
      }
    }

    final subtitle = parts.join(' • ');

    return Text(
      subtitle.isEmpty ? result.typeLabel : subtitle,
      style: TextStyle(
        color: Colors.white.withOpacity(0.6),
        fontSize: 13,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  void _onResultTap(SearchResult result) {
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
