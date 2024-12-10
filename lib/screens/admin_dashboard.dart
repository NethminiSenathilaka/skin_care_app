import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:spotlessyou/models/message.dart';
import 'package:spotlessyou/services/message_service.dart';

import '../models/spotelessyou_user.dart';
import '../services/spotlessyouuser_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Future<List<SpotelessYouUser>> _doctorsFuture;
  late Future<List<SpotelessYouUser>> _usersFuture;
  late Future<List<Message>> _messageFuture;
  int userCount = 0;

  @override
  void initState() {
    super.initState();
    _doctorsFuture = SpotlessyouuserService().getDoctorsList();
    _usersFuture = SpotlessyouuserService().getUsersList();
    _messageFuture = MessageService().getMessagesFutureList();
    _fetchUserCount();
  }

  Future<void> _fetchUserCount() async {
    final users = await _usersFuture;
    final messages = await _messageFuture;
    setState(() {
      userCount = users.length;
    });
  }

  List<BarChartGroupData> _generateAgeChartData(List<dynamic> users) {
    final ageGroups = <String, int>{'18-25': 0, '26-35': 0, '36-45': 0, '46+': 0};

    for (var user in users) {
      int age = int.tryParse(user.age) ?? 0;
      if (age >= 18 && age <= 25) ageGroups['18-25'] = ageGroups['18-25']! + 1;
      else if (age >= 26 && age <= 35) ageGroups['26-35'] = ageGroups['26-35']! + 1;
      else if (age >= 36 && age <= 45) ageGroups['36-45'] = ageGroups['36-45']! + 1;
      else if (age > 45) ageGroups['46+'] = ageGroups['46+']! + 1;
    }

    return ageGroups.entries.map((entry) {
      return BarChartGroupData(
        x: ageGroups.keys.toList().indexOf(entry.key),
        barRods: [BarChartRodData(toY: entry.value.toDouble(), width: 20)],
      );
    }).toList();
  }

  List<PieChartSectionData> _generateGenderChartData(List<dynamic> users) {
    final genderCount = {'Male': 0, 'Female': 0, 'Other': 0};

    for (var user in users) {
      if (user.gender == 'Male') genderCount['Male'] = genderCount['Male']! + 1;
      else if (user.gender == 'Female') genderCount['Female'] = genderCount['Female']! + 1;
      else genderCount['Other'] = genderCount['Other']! + 1;
    }

    return genderCount.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.key} (${entry.value})',
        color: entry.key == 'Male' ? Colors.blue : entry.key == 'Female' ? Colors.pink : Colors.purple,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        // Always prevent navigation
        return;
      },
      child: Scaffold(
        backgroundColor: Colors.pink[100],
        appBar: AppBar(
          backgroundColor: Colors.pinkAccent,
          title: const Text('Admin Dashboard'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/doctorSignup'),
              icon: const Icon(Icons.local_hospital),
              color: Colors.white70,
            ),
            IconButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: FutureBuilder<List<List<dynamic>>>(
          future: Future.wait([_doctorsFuture, _usersFuture, _messageFuture]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No data found.'));
            } else {
              final doctors = snapshot.data![0];
              final users = snapshot.data![1];
              final messages = snapshot.data![2];

              // Group messages by doctor name for feedback section
              final feedbackByDoctor = <String, List<Message>>{};
              for (var message in messages) {
                feedbackByDoctor.putIfAbsent(message.docname, () => []).add(message);
              }

              return ListView(
                padding: const EdgeInsets.all(8.0),
                children: [
                  Text(
                    'Doctors List',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      final doctor = doctors[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 4.0,
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(doctor.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email: ${doctor.email}'),
                              Text('Mobile: ${doctor.mobile}'),
                              //Text('Age: ${doctor.age}'),
                              //Text('Gender: ${doctor.gender}'),
                              //Text('District: ${doctor.district}'),
                              Text('Bio: ${doctor.bio}'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'User Count: $userCount',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 20),
                  Text('Age Distribution', style: Theme.of(context).textTheme.titleSmall),
                  SizedBox(
                    height: 300,
                    child: BarChart(
                      BarChartData(
                        barGroups: _generateAgeChartData(users),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                const ageLabels = ['18-25', '26-35', '36-45', '46+'];
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(ageLabels[value.toInt()]),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Gender Distribution', style: Theme.of(context).textTheme.titleSmall),
                  SizedBox(
                    height: 300,
                    child: PieChart(
                      PieChartData(
                        sections: _generateGenderChartData(users),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Feedbacks', style: Theme.of(context).textTheme.titleMedium),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: feedbackByDoctor.keys.length,
                    itemBuilder: (context, index) {
                      final doctorName = feedbackByDoctor.keys.elementAt(index);
                      final feedbacks = feedbackByDoctor[doctorName]!;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 4.0,
                        child: ListTile(
                          title: Text('Doctor: $doctorName', style: Theme.of(context).textTheme.titleMedium),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: feedbacks.where((message) => message.feedback.isNotEmpty).map((message) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text('\u2022 ${message.feedback}'),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            }
          },
        ),
        // floatingActionButton: FloatingActionButton.extended(
        //   onPressed: () => Navigator.pushReplacementNamed(context, '/doctorSignup'),
        //   icon: const Icon(Icons.local_hospital),
        //   label: const Text('Doctor Signup'),
        //   backgroundColor: Colors.pink,
        // ),
      ),
    );
  }
}
