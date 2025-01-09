// // lib/providers/quotation_notifier.dart

// import 'package:flutter/material.dart';
// import '../services/api_service.dart';
// import '../services/socket_service.dart';
// import '../models/quotation.dart';

// class QuotationNotifier extends ChangeNotifier {
//   final ApiService _apiService;
//   final SocketService _socketService;
//   List<Quotation> _quotations = [];
//   bool _isLoading = false;
//   String _error = '';

//   QuotationNotifier(this._apiService, this._socketService) {
//     _initializeSocketListeners();
//   }

//   List<Quotation> get quotations => _quotations;
//   bool get isLoading => _isLoading;
//   String get error => _error;

//   void _initializeSocketListeners() {
//     print('� Initializing socket listeners in QuotationNotifier');
    
//     _socketService.onConnect((_) {
//       print('✅ QuotationNotifier: Socket connected');
//       _error = '';
//       notifyListeners();
//     });

//     _socketService.onDisconnect((_) {
//       print('❌ QuotationNotifier: Socket disconnected');
//       _error = 'Socket disconnected';
//       notifyListeners();
//     });

//     _socketService.on('newQuotation', (data) {
//       print('� QuotationNotifier: New quotation received');
//       fetchQuotations();
//     });



//     _socketService.on('quotationUpdated', (data) {
//       print('� QuotationNotifier: Quotation updated');
//       fetchQuotations();
//     });

//     _socketService.on('quotationDeleted', (data) {
//       print('�️ QuotationNotifier: Quotation deleted');
//       fetchQuotations();
//     });
//   }

//   List<Quotation> getQuotationsByState(String state) {
//     if (state == 'all') return _quotations;
//     return _quotations.where((q) => q.state == state).toList();
//   }

//   Future<void> fetchQuotations() async {
//     _isLoading = true;
//     _error = '';
//     notifyListeners();

//     try {
//       final data = await _apiService.getQuotationsWithDebug();
//       _quotations = data.map((json) => Quotation.fromJson(json)).toList()
//         ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
//     } catch (e) {
//       _error = e.toString();
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> updateQuotationState(String id, String newState) async {
//     try {
//       await _apiService.updateQuotationState(id, newState);
//       // Socket will trigger update
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//       rethrow;
//     }
//   }

//   @override
//   void dispose() {
//     _socketService.off('newQuotation');
//     _socketService.off('quotationUpdated');
//     _socketService.off('quotationDeleted');
//     super.dispose();
//   }
// }