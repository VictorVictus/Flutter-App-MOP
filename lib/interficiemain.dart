import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboardpage.dart';

class ProfileSelectionPage extends StatefulWidget {
  @override
  _ProfileSelectionPageState createState() => _ProfileSelectionPageState();
}

class _ProfileSelectionPageState extends State<ProfileSelectionPage> {
  bool _isScanning = false;
  String _scanStatus = 'A l\'espera de lectura NFC...';
  Timer? _nfcSimulationTimer;
  bool _showNfcMode = true; // Start in NFC mode

  @override
  void dispose() {
    _nfcSimulationTimer?.cancel();
    super.dispose();
  }

  // NFC SIMULATION - Auto-login when "card" is detected
  void _startNfcSimulation() {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _scanStatus = 'Detectant NFC...\nMantingui la targeta prop del lector';
    });

    // Simulate 1.5 seconds of NFC detection
    _nfcSimulationTimer = Timer(Duration(milliseconds: 1500), () {
      _completeNfcLogin();
    });
  }

  void _completeNfcLogin() async {
    setState(() {
      _scanStatus = 'Acces concedit!\nCarregant el tauler...';
    });

    // Brief delay for realism
    await Future.delayed(Duration(milliseconds: 800));

    // Auto-login to first profile (or create demo)
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String profileName = 'Demo Home';

    // Try to find existing profiles
    for (var key in prefs.getKeys()) {
      if (key.startsWith('profile_')) {
        profileName = key.replaceFirst('profile_', '');
        break;
      }
    }

    // If no profile exists, create demo one
    if (!prefs.containsKey('profile_$profileName')) {
      await prefs.setString('profile_$profileName', 'demo123');

      Map<String, dynamic> defaultData = {
        'points': 850,
        'totalKg': 6.7,
        'itemsRecycled': 22,
        'wasteTypes': {
          'Plastic': 2.8,
          'Paper': 2.1,
          'Glass': 1.2,
          'Organic': 0.6,
        },
      };
      await prefs.setString('data_$profileName', json.encode(defaultData));
    }

    // Navigate to dashboard
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => DashboardPage(profileName: profileName),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  Future<Map<String, String>> _loadProfiles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, String> profiles = {};
    for (var k in prefs.getKeys()) {
      if (k.startsWith('profile_')) {
        profiles[k.replaceFirst('profile_', '')] = prefs.getString(k) ?? '';
        final dataKey = 'data_${k.replaceFirst('profile_', '')}';
        if (!prefs.containsKey(dataKey)) {
          Map<String, dynamic> defaultData = {
            'points': 0,
            'totalKg': 0.0,
            'itemsRecycled': 0,
            'wasteTypes': {
              'Plastic': 0.0,
              'Paper': 0.0,
              'Glass': 0.0,
              'Organic': 0.0,
            },
          };
          prefs.setString(dataKey, json.encode(defaultData));
        }
      }
    }
    return profiles;
  }

  // Manual profile methods (from original code)
  Future<void> _verifyPassword(String profile) async {
    TextEditingController passCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF111111),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Introdueixi la contrasenya per a "$profile"',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white10,
            labelText: 'Password',
            labelStyle: TextStyle(color: Colors.white70),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              final stored = prefs.getString('profile_$profile') ?? '';
              if (stored == passCtrl.text) {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DashboardPage(profileName: profile),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Contrasenya incorrecta')),
                );
              }
            },
            child: Text('Iniciar sessió'),
          ),
        ],
      ),
    );
  }

  Color _avatarColor(String name) {
    final list = Colors.primaries;
    return list[name.hashCode % list.length].shade400;
  }

  IconData _houseIconForName(String name) {
    final icons = [
      Icons.house_rounded,
      Icons.home,
      Icons.cottage,
      Icons.villa,
      Icons.apartment,
    ];
    return icons[name.hashCode % icons.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text('ARAMVA Recycle: Login'),
        backgroundColor: Colors.black,
        actions: [],
      ),
      body: _showNfcMode
          ? _buildNfcMode()
          : FutureBuilder<Map<String, String>>(
              future: _loadProfiles(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final profiles = snap.data!;
                return _buildManualMode(profiles);
              },
            ),
    );
  }

  // NFC MODE UI
  Widget _buildNfcMode() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // NFC Scanner Animation
        GestureDetector(
          onTap: _startNfcSimulation,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 400),
            width: 275,
            height: 275,
            margin: EdgeInsets.only(bottom: 40),
            decoration: BoxDecoration(
              color: _isScanning
                  ? Colors.blue.shade900.withOpacity(0.3)
                  : Colors.black,
              shape: BoxShape.circle,
              border: Border.all(
                color: _isScanning ? Colors.blueAccent : Colors.greenAccent,
                width: 4,
              ),
              boxShadow: _isScanning
                  ? [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 500),
                  child: Icon(
                    _isScanning ? Icons.nfc : Icons.phone_android,
                    size: 70,
                    color: _isScanning ? Colors.blueAccent : Colors.greenAccent,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  _isScanning ? 'DETECTANT...' : 'TOCA PER LLEGIR NFC',
                  style: TextStyle(
                    color: _isScanning ? Colors.blueAccent : Colors.greenAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Status Panel
        Container(
          width: 300,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isScanning
                  ? Colors.blueAccent.withOpacity(0.4)
                  : Colors.blueGrey,
            ),
          ),
          child: Column(
            children: [
              Icon(
                _isScanning ? Icons.wifi_find : Icons.contactless_outlined,
                size: 32,
                color: _isScanning ? Colors.blueAccent : Colors.blueGrey,
              ),
              SizedBox(height: 12),
              Text(
                _scanStatus,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isScanning ? Colors.blueAccent : Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              if (_isScanning) ...[
                SizedBox(height: 16),
                LinearProgressIndicator(
                  backgroundColor: Colors.blue.shade900,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              ],
            ],
          ),
        ),

        // Demo Instructions
        Container(
          margin: EdgeInsets.all(30),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info, color: Colors.greenAccent, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'MODE DE SHOWCASE ACTIVAT',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Per a la demostració: Toca el cercle NFC per començar a llegir NFC.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 150),
        Text(
          'Una App feta per ARAMVA Engineering',
          style: TextStyle(
            color: Colors.greenAccent,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // MANUAL MODE UI
  Widget _buildManualMode(Map<String, String> profiles) {
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(20),
          child: Text(
            'Select Your Home',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Profiles Grid
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.9,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: profiles.length + 1,
            itemBuilder: (_, i) {
              if (i == profiles.length) {
                // Add new profile tile
                return GestureDetector(
                  onTap: () => _addProfile(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey.shade800,
                          child: Icon(
                            Icons.add_home_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Add Home',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final name = profiles.keys.elementAt(i);
              return GestureDetector(
                onTap: () => _verifyPassword(name),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF111111),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 8,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: _avatarColor(name),
                        child: Icon(
                          _houseIconForName(name),
                          size: 38,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Original add profile method (simplified)
  Future<void> _addProfile() async {
    TextEditingController nameCtrl = TextEditingController();
    TextEditingController passCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF111111),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Crea una nova residencia',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Profile Name',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: passCtrl,
              obscureText: true,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final pass = passCtrl.text.trim();
              if (name.isEmpty || pass.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Els camps no poden estar buits')),
                );
                return;
              }

              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('profile_$name', pass);

              Map<String, dynamic> defaultData = {
                'points': 420,
                'totalKg': 2.4,
                'itemsRecycled': 8,
                'wasteTypes': {
                  'Plastic': 1.0,
                  'Paper': 0.6,
                  'Glass': 0.4,
                  'Organic': 0.4,
                },
              };
              await prefs.setString('data_$name', json.encode(defaultData));

              Navigator.pop(context);
              setState(() {});
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }
}
