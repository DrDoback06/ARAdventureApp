import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

enum SyncStatus {
  idle,
  syncing,
  synced,
  failed,
  offline,
}

enum DataType {
  character,
  inventory,
  achievements,
  quests,
  settings,
  analytics,
  social,
  battle,
}

class CloudSaveData {
  final String id;
  final DataType type;
  final Map<String, dynamic> data;
  final DateTime lastModified;
  final String? userId;
  final String? deviceId;
  final int version;

  CloudSaveData({
    String? id,
    required this.type,
    required this.data,
    DateTime? lastModified,
    this.userId,
    this.deviceId,
    this.version = 1,
  })  : id = id ?? _generateDataId(),
        lastModified = lastModified ?? DateTime.now();

  static String _generateDataId() {
    return 'cloud_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'data': data,
      'lastModified': lastModified.toIso8601String(),
      'userId': userId,
      'deviceId': deviceId,
      'version': version,
    };
  }

  factory CloudSaveData.fromJson(Map<String, dynamic> json) {
    return CloudSaveData(
      id: json['id'],
      type: DataType.values.firstWhere((e) => e.name == json['type']),
      data: Map<String, dynamic>.from(json['data']),
      lastModified: DateTime.parse(json['lastModified']),
      userId: json['userId'],
      deviceId: json['deviceId'],
      version: json['version'] ?? 1,
    );
  }
}

class SyncOperation {
  final String id;
  final DataType type;
  final SyncStatus status;
  final DateTime timestamp;
  final String? errorMessage;
  final int retryCount;

  SyncOperation({
    String? id,
    required this.type,
    this.status = SyncStatus.idle,
    DateTime? timestamp,
    this.errorMessage,
    this.retryCount = 0,
  })  : id = id ?? _generateOperationId(),
        timestamp = timestamp ?? DateTime.now();

  static String _generateOperationId() {
    return 'sync_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
  }

  SyncOperation copyWith({
    String? id,
    DataType? type,
    SyncStatus? status,
    DateTime? timestamp,
    String? errorMessage,
    int? retryCount,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'errorMessage': errorMessage,
      'retryCount': retryCount,
    };
  }

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'],
      type: DataType.values.firstWhere((e) => e.name == json['type']),
      status: SyncStatus.values.firstWhere((e) => e.name == json['status']),
      timestamp: DateTime.parse(json['timestamp']),
      errorMessage: json['errorMessage'],
      retryCount: json['retryCount'] ?? 0,
    );
  }
}

class CloudSaveService extends ChangeNotifier {
  static CloudSaveService? _instance;
  static CloudSaveService get instance => _instance ??= CloudSaveService._();
  
  CloudSaveService._();
  
  List<CloudSaveData> _cloudData = [];
  List<SyncOperation> _syncOperations = [];
  SyncStatus _overallStatus = SyncStatus.idle;
  bool _isOnline = true;
  bool _autoSync = true;
  String? _currentUserId;
  String? _deviceId;
  
  // Getters
  List<CloudSaveData> get cloudData => _cloudData;
  List<SyncOperation> get syncOperations => _syncOperations;
  SyncStatus get overallStatus => _overallStatus;
  bool get isOnline => _isOnline;
  bool get autoSync => _autoSync;
  String? get currentUserId => _currentUserId;
  String? get deviceId => _deviceId;

  // Initialize cloud save service
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('cloud_save_data');
      final savedOperations = prefs.getString('cloud_sync_operations');
      final autoSync = prefs.getBool('cloud_auto_sync') ?? true;
      final deviceId = prefs.getString('device_id');
      
      if (savedData != null) {
        final List<dynamic> dataJson = jsonDecode(savedData);
        _cloudData = dataJson.map((json) => CloudSaveData.fromJson(json)).toList();
      }
      
      if (savedOperations != null) {
        final List<dynamic> operationsJson = jsonDecode(savedOperations);
        _syncOperations = operationsJson.map((json) => SyncOperation.fromJson(json)).toList();
      }
      
      _autoSync = autoSync;
      _deviceId = deviceId ?? _generateDeviceId();
      
      // Save device ID
      await prefs.setString('device_id', _deviceId!);
      
