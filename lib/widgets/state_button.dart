// state_button.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class QuotationStateButton extends StatelessWidget {
  final String quotationId;
  final String currentState;
  final Future<void> Function()? onUpdateComplete;
  final ApiService apiService;

  const QuotationStateButton({
    super.key,
    required this.quotationId,
    required this.currentState,
    required this.apiService,
    this.onUpdateComplete,
  });

  Future<void> _handleStateUpdate(BuildContext context) async {
    try {
      String newState;
      // Handle state transitions
      switch (currentState.toLowerCase()) {
        case 'pending':
          newState = 'answered';
          break;
        case 'answered':
          newState = 'pending';
          break;
        default:
          return; // No action for approved state
      }

      await apiService.updateQuotationState(quotationId, newState);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quotation updated to $newState'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (onUpdateComplete != null) {
        await onUpdateComplete!();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update quotation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Get button color based on state
  Color _getButtonColor(String state) {
    switch (state.toLowerCase()) {
      case 'pending':
        return Colors.green;
      case 'answered':
        return Colors.grey;
      case 'approved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Get button text based on state
  String _getButtonText(String state) {
    switch (state.toLowerCase()) {
      case 'pending':
        return 'Mark as Answered';
      case 'answered':
        return 'Mark as Pending';
      case 'approved':
        return 'Approved ✓';
      default:
        return 'Unknown State';
    }
  }

  // Get button icon based on state
  IconData _getButtonIcon(String state) {
    switch (state.toLowerCase()) {
      case 'pending':
        return Icons.check_circle_outline;
      case 'answered':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle;
      default:
        return Icons.error_outline;
    }
  }

 
  

  @override
  Widget build(BuildContext context) {
      final bool isEnabled = currentState.toLowerCase() != 'approved';

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 16),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _getButtonColor(currentState),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        disabledForegroundColor: Colors.white.withOpacity(0.5),
        disabledBackgroundColor: _getButtonColor(currentState).withOpacity(0.5),
      ),
      onPressed: isEnabled ? () => _handleStateUpdate(context) : null,
      child: IconTheme(
        data: const IconThemeData(
          color: Colors.white, // Set icon color to white
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getButtonIcon(currentState)),
            const SizedBox(width: 8),
            Text(
              _getButtonText(currentState),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ),
  );
   
  }

}



 // final bool isEnabled = currentState.toLowerCase() != 'approved';

    // return Container(
    //   width: double.infinity,
    //   margin: const EdgeInsets.only(top: 16),
    //   padding: const EdgeInsets.symmetric(horizontal: 16),
    //   child: ElevatedButton(
    //     style: ElevatedButton.styleFrom(
    //       backgroundColor: _getButtonColor(currentState),
    //       foregroundColor: Colors.white,
    //       padding: const EdgeInsets.symmetric(vertical: 12),
    //       disabledForegroundColor: Colors.white.withOpacity(0.5),
    //       disabledBackgroundColor: _getButtonColor(currentState).withOpacity(0.5),
    //     ),
    //     onPressed: isEnabled ? () => _handleStateUpdate(context) : null,
    //     child: Row(
          
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: [
    //         Icon(_getButtonIcon(currentState)),
    //         const SizedBox(width: 8),
    //         Text(
    //           _getButtonText(currentState),
    //           style: const TextStyle(
    //             fontWeight: FontWeight.bold,
    //           ),
    //         ),
    //       ],
    //     ),
    //   ),
    // );