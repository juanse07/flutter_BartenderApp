import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'notification_service.dart';

class SocketService {
  late IO.Socket _socket;
  final NotificationService _notificationService = NotificationService();

  SocketService._internal() {
    _socket = IO.io(
        dotenv.env['API_URL'] ?? 'http://localhost:8888',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setPath('/socket.io/')
            .enableAutoConnect()
            .build());
  }

  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  String formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, y').format(date); // Oct 25, 2023
    } catch (e) {
      return dateStr;
    }
  }

  // Helper function to format time
  String formatTime(String timeStr) {
    try {
      // Assuming time comes in 24-hour format (HH:mm)
      final time = DateFormat('HH:mm').parse(timeStr);
      return DateFormat('h:mm a').format(time); // 2:30 PM
    } catch (e) {
      return timeStr;
    }
  }

  void onConnect(Function(dynamic) handler) {
    _socket.onConnect(handler);
  }

  void onDisconnect(Function(dynamic) handler) {
    _socket.onDisconnect(handler);
  }

  void on(String event, Function(dynamic) handler) {
    final eventMap = {
      'newQuotation': 'newBarServiceQuotation',
      'quotationUpdated': 'updateBarServiceQuotation',
      'quotationDeleted': 'deleteBarServiceQuotation'
    };

    final backendEvent = eventMap[event] ?? event;
    _socket.on(backendEvent, (data) async {
      print('ReceivedBkc $backendEvent: $data');

      try {
        if (backendEvent == 'newBarServiceQuotation') {
          print('🔄 Socket event received: newBarServiceQuotation');
          if (data is Map<String, dynamic>) {
            String contactName = data['contactName']?.toString() ?? 'Unknown';
            String eventType = data['eventType']?.toString() ?? 'N/A';
            String eventDate =
                formatDate(data['eventDate']?.toString() ?? 'N/A');
            String eventTime = data['eventTime']?.toString() ?? 'N/A';
            String guestCount = data['guestCount'] is int
                ? data['guestCount'].toString()
                : data['guestCount']?.toString() ?? 'N/A';

            print('📝 Preparing notification with data:');
            print('Contact: $contactName');
            print('Date: $eventDate');
            print('Time: $eventTime');
            print('Guests: $guestCount');

            await _notificationService.showNotification(
              title: 'NSC from: $contactName',
              body:
                  'Date: $eventDate\nTime: $eventTime\nGuests: $guestCount\nAprox',
            );
          } else {
            print('⚠️ Invalid data format received: $data');
            await _notificationService.showNotification(
              title: 'New Quotation',
              body: 'A new quotation request has been received',
            );
          }
        } else if (backendEvent == 'updateBarServiceQuotation') {
          await _notificationService.showNotification(
            title: 'Quotation Updated',
            body: 'A quotation has been modified',
          );
        } else if (backendEvent == 'deleteBarServiceQuotation') {
          await _notificationService.showNotification(
            title: 'Quotation Deleted',
            body: 'A quotation has been removed',
          );
        }
      } catch (e) {
        print('❌ Error processing socket event: $e');
      }

      handler(data);
    });
  }

  void off(String event) {
    _socket.off(event);
  }

  void connect() => _socket.connect();
  void disconnect() => _socket.disconnect();
  bool get isConnected => _socket.connected;
}
