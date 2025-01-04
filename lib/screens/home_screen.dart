import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/socket_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
 final SocketService _socketService = SocketService();
  List<dynamic> quotations = [];
  bool isLoading = true;
  String error = '';

  
  @override
  void initState() {
    super.initState();
    print('HomeScreen initialized');
    _loadQuotations();
    _initializeSocketListeners();
  }

  void _initializeSocketListeners() {
  print('🔧 Initializing socket listeners...');
  
  _socketService.onConnect((_) {
    print('✅ HomeScreen: Socket connected');
    setState(() {
      error = '';
    });
  });

  _socketService.onDisconnect((_) {
    print('❌ HomeScreen: Socket disconnected');
    setState(() {
      error = 'Socket disconnected';
    });
  });

  _socketService.on('newQuotation', (data) {
    print('📥 HomeScreen: New quotation received');
    print('Data: $data');
    _loadQuotations();
  });

  _socketService.on('quotationUpdated', (data) {
    print('🔄 HomeScreen: Quotation updated');
    print('Data: $data');
    _loadQuotations();
  });

  _socketService.on('quotationDeleted', (data) {
    print('🗑️ HomeScreen: Quotation deleted');
    print('Data: $data');
    _loadQuotations();
  });
}

@override
void dispose() {
  _socketService.off('newQuotation');
  _socketService.off('quotationUpdated');
  _socketService.off('quotationDeleted');
  super.dispose();
}


  Future<void> _loadQuotations() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      print('Starting to load quotations');
      final data = await _apiService.getQuotationsWithDebug();
      
      if (!mounted) return;

      data.sort((a, b) {
        final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(1900);
        final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(1900);
        return dateB.compareTo(dateA); // Newest first
      });
      
      print('Quotations loaded successfully: ${data.length} items');
      setState(() {
        quotations = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error in _loadQuotations: $e');
      if (!mounted) return;
      
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DenverBartenders'),
        backgroundColor: Colors.black87,
        actions: [
          Icon(
          _socketService.isConnected ? Icons.cloud_done : Icons.cloud_off,
          color: _socketService.isConnected ? Colors.green : Colors.red,
        ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : _loadQuotations,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    print('Building body - isLoading: $isLoading, error: $error, quotations: ${quotations.length}');
    
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
            SizedBox(height: 16),
            Text('Loading quotations...'),
          ],
        ),
      );
    }

    if (error.isNotEmpty) {
      return RefreshIndicator(
        onRefresh: _loadQuotations,
        color: Colors.amber,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading quotations:\n$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadQuotations,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (quotations.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadQuotations,
        color: Colors.amber,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: 100),
                child: Text('No quotations available'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQuotations,
      color: Colors.amber,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: quotations.length,
        itemBuilder: (context, index) {
          final quotation = quotations[index];
          final eventDate = DateTime.tryParse(quotation['eventDate'] ?? '')
              ?.toString().split(' ')[0] ?? 'No date';
          final createdAt = DateTime.tryParse(quotation['createdAt'] ?? '')
              ?.toString().split(' ')[0] ?? 'No date';

          return Card(
            margin: const EdgeInsets.all(8.0),
            color: Colors.black87,
            child: ExpansionTile(
              backgroundColor: Colors.black87,
              collapsedBackgroundColor: Colors.black87,
              title: Text(
                quotation['clientName'] ?? 'No name',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              subtitle: Text(
                'Company: ${quotation['companyName'] ?? 'N/A'}\n'
                'Created: $createdAt',
                style: const TextStyle(color: Colors.white70),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Event Date', eventDate),
                      _buildInfoRow('Time', '${quotation['startTime'] ?? 'N/A'} - ${quotation['endTime'] ?? 'N/A'}'),
                      _buildInfoRow('Guests', '${quotation['numberOfGuests']?.toString() ?? 'N/A'}'),
                      const SizedBox(height: 8),
                      const Text(
                        'Services Requested:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      ...List<Widget>.from(
                        (quotation['servicesRequested'] as List? ?? []).map(
                          (service) => Padding(
                            padding: const EdgeInsets.only(left: 16, top: 4),
                            child: Text(
                              '• $service',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}