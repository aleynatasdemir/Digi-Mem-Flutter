import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../services/memory_service.dart';
import '../services/auth_service.dart';
import '../models/memory.dart';
import 'add_memory_screen.dart';
import 'memory_detail_screen.dart';
import '../utils/api_constants.dart';

class ModernDashboardScreen extends StatefulWidget {
  const ModernDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ModernDashboardScreen> createState() => _ModernDashboardScreenState();
}

class _ModernDashboardScreenState extends State<ModernDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MemoryService>(context, listen: false).fetchMemories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final memoryService = Provider.of<MemoryService>(context);
    final userName = authService.user?.name.split(' ').first ?? 'Misafir';

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Profile Picture
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF7b3fcf).withOpacity(0.2),
                            width: 2,
                          ),
                          image: authService.user?.avatar != null
                              ? DecorationImage(
                                  image: NetworkImage(authService.user!.avatar!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: authService.user?.avatar == null
                            ? Icon(
                                Icons.person,
                                color: const Color(0xFF7b3fcf),
                                size: 24,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'JOURNAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF7b3fcf),
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              '${_getGreeting()}, $userName',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF141019),
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, size: 24),
                        onPressed: () {},
                        color: const Color(0xFF141019),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, size: 24),
                        onPressed: () {},
                        color: const Color(0xFF141019),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Create New Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YENİ OLUŞTUR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF141019).withOpacity(0.4),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _CreateButton(
                        icon: Icons.photo_camera,
                        label: 'Fotoğraf',
                        onTap: () => _openAddMemory('PHOTO'),
                      ),
                      _CreateButton(
                        icon: Icons.videocam,
                        label: 'Video',
                        onTap: () => _openAddMemory('VIDEO'),
                      ),
                      _CreateButton(
                        icon: Icons.edit_note,
                        label: 'Metin',
                        onTap: () => _openAddMemory('TEXT'),
                      ),
                      _CreateButton(
                        icon: Icons.mic,
                        label: 'Ses',
                        onTap: () => _openAddMemory('VOICE'),
                      ),
                      _CreateButton(
                        icon: Icons.music_note,
                        label: 'Şarkı',
                        onTap: () => _openAddMemory('SONG'),
                      ),
                      _CreateButton(
                        icon: Icons.description,
                        label: 'Not',
                        onTap: () => _openAddMemory('TEXT'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFEAEAEA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 44, vertical: 12),
                  hintText: 'Anılarını ara...',
                  hintStyle: TextStyle(
                    color: const Color(0xFF141019).withOpacity(0.4),
                    fontSize: 14,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      Icons.search,
                      color: const Color(0xFF141019).withOpacity(0.4),
                      size: 20,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 20,
                  ),
                ),
              ),
            ),
          ),

          // Recent Thoughts Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Son Anılar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF141019),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Tümünü Gör',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7b3fcf),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Masonry Grid
          memoryService.isLoading
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(
                        color: Color(0xFF7b3fcf),
                      ),
                    ),
                  ),
                )
              : memoryService.memories.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.collections_bookmark_outlined,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Henüz anı yok',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverMasonryGrid.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childCount: memoryService.memories.length,
                        itemBuilder: (context, index) {
                          final memory = memoryService.memories[index];
                          return _MemoryCard(
                            memory: memory,
                            onTap: () => _openMemoryDetail(memory),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }

  void _openAddMemory(String type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMemoryScreen(initialType: type),
      ),
    );
    if (result == true) {
      Provider.of<MemoryService>(context, listen: false).fetchMemories();
    }
  }

  void _openMemoryDetail(Memory memory) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemoryDetailScreen(memory: memory),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CreateButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF7b3fcf).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF7b3fcf).withOpacity(0.05),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF7b3fcf),
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF141019),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback onTap;

  const _MemoryCard({
    required this.memory,
    required this.onTap,
  });

  String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // Relative path ise base URL ile birleştir
    return '${ApiConstants.baseUrl}/$url'.replaceAll('//', '/').replaceAll(':/', '://');
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Bugün • ${DateFormat('HH:mm').format(dateTime)}';
      }
      return 'Bugün • ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Dün • ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return DateFormat('dd MMM yyyy', 'tr_TR').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (memory.type.toUpperCase()) {
      case 'PHOTO':
        return _PhotoCard(
          memory: memory,
          onTap: onTap,
          relativeTime: _getRelativeTime(memory.createdAt),
        );
      case 'VIDEO':
        return _VideoCard(
          memory: memory,
          onTap: onTap,
          relativeTime: _getRelativeTime(memory.createdAt),
        );
      case 'VOICE':
        return _VoiceCard(
          memory: memory,
          onTap: onTap,
          relativeTime: _getRelativeTime(memory.createdAt),
        );
      case 'SONG':
        return _SongCard(
          memory: memory,
          onTap: onTap,
          relativeTime: _getRelativeTime(memory.createdAt),
        );
      case 'TEXT':
        return _TextCard(
          memory: memory,
          onTap: onTap,
          relativeTime: _getRelativeTime(memory.createdAt),
        );
      default:
        return _TextCard(
          memory: memory,
          onTap: onTap,
          relativeTime: _getRelativeTime(memory.createdAt),
        );
    }
  }
}

