import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
// for checking whether running on Web or not
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:pdf_render/pdf_render.dart';

import 'package:pdf_render/pdf_render_image.dart';

void main(List<String> args) => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final controller = PdfViewerController();
  TapDownDetails? _doubleTapDetails;
  List<ui.Image> images = [];
  File? file;

  @override
  void initState() {
    confertPdfToImages(
            "http://lib.sseu.ru/sites/default/files/2017/01/primery_oformleniya_ssylok_v_dissertacii_gost_r_7.0.5-2008_bibliogr.ssylka_0.pdf")
        .then(
      (value) {
        addToList(value);
        setState(() {});
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<File> confertPdfToImages(String url) async {
    Directory tempDir = await getApplicationDocumentsDirectory();
    dynamic response = await Dio().get(
      url,
      onReceiveProgress: null,
      options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) {
            if (status != null) {
              return status < 500;
            } else {
              return false;
            }
          }),
    );
    file = File("${tempDir.path}/temp.pdf");
    var raf = file!.openSync(mode: FileMode.write);
    raf.writeFromSync(response.data);
    return file!;
  }

  void addToList(File file) async {
    PdfDocument doc = await PdfDocument.openFile(file.path);

    for (int i = 1; i <= doc.pageCount; i++) {
      PdfPage page = await doc.getPage(i);
      PdfPageImage pageImage = await page.render();
      ui.Image image = await pageImage.createImageIfNotAvailable();
      images.add(image);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: ValueListenableBuilder<Matrix4>(
              // The controller is compatible with ValueListenable<Matrix4> and you can receive notifications on scrolling and zooming of the view.
              valueListenable: controller,
              builder: (context, _, child) =>
                  Text(controller.isReady ? 'Page #${controller.currentPageNumber}' : 'Page -')),
        ),
        backgroundColor: Colors.grey.shade300,
        body: GestureDetector(
          // Supporting double-tap gesture on the viewer.
          onDoubleTapDown: (details) => _doubleTapDetails = details,
          onDoubleTap: () {
            if (controller.zoomRatio < 5) {
              controller.ready?.setZoomRatio(
                zoomRatio: controller.zoomRatio * 2,
                center: _doubleTapDetails!.localPosition,
              );
            } else {
              controller.ready?.setZoomRatio(
                zoomRatio: 1,
                center: _doubleTapDetails!.localPosition,
              );
            }
          },
          child: images.isNotEmpty
              // Networking sample using flutter_cache_manager
              ? PdfImageViewer.openFutureFile(
                  // Accepting function that returns Future<String> of PDF file path
                  () async => (await DefaultCacheManager().getSingleFile(
                          'http://lib.sseu.ru/sites/default/files/2017/01/primery_oformleniya_ssylok_v_dissertacii_gost_r_7.0.5-2008_bibliogr.ssylka_0.pdf'))
                      .path,
                  viewerController: controller,
                  onError: (err) => print(err),
                  params: const PdfViewerParams(
                    padding: 10,
                    minScale: 1.0,
                    // scrollDirection: Axis.horizontal,
                  ),
                  images: images,
                )
              : const Center(child: CircularProgressIndicator()),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            FloatingActionButton(
              child: const Icon(Icons.first_page),
              onPressed: () => controller.ready?.goToPage(pageNumber: 1),
            ),
            const SizedBox(height: 10),
            FloatingActionButton(
              child: const Icon(Icons.last_page),
              onPressed: () => controller.ready?.goToPage(pageNumber: controller.pageCount),
            ),
            const SizedBox(height: 10),
            FloatingActionButton(
              child: const Icon(Icons.bug_report),
              onPressed: () => rendererTest(),
            ),
          ],
        ),
      ),
    );
  }

  /// Just testing internal rendering logic
  Future<void> rendererTest() async {
    final PdfDocument doc;
    if (Platform.isAndroid) {
      final file = (await DefaultCacheManager().getSingleFile('https://oadk.at.ua/Richard_Dokinz_gen.pdf')).path;
      doc = await PdfDocument.openFile(file);
    } else {
      doc = await PdfDocument.openAsset('assets/hello.pdf');
    }

    try {
      final page = await doc.getPage(1);
      final image = await page.render();
      print('${image.width}x${image.height}: ${image.pixels.lengthInBytes} bytes.');
    } finally {
      doc.dispose();
    }
  }
}
