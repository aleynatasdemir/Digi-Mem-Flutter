import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/memory_service.dart';
import '../services/auth_service.dart';
import '../services/upload_service.dart';
import '../models/memory.dart';

class AddMemoryScreen extends StatefulWidget {
  final String? initialType;
  
  const AddMemoryScreen({Key? key, this.initialType}) : super(key: key);

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();
  late String _memoryType;
  DateTime _selectedDate = DateTime.now();
  final List<String> _tags = [];
  bool _isLoading = false;
  File? _selectedFile;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    _memoryType = widget.initialType ?? 'TEXT';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    XFile? pickedFile;

    try {
      if (_memoryType == 'PHOTO') {
        pickedFile = await picker.pickImage(source: ImageSource.gallery);
      } else if (_memoryType == 'VIDEO') {
        pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      } else if (_memoryType == 'AUDIO') {
        // Audio picker - for now show a message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ses dosyalarını galeriden seçebilirsiniz'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile!.path);
          _fileName = pickedFile!.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya seçilirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearFile() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
    });
  }

  Future<void> _saveMemory() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if media types have file selected
    if (_memoryType != 'TEXT' && _selectedFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen bir dosya seçin'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final memoryService = Provider.of<MemoryService>(context, listen: false);
    final uploadService = UploadService(authService);

    String? fileUrl;
    String? thumbnailUrl;

    // Upload file if selected
    if (_selectedFile != null) {
      try {
        final uploadResponse = await uploadService.uploadFile(_selectedFile!, _memoryType.toLowerCase());
        
        if (uploadResponse != null) {
          fileUrl = uploadResponse.fileUrl;
          thumbnailUrl = uploadResponse.thumbnailUrl;
          print('Upload successful - fileUrl: $fileUrl, thumbnailUrl: $thumbnailUrl');
        } else {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Dosya yüklenemedi'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Yükleme hatası: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    final memory = Memory(
      type: _memoryType,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      memoryDate: _selectedDate,
      createdAt: DateTime.now(),
      tags: _tags,
      fileUrl: fileUrl,
      thumbnailUrl: thumbnailUrl,
      userId: authService.user!.id,
    );

    final success = await memoryService.createMemory(memory);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anı başarıyla kaydedildi'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anı kaydedilemedi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getMemoryTypeLabel() {
    switch (_memoryType.toUpperCase()) {
      case 'PHOTO':
        return 'Fotoğraf';
      case 'VIDEO':
        return 'Video';
      case 'AUDIO':
        return 'Ses Kaydı';
      case 'SONG':
        return 'Şarkı';
      case 'TEXT':
      default:
        return 'Metin';
    }
  }

  IconData _getMemoryTypeIcon() {
    switch (_memoryType.toUpperCase()) {
      case 'PHOTO':
        return Icons.photo;
      case 'VIDEO':
        return Icons.videocam;
      case 'AUDIO':
        return Icons.mic;
      case 'SONG':
        return Icons.music_note;
      case 'TEXT':
      default:
        return Icons.note;
    }
  }

  Color _getMemoryTypeColor() {
    switch (_memoryType.toUpperCase()) {
      case 'PHOTO':
        return Colors.blue;
      case 'VIDEO':
        return Colors.purple;
      case 'AUDIO':
        return Colors.orange;
      case 'SONG':
        return Colors.pink;
      case 'TEXT':
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_getMemoryTypeLabel()} Ekle'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveMemory,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type Header Card
            Card(
              color: _getMemoryTypeColor().withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getMemoryTypeColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getMemoryTypeIcon(),
                        color: _getMemoryTypeColor(),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getMemoryTypeLabel(),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Yeni bir ${_getMemoryTypeLabel().toLowerCase()} anı ekle',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Başlık',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Başlık gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),

            // File Selection (for media types)
            if (_memoryType != 'TEXT')
              Card(
                color: _getMemoryTypeColor().withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dosya Seç',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_selectedFile == null)
                        InkWell(
                          onTap: _pickFile,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _getMemoryTypeColor(),
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: _getMemoryTypeColor().withOpacity(0.05),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    color: _getMemoryTypeColor(),
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _memoryType == 'PHOTO'
                                        ? 'Fotoğraf Seç'
                                        : _memoryType == 'VIDEO'
                                            ? 'Video Seç'
                                            : 'Dosya Seç',
                                    style: TextStyle(
                                      color: _getMemoryTypeColor(),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Galeriden seçmek için dokunun',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getMemoryTypeColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _memoryType == 'PHOTO'
                                        ? Icons.image
                                        : Icons.video_library,
                                    color: _getMemoryTypeColor(),
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _fileName ?? 'Dosya',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          maxLines: 1,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${(_selectedFile!.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: _clearFile,
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: _pickFile,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Başka Dosya Seç'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Date
            ListTile(
              title: const Text('Tarih'),
              subtitle: Text(
                '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
            ),
            const SizedBox(height: 16),

            // Tags
            TextField(
              controller: _tagController,
              decoration: InputDecoration(
                labelText: 'Etiket Ekle',
                hintText: 'Etiket yazıp Enter tuşuna bas',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final tag = _tagController.text.trim();
                    if (tag.isNotEmpty && !_tags.contains(tag)) {
                      setState(() {
                        _tags.add(tag);
                        _tagController.clear();
                      });
                    }
                  },
                ),
              ),
              onSubmitted: (value) {
                final tag = value.trim();
                if (tag.isNotEmpty && !_tags.contains(tag)) {
                  setState(() {
                    _tags.add(tag);
                    _tagController.clear();
                  });
                }
              },
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        onDeleted: () {
                          setState(() => _tags.remove(tag));
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
