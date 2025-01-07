import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';


class InfoRow extends StatelessWidget {
  final String label;
  final dynamic value;
  final String? type;

  const InfoRow({
    Key? key,
    required this.label,
    required this.value,
    this.type,
  }) : super(key: key);


Future<void> _openMap(String addressToOpen) async {
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeFull(addressToOpen)}');
    
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $googleMapsUrl');
    }
  }
Future<void> _makePhoneCall(String phoneNumber) async {
  final Uri launchUri = Uri(
    scheme: 'tel',
    path: phoneNumber,
  );
  if (await canLaunchUrl(launchUri)) {
    await launchUrl(launchUri);
  } else {
    throw 'Could not launch $launchUri';
  }
}

// Function to send an email
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

 

  Future<void> _handleTap() async {
    Uri? launchUri;
    
    switch (type) {
      case 'phone':
        launchUri = Uri(
          scheme: 'tel',
          path: value.replaceAll(RegExp(r'[^\d+]'), ''), // Clean phone number
        );
        break;
      case 'email':
        launchUri = Uri(
          scheme: 'mailto',
          path: value,
        );
        break;
      case 'map':
        // For iOS, we use Apple Maps
        final encodedAddress = Uri.encodeComponent(value);
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
                onTap: type == 'map' ? _handleTap : null,
                child: Text(
                  value,
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
                  onTap: _handleTap,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white70,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white70,
                      decorationStyle: TextDecorationStyle.dashed,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(color: Colors.white70),
                ),
        ],
      ),
    );
  }
}