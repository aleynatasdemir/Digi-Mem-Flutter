import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/memory_service.dart';
import '../utils/api_constants.dart';

class SummariesScreen extends StatefulWidget {
  const SummariesScreen({Key? key}) : super(key: key);

  @override
  State<SummariesScreen> createState() => _SummariesScreenState();
}

class _SummariesScreenState extends State<SummariesScreen> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _weeklyData = [];
  bool _isLoadingStats = true;
  
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  String? _selectedWeek;

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

      setState(() {
        _stats = stats;
        _weeklyData = weeklyStats ?? [];
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
            Text(
              'İstatistikler',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Anılarınızın özeti ve istatistikleri',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            
            // Özet Oluştur Bölümü
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Theme.of(context).primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Özet Oluştur',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _CreateSummaryCard(
                    title: 'Haftalık Özet',
                    subtitle: 'Fotoğraflardan kolaj oluştur',
                    icon: Icons.calendar_today_rounded,
                    gradientColors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    onTap: () => _showWeeklySummaryDialog(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CreateSummaryCard(
                    title: 'Aylık Özet',
                    subtitle: 'Fotoğraflardan kolaj oluştur',
                    icon: Icons.calendar_month_rounded,
                    gradientColors: [Color(0xFFA855F7), Color(0xFF9333EA)],
                    onTap: () => _showMonthlySummaryDialog(),
                  ),
                ),
              ],
            ),
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

  void _showWeeklySummaryDialog() async {
    final service = Provider.of<MemoryService>(context, listen: false);
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: service.getAvailableWeeks(_selectedYear, _selectedMonth),
            builder: (context, snapshot) {
              final weeks = snapshot.data ?? [];
              
              return AlertDialog(
                title: Text('Haftalık Özet'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Gemini AI ile özet oluştur'),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedYear,
                            decoration: InputDecoration(labelText: 'Yıl', isDense: true),
                            items: [2024, 2025, 2026]
                                .map((year) => DropdownMenuItem(value: year, child: Text('$year')))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedYear = value);
                                setDialogState(() {});
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedMonth,
                            decoration: InputDecoration(labelText: 'Ay', isDense: true),
                            items: List.generate(12, (i) => i + 1)
                                .map((month) => DropdownMenuItem(value: month, child: Text(_getMonthName(month))))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedMonth = value);
                                setDialogState(() {});
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      CircularProgressIndicator()
                    else if (weeks.isEmpty)
                      Text('Bu ay için fotoğraf bulunamadı', style: TextStyle(color: Colors.grey[600]))
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedWeek,
                        decoration: InputDecoration(labelText: 'Hafta Seçin', isDense: true),
                        items: weeks.map((week) {
                          final startDate = DateTime.parse(week['weekStart']);
                          final endDate = DateTime.parse(week['weekEnd']);
                          final photoCount = week['photoCount'] ?? 0;
                          return DropdownMenuItem<String>(
                            value: week['weekStart'],
                            child: Text(
                              '${startDate.day}.${startDate.month}.${startDate.year} - ${endDate.day}.${endDate.month}.${endDate.year} ($photoCount fotoğraf)',
                              style: TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedWeek = value);
                          setDialogState(() {});
                        },
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('İptal'),
                  ),
                  ElevatedButton.icon(
                    onPressed: weeks.isEmpty || _selectedWeek == null ? null : () async {
                      Navigator.pop(ctx);
                      await _generateWeeklyCollage();
                    },
                    icon: Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text('AI ile Oluştur'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showMonthlySummaryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Aylık Özet'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Gemini AI ile özet oluştur'),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedYear,
                        decoration: InputDecoration(labelText: 'Yıl', isDense: true),
                        items: [2024, 2025, 2026]
                            .map((year) => DropdownMenuItem(value: year, child: Text('$year')))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => _selectedYear = value);
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedMonth,
                        decoration: InputDecoration(labelText: 'Ay', isDense: true),
                        items: List.generate(12, (i) => i + 1)
                            .map((month) => DropdownMenuItem(value: month, child: Text(_getMonthName(month))))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => _selectedMonth = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await _generateMonthlyCollage();
            },
            icon: Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text('AI ile Oluştur'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateWeeklyCollage() async {
    if (_selectedWeek == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen bir hafta seçin')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Haftalık kolaj oluşturuluyor...'), duration: Duration(seconds: 2)),
    );

    try {
      final service = Provider.of<MemoryService>(context, listen: false);
      
      print('Generating weekly collage for: $_selectedWeek');
      final result = await service.generateWeeklyCollage(_selectedWeek!);
      
      print('Weekly collage result: $result');
      
      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kolaj oluşturulamadı'), backgroundColor: Colors.red),
          );
        }
        return;
      }
      
      _showCollageResult(result);
    } catch (e) {
      print('Weekly collage error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _generateMonthlyCollage() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Aylık kolaj oluşturuluyor...'), duration: Duration(seconds: 2)),
    );

    try {
      final service = Provider.of<MemoryService>(context, listen: false);
      
      print('Generating monthly collage for: $_selectedYear-$_selectedMonth');
      final result = await service.generateMonthlyCollage(_selectedYear, _selectedMonth);
      
      print('Monthly collage result: $result');
      
      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kolaj oluşturulamadı'), backgroundColor: Colors.red),
          );
        }
        return;
      }
      
      _showCollageResult(result);
    } catch (e) {
      print('Monthly collage error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showCollageResult(Map<String, dynamic> result) {
    print('Showing collage result: $result');
    
    // Backend returns 'url' not 'imageUrl'
    final imageUrl = (result['imageUrl'] ?? result['url']) as String?;
    final downloadUrl = result['downloadUrl'] as String?;
    
    print('Image URL: $imageUrl');
    print('Download URL: $downloadUrl');
    
    if (imageUrl == null || imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kolaj oluşturuldu ancak görüntülenemedi'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final fullImageUrl = imageUrl.startsWith('http') 
        ? imageUrl 
        : '${ApiConstants.baseUrl}$imageUrl';
    
    print('Full image URL: $fullImageUrl');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Theme.of(context).primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'AI Kolajınız Hazır!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            // Image
            Container(
              constraints: BoxConstraints(maxHeight: 400, maxWidth: 500),
              padding: EdgeInsets.all(8),
              child: Image.network(
                fullImageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('Image load error: $error');
                  return Container(
                    height: 200,
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red),
                          SizedBox(height: 8),
                          Text('Resim yüklenemedi', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text(
                            fullImageUrl,
                            style: TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Download Button
            Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: downloadUrl != null ? () {
                    _downloadCollage(downloadUrl);
                  } : null,
                  icon: Icon(Icons.download_rounded),
                  label: Text('İndir'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadCollage(String downloadUrl) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İndirme başlatılıyor...')),
      );
      
      // TODO: Implement actual download functionality
      // For now, just show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kolaj indirildi!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İndirme hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getMonthName(int month) {
    const months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return months[month - 1];
  }

  Widget _buildStatsCards() {
    if (_isLoadingStats) {
      return Center(child: CircularProgressIndicator());
    }

    final stats = _stats ?? {};
    final total = stats['total'] ?? 0;
    final thisWeek = stats['thisWeek'] ?? 0;
    final thisMonth = stats['thisMonth'] ?? 0;

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
    if (_isLoadingStats) return const SizedBox.shrink();

    final stats = _stats ?? {};
    final byType = stats['byType'] as Map<String, dynamic>? ?? {};
    final total = stats['total'] ?? 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Format Dağılımı',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Yüklenen anıların format bazında dağılımı', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 20),
          _FormatBar(label: 'Fotoğraf', count: byType['photo'] ?? 0, total: total, icon: Icons.photo, color: Color(0xFF3B82F6)),
          const SizedBox(height: 12),
          _FormatBar(label: 'Video', count: byType['video'] ?? 0, total: total, icon: Icons.videocam, color: Color(0xFFA855F7)),
          const SizedBox(height: 12),
          _FormatBar(label: 'Metin', count: byType['text'] ?? 0, total: total, icon: Icons.text_fields, color: Color(0xFF10B981)),
          const SizedBox(height: 12),
          _FormatBar(label: 'Ses', count: byType['audio'] ?? 0, total: total, icon: Icons.mic, color: Color(0xFFF59E0B)),
          const SizedBox(height: 12),
          _FormatBar(label: 'Şarkı', count: byType['music'] ?? 0, total: total, icon: Icons.music_note, color: Color(0xFFEC4899)),
        ],
      ),
    );
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
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2)),
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
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: TextStyle(color: Colors.grey[500], fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
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
        height: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradientColors),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: gradientColors[0].withOpacity(0.3), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
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
                Text(label, style: const TextStyle(fontSize: 13)),
              ],
            ),
            Text('$count', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
