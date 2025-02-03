import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final dynamic value;
  final String? type;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.type,
  });

  Future<void> _openMap(String addressToOpen) async {
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeFull(addressToOpen)}');
    
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $googleMapsUrl');
    }
  }

  Future<void> _handlePhoneContact(BuildContext context, String phoneNumber) async {
    final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.call),
                title: const Text('Call'),
                onTap: () async {
                  Navigator.pop(context);
                  final Uri callUri = Uri(
                    scheme: 'tel',
                    path: cleanPhoneNumber,
                  );
                  if (await canLaunchUrl(callUri)) {
                    await launchUrl(callUri);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.message),
                title: const Text('Message'),
                onTap: () async {
                  Navigator.pop(context);
                  final Uri smsUri = Uri(
                    scheme: 'sms',
                    path: cleanPhoneNumber,
                  );
                  if (await canLaunchUrl(smsUri)) {
                    await launchUrl(smsUri);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $launchUri';
    }
  }

  Future<void> _handleTap(BuildContext context) async {
    Uri? launchUri;
    
    switch (type) {
      case 'phone':
        return _handlePhoneContact(context, value.toString());
      case 'email':
        launchUri = Uri(
          scheme: 'mailto',
          path: value.toString(),
        );
        break;
      case 'map':
        final encodedAddress = Uri.encodeComponent(value.toString());
        launchUri = Uri.parse('http://maps.apple.com/?address=$encodedAddress');
        break;
    }

    if (launchUri != null && await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (type == 'map' || type == 'notes' || type == 'services') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 4),
            if (type == 'services')
              ...List<Widget>.from(
                (value as List? ?? []).map(
                  (service) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text(
                      '• $service',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              )
            else
              InkWell(
                onTap: type == 'map' ? () => _handleTap(context) : null,
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    color: Colors.white70,
                    decoration: type == 'map' ? TextDecoration.underline : null,
                    decorationColor: Colors.white70,
                    decorationStyle: TextDecorationStyle.dashed,
                  ),
                ),
              ),
          ],
        ),
      );
    }

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
          type != null
              ? InkWell(
                  onTap: () => _handleTap(context),
                  child: Text(
                    value.toString(),
                    style: const TextStyle(
                      color: Colors.white70,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white70,
                      decorationStyle: TextDecorationStyle.dashed,
                    ),
                  ),
                )
              : Text(
                  value.toString(),
                  style: const TextStyle(color: Colors.white70),
                ),
        ],
      ),
    );
  }
}