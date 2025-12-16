// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package

import 'package:file/local.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FilePickerDemo extends StatefulWidget {
  const FilePickerDemo({super.key});

  @override
  State<FilePickerDemo> createState() => _FilePickerDemoState();
}

class _FilePickerDemoState extends State<FilePickerDemo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _defaultFileNameController = TextEditingController();
  final _dialogTitleController = TextEditingController();
  final _initialDirectoryController = TextEditingController();
  final _fileExtensionController = TextEditingController();
  String? _extension;
  bool _isLoading = false;
  bool _lockParentWindow = false;
  bool _userAborted = false;
  bool _multiPick = false;
  FileType _pickingType = FileType.any;
  List<PlatformFile>? pickedFiles;
  String? _selectedPdfName;
  bool _isAnalyzingPdf = false;
  Map<String, String> _labResults = <String, String>{};
  Widget _resultsWidget = const Row(
    children: [
      Expanded(
        child: Center(
          child: SizedBox(
            width: 300,
            child: ListTile(
              leading: Icon(
                Icons.error_outline,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 40.0),
              title: Text('No action taken yet'),
              subtitle: Text(
                'Please use on one of the buttons above to get started',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    _fileExtensionController
        .addListener(() => _extension = _fileExtensionController.text);
  }

  Widget _buildFilePickerResultsWidget({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.50,
      child: ListView.separated(
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        separatorBuilder: (BuildContext context, int index) => const Divider(),
      ),
    );
  }

  void _pickFiles() async {
    bool hasUserAborted = true;
    _resetState();

    try {
      pickedFiles = (await FilePicker.platform.pickFiles(
        type: _pickingType,
        allowMultiple: _multiPick,
        onFileLoading: (FilePickerStatus status) => setState(() {
          _isLoading = status == FilePickerStatus.picking;
        }),
        allowedExtensions: (_extension?.isNotEmpty ?? false)
            ? _extension?.replaceAll(' ', '').split(',')
            : null,
        dialogTitle: _dialogTitleController.text,
        initialDirectory: _initialDirectoryController.text,
        lockParentWindow: _lockParentWindow,
        withData: true,
      ))
          ?.files;
      hasUserAborted = pickedFiles == null;
    } on PlatformException catch (e) {
      _logException('Unsupported operation: $e');
    } catch (e) {
      _logException(e.toString());
    }
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _userAborted = hasUserAborted;
      _resultsWidget = _buildFilePickerResultsWidget(
        itemCount: pickedFiles?.length ?? 0,
        itemBuilder: (BuildContext context, int index) {
          final path =
              pickedFiles!.map((e) => e.path).toList()[index].toString();
          return ListTile(
            leading: Text(
              index.toString(),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            title: Text("File path:"),
            subtitle: Text(path),
          );
        },
      );
    });
  }

  void _pickFileAndDirectoryPaths() async {
    List<String>? pickedFilesAndDirectories;
    bool hasUserAborted = true;
    _resetState();

    try {
      pickedFilesAndDirectories =
          await FilePicker.platform.pickFileAndDirectoryPaths(
        type: _pickingType,
        allowedExtensions: (_extension?.isNotEmpty ?? false)
            ? _extension?.replaceAll(' ', '').split(',')
            : null,
        initialDirectory: _initialDirectoryController.text,
      );
      hasUserAborted = pickedFilesAndDirectories == null;
    } on PlatformException catch (e) {
      _logException('Unsupported operation: $e');
    } catch (e) {
      _logException(e.toString());
    }
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _userAborted = hasUserAborted;
      _resultsWidget = _buildFilePickerResultsWidget(
        itemCount: pickedFilesAndDirectories?.length ?? 0,
        itemBuilder: (BuildContext context, int index) {
          String name = 'File path:';
          if (!kIsWeb) {
            final fs = LocalFileSystem();
            name = fs.isFileSync(pickedFilesAndDirectories![index])
                ? 'File path:'
                : 'Directory path:';
          }
          return ListTile(
            leading: Text(
              index.toString(),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            title: Text(name),
            subtitle: Text(pickedFilesAndDirectories![index]),
          );
        },
      );
    });
  }

  void _clearCachedFiles() async {
    _resetState();
    try {
      bool? result = await FilePicker.platform.clearTemporaryFiles();
      _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            (result!
                ? 'Temporary files removed with success.'
                : 'Failed to clean temporary files'),
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      );
    } on PlatformException catch (e) {
      _logException('Unsupported operation: $e');
    } catch (e) {
      _logException(e.toString());
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _selectFolder() async {
    String? pickedDirectoryPath;
    bool hasUserAborted = true;
    _resetState();

    try {
      pickedDirectoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: _dialogTitleController.text,
        initialDirectory: _initialDirectoryController.text,
        lockParentWindow: _lockParentWindow,
      );
      hasUserAborted = pickedDirectoryPath == null;
    } on PlatformException catch (e) {
      _logException('Unsupported operation: $e');
    } catch (e) {
      _logException(e.toString());
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _userAborted = hasUserAborted;
      _resultsWidget = _buildFilePickerResultsWidget(
        itemCount: pickedDirectoryPath != null ? 1 : 0,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: const Text('Directory path:'),
            subtitle: Text(pickedDirectoryPath ?? ''),
          );
        },
      );
    });
  }

  Future<void> _saveFile() async {
    String? pickedSaveFilePath;
    bool hasUserAborted = true;
    _resetState();

    try {
      pickedSaveFilePath = await FilePicker.platform.saveFile(
        allowedExtensions: (_extension?.isNotEmpty ?? false)
            ? _extension?.replaceAll(' ', '').split(',')
            : null,
        type: FileType.custom,
        dialogTitle: _dialogTitleController.text,
        fileName: _defaultFileNameController.text,
        initialDirectory: _initialDirectoryController.text,
        lockParentWindow: _lockParentWindow,
        bytes: pickedFiles?.first.bytes,
      );
      hasUserAborted = pickedSaveFilePath == null;
    } on PlatformException catch (e) {
      _logException('Unsupported operation: $e');
    } catch (e) {
      _logException(e.toString());
    }
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _userAborted = hasUserAborted;
      _resultsWidget = _buildFilePickerResultsWidget(
        itemCount: pickedSaveFilePath != null ? 1 : 0,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: const Text('Save file path:'),
            subtitle: Text(pickedSaveFilePath ?? ''),
          );
        },
      );
    });
  }

  void _logException(String message) {
    printInDebug(message);
    _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _resetState() {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _userAborted = false;
    });
  }

  Future<void> _pickPdf() async {
    setState(() {
      _isAnalyzingPdf = false;
      _selectedPdfName = null;
      _labResults = <String, String>{};
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        allowMultiple: false,
        onFileLoading: (FilePickerStatus status) => setState(() {
          _isLoading = status == FilePickerStatus.picking;
        }),
        dialogTitle: _dialogTitleController.text.isNotEmpty
            ? _dialogTitleController.text
            : 'PDF seçin',
        initialDirectory: _initialDirectoryController.text.isNotEmpty
            ? _initialDirectoryController.text
            : null,
        lockParentWindow: _lockParentWindow,
        withData: true,
      );

      if (!mounted) return;

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isLoading = false;
          _userAborted = true;
        });
        return;
      }

      final file = result.files.single;
      setState(() {
        _selectedPdfName = file.name;
        _isLoading = false;
        _userAborted = false;
        _isAnalyzingPdf = true;
      });

      final parsed = await _parsePdf(result.files.single.bytes);

      if (!mounted) return;
      setState(() {
        _isAnalyzingPdf = false;
        _labResults = parsed;
      });
    } on PlatformException catch (e) {
      _logException('Unsupported operation: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _logException(e.toString());
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, String>> _parsePdf(Uint8List? bytes) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return <String, String>{
      'D Vitamini (25-OH)': '22 ng/mL',
      'B12 Vitamini': '310 pg/mL',
      'Ferritin': '45 ng/mL',
      'HbA1c': '5.4 %',
      'CRP': '0.6 mg/L',
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.deepPurple,
        ),
      ),
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('Tahlil'),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Text(
                  'Tahlil Yükle',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _pickPdf,
                    icon: const Icon(Icons.add, size: 22),
                    label: const Text(
                      'PDF YÜKLE',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.deepPurple, width: 2),
                      foregroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Analiz Sonucu',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_userAborted)
                  const Text('Seçim iptal edildi.')
                else if (_selectedPdfName == null)
                  const Text('Henüz dosya seçilmedi.')
                else if (_isAnalyzingPdf)
                  const Text('Yüklediğiniz tahlil dosyası analiz ediliyor...')
                else ...[
                  Text('Yüklenen dosya: \n$_selectedPdfName'),
                  const SizedBox(height: 12),
                  if (_labResults.isNotEmpty)
                    _LabResultsList(results: _labResults),
                  if (_labResults.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RecommendationsPage(results: _labResults),
                            ),
                          );
                        },
                        child: const Text('Önerileri Gör'),
                      ),
                    ),
                  ]
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void printInDebug(Object object) => debugPrint(object.toString());
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0, right: 8.0),
            child: Icon(Icons.circle, size: 8),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabResultsList extends StatelessWidget {
  final Map<String, String> results;

  const _LabResultsList({required this.results});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 16),
      itemBuilder: (context, index) {
        final key = results.keys.elementAt(index);
        final value = results[key]!;
        return Row(
          children: [
            Expanded(
              child: Text(key, style: const TextStyle(fontSize: 16)),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        );
      },
    );
  }
}

