import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboardpage.dart';

class ProfileSelectionPage extends StatefulWidget {
  @override
  _ProfileSelectionPageState createState() => _ProfileSelectionPageState();
}

class _ProfileSelectionPageState extends State<ProfileSelectionPage> {
  Future<Map<String, String>> _loadProfiles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, String> profiles = {};
    for (var k in prefs.getKeys()) {
      if (k.startsWith('profile_')) {
        profiles[k.replaceFirst('profile_', '')] = prefs.getString(k) ?? '';
        // Ensure there is a data_<name> entry (defaults) to avoid nulls later:
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

  Future<void> _addProfile() async {
    TextEditingController nameCtrl = TextEditingController();
    TextEditingController passCtrl = TextEditingController();

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Close", // required by Flutter assertion
      barrierColor: Colors.black54,
      transitionDuration: Duration(milliseconds: 420),
      pageBuilder: (_, __, ___) => SizedBox.shrink(),
      transitionBuilder: (context, anim, secondary, child) {
        final curved = Curves.easeOut.transform(anim.value);
        return Transform.scale(
          scale: 0.9 + 0.1 * curved,
          child: Opacity(
            opacity: anim.value,
            child: Center(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 28),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF111111),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.08),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Create a new Home profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 14),
                        TextField(
                          controller: nameCtrl,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white10,
                            labelText: 'Profile Name',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
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
                        SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.greenAccent,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                final name = nameCtrl.text.trim();
                                final pass = passCtrl.text.trim();
                                if (name.isEmpty || pass.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Fields cannot be empty'),
                                    ),
                                  );
                                  return;
                                }

                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                // Save password
                                await prefs.setString('profile_$name', pass);

                                // Save default profile data (mock values)
                                Map<String, dynamic> defaultData = {
                                  'points': 420, // example starting points
                                  'totalKg': 2.4,
                                  'itemsRecycled': 8,
                                  'wasteTypes': {
                                    'Plastic': 1.0,
                                    'Paper': 0.6,
                                    'Glass': 0.4,
                                    'Organic': 0.4,
                                  },
                                };
                                await prefs.setString(
                                  'data_$name',
                                  json.encode(defaultData),
                                );

                                Navigator.pop(context);
                                setState(() {});
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 10,
                                ),
                                child: Text(
                                  'Create',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _verifyPassword(String profile) async {
    TextEditingController passCtrl = TextEditingController();

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Close", // required by Flutter assertion
      barrierColor: Colors.black54,
      transitionDuration: Duration(milliseconds: 420),
      pageBuilder: (_, __, ___) => SizedBox.shrink(),
      transitionBuilder: (context, anim, secondary, child) {
        final curved = Curves.easeOut.transform(anim.value);
        return Transform.translate(
          offset: Offset(0, (1 - curved) * 40),
          child: Opacity(
            opacity: anim.value,
            child: Center(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 28),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF111111),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.05),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Enter password for "$profile"',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 12),
                        TextField(
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
                        SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.greenAccent,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                final stored =
                                    prefs.getString('profile_$profile') ?? '';
                                if (stored == passCtrl.text) {
                                  Navigator.pop(context);
                                  // Smooth route push to dashboard with fade
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      transitionDuration: Duration(
                                        milliseconds: 600,
                                      ),
                                      pageBuilder:
                                          (context, anim, secondAnim) =>
                                              FadeTransition(
                                                opacity: anim,
                                                child: DashboardPage(
                                                  profileName: profile,
                                                ),
                                              ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Wrong password')),
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 10,
                                ),
                                child: Text(
                                  'Login',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
      appBar: AppBar(
        title: Text('Select Your Home'),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<Map<String, String>>(
        future: _loadProfiles(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final profiles = snap.data!;
          return GridView.builder(
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
                // Add tile
                return GestureDetector(
                  onTap: _addProfile,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
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
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.98, end: 1.0),
                  duration: Duration(milliseconds: 280),
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
