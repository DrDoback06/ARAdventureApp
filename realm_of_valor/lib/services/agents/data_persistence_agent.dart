import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../services/event_bus.dart';
import 'integration_orchestrator_agent.dart';

/// Data sync status
enum SyncStatus {
  synced,
  pending,
  syncing,
  failed,
  offline,
}

/// Data entity for persistence
class DataEntity {
  final String id;
  final String collection;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final SyncStatus syncStatus;
  final int version;

  DataEntity({
    required this.id,
    required this.collection,
    required this.data,
    DateTime? timestamp,
    this.syncStatus = SyncStatus.pending,
    this.version = 1,
  }) : timestamp = timestamp ?? DateTime.now();

  DataEntity copyWith({
    String? id,
    String? collection,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    SyncStatus? syncStatus,
    int? version,
  }) {
    return DataEntity(
      id: id ?? this.id,
      collection: collection ?? this.collection,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collection': collection,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'syncStatus': syncStatus.toString(),
      'version': version,
    };
  }

  factory DataEntity.fromJson(Map<String, dynamic> json) {
    return DataEntity(
      id: json['id'],
      collection: json['collection'],
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      syncStatus: SyncStatus.values.firstWhere(
        (s) => s.toString() == json['syncStatus'],
        orElse: () => SyncStatus.pending,
      ),
      version: json['version'] ?? 1,
    );
  }
}

/// Data conflict resolution
class DataConflict {
  final String id;
  final String collection;
  final DataEntity localEntity;
  final DataEntity remoteEntity;
  final DateTime detectedAt;

  DataConflict({
    required this.id,
    required this.collection,
    required this.localEntity,
    required this.remoteEntity,
    DateTime? detectedAt,
  }) : detectedAt = detectedAt ?? DateTime.now();
}

/// Data Persistence Agent - Centralized data management with Firebase integration
class DataPersistenceAgent extends BaseAgent {
  static const String agentId = 'data_persistence';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SharedPreferences _prefs;
  
  // Local data cache
  final Map<String, Map<String, DataEntity>> _localCache = {};
  final List<DataEntity> _syncQueue = [];
  final List<DataConflict> _conflicts = [];
  
  // Sync state
  bool _isOnline = true;
  bool _isSyncing = false;
  Timer? _syncTimer;
  Timer? _connectivityTimer;
  
  // Configuration
  static const Duration syncInterval = Duration(minutes: 5);
  static const Duration offlineRetryInterval = Duration(minutes: 1);
  static const int maxSyncRetries = 3;
  static const int maxCacheSize = 10000;

  DataPersistenceAgent({
    required SharedPreferences prefs,
  }) : _prefs = prefs, super(agentId: agentId);

  @override
  Future<void> onInitialize() async {
    developer.log('Initializing Data Persistence Agent', name: agentId);
    
    // Initialize connectivity monitoring
    await _initializeConnectivity();
    
    // Load cached data
    await _loadLocalCache();
    
    // Set up authentication listener
    _auth.authStateChanges().listen(_handleAuthStateChange);
    
    // Start periodic sync
    _startPeriodicSync();
    
    developer.log('Data Persistence Agent initialized', name: agentId);
  }

  @override
  void subscribeToEvents() {
    // Data operations
    subscribe('save_data', _handleSaveData);
    subscribe('load_data', _handleLoadData);
    subscribe('delete_data', _handleDeleteData);
    subscribe('sync_data', _handleSyncData);
    subscribe('query_data', _handleQueryData);
    
    // Bulk operations
    subscribe('save_bulk_data', _handleSaveBulkData);
    subscribe('load_bulk_data', _handleLoadBulkData);
    
    // Sync management
    subscribe('force_sync', _handleForceSync);
    subscribe('resolve_conflict', _handleResolveConflict);
    subscribe('get_sync_status', _handleGetSyncStatus);
    
    // User management
    subscribe('user_login', _handleUserLogin);
    subscribe('user_logout', _handleUserLogout);
  }

