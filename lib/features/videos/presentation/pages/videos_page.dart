import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/navigation/app_router.dart';
import '../bloc/videos_bloc.dart';
import '../bloc/videos_event.dart';
import '../bloc/videos_state.dart';
import '../widgets/video_card.dart';
import '../widgets/category_chips.dart';

class VideosPage extends StatefulWidget {
  const VideosPage({super.key});

  @override
  State<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wellness Videos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search videos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<VideosBloc>().add(const LoadVideos());
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusM,
                  ),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (query) {
                setState(() {});
                if (query.isEmpty) {
                  context.read<VideosBloc>().add(const LoadVideos());
                } else {
                  context.read<VideosBloc>().add(SearchVideos(query));
                }
              },
            ),
          ),
        ),
      ),
      body: BlocBuilder<VideosBloc, VideosState>(
        builder: (context, state) {
          if (state is VideosLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is VideosError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<VideosBloc>().add(const LoadVideos());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is VideosLoaded) {
            return Column(
              children: [
                CategoryChips(
                  currentCategory: state.currentCategory ?? 'All',
                  onCategorySelected: (category) {
                    context
                        .read<VideosBloc>()
                        .add(FilterVideosByCategory(category));
                  },
                ),
                Expanded(
                  child: state.videos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.video_library_outlined,
                                size: 80,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.5),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'No videos found',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            context.read<VideosBloc>().add(const LoadVideos());
                          },
                          child: GridView.builder(
                            padding: const EdgeInsets.all(AppConstants.spacingM),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 1,
                              childAspectRatio: 1.5,
                              crossAxisSpacing: AppConstants.spacingM,
                              mainAxisSpacing: AppConstants.spacingM,
                            ),
                            itemCount: state.videos.length,
                            itemBuilder: (context, index) {
                              final video = state.videos[index];
                              return VideoCard(
                                video: video,
                                onTap: () {
                                  context.push(
                                    '${AppRouter.videoPlayer}?id=${video.id}',
                                  );
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          }

          return const Center(child: Text('Unknown state'));
        },
      ),
    );
  }
}
