import 'dart:async';

import 'package:flutter/material.dart';
import 'package:native_pdf_renderer/native_pdf_renderer.dart';
import 'package:native_pdf_renderer_example/has_support.dart';

void main() => runApp(ExampleApp());

class ExampleApp extends StatefulWidget {
  @override
  _ExampleAppState createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  Future<PDFDocument> _getDocument() async {
    if (await hasSupport()) {
      return PDFDocument.openAsset('assets/sample.pdf');
    } else {
      throw Exception(
        'PDF Rendering does not '
        'support on the system of this version',
      );
    }
  }

  bool cropped = false;
  Future<PDFDocument> pdfFuture;

  @override
  void initState() {
    super.initState();

    pdfFuture = _getDocument();
  }

  @override
  Widget build(BuildContext context) {
    final storage = PagesStorage();

    return MaterialApp(
      title: 'PDF View example',
      color: Colors.white,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Native PDF Renderer Example'),
          actions: <Widget>[IconButton(icon: Icon(Icons.crop), onPressed: () {
            setState(() {
              cropped = !cropped;
            });
          },)],
        ),
        body: FutureBuilder(
          future: pdfFuture,
          builder: (context, AsyncSnapshot<PDFDocument> snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(snapshot.error.toString()),
              );
            }

            return PageView(
              children: <Widget>[
                ImageLoader(
                  storage: storage,
                  document: snapshot.data,
                  pageNumber: 1,
                  cropped: cropped,
                ),
                ImageLoader(
                  storage: storage,
                  document: snapshot.data,
                  pageNumber: 2,
                  cropped: cropped,
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: BottomAppBar(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Swipe to right',
                  style: Theme.of(context).textTheme.title,
                ),
                Icon(Icons.keyboard_arrow_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PagesStorage {
  final Map<int, PDFPageImage> pages = {};
}

class ImageLoader extends StatelessWidget {
  ImageLoader({
    @required this.storage,
    @required this.document,
    @required this.pageNumber,
    @required this.cropped,
    Key key,
  }) : super(key: key);

  final PagesStorage storage;
  final PDFDocument document;
  final int pageNumber;
  final bool cropped;

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: _renderPage(),
        builder: (context, AsyncSnapshot<PDFPageImage> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error'),
            );
          }
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          return Image(
            image: MemoryImage(snapshot.data.bytes),
          );
        },
      );

  Future<PDFPageImage> _renderPage() async {
    if (storage.pages.containsKey(pageNumber)) {
      return storage.pages[pageNumber];
    }
    final page = await document.getPage(pageNumber);
    // final cropRect = cropped ? Rect.fromLTWH(0, 0, w / 2, h / 2) : null;
    final pageImage = await page.render(
      width: cropped ? page.width ~/ 2 : page.width,
      height: cropped ? page.height ~/ 2 : page.height,
      scale: 2,
      format: PDFPageFormat.JPEG,
      backgroundColor: '#ffffff',
    );
    await page.close();
    storage.pages[pageNumber] = pageImage;
    return pageImage;
  }
}
