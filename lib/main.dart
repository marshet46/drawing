import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:permission_handler/permission_handler.dart';
void main() {
  runApp(DrawingApp());
}

class DrawingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drawing App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DrawingHomePage(),
    );
  }
}

class DrawingHomePage extends StatefulWidget {
  @override
  _DrawingHomePageState createState() => _DrawingHomePageState();
}

class _DrawingHomePageState extends State<DrawingHomePage> {
  List<Offset?> _points = <Offset?>[];
  Color _selectedColor = Colors.red;
  double _strokeWidth = 5.0;

  void _selectColor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select a color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Drawing App',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue, // Use a consistent color scheme
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.color_lens),
            onPressed: () => _selectColor(),
          ),
          IconButton(
            icon: Icon(
              Icons.clear,
              color: Colors.red,
            ),
            onPressed: () {
              if (_points.isNotEmpty) {
                setState(() {
                  _points.clear(); // Clear all points
                });
              }
            },
          ),
          IconButton(
            icon: Icon(
              Icons.save,
              color: Colors.red,
            ),
            onPressed: () {
              _captureDrawing(context);
            },
          ),
        ],
      ),
     body: RepaintBoundary(
  child: GestureDetector(
    onPanUpdate: (DragUpdateDetails details) {
      setState(() {
        RenderBox renderBox = context.findRenderObject() as RenderBox;
        Offset localPosition = renderBox.globalToLocal(details.globalPosition);
        _points.add(localPosition);
      });
    },
    onPanEnd: (DragEndDetails details) {
      _points.add(null);
    },
    child: CustomPaint(
      painter: DrawingPainter(
        points: _points,
        color: _selectedColor,
        strokeWidth: _strokeWidth,
      ),
      size: Size.infinite,
    ),
  ),
),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Container(
                height: 200,
                color: Colors.blue,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    const Text(
                      'Adjust Stroke Width',
                      style: TextStyle(color: Colors.white),
                    ),
                    Slider(
                      value: _strokeWidth,
                      min: 1.0,
                      max: 20.0,
                      onChanged: (value) {
                        setState(() {
                          _strokeWidth = value;
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: Icon(Icons.edit),
        backgroundColor: Colors.blue, // Use a consistent color scheme
      ),
    );
  }

Future<void> _captureDrawing(BuildContext context) async {
  try {
    // Request storage permission
    var status = await Permission.storage.request();
    if (status.isGranted) {
      RenderRepaintBoundary boundary =
          context.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      await ImageGallerySaver.saveImage(pngBytes);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Drawing saved to gallery!'),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Permission denied to save drawing!'),
      ));
    }
  } catch (e) {
    print('Error saving drawing: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Error saving drawing!'),
    ));
  }
}
}

class DrawingPainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;
  final double strokeWidth;

  DrawingPainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
