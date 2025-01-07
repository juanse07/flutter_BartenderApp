import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/socket_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../widgets/buildInfoRow.dart';
import '../widgets/custom_app_bar.dart';

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
    print('� Initializing socket listeners...');
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
      print('� HomeScreen: New quotation received');
      print('Data: $data');
      _loadQuotations();
    });

    _socketService.on('quotationUpdated', (data) {
      print('� HomeScreen: Quotation updated');
      print('Data: $data');
      _loadQuotations();
    });

    _socketService.on('quotationDeleted', (data) {
      print('�️ HomeScreen: Quotation deleted');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
         title: 'DenverBartenders',
        socketService: _socketService,
        onRefresh: _loadQuotations,
        isLoading: isLoading,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    print(
        'Building body - isLoading: $isLoading, error: $error, quotations: ${quotations.length}');

    Color _getStatusColor(String state) {
      switch (state.toLowerCase()) {
        case 'approved':
          return Colors.green;
        case 'rejected':
          return Colors.red;
        case 'in_progress':
          return Colors.blue;
        case 'pending':
        default:
          return Colors.amber; // Yellow indicator for pending state
      }
    }

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
                  ?.toString()
                  .split(' ')[0] ??
              'No date';
          final createdAt = DateTime.tryParse(quotation['createdAt'] ?? '')
                  ?.toString()
                  .split(' ')[0] ??
              'No date';

          return Card(
            margin: const EdgeInsets.all(8.0),
            color: Colors.black87,
            child: ExpansionTile(
              backgroundColor: Colors.black87,
              collapsedBackgroundColor: Colors.black87,
              title: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getStatusColor(quotation['state'] ?? 'pending'),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor(
                                  quotation['state'] ?? 'pending')
                              .withOpacity(0.3),
                          blurRadius: 4,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      quotation['clientName'] ?? 'No name',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Company: ${quotation['companyName'] ?? 'N/A'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Row(
                    children: [
                      Text(
                        'Received: $createdAt ',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeago.format(
                            DateTime.parse(quotation['createdAt'] ?? '')),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Event Information Section
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.amber.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Event Information',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            InfoRow(label: 'Event Date', value: eventDate),
                            InfoRow(
                              label: 'Time',
                              value:
                                  '${quotation['startTime'] ?? 'N/A'} - ${quotation['endTime'] ?? 'N/A'}',
                            ),
                            InfoRow(
                              label: 'Guests',
                              value: '${quotation['numberOfGuests']?.toString() ?? 'N/A'}',
                            ),
                            InfoRow(
                              label: 'Services Requested',
                              value: quotation['servicesRequested'],
                              type: 'services',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Contact Information Section
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.amber.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Contact Information',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            InfoRow(
                              label: 'Phone',
                              value: quotation['phone'] ?? 'No phone',
                              type: 'phone',
                            ),
                            InfoRow(
                              label: 'Email',
                              value: quotation['email'] ?? 'No email',
                              type: 'email',
                            ),
                            InfoRow(
                              label: 'Address',
                              value: quotation['address'] ?? 'No address',
                              type: 'map',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Notes Section
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.amber.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InfoRow(
                              label: 'Notes',
                              value: quotation['notes'] ?? 'No notes',
                              type: 'notes',
                            ),
                          ],
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
