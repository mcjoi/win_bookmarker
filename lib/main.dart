import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:fluent_ui/fluent_ui.dart';
// ignore: implementation_imports
import 'package:fluent_ui/src/styles/color.dart' as fc;
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:system_tray/system_tray.dart';

//read txt file
String filePath = "./path\\path.json";
Map<String, List<String>> itemlist = {};

Future<void> readJsonFileAsMap(String filePath) async {
  File file = File(filePath);

  if (!await file.exists()) {
    debugPrint("json 파일이 존재하지 않습니다: $filePath");
  }

  // 파일 내용 읽기
  String content = await file.readAsString();

  // JSON 디코딩
  Map<String, dynamic> jsonData = jsonDecode(content);

  // `Map<String, dynamic>` → `Map<String, List<String>>` 변환
  itemlist = jsonData.map((key, value) {
    return MapEntry(key, List<String>.from(value));
  });
}

// 창 닫기 이벤트 감지 후 프로세스 완전 종료
class MyWindowListener extends WindowListener {
  @override
  void onWindowClose() async {
    exit(0); // 닫기 버튼 클릭 시 완전 종료
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await readJsonFileAsMap(filePath);

  await Window.initialize();

  await Window.setEffect(
    effect: WindowEffect.acrylic,
    // color: fc.Colors.black.withAlpha(200),
    dark: true,
  );

  // Initialize the window manager
  await windowManager.ensureInitialized();

  double addsize() {
    int itemlistLen = itemlist.values.elementAt(0).length;

    double addsize = 0.0;

    switch (itemlistLen) {
      case >= 13 && <= 15:
        addsize = 80.0;
      case >= 16 && <= 18:
        addsize = 160.0;
      case >= 19 && <= 21:
        addsize = 240.0;
      case >= 22:
        addsize = 320.0;
    }

    debugPrint("addsize: $addsize");
    return addsize;
  }

  double windowWidth = 240;
  double windowHeight = 340 + addsize();

  double posX = 1920 - windowWidth - 20; // 오른쪽 끝에서 약간 떨어진 위치
  double posY = 1080 - windowHeight - 50; // 아래쪽 끝에서 약간 떨어진 위치

  windowManager.waitUntilReadyToShow(
      WindowOptions(
        size: Size(windowWidth, windowHeight),
        alwaysOnTop: true,
        minimumSize: Size(windowWidth, windowHeight),
        maximumSize: Size(windowWidth, windowHeight),
      ), () async {
    windowManager.setPosition(Offset(posX, posY));
    windowManager.setHasShadow(false);
    windowManager.setMaximizable(false);
    windowManager.setMinimizable(true);
    windowManager.setSkipTaskbar(true);
    // windowManager.setClosable(false);
    windowManager.setPreventClose(true);
    windowManager.addListener(MyWindowListener());

    await windowManager.show();
    await windowManager.focus();
  });

  runApp(MyAppMaterial());
}

class MyAppMaterial extends StatelessWidget {
  const MyAppMaterial({super.key});

  @override
  Widget build(BuildContext context) {
    return const FluentApp(
      debugShowCheckedModeBanner: false,
      home: ViewPage(),
    );
  }
}

class ViewPage extends StatefulWidget {
  const ViewPage({super.key});

  @override
  State<ViewPage> createState() => _ViewPageState();
}

class _ViewPageState extends State<ViewPage> {
  late List<bool> isHoveredList;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    isHoveredList =
        List.generate(itemlist.values.elementAt(0).length, (_) => false);

    initSystemTray();
  }

