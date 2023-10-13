import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path_util;
import 'package:filesystem_picker/filesystem_picker.dart';

import 'common.dart';

class BackGroundImageDialog extends StatefulWidget {
  static Future<String?> navigatorPush(BuildContext context) async {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => const BackGroundImageDialog()));
  }

  const BackGroundImageDialog({Key? key}) : super(key: key);

  @override
  State<BackGroundImageDialog> createState() => _BackGroundImageDialogState();
}

class _BackGroundImageDialogState extends State<BackGroundImageDialog> {
  static const imageExtList = <String>['apng', 'avif', 'gif', 'jpg', 'jpeg', 'jfif', 'pjpeg', 'pjp', 'png', 'svg', 'webp', 'bmp', 'tif', 'tiff'];

  bool _isStarting = true;
  final _textControllerFolder  = TextEditingController();
  final _fileList = <String>[];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _starting();
    });
  }

  @override
  void dispose() {
    _textControllerFolder.dispose();
    super.dispose();
  }

  void _starting() async {
    if (_textControllerFolder.text.isEmpty) {
      _textControllerFolder.text = (await LocalStorage.getDownloadDir())??'';
    }

    await LocalStorage.checkPermission();

    await _refreshFileList(_textControllerFolder.text);

    setState(() {
      _isStarting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isStarting) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(TextConst.txtStarting),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(TextConst.txtBackGroundDialog),
      ),

      body: _body(),
    );
  }

  Widget _body() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: TextField(
            controller: _textControllerFolder,
            decoration: InputDecoration(
                filled: true,
                labelText: TextConst.txtImageFolder,
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(width: 3, color: Colors.blueGrey),
                  borderRadius: BorderRadius.circular(15),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(width: 3, color: Colors.blue),
                  borderRadius: BorderRadius.circular(15),
                ),
                suffixIcon: InkWell(
                  child: const Icon(Icons.folder),
                  onTap: () async {
                    final dir = Directory(_textControllerFolder.text);

                    final path = await FilesystemPicker.open(
                      title: TextConst.txtSelectImageFolder,
                      context: context,
                      rootDirectory: dir,
                      rootName: _textControllerFolder.text,
                      fsType: FilesystemType.folder,
                      pickText: TextConst.txtSelectFolder,
                      showGoUp: true,
                    );

                    if (path == null) return;

                    _textControllerFolder.text = path;
                    _refreshFileList(_textControllerFolder.text);
                    setState(() { });
                  },
                ),
            ),
            onChanged: ((_) {
              setState(() { });
            }),
          ),
        ),

        Expanded(
            child: ListView.builder(
              itemCount: _fileList.length,
              itemBuilder: (context, index) {
                final path = _fileList[index];
                final imgFile = File(path);

                return longPressMenu<String>(
                  context     : context,
                  child       : Image.file( imgFile ),
                  menuItemList: [
                    PopupMenuItem<String>(
                      child: Text(TextConst.txtSetBackgroundImage),
                    )
                  ],
                  onSelect: (_) {
                    Navigator.pop(context, path);
                  }
                );

              }
            )
        ),
      ],
    );
  }

  Future<void> _refreshFileList(String path) async {
    _fileList.clear();
    final fileList = Directory(path).listSync( recursive: false);

    for (var object in fileList) {
      if (object is File){
        final File file = object;
        final fileExt = path_util.extension(file.path).toLowerCase().substring(1);
        if (imageExtList.contains(fileExt)){
          _fileList.add(file.path);
        }
      }
    }

  }
}

class LocalStorage {
  static Future<String?> getRootDir() async {
    final dirList = await getExternalStorageDirectories();
    if (dirList == null || dirList.isEmpty) return null;

    for (var dir in dirList) {
      final path = dir.path;
      final pos = path.indexOf('Android/data');
      if (pos < 0) continue;

      final rootPath = path.substring(0, pos - 1);
      return rootPath;
    }

    return null;
  }

  static Future<String?> getDownloadDir() async {
    final rootDir = (await getRootDir())!;
    final downloadPath = path_util.join(rootDir, 'Download') ;

    final downloadDir = Directory(downloadPath);
    if (!await downloadDir.exists()) return null;

    return downloadPath;
  }

  static Future<bool> checkPermission() async {
    final status = await Permission.storage.request(); //status;
    if (status != PermissionStatus.granted) {
      final result = await Permission.storage.request();
      if (result != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }
}
