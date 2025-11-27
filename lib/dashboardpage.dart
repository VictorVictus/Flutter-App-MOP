import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  final String profileName;
  DashboardPage({required this.profileName});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  int points = 0;
  double totalKg = 0.0;
  int itemsRecycled = 0;
  Map<String, double> wasteTypes = {
    'Plastic': 0.0,
    'Paper': 0.0,
    'Glass': 0.0,
    'Organic': 0.0,
  };

  // Environmental impact stats
  double co2Saved = 0.0;
  double treesSaved = 0.0;
  double waterSaved = 0.0;
  double energySaved = 0.0;
  double moneySaved = 0.0;

  // Environmental impact conversion factors (sources: EPA, environmental studies)
  final Map<String, Map<String, double>> _impactFactors = {
    'Plastic': {
      'co2': 2.5, // kg CO2 per kg recycled (vs producing new plastic)
      'energy': 65.0, // kWh per kg recycled (energy savings)
      'water': 2500.0, // liters water saved per kg recycled
      'money': 0.15, // $ savings per kg recycled
    },
    'Paper': {
      'co2': 1.2, // kg CO2 per kg recycled
      'energy': 4.5, // kWh per kg recycled
      'water': 1500.0, // liters water saved per kg recycled
      'money': 0.12, // $ savings per kg recycled
      'trees': 0.017, // trees saved per kg (17 trees per ton)
    },
    'Glass': {
      'co2': 0.3, // kg CO2 per kg recycled
      'energy': 0.3, // kWh per kg recycled
      'water': 100.0, // liters water saved per kg recycled
      'money': 0.08, // $ savings per kg recycled
    },
    'Organic': {
      'co2': 0.5, // kg CO2 per kg composted (methane reduction)
      'energy': 0.1, // kWh per kg (energy from compost)
      'water': 50.0, // liters water saved per kg
      'money': 0.05, // $ savings per kg (reduced landfill costs)
    },
  };

  late AnimationController _controller;
  late Animation<double> _pointsAnimation;
  bool _isDataLoaded = false;

  // Calculate derived stats based on actual material types
  void _calculateDerivedStats() {
    double totalCO2 = 0.0;
    double totalEnergy = 0.0;
    double totalWater = 0.0;
    double totalMoney = 0.0;
    double totalTrees = 0.0;

    // Calculate impacts for each material type
    wasteTypes.forEach((material, kg) {
      final factors = _impactFactors[material]!;
      totalCO2 += kg * factors['co2']!;
      totalEnergy += kg * factors['energy']!;
      totalWater += kg * factors['water']!;
      totalMoney += kg * factors['money']!;

      // Trees saved only for paper
      if (material == 'Paper') {
        totalTrees += kg * factors['trees']!;
      }
    });

    setState(() {
      co2Saved = totalCO2;
      energySaved = totalEnergy;
      waterSaved = totalWater;
      moneySaved = totalMoney;
      treesSaved = totalTrees;
    });
  }

  // Get impact description for tooltips
  String _getImpactDescription(String impactType) {
    switch (impactType) {
      case 'CO₂':
        return 'Greenhouse gas emissions prevented';
      case 'Trees':
        return 'Trees preserved from logging';
      case 'Water':
        return 'Water consumption avoided';
      case 'Energy':
        return 'Energy savings compared to virgin materials';
      case 'Money':
        return 'Economic value created';
      default:
        return 'Environmental impact';
    }
  }

  // Get source information
  String _getImpactSource(String impactType) {
    return 'Based on EPA and industry lifecycle analysis';
  }

  // Beautiful color gradient based on percentage
  Color _getRingColor(double percentage) {
    final hue = 120.0 * percentage;
    final saturation = 0.9 + (0.1 * percentage);
    final lightness = 0.5 - (0.1 * percentage);
    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  }

  Color _getRingGlowColor(double percentage) {
    return _getRingColor(percentage).withOpacity(0.3);
  }

  Future<void> _loadProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('data_${widget.profileName}');

    if (raw != null) {
      try {
        final Map<String, dynamic> data = json.decode(raw);
        setState(() {
          points = (data['points'] ?? 0) as int;
          totalKg = (data['totalKg'] ?? 0.0).toDouble();
          itemsRecycled = (data['itemsRecycled'] ?? 0) as int;
          final wt = Map<String, dynamic>.from(data['wasteTypes'] ?? {});
          wasteTypes = {
            'Plastic': (wt['Plastic'] ?? 0.0).toDouble(),
            'Paper': (wt['Paper'] ?? 0.0).toDouble(),
            'Glass': (wt['Glass'] ?? 0.0).toDouble(),
            'Organic': (wt['Organic'] ?? 0.0).toDouble(),
          };
        });

        _calculateDerivedStats();

        // Reset and restart animation with new values
        _controller.reset();
        _pointsAnimation = Tween<double>(begin: 0, end: points / 1000.0)
            .animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
            );

        _controller.forward();

        setState(() {
          _isDataLoaded = true;
        });
      } catch (e) {
        print('Error loading profile data: $e');
        _initializeWithDefaults();
      }
    } else {
      _initializeWithDefaults();
    }
  }

  void _initializeWithDefaults() {
    setState(() {
      points = 420;
      totalKg = 2.4;
      itemsRecycled = 8;
      wasteTypes = {'Plastic': 1.0, 'Paper': 0.6, 'Glass': 0.4, 'Organic': 0.4};
    });

    _calculateDerivedStats();

    _controller.reset();
    _pointsAnimation = Tween<double>(
      begin: 0,
      end: points / 1000.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    setState(() {
      _isDataLoaded = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _pointsAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _loadProfileData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _refreshDashboard() {
    _loadProfileData();
  }

  String _getMotivationalMessage(double percentage) {
    if (percentage >= 0.9) return 'Excellent recycling performance';
    if (percentage >= 0.7) return 'Strong environmental contribution';
    if (percentage >= 0.5) return 'Good recycling progress';
    if (percentage >= 0.3) return 'Making a positive impact';
    if (percentage >= 0.1) return 'Building recycling habits';
    return 'Start your recycling journey today';
  }

  Color _colorFor(String key) {
    switch (key) {
      case 'Plastic':
        return Colors.blueAccent;
      case 'Paper':
        return Colors.orangeAccent;
      case 'Glass':
        return Colors.green;
      case 'Organic':
        return Colors.tealAccent;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, [
    String? subtitle,
    String? impactType,
  ]) {
    return Tooltip(
      message: impactType != null
          ? _getImpactDescription(impactType) +
                '\n' +
                _getImpactSource(impactType)
          : '',
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              spreadRadius: 1,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            SizedBox(height: 10),
            Text(title, style: TextStyle(color: Colors.white60, fontSize: 12)),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWasteRow(String name, double kg, double fraction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _colorFor(name),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 8,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(_colorFor(name)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(fraction * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${kg.toStringAsFixed(1)} kg',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDataLoaded) {
      return Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text('Dashboard — ${widget.profileName}'),
          elevation: 0,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final totalWaste = wasteTypes.values.fold(0.0, (a, b) => a + b);
    final wastePerc = totalWaste > 0
        ? wasteTypes.map((k, v) => MapEntry(k, v / totalWaste))
        : wasteTypes.map((k, v) => MapEntry(k, 0.0));

    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Dashboard — ${widget.profileName}'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white70),
            onPressed: _refreshDashboard,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white70),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => _EditDataDialog(
                  profileName: widget.profileName,
                  onDataUpdated: _refreshDashboard,
                ),
              );
            },
            tooltip: 'Edit Data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Environmental impact info panel
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.green[900]!.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.eco, color: Colors.greenAccent, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Environmental impacts calculated using EPA conversion factors',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),

              // Top card: eco-score & breakdown
              Container(
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Color(0xFF111111),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.06),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Circular points ring
                        Container(
                          width: 150,
                          height: 150,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _pointsAnimation,
                                builder: (context, child) {
                                  final glowColor = _getRingGlowColor(
                                    _pointsAnimation.value,
                                  );
                                  return Container(
                                    width: 160,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: glowColor,
                                          blurRadius: 15,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              SizedBox(
                                width: 150,
                                height: 150,
                                child: AnimatedBuilder(
                                  animation: _pointsAnimation,
                                  builder: (context, child) {
                                    final ringColor = _getRingColor(
                                      _pointsAnimation.value,
                                    );
                                    return CircularProgressIndicator(
                                      value: _pointsAnimation.value,
                                      strokeWidth: 12,
                                      backgroundColor: Colors.white12,
                                      valueColor: AlwaysStoppedAnimation(
                                        ringColor,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedBuilder(
                                    animation: _pointsAnimation,
                                    builder: (context, child) {
                                      final ringColor = _getRingColor(
                                        _pointsAnimation.value,
                                      );
                                      return Text(
                                        '${(_pointsAnimation.value * 100).toInt()}%',
                                        style: TextStyle(
                                          color: ringColor,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 10,
                                              color: ringColor.withOpacity(0.3),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '$points pts',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Performance',
                                    style: TextStyle(
                                      color: Colors.white30,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recycled breakdown',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 12),
                              _buildWasteRow(
                                'Plastic',
                                wasteTypes['Plastic'] ?? 0.0,
                                wastePerc['Plastic'] ?? 0.0,
                              ),
                              _buildWasteRow(
                                'Paper',
                                wasteTypes['Paper'] ?? 0.0,
                                wastePerc['Paper'] ?? 0.0,
                              ),
                              _buildWasteRow(
                                'Glass',
                                wasteTypes['Glass'] ?? 0.0,
                                wastePerc['Glass'] ?? 0.0,
                              ),
                              _buildWasteRow(
                                'Organic',
                                wasteTypes['Organic'] ?? 0.0,
                                wastePerc['Organic'] ?? 0.0,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.eco, color: Colors.greenAccent, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _pointsAnimation,
                              builder: (context, child) {
                                final ringColor = _getRingColor(
                                  _pointsAnimation.value,
                                );
                                return Text(
                                  _getMotivationalMessage(
                                    _pointsAnimation.value,
                                  ),
                                  style: TextStyle(
                                    color: ringColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Row 1: Basic Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Times recycled',
                      '$itemsRecycled',
                      Icons.restore,
                      Colors.greenAccent,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Kg recycled',
                      '${totalKg.toStringAsFixed(1)} kg',
                      Icons.scale,
                      Colors.greenAccent,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Row 2: Environmental Impact
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'CO₂ Saved',
                      '${co2Saved.toStringAsFixed(1)} kg',
                      Icons.cloud,
                      Colors.blueAccent,
                      'Emissions prevented',
                      'CO₂',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Trees Saved',
                      '${treesSaved.toStringAsFixed(2)}',
                      Icons.park,
                      Colors.green,
                      'Trees preserved',
                      'Trees',
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Row 3: Resources Saved
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Water Saved',
                      '${(waterSaved / 1000).toStringAsFixed(1)} m³',
                      Icons.water_drop,
                      Colors.lightBlue,
                      'Water conserved',
                      'Water',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Energy Saved',
                      '${energySaved.toStringAsFixed(1)} kWh',
                      Icons.bolt,
                      Colors.yellow,
                      'Energy generated',
                      'Energy',
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Row 4: Economic Impact
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Money Saved',
                      '\$${moneySaved.toStringAsFixed(2)}',
                      Icons.attach_money,
                      Colors.green,
                      'Economic value',
                      'Money',
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.43,
                    child: _buildStatCard(
                      'Total Impact',
                      '${totalKg.toStringAsFixed(1)} kg',
                      Icons.assessment,
                      Colors.teal,
                      'All materials recycled',
                    ),
                  ),
                ],
              ),

              SizedBox(height: 18),

              // Impact calculation info
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Impact Calculation Methodology',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Environmental impacts are calculated using material-specific conversion factors from EPA and industry lifecycle assessments. Each material type has different environmental savings per kilogram recycled.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 18),

              // Debug actions
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.1),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Actions',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.add, size: 16),
                            label: Text('Add 100 Points'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () async {
                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                              final raw = prefs.getString(
                                'data_${widget.profileName}',
                              );
                              if (raw != null) {
                                final Map<String, dynamic> data = json.decode(
                                  raw,
                                );
                                data['points'] = (data['points'] as int) + 100;
                                await prefs.setString(
                                  'data_${widget.profileName}',
                                  json.encode(data),
                                );
                                _refreshDashboard();
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.refresh, size: 16),
                            label: Text('Reset'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () async {
                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
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
                              await prefs.setString(
                                'data_${widget.profileName}',
                                json.encode(defaultData),
                              );
                              _refreshDashboard();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditDataDialog extends StatefulWidget {
  final String profileName;
  final VoidCallback onDataUpdated;

  const _EditDataDialog({
    required this.profileName,
    required this.onDataUpdated,
  });

  @override
  __EditDataDialogState createState() => __EditDataDialogState();
}

class __EditDataDialogState extends State<_EditDataDialog> {
  late TextEditingController pointsCtrl;
  late TextEditingController totalKgCtrl;
  late TextEditingController itemsCtrl;
  late TextEditingController plasticCtrl;
  late TextEditingController paperCtrl;
  late TextEditingController glassCtrl;
  late TextEditingController organicCtrl;

  @override
  void initState() {
    super.initState();
    pointsCtrl = TextEditingController();
    totalKgCtrl = TextEditingController();
    itemsCtrl = TextEditingController();
    plasticCtrl = TextEditingController();
    paperCtrl = TextEditingController();
    glassCtrl = TextEditingController();
    organicCtrl = TextEditingController();

    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('data_${widget.profileName}');
    if (raw != null) {
      final Map<String, dynamic> data = json.decode(raw);
      setState(() {
        pointsCtrl.text = (data['points'] ?? 0).toString();
        totalKgCtrl.text = (data['totalKg'] ?? 0.0).toString();
        itemsCtrl.text = (data['itemsRecycled'] ?? 0).toString();
        final wt = Map<String, dynamic>.from(data['wasteTypes'] ?? {});
        plasticCtrl.text = (wt['Plastic'] ?? 0.0).toString();
        paperCtrl.text = (wt['Paper'] ?? 0.0).toString();
        glassCtrl.text = (wt['Glass'] ?? 0.0).toString();
        organicCtrl.text = (wt['Organic'] ?? 0.0).toString();
      });
    }
  }

  Future<void> _saveData() async {
    try {
      Map<String, dynamic> newData = {
        'points': int.tryParse(pointsCtrl.text) ?? 0,
        'totalKg': double.tryParse(totalKgCtrl.text) ?? 0.0,
        'itemsRecycled': int.tryParse(itemsCtrl.text) ?? 0,
        'wasteTypes': {
          'Plastic': double.tryParse(plasticCtrl.text) ?? 0.0,
          'Paper': double.tryParse(paperCtrl.text) ?? 0.0,
          'Glass': double.tryParse(glassCtrl.text) ?? 0.0,
          'Organic': double.tryParse(organicCtrl.text) ?? 0.0,
        },
      };

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('data_${widget.profileName}', json.encode(newData));

      Navigator.pop(context);
      widget.onDataUpdated();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile data updated successfully! Dashboard refreshed.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating data: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Color(0xFF111111),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Profile Data (Live Debug)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Changes update immediately',
                style: TextStyle(color: Colors.greenAccent, fontSize: 12),
              ),
              SizedBox(height: 16),
              _buildNumberField(pointsCtrl, 'Points (0-1000)'),
              _buildNumberField(totalKgCtrl, 'Total Kg'),
              _buildNumberField(itemsCtrl, 'Items Recycled'),
              SizedBox(height: 8),
              Text(
                'Waste Types (kg):',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _buildNumberField(plasticCtrl, 'Plastic'),
              _buildNumberField(paperCtrl, 'Paper'),
              _buildNumberField(glassCtrl, 'Glass'),
              _buildNumberField(organicCtrl, 'Organic'),
              SizedBox(height: 20),
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
                    onPressed: _saveData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                    ),
                    child: Text(
                      'Save & Refresh',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