  /// Save data entity
  Future<void> saveData({
    required String id,
    required String collection,
    required Map<String, dynamic> data,
    bool syncImmediately = false,
  }) async {
    final entity = DataEntity(
      id: id,
      collection: collection,
      data: data,
      syncStatus: _isOnline ? SyncStatus.pending : SyncStatus.offline,
    );

    // Save to local cache
    _localCache.putIfAbsent(collection, () => {})[id] = entity;
    
    // Save to local storage
    await _saveToLocalStorage(entity);
    
    // Add to sync queue if online
    if (_isOnline) {
      _syncQueue.add(entity);
      
      if (syncImmediately) {
        await _syncToFirestore();
      }
    }

    // Publish data saved event
    await publishEvent(createEvent(
      eventType: EventTypes.dataSync,
      data: {
        'operation': 'save',
        'collection': collection,
        'id': id,
        'syncStatus': entity.syncStatus.toString(),
      },
    ));

    developer.log('Data saved: $collection/$id', name: agentId);
  }

  /// Load data entity
  Future<DataEntity?> loadData({
    required String id,
    required String collection,
    bool forceRemote = false,
  }) async {
    // Try local cache first (unless forcing remote)
    if (!forceRemote && _localCache[collection]?.containsKey(id) == true) {
      final entity = _localCache[collection]![id]!;
      developer.log('Data loaded from cache: $collection/$id', name: agentId);
      return entity;
    }

    // Try remote if online
    if (_isOnline && (_auth.currentUser != null || collection.startsWith('public_'))) {
      try {
        final doc = await _firestore.collection(collection).doc(id).get();
        if (doc.exists) {
          final data = doc.data()!;
          final entity = DataEntity(
            id: id,
            collection: collection,
            data: data,
            timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            syncStatus: SyncStatus.synced,
            version: data['version'] ?? 1,
          );

          // Update local cache
          _localCache.putIfAbsent(collection, () => {})[id] = entity;
          await _saveToLocalStorage(entity);

          developer.log('Data loaded from remote: $collection/$id', name: agentId);
          return entity;
        }
      } catch (e) {
        developer.log('Error loading from remote: $e', name: agentId);
      }
    }

    // Try local storage as fallback
    final entity = await _loadFromLocalStorage(collection, id);
    if (entity != null) {
      _localCache.putIfAbsent(collection, () => {})[id] = entity;
      developer.log('Data loaded from local storage: $collection/$id', name: agentId);
      return entity;
    }

    developer.log('Data not found: $collection/$id', name: agentId);
    return null;
  }

  /// Delete data entity
  Future<void> deleteData({
    required String id,
    required String collection,
    bool syncImmediately = false,
  }) async {
    // Remove from local cache
    _localCache[collection]?.remove(id);
    
    // Mark as deleted in local storage
    await _markDeletedInLocalStorage(collection, id);
    
    // Add deletion to sync queue if online
    if (_isOnline && _auth.currentUser != null) {
      final deleteEntity = DataEntity(
        id: id,
        collection: collection,
        data: {'_deleted': true},
        syncStatus: SyncStatus.pending,
      );
      
      _syncQueue.add(deleteEntity);
      
      if (syncImmediately) {
        await _syncToFirestore();
      }
    }

    developer.log('Data deleted: $collection/$id', name: agentId);
  }

