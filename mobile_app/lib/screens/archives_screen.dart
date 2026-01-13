import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/memory_service.dart';
import '../models/memory.dart';
import '../widgets/memory_card.dart';

class ArchivesScreen extends StatefulWidget {
  const ArchivesScreen({Key? key}) : super(key: key);

  @override
  State<ArchivesScreen> createState() => _ArchivesScreenState();
}

class _ArchivesScreenState extends State<ArchivesScreen> {
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDate;
  String _searchQuery = '';
  String _selectedType = 'ALL';

  // Türkçe ay isimleri
  final List<String> _monthNames = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Anı Kutusu',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Consumer<MemoryService>(
                  builder: (context, service, _) => Text(
                    'Toplam ${service.memories.length} anı saklanıyor.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          _buildCalendar(),
          _buildFilters(),
          Expanded(
            child: _buildMemoriesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month - 1,
                        );
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month + 1,
                        );
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateUtils.getDaysInMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final startOffset = (firstDayOfMonth.weekday - 1) % 7;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
              .map((day) => SizedBox(
                    width: 40,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[400],
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 240,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startOffset) {
                return const SizedBox.shrink();
              }

              final day = index - startOffset + 1;
              final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
              final memories = _getMemoriesForDate(date);
              final isSelected = _selectedDate != null &&
                  _selectedDate!.year == date.year &&
                  _selectedDate!.month == date.month &&
                  _selectedDate!.day == date.day;
              final isToday = DateTime.now().year == date.year &&
                  DateTime.now().month == date.month &&
                  DateTime.now().day == date.day;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDate = isSelected ? null : date;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isToday
                          ? Theme.of(context).primaryColor
                          : memories.isNotEmpty
                              ? Theme.of(context).primaryColor.withOpacity(0.3)
                              : Colors.grey[300]!,
                      width: isToday ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Arka plan fotoğrafı - Web ile aynı
                      if (memories.isNotEmpty && !isSelected)
                        _buildCalendarDayBackground(memories),
                      
                      // Gün numarası - Sol üstte
                      Positioned(
                        top: 2,
                        left: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: memories.isNotEmpty
                                ? Theme.of(context).primaryColor
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: memories.isNotEmpty || isSelected
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      
                      // Birden fazla fotoğraf varsa göster
                      if (!isSelected && memories.where((m) => m.type.toLowerCase() == 'photo').length > 1)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '+${memories.where((m) => m.type.toLowerCase() == 'photo').length - 1}',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                      
                      // Fotoğraf yoksa diğer medya tiplerini göster
                      if (!isSelected && memories.isNotEmpty && !memories.any((m) => m.type.toLowerCase() == 'photo'))
                        Center(child: _buildMediaIcons(memories)),
                      
                      // Fotoğraf varsa diğer medya tiplerini sağ altta göster
                      if (!isSelected && memories.isNotEmpty && memories.any((m) => m.type.toLowerCase() == 'photo'))
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: _buildSmallMediaIcons(memories.where((m) => m.type.toLowerCase() != 'photo').toList()),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Başlık veya etiket ara...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _selectedType,
            borderRadius: BorderRadius.circular(12),
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('Tümü')),
              DropdownMenuItem(value: 'PHOTO', child: Text('Fotoğraf')),
              DropdownMenuItem(value: 'VIDEO', child: Text('Video')),
              DropdownMenuItem(value: 'AUDIO', child: Text('Ses')),
              DropdownMenuItem(value: 'TEXT', child: Text('Not')),
              DropdownMenuItem(value: 'SONG', child: Text('Şarkı')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedType = value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMemoriesList() {
    return Consumer<MemoryService>(
      builder: (context, service, _) {
        // Yükleme durumunu kontrol et
        if (service.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Hata durumunu kontrol et
        if (service.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  service.error!,
                  style: TextStyle(color: Colors.red[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => service.fetchMemories(),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }

        // Debug: Anı sayısını yazdır
        print('Total memories loaded: ${service.memories.length}');
        
        final filteredMemories = service.memories.where((memory) {
          final checkDate = memory.memoryDate ?? memory.createdAt;
          final matchesDate = _selectedDate == null ||
              (checkDate.year == _selectedDate!.year &&
                  checkDate.month == _selectedDate!.month &&
                  checkDate.day == _selectedDate!.day);

          final matchesSearch = _searchQuery.isEmpty ||
              (memory.title ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (memory.tags?.any((tag) =>
                      (tag ?? '').toLowerCase().contains(_searchQuery.toLowerCase())) ??
                  false);

          final matchesType =
              _selectedType == 'ALL' || memory.type == _selectedType;

          return matchesDate && matchesSearch && matchesType;
        }).toList();
        
        // Tarihe göre grupla ve en yeniden eskiye sırala
        final groupedMemories = _groupMemoriesByDate(filteredMemories);
        final sortedDates = groupedMemories.keys.toList()..sort((a, b) => b.compareTo(a));

        if (filteredMemories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_list_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Bu kriterlere uygun anı bulunamadı',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (_searchQuery.isNotEmpty ||
                    _selectedType != 'ALL' ||
                    _selectedDate != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _selectedType = 'ALL';
                        _selectedDate = null;
                      });
                    },
                    child: const Text('Filtreleri Temizle'),
                  ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDates.length,
          itemBuilder: (context, dateIndex) {
            final date = sortedDates[dateIndex];
            final memoriesForDate = groupedMemories[date]!;
            
            final months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
            final dateString = '${date.day} ${months[date.month - 1]} ${date.year}';
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, top: 12),
                  child: Text(
                    dateString,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: memoriesForDate.length,
                  itemBuilder: (context, index) {
                    return MemoryCard(memory: memoriesForDate[index]);
                  },
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  List<Memory> _getMemoriesForDate(DateTime date) {
    final service = Provider.of<MemoryService>(context, listen: false);
    return service.memories.where((memory) {
      // memoryDate'i kullan, yoksa createdAt'ı kullan
      final checkDate = memory.memoryDate ?? memory.createdAt;
      return checkDate.year == date.year &&
          checkDate.month == date.month &&
          checkDate.day == date.day;
    }).toList();
  }

  Map<DateTime, List<Memory>> _groupMemoriesByDate(List<Memory> memories) {
    final grouped = <DateTime, List<Memory>>{};
    
    for (var memory in memories) {
      final checkDate = memory.memoryDate ?? memory.createdAt;
      final dateKey = DateTime(checkDate.year, checkDate.month, checkDate.day);
      
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(memory);
    }
    
    return grouped;
  }

  // Web ile aynı: Takvim gününün arka planını oluştur
  Widget _buildCalendarDayBackground(List<Memory> memories) {
    final photoMemory = memories.firstWhere(
      (m) => m.type.toLowerCase() == 'photo',
      orElse: () => memories.first,
    );

    print('Calendar background - Memory type: ${photoMemory.type}, fileUrl: ${photoMemory.fileUrl}, fullFileUrl: ${photoMemory.fullFileUrl}');

    if (photoMemory.type.toLowerCase() == 'photo' && photoMemory.fullFileUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: 0.4,
          child: Image.network(
            photoMemory.fullFileUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              print('Image error: $error');
              return Container(color: Colors.grey[200]);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(color: Colors.grey[100]);
            },
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  // Web ile aynı: Medya ikonları (fotoğraf yoksa ortada göster)
  Widget _buildMediaIcons(List<Memory> memories) {
    final nonPhotoMemories = memories.where((m) => m.type.toLowerCase() != 'photo').toList();
    if (nonPhotoMemories.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 2,
      runSpacing: 2,
      alignment: WrapAlignment.center,
      children: nonPhotoMemories.take(3).map((memory) {
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIconForType(memory.type),
            size: 10,
            color: Theme.of(context).primaryColor,
          ),
        );
      }).toList()
        ..addAll(nonPhotoMemories.length > 3
            ? [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '+${nonPhotoMemories.length - 3}',
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ]
            : []),
    );
  }

  // Web ile aynı: Küçük medya ikonları (fotoğraf varsa sağ altta göster)
  Widget _buildSmallMediaIcons(List<Memory> memories) {
    if (memories.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 1,
      runSpacing: 1,
      children: memories.take(4).map((memory) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIconForType(memory.type),
            size: 8,
            color: Theme.of(context).primaryColor,
          ),
        );
      }).toList()
        ..addAll(memories.length > 4
            ? [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '+${memories.length - 4}',
                      style: TextStyle(
                        fontSize: 6,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ]
            : []),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.videocam_rounded;
      case 'audio':
      case 'voice':
        return Icons.mic_rounded;
      case 'text':
        return Icons.text_fields_rounded;
      case 'song':
      case 'music':
        return Icons.music_note_rounded;
      default:
        return Icons.image_rounded;
    }
  }
}