class RecommendationsPage extends StatelessWidget {
  const RecommendationsPage({super.key, required this.results});

  final Map<String, String> results;

  double? _extractFirstNumber(String value) {
    final numberMatch = RegExp(r"[-+]?[0-9]*[\.,]?[0-9]+").firstMatch(value);
    if (numberMatch == null) return null;
    final raw = numberMatch.group(0)!.replaceAll(',', '.');
    return double.tryParse(raw);
  }

  List<String> _buildRecommendations(Map<String, String> r) {
    final List<String> recs = [];

    // D Vitamini (25-OH)
    final dKey = r.keys.firstWhere(
      (k) => k.toLowerCase().contains('d vitamini'),
      orElse: () => '',
    );
    if (dKey.isNotEmpty) {
      final v = _extractFirstNumber(r[dKey]!);
      if (v != null && v < 30) {
        recs.add('D vitamini düşük. Güneş ışığına düzenli çıkmayı ihmal etmeyin; hekiminize danışarak takviye düşünebilirsiniz.');
      }
    }

    // Ferritin
    final fKey = r.keys.firstWhere(
      (k) => k.toLowerCase().contains('ferritin'),
      orElse: () => '',
    );
    if (fKey.isNotEmpty) {
      final v = _extractFirstNumber(r[fKey]!);
      if (v != null && v < 30) {
        recs.add('Ferritin düşük olabilir. Kırmızı et, baklagil ve C vitamini ile demir emilimini destekleyin.');
      }
    }

    // B12
    final b12Key = r.keys.firstWhere(
      (k) => k.toLowerCase().contains('b12'),
      orElse: () => '',
    );
    if (b12Key.isNotEmpty) {
      final v = _extractFirstNumber(r[b12Key]!);
      if (v != null && v < 200) {
        recs.add('B12 vitamini düşük olabilir. Hayvansal gıdaları artırmayı ve hekiminize danışarak takviye alımını değerlendirin.');
      }
    }

    // HbA1c
    final a1cKey = r.keys.firstWhere(
      (k) => k.toLowerCase().contains('hba1c'),
      orElse: () => '',
    );
    if (a1cKey.isNotEmpty) {
      final v = _extractFirstNumber(r[a1cKey]!);
      if (v != null && v >= 5.7 && v < 6.5) {
        recs.add('HbA1c sınırda/yüksek. Rafine şeker ve un tüketimini azaltın, günlük hareketinizi artırın.');
      } else if (v != null && v >= 6.5) {
        recs.add('HbA1c yüksek. Bir hekime başvurarak detaylı değerlendirme yaptırın.');
      }
    }

    // CRP
    final crpKey = r.keys.firstWhere(
      (k) => k.toLowerCase().contains('crp'),
      orElse: () => '',
    );
    if (crpKey.isNotEmpty) {
      final v = _extractFirstNumber(r[crpKey]!);
      if (v != null && v > 5) {
        recs.add('CRP yüksek. Enfeksiyon veya inflamasyon açısından tıbbi değerlendirme önerilir.');
      }
    }

    if (recs.isEmpty) {
      recs.add('Genel olarak dengeli beslenme, düzenli egzersiz ve yeterli uykuya devam edin.');
    }

    return recs;
  }

  @override
  Widget build(BuildContext context) {
    final recs = _buildRecommendations(results);
    return Scaffold(
      appBar: AppBar(title: const Text('Öneriler')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ListView(
          children: [
            const SizedBox(height: 24),
            const Text('Yaşam Tarzı Önerileri',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const Text('Size Öneriler:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final item in recs) _Bullet(text: item),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