  /// Query data entities
  Future<List<DataEntity>> queryData({
    required String collection,
    Map<String, dynamic>? where,
    String? orderBy,
    bool ascending = true,
    int? limit,
    bool forceRemote = false,
  }) async {
    List<DataEntity> results = [];

    // Try remote first if forced or if we're online and authenticated
    if ((forceRemote || _isOnline) && (_auth.currentUser != null || collection.startsWith('public_'))) {
      try {
        Query query = _firestore.collection(collection);
        
        // Apply where clauses
        if (where != null) {
          for (final entry in where.entries) {
            query = query.where(entry.key, isEqualTo: entry.value);
          }
        }
        
        // Apply ordering
        if (orderBy != null) {
          query = query.orderBy(orderBy, descending: !ascending);
        }
        
        // Apply limit
        if (limit != null) {
          query = query.limit(limit);
        }

        final snapshot = await query.get();
        results = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return DataEntity(
            id: doc.id,
            collection: collection,
            data: data,
            timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            syncStatus: SyncStatus.synced,
            version: data['version'] ?? 1,
          );
        }).toList();

        // Update local cache
        for (final entity in results) {
          _localCache.putIfAbsent(collection, () => {})[entity.id] = entity;
          await _saveToLocalStorage(entity);
        }

        developer.log('Query executed on remote: $collection (${results.length} results)', name: agentId);
        return results;
      } catch (e) {
        developer.log('Error querying remote: $e', name: agentId);
      }
    }

    // Fallback to local cache
    final localEntities = _localCache[collection]?.values.toList() ?? [];
    
    // Apply local filtering (simplified)
    results = localEntities.where((entity) {
      if (where != null) {
        for (final entry in where.entries) {
          if (entity.data[entry.key] != entry.value) {
            return false;
          }
        }
      }
      return true;
    }).toList();

    // Apply ordering (simplified)
    if (orderBy != null) {
      results.sort((a, b) {
        final aValue = a.data[orderBy];
        final bValue = b.data[orderBy];
        
        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return ascending ? -1 : 1;
        if (bValue == null) return ascending ? 1 : -1;
        
        final comparison = aValue.toString().compareTo(bValue.toString());
        return ascending ? comparison : -comparison;
      });
    }

    // Apply limit
    if (limit != null && results.length > limit) {
      results = results.take(limit).toList();
    }

    developer.log('Query executed on local cache: $collection (${results.length} results)', name: agentId);
    return results;
  }

  /// Initialize connectivity monitoring
  Future<void> _initializeConnectivity() async {
    final connectivity = Connectivity();
    
    // Check initial connectivity
    final result = await connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    
    // Listen for connectivity changes
    connectivity.onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (!wasOnline && _isOnline) {
        developer.log('Connectivity restored - starting sync', name: agentId);
        _syncToFirestore();
      } else if (wasOnline && !_isOnline) {
        developer.log('Connectivity lost - switching to offline mode', name: agentId);
      }
    });
  }

  /// Load local cache from storage
  Future<void> _loadLocalCache() async {
    try {
      final keys = _prefs.getKeys().where((key) => key.startsWith('data_entity_'));
      
      for (final key in keys) {
        final jsonString = _prefs.getString(key);
        if (jsonString != null) {
          final json = jsonDecode(jsonString);
          final entity = DataEntity.fromJson(json);
          
          _localCache.putIfAbsent(entity.collection, () => {})[entity.id] = entity;
        }
      }
      
      developer.log('Loaded ${keys.length} entities from local cache', name: agentId);
    } catch (e) {
      developer.log('Error loading local cache: $e', name: agentId);
    }
  }

  /// Save entity to local storage
  Future<void> _saveToLocalStorage(DataEntity entity) async {
    try {
      final key = 'data_entity_${entity.collection}_${entity.id}';
      final jsonString = jsonEncode(entity.toJson());
      await _prefs.setString(key, jsonString);
    } catch (e) {
      developer.log('Error saving to local storage: $e', name: agentId);
    }
  }

  /// Load entity from local storage
  Future<DataEntity?> _loadFromLocalStorage(String collection, String id) async {
    try {
      final key = 'data_entity_${collection}_$id';
      final jsonString = _prefs.getString(key);
      if (jsonString != null) {
        final json = jsonDecode(jsonString);
        return DataEntity.fromJson(json);
      }
    } catch (e) {
      developer.log('Error loading from local storage: $e', name: agentId);
    }
    return null;
  }

  /// Mark entity as deleted in local storage
  Future<void> _markDeletedInLocalStorage(String collection, String id) async {
    try {
      final key = 'data_entity_${collection}_$id';
      await _prefs.remove(key);
    } catch (e) {
      developer.log('Error marking deleted in local storage: $e', name: agentId);
    }
  }

  /// Start periodic sync
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(syncInterval, (timer) {
      if (_isOnline && _auth.currentUser != null && !_isSyncing) {
        _syncToFirestore();
      }
    });
  }

  /// Sync data to Firestore
  Future<void> _syncToFirestore() async {
    if (_isSyncing || !_isOnline || _auth.currentUser == null) return;
    
    _isSyncing = true;
    developer.log('Starting data sync to Firestore', name: agentId);
    
    try {
      final batch = _firestore.batch();
      final processedEntities = <DataEntity>[];
      
      // Process sync queue
      for (final entity in _syncQueue.take(100)) { // Batch limit
        final docRef = _firestore.collection(entity.collection).doc(entity.id);
        
        if (entity.data['_deleted'] == true) {
          batch.delete(docRef);
        } else {
          final dataToSync = Map<String, dynamic>.from(entity.data);
          dataToSync['timestamp'] = FieldValue.serverTimestamp();
          dataToSync['version'] = entity.version;
          dataToSync['userId'] = _auth.currentUser!.uid;
          
          batch.set(docRef, dataToSync, SetOptions(merge: true));
        }
        
        processedEntities.add(entity);
      }
      
      if (processedEntities.isNotEmpty) {
        await batch.commit();
        
        // Update sync status
        for (final entity in processedEntities) {
          final updatedEntity = entity.copyWith(syncStatus: SyncStatus.synced);
          _localCache[entity.collection]?[entity.id] = updatedEntity;
          await _saveToLocalStorage(updatedEntity);
        }
        
        // Remove from sync queue
        _syncQueue.removeWhere((e) => processedEntities.contains(e));
        
        developer.log('Synced ${processedEntities.length} entities to Firestore', name: agentId);
      }
    } catch (e) {
      developer.log('Error syncing to Firestore: $e', name: agentId);
      
      // Mark failed entities
      for (final entity in _syncQueue.take(100)) {
        final failedEntity = entity.copyWith(syncStatus: SyncStatus.failed);
        _localCache[entity.collection]?[entity.id] = failedEntity;
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Handle authentication state changes
  void _handleAuthStateChange(User? user) {
    if (user != null) {
      developer.log('User authenticated - enabling sync', name: agentId);
      if (_isOnline) {
        _syncToFirestore();
      }
    } else {
      developer.log('User signed out - disabling sync', name: agentId);
    }
  }

  /// Handle save data events
  Future<AgentEventResponse?> _handleSaveData(AgentEvent event) async {
    final id = event.data['id'];
    final collection = event.data['collection'];
    final data = Map<String, dynamic>.from(event.data['data']);
    final syncImmediately = event.data['syncImmediately'] ?? false;

    try {
      await saveData(
        id: id,
        collection: collection,
        data: data,
        syncImmediately: syncImmediately,
      );

      return createResponse(
        originalEventId: event.id,
        responseType: 'data_saved',
        data: {'id': id, 'collection': collection},
      );
    } catch (e) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'data_save_failed',
        data: {'error': e.toString()},
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Handle load data events
  Future<AgentEventResponse?> _handleLoadData(AgentEvent event) async {
    final id = event.data['id'];
    final collection = event.data['collection'];
    final forceRemote = event.data['forceRemote'] ?? false;

    try {
      final entity = await loadData(
        id: id,
        collection: collection,
        forceRemote: forceRemote,
      );

      if (entity != null) {
        return createResponse(
          originalEventId: event.id,
          responseType: 'data_loaded',
          data: {
            'entity': entity.toJson(),
          },
        );
      } else {
        return createResponse(
          originalEventId: event.id,
          responseType: 'data_not_found',
          data: {'id': id, 'collection': collection},
          success: false,
        );
      }
    } catch (e) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'data_load_failed',
        data: {'error': e.toString()},
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Handle delete data events
  Future<AgentEventResponse?> _handleDeleteData(AgentEvent event) async {
    final id = event.data['id'];
    final collection = event.data['collection'];
    final syncImmediately = event.data['syncImmediately'] ?? false;

    try {
      await deleteData(
        id: id,
        collection: collection,
        syncImmediately: syncImmediately,
      );

      return createResponse(
        originalEventId: event.id,
        responseType: 'data_deleted',
        data: {'id': id, 'collection': collection},
      );
    } catch (e) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'data_delete_failed',
        data: {'error': e.toString()},
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Handle sync data events
  Future<AgentEventResponse?> _handleSyncData(AgentEvent event) async {
    try {
      await _syncToFirestore();

      return createResponse(
        originalEventId: event.id,
        responseType: 'data_synced',
        data: {
          'syncQueueSize': _syncQueue.length,
          'isOnline': _isOnline,
          'isSyncing': _isSyncing,
        },
      );
    } catch (e) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'data_sync_failed',
        data: {'error': e.toString()},
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Handle query data events
  Future<AgentEventResponse?> _handleQueryData(AgentEvent event) async {
    final collection = event.data['collection'];
    final where = event.data['where'] != null 
        ? Map<String, dynamic>.from(event.data['where'])
        : null;
    final orderBy = event.data['orderBy'];
    final ascending = event.data['ascending'] ?? true;
    final limit = event.data['limit'];
    final forceRemote = event.data['forceRemote'] ?? false;

    try {
      final results = await queryData(
        collection: collection,
        where: where,
        orderBy: orderBy,
        ascending: ascending,
        limit: limit,
        forceRemote: forceRemote,
      );

      return createResponse(
        originalEventId: event.id,
        responseType: 'data_queried',
        data: {
          'results': results.map((e) => e.toJson()).toList(),
          'count': results.length,
        },
      );
    } catch (e) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'data_query_failed',
        data: {'error': e.toString()},
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Handle save bulk data events
  Future<AgentEventResponse?> _handleSaveBulkData(AgentEvent event) async {
    final entities = List<Map<String, dynamic>>.from(event.data['entities']);
    final syncImmediately = event.data['syncImmediately'] ?? false;

    try {
      for (final entityData in entities) {
        await saveData(
          id: entityData['id'],
          collection: entityData['collection'],
          data: entityData['data'],
          syncImmediately: false, // Sync all at once at the end
        );
      }

      if (syncImmediately) {
        await _syncToFirestore();
      }

      return createResponse(
        originalEventId: event.id,
        responseType: 'bulk_data_saved',
        data: {'count': entities.length},
      );
    } catch (e) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'bulk_data_save_failed',
        data: {'error': e.toString()},
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Handle load bulk data events
  Future<AgentEventResponse?> _handleLoadBulkData(AgentEvent event) async {
    final requests = List<Map<String, dynamic>>.from(event.data['requests']);
    final forceRemote = event.data['forceRemote'] ?? false;

    try {
      final results = <Map<String, dynamic>>[];

      for (final request in requests) {
        final entity = await loadData(
          id: request['id'],
          collection: request['collection'],
          forceRemote: forceRemote,
        );

        if (entity != null) {
          results.add(entity.toJson());
        }
      }

      return createResponse(
        originalEventId: event.id,
        responseType: 'bulk_data_loaded',
        data: {
          'results': results,
          'found': results.length,
          'requested': requests.length,
        },
      );
    } catch (e) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'bulk_data_load_failed',
        data: {'error': e.toString()},
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Handle force sync events
  Future<AgentEventResponse?> _handleForceSync(AgentEvent event) async {
    try {
      await _syncToFirestore();

      return createResponse(
        originalEventId: event.id,
        responseType: 'force_sync_completed',
        data: {
          'syncQueueSize': _syncQueue.length,
          'conflictsCount': _conflicts.length,
        },
      );
    } catch (e) {
      return createResponse(
        originalEventId: event.id,
        responseType: 'force_sync_failed',
        data: {'error': e.toString()},
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Handle resolve conflict events
  Future<AgentEventResponse?> _handleResolveConflict(AgentEvent event) async {
    final conflictId = event.data['conflictId'];
    final resolution = event.data['resolution']; // 'local', 'remote', or 'merge'

    // TODO: Implement conflict resolution logic
    developer.log('Conflict resolution requested: $conflictId -> $resolution', name: agentId);

    return createResponse(
      originalEventId: event.id,
      responseType: 'conflict_resolved',
      data: {'conflictId': conflictId, 'resolution': resolution},
    );
  }

  /// Handle get sync status events
  Future<AgentEventResponse?> _handleGetSyncStatus(AgentEvent event) async {
    return createResponse(
      originalEventId: event.id,
      responseType: 'sync_status',
      data: {
        'isOnline': _isOnline,
        'isSyncing': _isSyncing,
        'syncQueueSize': _syncQueue.length,
        'conflictsCount': _conflicts.length,
        'cacheSize': _localCache.values.fold(0, (sum, collection) => sum + collection.length),
        'lastSyncAttempt': _syncTimer?.tick,
        'authenticated': _auth.currentUser != null,
      },
    );
  }

  /// Handle user login events
  Future<AgentEventResponse?> _handleUserLogin(AgentEvent event) async {
    developer.log('User login detected - preparing sync', name: agentId);
    
    if (_isOnline) {
      await _syncToFirestore();
    }

    return createResponse(
      originalEventId: event.id,
      responseType: 'user_login_acknowledged',
      data: {'syncing': _isSyncing},
    );
  }

  /// Handle user logout events
  Future<AgentEventResponse?> _handleUserLogout(AgentEvent event) async {
    developer.log('User logout detected - clearing sensitive data', name: agentId);
    
    // Clear sync queue of user-specific data
    _syncQueue.removeWhere((entity) => !entity.collection.startsWith('public_'));
    
    return createResponse(
      originalEventId: event.id,
      responseType: 'user_logout_acknowledged',
      data: {'cleared': true},
    );
  }

  @override
  Future<void> onDispose() async {
    _syncTimer?.cancel();
    _connectivityTimer?.cancel();
    
    // Final sync attempt
    if (_isOnline && _auth.currentUser != null && _syncQueue.isNotEmpty) {
      await _syncToFirestore();
    }
    
    developer.log('Data Persistence Agent disposed', name: agentId);
  }
}