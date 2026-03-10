import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/match.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final matchProvider = MatchProvider();
  await matchProvider.loadMatches(); // 加载保存的比赛数据
  await matchProvider.loadDefaultSettings(); // 加载默认设置
  
  runApp(MyApp(matchProvider: matchProvider));
}

class MyApp extends StatelessWidget {
  final MatchProvider matchProvider;
  
  const MyApp({super.key, required this.matchProvider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: matchProvider,
      child: MaterialApp(
        title: 'Table Tennis Scorekeeper',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}