  Future<void> initSystemTray() async {
    String path =
        Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.ico';

    final AppWindow appWindow = AppWindow();
    final SystemTray systemTray = SystemTray();

    // We first init the systray menu
    await systemTray.initSystemTray(
      title: "system tray",
      iconPath: path,
    );

    // create context menu
    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(label: 'Show', onClicked: (menuItem) => appWindow.show()),
      MenuItemLabel(label: 'Hide', onClicked: (menuItem) => appWindow.hide()),
      MenuItemLabel(label: 'Exit', onClicked: (menuItem) => appWindow.close()),
    ]);

    // set context menu
    await systemTray.setContextMenu(menu);

    // handle system tray event
    systemTray.registerSystemTrayEventHandler((eventName) {
      debugPrint("eventName: $eventName");
      if (eventName == kSystemTrayEventClick) {
        Platform.isWindows ? appWindow.show() : systemTray.popUpContextMenu();
      } else if (eventName == kSystemTrayEventRightClick) {
        Platform.isWindows ? systemTray.popUpContextMenu() : appWindow.show();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fc.Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: GridView.count(
          crossAxisCount: 3, // 2 columns
          mainAxisSpacing: 10, // Vertical spacing
          crossAxisSpacing: 10, // Horizontal spacing
          children: List.generate(itemlist.values.elementAt(0).length, (index) {
            return iconbuttongen(index, itemlist);
          }),
        ),
      ),
    );
  }

  void restartApp() async {
    String execPath = Platform.resolvedExecutable; // 실행 중인 Flutter 앱의 경로
    await Process.start(execPath, []); // 앱 다시 실행
    exit(0); // 현재 앱 종료
  }

  iconbuttongen(int idx, Map itemlist) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHoveredList[idx] = true),
      onExit: (_) => setState(() => isHoveredList[idx] = false),
      child: GestureDetector(
        child: Container(
          decoration: BoxDecoration(
            border: isHoveredList[idx]
                ? Border.all(
                    color: fc.Colors.white.withAlpha(200),
                    width: 2.0) // hover 시 테두리 3.0
                : null, // hover가 아닐 때는 테두리 제거
            borderRadius: BorderRadius.circular(50),
            image: DecorationImage(
              colorFilter: isHoveredList[idx]
                  ? ColorFilter.mode(
                      fc.Colors.black.withAlpha(180), BlendMode.darken)
                  : null,
              fit: BoxFit.cover,
              image: File(itemlist['img'][idx].toString()).existsSync()
                  ? FileImage(File(itemlist['img'][idx].toString()))
                  : AssetImage("assets/default.png") as ImageProvider,
            ),
          ),
          alignment: Alignment.center,
          child: isHoveredList[idx]
              ? Text(
                  itemlist['name'][idx],
                  style: TextStyle(
                    color: fc.Colors.white,
                    fontSize: 8,
                  ),
                  textAlign: TextAlign.center,
                )
              : Text(''),
        ),
        onTap: () {
          if (idx != itemlist.values.elementAt(0).length - 1) {
            _launch(itemlist['link'][idx].toString());
          } else {
            restartApp();
          }
        },
      ),
    );
  }

  
  void _launch(String path) async {
    //web URL
    if (path.startsWith('http://') || path.startsWith('https://')) {
      // ✅ 웹 URL 실행
      final Uri uri = Uri.parse(path);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint("Could not launch URL: $path - Error: $e");
      }
    }

    //programs
    else if (path.endsWith('.exe') ||
        path.endsWith('.bat') ||
        path.endsWith('.cmd')) {
      // ✅ (.EXE .bat, .cmd) 실행
      try {
        ProcessResult result = await Process.run(
          'powershell',
          ['-Command', 'Start-Process', '"$path"'],
          runInShell: true,
        );

        if (result.exitCode != 0) {
          debugPrint("Execution failed: ${result.stderr}");
        } else {
          debugPrint("Execution started: ${result.stdout}");
        }
      } catch (e) {
        debugPrint("Could not launch EXE/BAT/CMD: $path - Error: $e");
      }
    } else if (Directory(path).existsSync()) {
      // ✅ 폴더 경로 실행 (탐색기에서 열기)
      try {
        await Process.run('explorer', [path], runInShell: true);
      } catch (e) {
        debugPrint("Could not open folder: $path - Error: $e");
      }
    } else {
      debugPrint("Unsupported path: $path");
    }
  }
}
