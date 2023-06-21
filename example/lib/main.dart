import 'dart:io';
import 'dart:ui' as ui;
// for checking whether running on Web or not
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:pdf_render/pdf_render.dart';

import 'package:pdf_render/pdf_render_image.dart';

void main(List<String> args) => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final controller = PdfViewerController();

  List<ui.Image> images = [];

  @override
  void initState() {
    PdfImageViewer.returnFileFromUrl(
            url:
                "http://lib.sseu.ru/sites/default/files/2017/01/primery_oformleniya_ssylok_v_dissertacii_gost_r_7.0.5-2008_bibliogr.ssylka_0.pdf")
        .then(
      (value) {
        addPhotos(value);
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  addPhotos(File value) async {
    images.addAll(await PdfImageViewer.returnListOfImages(value));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    print(images.length);
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: ValueListenableBuilder<Matrix4>(
              valueListenable: controller,
              builder: (context, _, child) =>
                  Text(controller.isReady ? 'Page #${controller.currentPageNumber}' : 'Page -')),
        ),
        backgroundColor: Colors.grey.shade300,
        body: images.isNotEmpty
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

                  maxScale: 3.0,
                  // scrollDirection: Axis.horizontal,
                ),
                images: images,
              )
            : const Center(child: CircularProgressIndicator()),
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
