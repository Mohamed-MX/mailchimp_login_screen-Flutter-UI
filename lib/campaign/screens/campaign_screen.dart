import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../campaign_services.dart';

class CampaignScreen extends ConsumerStatefulWidget {
  final CampaignModel? campaign;

  const CampaignScreen({
    super.key,
    this.campaign,
  });

  @override
  ConsumerState<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends ConsumerState<CampaignScreen> {
  late TextEditingController _titleController;
  late String _campaignId;
  late DateTime _createdAt;
  late List<CampaignBlock> _blocks;
  final Map<String, TextEditingController> _textControllers = {};

  @override
  void initState() {
    super.initState();
    if (widget.campaign != null) {
      _campaignId = widget.campaign!.id;
      _titleController = TextEditingController(text: widget.campaign!.name);
      _createdAt = widget.campaign!.createdAt;
      _blocks = widget.campaign!.blocks
          .map((b) => b.copyWith())
          .toList();
    } else {
      _campaignId = 'camp_${DateTime.now().millisecondsSinceEpoch}';
      _titleController = TextEditingController(text: 'New Campaign');
      _createdAt = DateTime.now();
      _blocks = [
        CampaignBlock(
          id: 'blk_${DateTime.now().millisecondsSinceEpoch}_1',
          type: BlockType.imageText,
          imagePosition: ImagePosition.left,
          text: 'Welcome to this new campaign!',
        ),
      ];
    }

    for (final block in _blocks) {
      _textControllers[block.id] = TextEditingController(text: block.text);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncControllersToBlocks() {
    for (final block in _blocks) {
      if (_textControllers.containsKey(block.id)) {
        block.text = _textControllers[block.id]!.text;
      }
    }
  }

  void _addBlock(BlockType type) {
    _syncControllersToBlocks();
    final newId = 'blk_${DateTime.now().millisecondsSinceEpoch}';
    final newBlock = CampaignBlock(
      id: newId,
      type: type,
      imagePosition: ImagePosition.left,
      text: '',
    );
    _textControllers[newId] = TextEditingController(text: '');
    setState(() {
      _blocks.add(newBlock);
    });
  }

  void _removeBlock(int index) {
    _syncControllersToBlocks();
    final removed = _blocks.removeAt(index);
    _textControllers[removed.id]?.dispose();
    _textControllers.remove(removed.id);
    setState(() {});
  }

  void _moveBlock(int oldIndex, int newIndex) {
    if (newIndex < 0 || newIndex >= _blocks.length) return;
    _syncControllersToBlocks();
    setState(() {
      final item = _blocks.removeAt(oldIndex);
      _blocks.insert(newIndex, item);
    });
  }

  void _saveCampaign() {
    _syncControllersToBlocks();
    final updatedCampaign = CampaignModel(
      id: _campaignId,
      name: _titleController.text.trim().isEmpty
          ? 'Untitled Campaign'
          : _titleController.text.trim(),
      createdAt: _createdAt,
      updatedAt: DateTime.now(),
      blocks: _blocks,
    );

    ref.read(campaignListProvider.notifier).addOrUpdateCampaign(updatedCampaign);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Campaign saved successfully!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showImageOptionsModal(CampaignBlock block) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Select Image Option',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE01B).withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.link, color: Colors.black87),
                  ),
                  title: const Text(
                    'Option 1: Online Image',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Paste an image URL from the web'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showPasteUrlDialog(block);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.folder_open, color: Colors.blue),
                  ),
                  title: const Text(
                    'Option 2: File Picker',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Pick an image file from your device'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _pickLocalFile(block);
                  },
                ),
                if (block.imageUrl != null && block.imageUrl!.isNotEmpty) ...[
                  const Divider(),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                    title: const Text(
                      'Remove Image',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      setState(() {
                        block.imageUrl = null;
                        block.imageSourceType = ImageSourceType.none;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPasteUrlDialog(CampaignBlock block) {
    final urlController = TextEditingController(
      text: block.imageSourceType == ImageSourceType.url ? block.imageUrl : '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Enter Image URL'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'https://example.com/image.jpg',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFE01B),
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                final link = urlController.text.trim();
                if (link.isNotEmpty) {
                  setState(() {
                    block.imageUrl = link;
                    block.imageSourceType = ImageSourceType.url;
                  });
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Save Link'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickLocalFile(CampaignBlock block) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.image,
      );

      if (file != null && file.path != null) {
        setState(() {
          block.imageUrl = file.path;
          block.imageSourceType = ImageSourceType.file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _saveCampaign();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
          title: const Text(
            'Edit Campaign',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save_outlined),
              tooltip: 'Save Campaign',
              onPressed: () {
                _saveCampaign();
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Campaign Title Note Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Campaign Name',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF242424),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Enter campaign name...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Blocks Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CAMPAIGN BLOCKS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  '${_blocks.length} Blocks',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Horizontal blocks stacked
            if (_blocks.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.dashboard_customize_outlined,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No blocks added yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add an image, text, or combination below',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
            else
              ..._blocks.asMap().entries.map((entry) {
                final index = entry.key;
                final block = entry.value;
                return _buildBlockCard(index, block);
              }),

            const SizedBox(height: 24),

            // Block creation controls
            _buildAddBlockSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockCard(int index, CampaignBlock block) {
    if (!_textControllers.containsKey(block.id)) {
      _textControllers[block.id] = TextEditingController(text: block.text);
    }
    final textController = _textControllers[block.id]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Block Header with Tools
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
              ),
            ),
            child: Row(
              children: [
                _buildBlockTypeBadge(block.type),
                const Spacer(),
                if (block.type == BlockType.imageText) ...[
                  IconButton(
                    icon: const Icon(Icons.swap_horiz, size: 20),
                    tooltip: 'Swap text and image sides',
                    onPressed: () {
                      setState(() {
                        block.imagePosition =
                            block.imagePosition == ImagePosition.left
                                ? ImagePosition.right
                                : ImagePosition.left;
                      });
                    },
                  ),
                ],
                if (index > 0)
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, size: 18),
                    tooltip: 'Move up',
                    onPressed: () => _moveBlock(index, index - 1),
                  ),
                if (index < _blocks.length - 1)
                  IconButton(
                    icon: const Icon(Icons.arrow_downward, size: 18),
                    tooltip: 'Move down',
                    onPressed: () => _moveBlock(index, index + 1),
                  ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.red),
                  tooltip: 'Delete Block',
                  onPressed: () => _removeBlock(index),
                ),
              ],
            ),
          ),

          // Block Content Area
          Padding(
            padding: const EdgeInsets.all(14),
            child: _buildBlockContent(block, textController),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockTypeBadge(BlockType type) {
    String label;
    IconData icon;
    switch (type) {
      case BlockType.imageText:
        label = 'Image & Text Block';
        icon = Icons.view_sidebar_outlined;
        break;
      case BlockType.textOnly:
        label = 'Just Text Block';
        icon = Icons.text_fields;
        break;
      case BlockType.imageOnly:
        label = 'Just Image Block';
        icon = Icons.image_outlined;
        break;
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black87),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildBlockContent(
      CampaignBlock block, TextEditingController textController) {
    switch (block.type) {
      case BlockType.textOnly:
        return _buildTextArea(textController, 'Enter campaign text here...');
      case BlockType.imageOnly:
        return _buildImagePlaceholder(block, height: 180);
      case BlockType.imageText:
        final imageWidget = Expanded(
          flex: 1,
          child: _buildImagePlaceholder(block, height: 130),
        );
        final textWidget = Expanded(
          flex: 1,
          child: Padding(
            padding: EdgeInsets.only(
              left: block.imagePosition == ImagePosition.left ? 12 : 0,
              right: block.imagePosition == ImagePosition.right ? 12 : 0,
            ),
            child: _buildTextArea(textController, 'Add text next to image...', minLines: 4),
          ),
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: block.imagePosition == ImagePosition.left
              ? [imageWidget, textWidget]
              : [textWidget, imageWidget],
        );
    }
  }

  Widget _buildTextArea(TextEditingController controller, String hint,
      {int minLines = 3}) {
    return TextField(
      controller: controller,
      maxLines: null,
      minLines: minLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black87, width: 1.5),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.all(12),
      ),
      style: const TextStyle(fontSize: 14, height: 1.4),
    );
  }

  Widget _buildImagePlaceholder(CampaignBlock block, {required double height}) {
    final hasImage = block.imageUrl != null && block.imageUrl!.isNotEmpty;

    return InkWell(
      onTap: () => _showImageOptionsModal(block),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasImage ? Colors.transparent : Colors.grey.shade300,
            style: hasImage ? BorderStyle.none : BorderStyle.solid,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            if (hasImage)
              _renderBlockImage(block)
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 32, color: Colors.grey[600]),
                  const SizedBox(height: 6),
                  Text(
                    'Click to add image',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'URL link or file',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
            if (hasImage)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Change',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _renderBlockImage(CampaignBlock block) {
    if (block.imageSourceType == ImageSourceType.file) {
      final file = File(block.imageUrl!);
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, color: Colors.red, size: 30),
                const SizedBox(height: 4),
                Text('File not accessible',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          );
        },
      );
    } else {
      return Image.network(
        block.imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, color: Colors.red, size: 30),
                const SizedBox(height: 4),
                Text('Invalid image link',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildAddBlockSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Block Layout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAddButton(
                  icon: Icons.view_sidebar_outlined,
                  label: 'Image + Text',
                  onTap: () => _addBlock(BlockType.imageText),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAddButton(
                  icon: Icons.text_fields,
                  label: 'Just Text',
                  onTap: () => _addBlock(BlockType.textOnly),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAddButton(
                  icon: Icons.image_outlined,
                  label: 'Just Image',
                  onTap: () => _addBlock(BlockType.imageOnly),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: Colors.black87),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