class _PhotoCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback onTap;
  final String relativeTime;

  const _PhotoCard({
    required this.memory,
    required this.onTap,
    required this.relativeTime,
  });

  String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return '${ApiConstants.baseUrl}/$url'.replaceAll('//', '/').replaceAll(':/', '://');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFdad3e4).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (memory.fileUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: _getFullImageUrl(memory.fileUrl),
                      height: 192,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 192,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 192,
                        color: Colors.grey[200],
                        child: const Icon(Icons.error),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.image,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memory.title ?? 'Başlıksız',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF141019),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    relativeTime.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF141019).withOpacity(0.5),
                      letterSpacing: 0.5,
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
}

class _VideoCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback onTap;
  final String relativeTime;

  const _VideoCard({
    required this.memory,
    required this.onTap,
    required this.relativeTime,
  });

  String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return '${ApiConstants.baseUrl}/$url'.replaceAll('//', '/').replaceAll(':/', '://');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFdad3e4).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (memory.thumbnailUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: _getFullImageUrl(memory.thumbnailUrl),
                      height: 128,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 128,
                        color: Colors.grey[200],
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 128,
                        color: Colors.grey[200],
                        child: const Icon(Icons.error),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.2),
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memory.title ?? 'Başlıksız Video',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF141019),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    relativeTime.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF141019).withOpacity(0.5),
                      letterSpacing: 0.5,
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
}

class _VoiceCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback onTap;
  final String relativeTime;

  const _VoiceCard({
    required this.memory,
    required this.onTap,
    required this.relativeTime,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFdad3e4).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7b3fcf).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: Color(0xFF7b3fcf),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'SES',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF141019).withOpacity(0.4),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              memory.title ?? 'Ses Kaydı',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF141019),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Waveform simulation
            Row(
              children: List.generate(
                20,
                (index) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    height: 8.0 + (index % 5) * 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7b3fcf).withOpacity(
                        index % 3 == 0 ? 1.0 : (index % 2 == 0 ? 0.6 : 0.3),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              relativeTime.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF141019).withOpacity(0.5),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SongCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback onTap;
  final String relativeTime;

  const _SongCard({
    required this.memory,
    required this.onTap,
    required this.relativeTime,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7b3fcf),
              Color(0xFF9b5fcf),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7b3fcf).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.music_note,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 12),
            Text(
              memory.songTitle ?? memory.title ?? 'Başlıksız Şarkı',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (memory.artistName != null) ...[
              const SizedBox(height: 4),
              Text(
                memory.artistName!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              relativeTime.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.6),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback onTap;
  final String relativeTime;

  const _TextCard({
    required this.memory,
    required this.onTap,
    required this.relativeTime,
  });

  @override
  Widget build(BuildContext context) {
    // Randomly use purple or white background for variety
    final isPurple = (memory.id ?? 0) % 3 == 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPurple ? const Color(0xFF7b3fcf) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isPurple
              ? null
              : Border.all(
                  color: const Color(0xFFdad3e4).withOpacity(0.3),
                  width: 1,
                ),
          boxShadow: [
            BoxShadow(
              color: isPurple
                  ? const Color(0xFF7b3fcf).withOpacity(0.3)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (memory.title != null && memory.title!.isNotEmpty) ...[
              Text(
                memory.title!.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isPurple ? Colors.white : const Color(0xFF7b3fcf),
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
            ] else ...[
              Icon(
                Icons.description,
                color: isPurple ? Colors.white.withOpacity(0.5) : const Color(0xFF7b3fcf).withOpacity(0.5),
                size: 20,
              ),
              const SizedBox(height: 8),
            ],
            if (memory.description != null && memory.description!.isNotEmpty)
              Text(
                memory.description!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isPurple ? Colors.white : const Color(0xFF141019).withOpacity(0.7),
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 12),
            Text(
              relativeTime.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isPurple
                    ? Colors.white.withOpacity(0.6)
                    : const Color(0xFF141019).withOpacity(0.5),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
