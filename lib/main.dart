import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:romanian_eid_sdk/romanian_eid_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Romanian eID SDK Demo',
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
  String _status = 'Not initialized';
  IDCardResult? _idCardResult;
  PassportResult? _passportResult;

  final _licenseKeyController = TextEditingController();
  final _canController = TextEditingController();
  final _pinController = TextEditingController();
  final _docNumController = TextEditingController();
  final _dobController = TextEditingController();
  final _doeController = TextEditingController();

  StreamSubscription<ReadingProgress>? _progressSubscription;

  @override
  void initState() {
    super.initState();
    _checkNfc();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _licenseKeyController.dispose();
    _canController.dispose();
    _pinController.dispose();
    _docNumController.dispose();
    _dobController.dispose();
    _doeController.dispose();
    super.dispose();
  }

  Future<void> _checkNfc() async {
    final available = await RomanianEidSdk.isNfcAvailable();
    setState(() {
      _isNfcAvailable = available;
      _status = available ? 'NFC available' : 'NFC not available';
    });
  }

  Future<void> _initialize() async {
    final key = _licenseKeyController.text.trim();
    if (key.isEmpty) {
      _showError('Please enter a license key');
      return;
    }

    setState(() => _status = 'Initializing...');
    try {
      final success = await RomanianEidSdk.initialize(key);
      setState(() {
        _isInitialized = success;
        _status = success ? 'SDK initialized' : 'Initialization failed';
      });
    } catch (e) {
      _showError('Init error: $e');
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
        _status = result.success ? 'ID card read successfully!' : 'Read failed: ${result.errorMessage}';
      });
    } catch (e) {
      _showError('Read error: $e');
    } finally {
      _progressSubscription?.cancel();
    }
  }

  Future<void> _readPassport() async {
    final docNum = _docNumController.text.trim();
    final dob = _dobController.text.trim();
    final doe = _doeController.text.trim();

    if (docNum.isEmpty || dob.isEmpty || doe.isEmpty) {
      _showError('Fill all passport fields');
      return;
    }

    setState(() {
      _status = 'Hold the passport against your phone...';
      _passportResult = null;
    });

    _progressSubscription?.cancel();
    _progressSubscription = RomanianEidSdk.progressStream.listen((p) {
      setState(() => _status = '${p.percentage}%: ${p.message}');
    });

    try {
      final result = await RomanianEidSdk.readPassport(
        documentNumber: docNum,
        dateOfBirth: dob,
        dateOfExpiry: doe,
      );
      setState(() {
        _passportResult = result;
        _status = result.success ? 'Passport read successfully!' : 'Read failed: ${result.errorMessage}';
      });
    } catch (e) {
      _showError('Read error: $e');
    } finally {
      _progressSubscription?.cancel();
    }
  }

  void _showError(String message) {
    setState(() => _status = 'Error: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Romanian eID SDK Demo'),
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

            // Initialize
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Initialize SDK', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _licenseKeyController,
                      decoration: const InputDecoration(labelText: 'License Key', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _initialize, child: const Text('Initialize')),
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
                    const Text('Read ID Card (PACE)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _canController,
                      decoration: const InputDecoration(labelText: 'CAN (6 digits)', hintText: '123456', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _pinController,
                      decoration: const InputDecoration(labelText: 'PIN (4 digits, optional)', hintText: '1234', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isInitialized ? _readIDCard : null,
                      child: const Text('Read ID Card'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Read Passport
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Read Passport (BAC)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(controller: _docNumController, decoration: const InputDecoration(labelText: 'Document Number', border: OutlineInputBorder())),
                    const SizedBox(height: 8),
                    TextField(controller: _dobController, decoration: const InputDecoration(labelText: 'Date of Birth (YYMMDD)', border: OutlineInputBorder())),
                    const SizedBox(height: 8),
                    TextField(controller: _doeController, decoration: const InputDecoration(labelText: 'Date of Expiry (YYMMDD)', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isInitialized ? _readPassport : null,
                      child: const Text('Read Passport'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ID Card Results
            if (_idCardResult != null) _buildIDCardResults(),

            // Passport Results
            if (_passportResult != null) _buildPassportResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildIDCardResults() {
    final c = _idCardResult!;
    return Card(
      color: c.success ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID Card Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: c.success ? Colors.green.shade800 : Colors.red.shade800)),
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
            _row('CSCA Valid', c.cscaValidated ? 'Yes' : 'No'),
            if (c.facialImageBase64 != null) ...[
              const SizedBox(height: 12),
              const Text('Face Photo:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Image.memory(base64Decode(c.facialImageBase64!), height: 120),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPassportResults() {
    final p = _passportResult!;
    return Card(
      color: p.success ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Passport Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: p.success ? Colors.green.shade800 : Colors.red.shade800)),
            const SizedBox(height: 12),
            _row('Name', p.fullName),
            _row('Document Nr.', p.documentNumber),
            _row('Nationality', p.nationality),
            _row('Date of Birth', p.dateOfBirth),
            _row('Date of Expiry', p.dateOfExpiry),
            _row('Sex', p.sex),
            _row('CSCA Valid', p.cscaValidated ? 'Yes' : 'No'),
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