      debugPrint('[CLOUD_SAVE] Service initialized with ${_cloudData.length} data items');
    } catch (e) {
      debugPrint('[CLOUD_SAVE] Error initializing: $e');
    }
  }

  // Generate device ID
  String _generateDeviceId() {
    return 'device_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(10000)}';
  }

  // Set user ID
  void setUserId(String userId) {
    _currentUserId = userId;
    notifyListeners();
  }

  // Set online status
  void setOnlineStatus(bool isOnline) {
    _isOnline = isOnline;
    if (isOnline && _autoSync) {
      _syncAllData();
    }
    notifyListeners();
  }

  // Enable/disable auto sync
  Future<void> setAutoSync(bool enabled) async {
    _autoSync = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cloud_auto_sync', enabled);
    notifyListeners();
  }

  // Save data to cloud
  Future<bool> saveData(DataType type, Map<String, dynamic> data) async {
    try {
      // Create or update cloud save data
      final existingIndex = _cloudData.indexWhere((item) => item.type == type);
      
      final cloudData = CloudSaveData(
        type: type,
        data: data,
        userId: _currentUserId,
        deviceId: _deviceId,
        version: existingIndex >= 0 ? _cloudData[existingIndex].version + 1 : 1,
      );
      
      if (existingIndex >= 0) {
        _cloudData[existingIndex] = cloudData;
      } else {
        _cloudData.add(cloudData);
      }
      
      // Create sync operation
      final syncOperation = SyncOperation(
        type: type,
        status: _isOnline ? SyncStatus.syncing : SyncStatus.offline,
      );
      _syncOperations.add(syncOperation);
      
      await _saveCloudData();
      await _saveSyncOperations();
      
      if (_isOnline && _autoSync) {
        _syncData(type);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[CLOUD_SAVE] Error saving data: $e');
      return false;
    }
  }

  // Load data from cloud
  Future<Map<String, dynamic>?> loadData(DataType type) async {
    try {
      final cloudData = _cloudData.firstWhere(
        (item) => item.type == type,
        orElse: () => CloudSaveData(type: type, data: {}),
      );
      
      return cloudData.data;
    } catch (e) {
      debugPrint('[CLOUD_SAVE] Error loading data: $e');
      return null;
    }
  }

  // Sync specific data type
  Future<void> _syncData(DataType type) async {
    if (!_isOnline) return;
    
    try {
      final operation = _syncOperations.firstWhere(
        (op) => op.type == type && op.status == SyncStatus.syncing,
        orElse: () => SyncOperation(type: type, status: SyncStatus.syncing),
      );
      
      final operationIndex = _syncOperations.indexWhere((op) => op.id == operation.id);
      if (operationIndex >= 0) {
        _syncOperations[operationIndex] = operation.copyWith(
          status: SyncStatus.synced,
        );
      }
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      debugPrint('[CLOUD_SAVE] Synced data type: ${type.name}');
      notifyListeners();
    } catch (e) {
      debugPrint('[CLOUD_SAVE] Error syncing data: $e');
      
      final operationIndex = _syncOperations.indexWhere((op) => op.type == type);
      if (operationIndex >= 0) {
        _syncOperations[operationIndex] = _syncOperations[operationIndex].copyWith(
          status: SyncStatus.failed,
          errorMessage: e.toString(),
          retryCount: _syncOperations[operationIndex].retryCount + 1,
        );
      }
      
      notifyListeners();
    }
  }

  // Sync all data
  Future<void> _syncAllData() async {
    if (!_isOnline) return;
    
    _overallStatus = SyncStatus.syncing;
    notifyListeners();
    
    try {
      for (final dataType in DataType.values) {
        await _syncData(dataType);
      }
      
      _overallStatus = SyncStatus.synced;
      debugPrint('[CLOUD_SAVE] All data synced successfully');
    } catch (e) {
      _overallStatus = SyncStatus.failed;
      debugPrint('[CLOUD_SAVE] Error syncing all data: $e');
    }
    
    notifyListeners();
  }

  // Manual sync
  Future<void> syncNow() async {
    await _syncAllData();
  }

  // Retry failed syncs
  Future<void> retryFailedSyncs() async {
    final failedOperations = _syncOperations.where((op) => op.status == SyncStatus.failed).toList();
    
    for (final operation in failedOperations) {
      if (operation.retryCount < 3) {
        final index = _syncOperations.indexWhere((op) => op.id == operation.id);
        if (index >= 0) {
          _syncOperations[index] = operation.copyWith(
            status: SyncStatus.syncing,
          );
        }
        await _syncData(operation.type);
      }
    }
  }

  // Get sync statistics
  Map<String, dynamic> getSyncStats() {
    final totalOperations = _syncOperations.length;
    final successfulOperations = _syncOperations.where((op) => op.status == SyncStatus.synced).length;
    final failedOperations = _syncOperations.where((op) => op.status == SyncStatus.failed).length;
    final pendingOperations = _syncOperations.where((op) => op.status == SyncStatus.syncing).length;
    
    return {
      'totalOperations': totalOperations,
      'successfulOperations': successfulOperations,
      'failedOperations': failedOperations,
      'pendingOperations': pendingOperations,
      'successRate': totalOperations > 0 ? (successfulOperations / totalOperations) * 100 : 0,
      'lastSync': _syncOperations.isNotEmpty ? _syncOperations.last.timestamp : null,
      'overallStatus': overallStatus.name,
      'isOnline': _isOnline,
      'autoSync': _autoSync,
    };
  }

  // Get data statistics
  Map<String, dynamic> getDataStats() {
    final dataByType = <DataType, int>{};
    for (final data in _cloudData) {
      dataByType[data.type] = (dataByType[data.type] ?? 0) + 1;
    }
    
    return {
      'totalDataItems': _cloudData.length,
      'dataByType': dataByType.map((key, value) => MapEntry(key.name, value)),
      'lastModified': _cloudData.isNotEmpty 
        ? _cloudData.map((d) => d.lastModified).reduce((a, b) => a.isAfter(b) ? a : b)
        : null,
      'totalSize': _calculateTotalSize(),
    };
  }

  // Calculate total data size
  int _calculateTotalSize() {
    int totalSize = 0;
    for (final data in _cloudData) {
      totalSize += jsonEncode(data.toJson()).length;
    }
    return totalSize;
  }

  // Clear all data
  Future<void> clearAllData() async {
    _cloudData.clear();
    _syncOperations.clear();
    await _saveCloudData();
    await _saveSyncOperations();
    notifyListeners();
  }

  // Export data
  Map<String, dynamic> exportData() {
    return {
      'cloudData': _cloudData.map((d) => d.toJson()).toList(),
      'syncOperations': _syncOperations.map((o) => o.toJson()).toList(),
      'stats': {
        'syncStats': getSyncStats(),
        'dataStats': getDataStats(),
      },
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  // Import data
  Future<bool> importData(Map<String, dynamic> data) async {
    try {
      if (data['cloudData'] != null) {
        final List<dynamic> dataJson = data['cloudData'];
        _cloudData = dataJson.map((json) => CloudSaveData.fromJson(json)).toList();
      }
      
      if (data['syncOperations'] != null) {
        final List<dynamic> operationsJson = data['syncOperations'];
        _syncOperations = operationsJson.map((json) => SyncOperation.fromJson(json)).toList();
      }
      
      await _saveCloudData();
      await _saveSyncOperations();
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('[CLOUD_SAVE] Error importing data: $e');
      return false;
    }
  }

  // Save cloud data to preferences
  Future<void> _saveCloudData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataJson = _cloudData.map((data) => data.toJson()).toList();
      await prefs.setString('cloud_save_data', jsonEncode(dataJson));
    } catch (e) {
      debugPrint('[CLOUD_SAVE] Error saving cloud data: $e');
    }
  }

  // Save sync operations to preferences
  Future<void> _saveSyncOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final operationsJson = _syncOperations.map((op) => op.toJson()).toList();
      await prefs.setString('cloud_sync_operations', jsonEncode(operationsJson));
    } catch (e) {
      debugPrint('[CLOUD_SAVE] Error saving sync operations: $e');
    }
  }

  // Check for conflicts
  List<Map<String, dynamic>> checkConflicts() {
    final conflicts = <Map<String, dynamic>>[];
    
    // Check for multiple versions of same data type
    final dataByType = <DataType, List<CloudSaveData>>{};
    for (final data in _cloudData) {
      dataByType.putIfAbsent(data.type, () => []).add(data);
    }
    
    for (final entry in dataByType.entries) {
      if (entry.value.length > 1) {
        conflicts.add({
          'type': entry.key.name,
          'count': entry.value.length,
          'versions': entry.value.map((d) => d.version).toList(),
          'devices': entry.value.map((d) => d.deviceId).toList(),
        });
      }
    }
    
    return conflicts;
  }

  // Resolve conflicts
  Future<void> resolveConflicts(DataType type, int version) async {
    final dataToKeep = _cloudData.where((d) => d.type == type && d.version == version).toList();
    final dataToRemove = _cloudData.where((d) => d.type == type && d.version != version).toList();
    
    for (final data in dataToRemove) {
      _cloudData.remove(data);
    }
    
    await _saveCloudData();
    notifyListeners();
  }
} 