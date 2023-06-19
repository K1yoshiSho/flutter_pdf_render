import 'dart:io';

// for checking whether running on Web or not
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:pdf_render/pdf_render.dart';
import 'package:pdf_render/pdf_render_widgets.dart';

void main(List<String> args) => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final controller = PdfViewerController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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
          child: Platform.isAndroid
              // Networking sample using flutter_cache_manager
              ? PdfViewer.openFutureFile(
                  // Accepting function that returns Future<String> of PDF file path
                  () async =>
                      (await DefaultCacheManager().getSingleFile('https://oadk.at.ua/Richard_Dokinz_gen.pdf')).path,
                  viewerController: controller,
                  onError: (err) => print(err),
                  params: const PdfViewerParams(
                    padding: 10,
                    minScale: 1.0,
                    // scrollDirection: Axis.horizontal,
                  ),
                )
              : PdfViewer.openAsset(
                  'assets/hello.pdf',
                  viewerController: controller,
                  onError: (err) => print(err),
                  params: const PdfViewerParams(
                    padding: 10,
                    minScale: 1.0,
                    // scrollDirection: Axis.horizontal,
                  ),
                ),
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
