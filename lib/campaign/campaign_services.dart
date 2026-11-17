import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BlockType {
  imageText,
  textOnly,
  imageOnly,
}

enum ImagePosition {
  left,
  right,
}

enum ImageSourceType {
  none,
  url,
  file,
}

class CampaignBlock {
  final String id;
  BlockType type;
  ImagePosition imagePosition;
  ImageSourceType imageSourceType;
  String? imageUrl;
  String text;

  CampaignBlock({
    required this.id,
    required this.type,
    this.imagePosition = ImagePosition.left,
    this.imageSourceType = ImageSourceType.none,
    this.imageUrl,
    this.text = '',
  });

  CampaignBlock copyWith({
    String? id,
    BlockType? type,
    ImagePosition? imagePosition,
    ImageSourceType? imageSourceType,
    String? imageUrl,
    String? text,
  }) {
    return CampaignBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      imagePosition: imagePosition ?? this.imagePosition,
      imageSourceType: imageSourceType ?? this.imageSourceType,
      imageUrl: imageUrl ?? this.imageUrl,
      text: text ?? this.text,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'imagePosition': imagePosition.name,
      'imageSourceType': imageSourceType.name,
      'imageUrl': imageUrl,
      'text': text,
    };
  }

  factory CampaignBlock.fromJson(Map<String, dynamic> json) {
    return CampaignBlock(
      id: json['id'] as String? ?? UniqueKey().toString(),
      type: BlockType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BlockType.textOnly,
      ),
      imagePosition: ImagePosition.values.firstWhere(
        (e) => e.name == json['imagePosition'],
        orElse: () => ImagePosition.left,
      ),
      imageSourceType: ImageSourceType.values.firstWhere(
        (e) => e.name == json['imageSourceType'],
        orElse: () => ImageSourceType.none,
      ),
      imageUrl: json['imageUrl'] as String?,
      text: json['text'] as String? ?? '',
    );
  }
}

class CampaignModel {
  final String id;
  String name;
  final DateTime createdAt;
  DateTime updatedAt;
  List<CampaignBlock> blocks;

  CampaignModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.blocks,
  });

  CampaignModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<CampaignBlock>? blocks,
  }) {
    return CampaignModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      blocks: blocks ?? this.blocks.map((b) => b.copyWith()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'blocks': blocks.map((b) => b.toJson()).toList(),
    };
  }

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    return CampaignModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Untitled Campaign',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      blocks: (json['blocks'] as List<dynamic>?)
              ?.map((b) => CampaignBlock.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class CampaignService {
  static const String _storageKey = 'campaigns_list_storage';

  static Future<List<CampaignModel>> loadCampaigns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? rawJson = prefs.getString(_storageKey);
      if (rawJson == null || rawJson.isEmpty) {
        final initial = _getDefaultCampaigns();
        await saveCampaigns(initial);
        return initial;
      }
      final List<dynamic> decoded = jsonDecode(rawJson) as List<dynamic>;
      return decoded
          .map((item) => CampaignModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading campaigns: $e');
      return _getDefaultCampaigns();
    }
  }

  static Future<void> saveCampaigns(List<CampaignModel> campaigns) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String rawJson = jsonEncode(campaigns.map((c) => c.toJson()).toList());
      await prefs.setString(_storageKey, rawJson);
    } catch (e) {
      debugPrint('Error saving campaigns: $e');
    }
  }

  static List<CampaignModel> _getDefaultCampaigns() {
    final now = DateTime.now();
    return [
      CampaignModel(
        id: 'camp_1',
        name: 'Summer Sale Launch 2026',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
        blocks: [
          CampaignBlock(
            id: 'b1',
            type: BlockType.imageText,
            imagePosition: ImagePosition.left,
            imageSourceType: ImageSourceType.url,
            imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600',
            text: 'Discover our exclusive summer lineup with up to 50% discount on all items!',
          ),
          CampaignBlock(
            id: 'b2',
            type: BlockType.textOnly,
            text: 'Don\'t miss out on this limited-time offer. Free delivery on orders over \$50.',
          ),
        ],
      ),
      CampaignModel(
        id: 'camp_2',
        name: 'Product Newsletter #42',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 3)),
        blocks: [
          CampaignBlock(
            id: 'b3',
            type: BlockType.imageOnly,
            imageSourceType: ImageSourceType.url,
            imageUrl: 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=600',
            text: '',
          ),
          CampaignBlock(
            id: 'b4',
            type: BlockType.imageText,
            imagePosition: ImagePosition.right,
            imageSourceType: ImageSourceType.url,
            imageUrl: 'https://images.unsplash.com/photo-1551836022-d5d88e9218df?w=600',
            text: 'Introducing smart analytics with real-time feedback loops and campaign insights.',
          ),
        ],
      ),
    ];
  }
}

class CampaignNotifier extends Notifier<List<CampaignModel>> {
  @override
  List<CampaignModel> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final loaded = await CampaignService.loadCampaigns();
    state = loaded;
  }

  Future<void> addOrUpdateCampaign(CampaignModel campaign) async {
    final index = state.indexWhere((c) => c.id == campaign.id);
    List<CampaignModel> updated;
    if (index >= 0) {
      updated = [...state];
      updated[index] = campaign.copyWith(updatedAt: DateTime.now());
    } else {
      updated = [campaign, ...state];
    }
    state = updated;
    await CampaignService.saveCampaigns(updated);
  }

  Future<void> deleteCampaign(String id) async {
    final updated = state.where((c) => c.id != id).toList();
    state = updated;
    await CampaignService.saveCampaigns(updated);
  }
}

final campaignListProvider =
    NotifierProvider<CampaignNotifier, List<CampaignModel>>(() {
  return CampaignNotifier();
});
