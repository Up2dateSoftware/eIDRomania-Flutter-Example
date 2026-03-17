import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:romanian_eid_sdk/romanian_eid_sdk.dart';

const String _licenseKey = 'YOUR_LICENSE_KEY_HERE';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eID Romania Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF123E72)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isInitialized = false;
  bool _isNfcAvailable = false;
  String _status = 'Initializing...';
  IDCardResult? _idCardResult;

  final _canController = TextEditingController();
  final _pinController = TextEditingController();

  StreamSubscription<ReadingProgress>? _progressSubscription;

  @override
  void initState() {
    super.initState();
    _initSdk();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _canController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _initSdk() async {
    try {
      final success = await RomanianEidSdk.initialize(_licenseKey);
      final nfc = await RomanianEidSdk.isNfcAvailable();
      setState(() {
        _isInitialized = success;
        _isNfcAvailable = nfc;
        _status = success
            ? (nfc ? 'Ready — enter CAN and PIN' : 'SDK ready but NFC not available')
            : 'SDK initialization failed';
      });
    } catch (e) {
      setState(() => _status = 'Init error: $e');
    }
  }

  Future<void> _readIDCard() async {
    final can = _canController.text.trim();
    final pin = _pinController.text.trim();

    if (can.length != 6) {
      _showError('CAN must be 6 digits');
      return;
    }

    setState(() {
      _status = 'Hold the card against your phone...';
      _idCardResult = null;
    });

    _progressSubscription?.cancel();
    _progressSubscription = RomanianEidSdk.progressStream.listen((p) {
      setState(() => _status = '${p.percentage}%: ${p.message}');
    });

    try {
      final result = await RomanianEidSdk.readIDCard(
        can: can,
        pin: pin.isNotEmpty ? pin : null,
      );
      setState(() {
        _idCardResult = result;
        _status = result.success ? 'Card read successfully!' : 'Read failed: ${result.errorMessage}';
      });
    } on PlatformException catch (e) {
      setState(() => _status = 'Error: ${e.message}');
      _showError('${e.code}: ${e.message}');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      _progressSubscription?.cancel();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('eID Romania Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.nfc, color: _isNfcAvailable ? Colors.green : Colors.red),
                      const SizedBox(width: 8),
                      Text(_isNfcAvailable ? 'NFC Available' : 'NFC Not Available',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 8),
                    Text('Status: $_status'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Read ID Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Read ID Card', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _canController,
                      decoration: const InputDecoration(
                        labelText: 'CAN (6 digits)',
                        hintText: '123456',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _pinController,
                      decoration: const InputDecoration(
                        labelText: 'PIN (4 digits, optional)',
                        hintText: '1234',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isInitialized && _isNfcAvailable ? _readIDCard : null,
                        icon: const Icon(Icons.nfc),
                        label: const Text('Read Card'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Results
            if (_idCardResult != null) _buildResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final c = _idCardResult!;
    return Card(
      color: c.success ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.success ? 'Card Data' : 'Read Failed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: c.success ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 12),
            _row('Name', c.fullName),
            _row('CNP', c.cnp),
            _row('Document Nr.', c.documentNumber),
            _row('Date of Birth', c.dateOfBirth),
            _row('Sex', c.sex),
            _row('Nationality', c.citizenship),
            _row('Place of Birth', c.placeOfBirth),
            _row('Address', c.permanentAddress),
            _row('Issuing Auth.', c.issuingAuthority),
            _row('Date of Expiry', c.dateOfExpiry),
            _row('Authentic', c.cscaValidated ? 'Yes' : 'No'),
            if (c.facialImageBase64 != null) ...[
              const SizedBox(height: 12),
              const Text('Face Photo:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(base64Decode(c.facialImageBase64!), height: 150),
              ),
            ],
            if (c.signatureImageBase64 != null) ...[
              const SizedBox(height: 12),
              const Text('Signature:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Image.memory(base64Decode(c.signatureImageBase64!), height: 60),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(child: Text(value ?? '-')),
        ],
      ),
    );
  }
}
