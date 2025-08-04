import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../services/qr_scanner_service.dart';
import '../services/audio_service.dart';

class QRScannerWidget extends StatefulWidget {
  const QRScannerWidget({super.key});

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _qrInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _qrInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RealmOfValorTheme.surfaceDark,
      appBar: AppBar(
        title: const Text('QR Scanner'),
        backgroundColor: RealmOfValorTheme.surfaceDark,
        foregroundColor: RealmOfValorTheme.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: RealmOfValorTheme.accentGold,
          labelColor: RealmOfValorTheme.accentGold,
          unselectedLabelColor: RealmOfValorTheme.textSecondary,
          tabs: const [
            Tab(text: 'Scanner'),
            Tab(text: 'Scanned'),
            Tab(text: 'Available'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScannerTab(),
          _buildScannedTab(),
          _buildAvailableTab(),
        ],
      ),
    );
  }

  Widget _buildScannerTab() {
    return Consumer<QRScannerService>(
      builder: (context, qrService, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScanModeSelector(qrService),
              const SizedBox(height: 16),
              _buildScannerInterface(qrService),
              const SizedBox(height: 16),
              _buildScannerStatistics(qrService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScannedTab() {
    return Consumer<QRScannerService>(
      builder: (context, qrService, child) {
        final scannedCodes = qrService.scannedCodes;
        final stats = qrService.getQRScannerStatistics();
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScannedHeader(stats),
              const SizedBox(height: 16),
              Expanded(
                child: scannedCodes.isEmpty
                    ? _buildEmptyScannedState()
                    : _buildScannedCodesList(scannedCodes, qrService),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvailableTab() {
    return Consumer<QRScannerService>(
      builder: (context, qrService, child) {
        final availableCodes = qrService.availableCodes.values.toList();
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available QR Codes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${availableCodes.length} codes available for scanning',
                style: TextStyle(
                  color: RealmOfValorTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: availableCodes.isEmpty
                    ? _buildEmptyAvailableState()
                    : _buildAvailableCodesList(availableCodes, qrService),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScanModeSelector(QRScannerService qrService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scan Mode',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: QRScanMode.values.map((mode) {
              final isSelected = qrService.currentMode == mode;
              return GestureDetector(
                onTap: () {
                  AudioService.instance.playSound(AudioType.buttonClick);
                  qrService.setScanMode(mode);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? RealmOfValorTheme.accentGold 
                        : RealmOfValorTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected 
                          ? RealmOfValorTheme.accentGold 
                          : RealmOfValorTheme.textSecondary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    mode.name.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : RealmOfValorTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerInterface(QRScannerService qrService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.qr_code_scanner,
                color: RealmOfValorTheme.accentGold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'QR Code Scanner',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: RealmOfValorTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Mode: ${qrService.currentMode.name.toUpperCase()}',
            style: TextStyle(
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _qrInputController,
            decoration: InputDecoration(
              hintText: 'Enter QR code data or scan (try: card_sword_legendary, quest_dragon_hunt, enemy_dragon)',
              hintStyle: TextStyle(color: RealmOfValorTheme.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  AudioService.instance.playSound(AudioType.buttonClick);
                  _simulateQRScan(qrService);
                },
                icon: Icon(Icons.qr_code_scanner, color: RealmOfValorTheme.accentGold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    AudioService.instance.playSound(AudioType.buttonClick);
                    _scanQRCode(qrService);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RealmOfValorTheme.accentGold,
                  ),
                  child: const Text('Scan QR Code'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    AudioService.instance.playSound(AudioType.buttonClick);
                    _simulateQRScan(qrService);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text('Simulate Scan'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Sample QR Codes:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSampleQRButton('card_sword_legendary', 'Legendary Sword', qrService),
              _buildSampleQRButton('quest_dragon_hunt', 'Dragon Hunt', qrService),
              _buildSampleQRButton('enemy_dragon', 'Dragon Enemy', qrService),
              _buildSampleQRButton('item_health_potion', 'Health Potion', qrService),
              _buildSampleQRButton('location_dragon_cave', 'Dragon Cave', qrService),
              _buildSampleQRButton('achievement_first_scan', 'First Scan', qrService),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScannerStatistics(QRScannerService qrService) {
    final stats = qrService.getQRScannerStatistics();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scanner Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem('Scanned', '${stats['totalScanned']}', Icons.qr_code),
              const SizedBox(width: 16),
              _buildStatItem('Redeemed', '${stats['totalRedeemed']}', Icons.check_circle),
              const SizedBox(width: 16),
              _buildStatItem('Available', '${stats['totalAvailable']}', Icons.list),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: stats['completionRate'] as double,
            backgroundColor: RealmOfValorTheme.surfaceDark,
            valueColor: AlwaysStoppedAnimation<Color>(RealmOfValorTheme.accentGold),
          ),
          const SizedBox(height: 4),
          Text(
            '${(stats['completionRate'] * 100).round()}% Complete',
            style: TextStyle(
              fontSize: 12,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedHeader(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RealmOfValorTheme.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scanned QR Codes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${stats['totalScanned']} codes scanned, ${stats['totalRedeemed']} redeemed',
            style: TextStyle(
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem('Cards', '${stats['typeStats']['card'] ?? 0}', Icons.credit_card),
              const SizedBox(width: 16),
              _buildStatItem('Quests', '${stats['typeStats']['quest'] ?? 0}', Icons.assignment),
              const SizedBox(width: 16),
              _buildStatItem('Enemies', '${stats['typeStats']['enemy'] ?? 0}', Icons.sports_esports),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyScannedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_outlined,
            size: 64,
            color: RealmOfValorTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No QR Codes Scanned',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan some QR codes to see them here',
            style: TextStyle(
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedCodesList(List<QRCodeData> scannedCodes, QRScannerService qrService) {
    return ListView.builder(
      itemCount: scannedCodes.length,
      itemBuilder: (context, index) {
        final code = scannedCodes[index];
        return _buildQRCodeCard(code, qrService, true);
      },
    );
  }

  Widget _buildEmptyAvailableState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_outlined,
            size: 64,
            color: RealmOfValorTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Available QR Codes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'QR codes will appear here when available',
            style: TextStyle(
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableCodesList(List<QRCodeData> availableCodes, QRScannerService qrService) {
    return ListView.builder(
      itemCount: availableCodes.length,
      itemBuilder: (context, index) {
        final code = availableCodes[index];
        return _buildQRCodeCard(code, qrService, false);
      },
    );
  }

  Widget _buildQRCodeCard(QRCodeData code, QRScannerService qrService, bool isScanned) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealmOfValorTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getQRCodeBorderColor(code, isScanned),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getQRCodeTypeColor(code.type).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getQRCodeTypeIcon(code.type),
                  color: _getQRCodeTypeColor(code.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      code.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: RealmOfValorTheme.textPrimary,
                      ),
                    ),
                    Text(
                      code.type.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getQRCodeTypeColor(code.type),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (isScanned) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: code.isRedeemed ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    code.isRedeemed ? 'REDEEMED' : 'SCANNED',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            code.description,
            style: TextStyle(
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
          if (isScanned) ...[
            const SizedBox(height: 8),
            Text(
              'Scanned: ${_formatDateTime(code.scannedAt)}',
              style: TextStyle(
                fontSize: 12,
                color: RealmOfValorTheme.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (isScanned && !code.isRedeemed) ...[
            ElevatedButton(
              onPressed: () {
                AudioService.instance.playSound(AudioType.buttonClick);
                _redeemQRCode(code, qrService);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Redeem'),
            ),
          ] else if (!isScanned) ...[
            ElevatedButton(
              onPressed: () {
                AudioService.instance.playSound(AudioType.buttonClick);
                _simulateScanSpecificCode(code, qrService);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: RealmOfValorTheme.accentGold,
              ),
              child: const Text('Simulate Scan'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: RealmOfValorTheme.textSecondary, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: RealmOfValorTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: RealmOfValorTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getQRCodeBorderColor(QRCodeData code, bool isScanned) {
    if (!isScanned) return RealmOfValorTheme.textSecondary.withOpacity(0.3);
    if (code.isRedeemed) return Colors.green;
    return RealmOfValorTheme.accentGold;
  }

  Color _getQRCodeTypeColor(QRCodeType type) {
    switch (type) {
      case QRCodeType.card:
        return Colors.blue;
      case QRCodeType.quest:
        return Colors.green;
      case QRCodeType.enemy:
        return Colors.red;
      case QRCodeType.item:
        return Colors.orange;
      case QRCodeType.location:
        return Colors.purple;
      case QRCodeType.achievement:
        return Colors.yellow;
      case QRCodeType.unknown:
        return Colors.grey;
    }
  }

  IconData _getQRCodeTypeIcon(QRCodeType type) {
    switch (type) {
      case QRCodeType.card:
        return Icons.credit_card;
      case QRCodeType.quest:
        return Icons.assignment;
      case QRCodeType.enemy:
        return Icons.sports_esports;
      case QRCodeType.item:
        return Icons.inventory;
      case QRCodeType.location:
        return Icons.location_on;
      case QRCodeType.achievement:
        return Icons.emoji_events;
      case QRCodeType.unknown:
        return Icons.help;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _scanQRCode(QRScannerService qrService) {
    final qrData = _qrInputController.text.trim();
    if (qrData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter QR code data'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    qrService.scanQRCode(qrData).then((scannedCode) {
      if (scannedCode != null) {
        _qrInputController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully scanned: ${scannedCode.title}'),
            backgroundColor: RealmOfValorTheme.accentGold,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to scan QR code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _simulateQRScan(QRScannerService qrService) {
    final availableCodes = qrService.availableCodes.values.toList();
    if (availableCodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No QR codes available for simulation'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Simulate scanning a random available code
    final randomCode = availableCodes[DateTime.now().millisecond % availableCodes.length];
    _simulateScanSpecificCode(randomCode, qrService);
  }

  void _simulateScanSpecificCode(QRCodeData code, QRScannerService qrService) {
    qrService.scanQRCode(code.id).then((scannedCode) {
      if (scannedCode != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Simulated scan: ${scannedCode.title}'),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code already scanned'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  void _redeemQRCode(QRCodeData code, QRScannerService qrService) {
    qrService.redeemQRCode(code.id).then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Redeemed: ${code.title}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to redeem QR code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  Widget _buildSampleQRButton(String qrCode, String label, QRScannerService qrService) {
    return ElevatedButton(
      onPressed: () {
        AudioService.instance.playSound(AudioType.buttonClick);
        _qrInputController.text = qrCode;
        _scanQRCode(qrService);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.withOpacity(0.8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
} 