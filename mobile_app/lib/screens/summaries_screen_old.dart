import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../services/memory_service.dart';
import '../services/auth_service.dart';
import '../models/memory.dart';

class SummariesScreen extends StatefulWidget {
  const SummariesScreen({Key? key}) : super(key: key);

  @override
  State<SummariesScreen> createState() => _SummariesScreenState();
}

class _SummariesScreenState extends State<SummariesScreen> {
  // Stats data
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _weeklyData = [];
  List<Map<String, dynamic>> _monthlyData = [];
  bool _isLoadingStats = true;
  
  // Collage generation state
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  List<Map<String, dynamic>> _availableWeeks = [];
  String? _selectedWeek;
  Map<String, dynamic>? _generatedCollage;
  bool _isGenerating = false;
  String? _error;
  bool _showWeeklyDialog = false;
  bool _showMonthlyDialog = false;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final memoryService = Provider.of<MemoryService>(context, listen: false);
      
      final stats = await memoryService.fetchStats();
      final weeklyStats = await memoryService.getWeeklyStats();
      final monthlyStats = await memoryService.getMonthlyStats();

      setState(() {
        _stats = stats;
        _weeklyData = weeklyStats ?? [];
        _monthlyData = monthlyStats ?? [];
        _isLoadingStats = false;
      });
    } catch (e) {
      print('Error loading statistics: $e');
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'İstatistikler',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Anılarınızın özeti ve istatistikleri',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            
            // Özet Oluştur Bölümü
            _buildCreateSummarySection(),
            const SizedBox(height: 32),
            
            // İstatistik Kartları
            _buildStatsCards(),
            const SizedBox(height: 24),
            
            // Format Dağılımı
            _buildFormatDistribution(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: Theme.of(context).primaryColor, size: 24),
            const SizedBox(width: 8),
            Text(
              'Özet Oluştur',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _CreateSummaryCard(
                title: 'Haftalık Özet',
                subtitle: 'Seçtiğiniz haftanın tüm fotoğraflarından kolaj oluşturun',
                icon: Icons.calendar_today_rounded,
                gradientColors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                onTap: () {
                  setState(() {
                    _showWeeklyDialog = true;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CreateSummaryCard(
                title: 'Aylık Özet',
                subtitle: 'Seçtiğiniz ayın tüm fotoğraflarından kolaj oluşturun',
                icon: Icons.calendar_month_rounded,
                gradientColors: [Color(0xFFA855F7), Color(0xFF9333EA)],
                onTap: () {
                  setState(() {
                    _showMonthlyDialog = true;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    if (_isLoadingStats) {
      return Center(child: CircularProgressIndicator());
    }

    final stats = _stats ?? {};
    final total = stats['total'] ?? 0;
    final thisWeek = stats['thisWeek'] ?? 0;
    final thisMonth = stats['thisMonth'] ?? 0;

    // Calculate daily average
    final weeklyUploads = _weeklyData.fold<int>(0, (sum, day) => sum + (day['uploads'] as int? ?? 0));
    final dailyAverage = weeklyUploads > 0 ? (weeklyUploads / 7).toStringAsFixed(1) : '0';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Günlük Ortalama',
                value: dailyAverage,
                subtitle: 'anı / gün',
                icon: Icons.trending_up_rounded,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Bu Hafta',
                value: '$thisWeek',
                subtitle: 'anı bu hafta',
                icon: Icons.calendar_today_rounded,
                color: Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatCard(
          title: 'Bu Ay',
          value: '$thisMonth',
          subtitle: 'anı bu ay',
          icon: Icons.calendar_month_rounded,
          color: Color(0xFFA855F7),
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildFormatDistribution() {
    if (_isLoadingStats) {
      return const SizedBox.shrink();
    }

    final stats = _stats ?? {};
    final byType = stats['byType'] as Map<String, dynamic>? ?? {};
    final total = stats['total'] ?? 1;

    final photo = byType['photo'] ?? 0;
    final video = byType['video'] ?? 0;
    final audio = byType['audio'] ?? 0;
    final text = byType['text'] ?? 0;
    final music = byType['music'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Format Dağılımı',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Yüklenen anıların format bazında dağılımı',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 20),
          _FormatBar(
            label: 'Fotoğraf',
            count: photo,
            total: total,
            icon: Icons.photo,
            color: Color(0xFF3B82F6),
          ),
          const SizedBox(height: 12),
          _FormatBar(
            label: 'Video',
            count: video,
            total: total,
            icon: Icons.videocam,
            color: Color(0xFFA855F7),
          ),
          const SizedBox(height: 12),
          _FormatBar(
            label: 'Metin',
            count: text,
            total: total,
            icon: Icons.text_fields,
            color: Color(0xFF10B981),
          ),
          const SizedBox(height: 12),
          _FormatBar(
            label: 'Ses',
            count: audio,
            total: total,
            icon: Icons.mic,
            color: Color(0xFFF59E0B),
          ),
          const SizedBox(height: 12),
          _FormatBar(
            label: 'Şarkı',
            count: music,
            total: total,
            icon: Icons.music_note,
            color: Color(0xFFEC4899),
          ),
        ],
      ),
    );
  }
    // Initialize map with 0 for all months (0-11)
    final map = Map<int, int>.fromIterable(
      List.generate(12, (i) => i),
      key: (i) => i,
      value: (_) => 0,
    );

    final currentYear = DateTime.now().year;

    for (var memory in memories) {
      if (memory.createdAt.year == currentYear) {
        map[memory.createdAt.month - 1] = (map[memory.createdAt.month - 1] ?? 0) + 1;
      }
    }
    return map;
  }

  Widget _buildStatsCards() {
    return Consumer<MemoryService>(
      builder: (context, service, _) {
        final total = service.memories.length;
        final thisMonth = service.memories
            .where((m) => m.createdAt.month == DateTime.now().month)
            .length;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Toplam Anı',
                    value: '$total',
                    icon: Icons.collections_rounded,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Bu Ay',
                    value: '$thisMonth',
                    icon: Icons.calendar_today_rounded,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildWizard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: Colors.amber.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                'Sihirli Anı Asistanı',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Seçtiğin tarih aralığındaki anıları harika bir hikayeye dönüştürelim.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
          const SizedBox(height: 24),
          if (_step == 1) _buildStep1PeriodType(),
          if (_step == 2) _buildStep2SpecificDate(),
          if (_step == 3) _buildStep3ContentType(),
          if (_step == 4) _buildStep4Result(),
        ],
      ),
    );
  }

  Widget _buildStep1PeriodType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. Hangi dönemi özetleyelim?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _PeriodButton(
                label: 'Haftalık',
                icon: Icons.date_range_rounded,
                onTap: () => setState(() {
                  _periodType = 'WEEK';
                  _step = 2;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PeriodButton(
                label: 'Aylık',
                icon: Icons.calendar_month_rounded,
                onTap: () => setState(() {
                  _periodType = 'MONTH';
                  _step = 2;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PeriodButton(
                label: 'Yıllık',
                icon: Icons.calendar_today_rounded,
                onTap: () => setState(() {
                  _periodType = 'YEAR';
                  _step = 2;
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2SpecificDate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '2. Hangi ${_periodType == 'WEEK' ? 'hafta' : _periodType == 'MONTH' ? 'ay' : 'yıl'}?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        if (_periodType == 'WEEK') ...[
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedYear,
                  decoration: InputDecoration(
                    labelText: 'Yıl',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [2024, 2025, 2026]
                      .map((year) => DropdownMenuItem(
                            value: year,
                            child: Text('$year'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedYear = value;
                        _loadAvailableWeeks();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedMonth,
                  decoration: InputDecoration(
                    labelText: 'Ay',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: List.generate(12, (i) => i + 1)
                      .map((month) => DropdownMenuItem(
                            value: month,
                            child: Text(_getMonthName(month)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedMonth = value;
                        _loadAvailableWeeks();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_availableWeeks.isNotEmpty)
            DropdownButtonFormField<String>(
              value: _selectedWeek,
              decoration: InputDecoration(
                labelText: 'Hafta Seçin',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _availableWeeks
                  .map((week) => DropdownMenuItem<String>(
                        value: week['weekStart'],
                        child: Text(
                            '${_formatDate(week['weekStart'])} - ${_formatDate(week['weekEnd'])} (${week['photoCount']} fotoğraf)'),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedWeek = value),
            )
          else
            Text(
              'Bu ay için fotoğraf bulunamadı',
              style: TextStyle(color: Colors.grey[600]),
            ),
        ] else if (_periodType == 'MONTH') ...[
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedYear,
                  decoration: InputDecoration(
                    labelText: 'Yıl',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [2024, 2025, 2026]
                      .map((year) => DropdownMenuItem(
                            value: year,
                            child: Text('$year'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedYear = value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedMonth,
                  decoration: InputDecoration(
                    labelText: 'Ay',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: List.generate(12, (i) => i + 1)
                      .map((month) => DropdownMenuItem(
                            value: month,
                            child: Text(_getMonthName(month)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedMonth = value);
                  },
                ),
              ),
            ],
          ),
        ] else ...[
          DropdownButtonFormField<int>(
            value: _selectedYear,
            decoration: InputDecoration(
              labelText: 'Yıl',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: [2024, 2025, 2026]
                .map((year) => DropdownMenuItem(
                      value: year,
                      child: Text('$year'),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedYear = value);
            },
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() => _step = 1),
              child: const Text('Geri'),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => setState(() => _step = 3),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Devam Et'),
            ),
          ],
        ),
      ],
    );
  }

  void _loadAvailableWeeks() async {
    final service = Provider.of<MemoryService>(context, listen: false);
    final weeks = await service.getAvailableWeeks(_selectedYear, _selectedMonth);
    setState(() {
      _availableWeeks = weeks;
      _selectedWeek = null;
    });
  }

  String _getMonthName(int month) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return months[month - 1];
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day}.${date.month}.${date.year}';
  }

  Widget _buildStep3ContentType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '3. Ne oluşturmak istersin?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        _ContentTypeCard(
          title: 'Hikaye Özeti',
          subtitle: 'Yapay zeka ile bu dönemin hikayesini yaz',
          icon: Icons.auto_awesome_rounded,
          color: Colors.amber,
          onTap: () => setState(() {
            _generationType = 'SUMMARY';
            _step = 4;
          }),
        ),
        const SizedBox(height: 12),
        _ContentTypeCard(
          title: 'Anı Kolajı',
          subtitle: 'Bu döneme ait fotoğraflardan bir kolaj oluştur',
          icon: Icons.grid_view_rounded,
          color: Colors.purple,
          onTap: () async {
            setState(() {
              _generationType = 'COLLAGE';
              _isGenerating = true;
              _error = null;
            });
            await _generateCollage();
            setState(() => _step = 4);
          },
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _step = 2),
          child: const Text('Tarihi Değiştir'),
        ),
      ],
    );
  }

  Widget _buildStep4Result() {
    if (_isGenerating) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Kolaj oluşturuluyor...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.red.shade700)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {
                _step = 1;
                _error = null;
              }),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Özet Oluşturuldu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() {
                  _step = 1;
                  _periodType = null;
                  _specificDateValue = null;
                  _generationType = null;
                  _generatedCollage = null;
                }),
                child: const Text('Yeni Oluştur'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_generationType == 'SUMMARY')
            Text(
              'Bu dönemde toplam ${Provider.of<MemoryService>(context, listen: false).memories.length} anı eklendi. En çok fotoğraf ve video tipi anılar paylaşıldı. Güzel günler geçirdiğiniz anlaşılıyor!',
              style: TextStyle(color: Colors.grey[700], height: 1.5),
            )
          else if (_generatedCollage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                // Use a helper method or verify if _generatedCollage['url'] needs fix
                // Assuming backend returns relative path like /uploads/...
                _generatedCollage!['url'].toString().startsWith('http')
                    ? _generatedCollage!['url']
                    : 'http://10.0.2.2:5299${_generatedCollage!['url']}',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Center(
                      child: Text('Kolaj yüklenemedi'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Download functionality will be added
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('İndirme özelliği yakında eklenecek')),
                );
              },
              icon: Icon(Icons.download),
              label: Text('Kolajı İndir'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _generateCollage() async {
    final service = Provider.of<MemoryService>(context, listen: false);
    
    try {
      Map<String, dynamic>? result;
      
      if (_periodType == 'WEEK') {
        if (_selectedWeek == null) {
          setState(() => _error = 'Lütfen bir hafta seçin');
          return;
        }
        result = await service.generateWeeklyCollage(_selectedWeek!);
      } else if (_periodType == 'MONTH') {
        result = await service.generateMonthlyCollage(_selectedYear, _selectedMonth);
      } else if (_periodType == 'YEAR') {
        result = await service.generateYearlyCollage(_selectedYear);
      }
      
      if (result != null) {
        setState(() {
          _generatedCollage = result;
          _isGenerating = false;
        });
      } else {
        setState(() {
          _error = 'Kolaj oluşturulamadı';
          _isGenerating = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Bir hata oluştu: $e';
        _isGenerating = false;
      });
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool isWide;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateSummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _CreateSummaryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final IconData icon;
  final Color color;

  const _FormatBar({
    required this.label,
    required this.count,
    required this.total,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
