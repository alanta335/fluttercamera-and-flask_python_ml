import 'dart:io';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:multipart_request/multipart_request.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'API.dart';
import 'dart:convert';
import 'package:camera/camera.dart';
Future<void> main() async {// Pass the appropriate camera to the TakePictureScreen widget.
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.elementAt(1);
  runApp(MyApp(
    // Pass the appropriate camera to the TakePictureScreen widget.
    camera: firstCamera,
  ));
  }

class MyApp extends StatefulWidget {
  final CameraDescription camera;

  const MyApp({
    Key key,
    @required this.camera,
  }) : super(key: key);
  @override
  _MyAppState createState() => _MyAppState();
}
class _MyAppState extends State<MyApp> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;
  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.max,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }
  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
          body: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              // If the Future is complete, display the preview.
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      FlatButton(
                        child: Text("Pick an image"),
                        onPressed: () async {
                                    // Take the Picture in a try / catch block. If anything goes wrong,
                                      // Ensure that the camera is initialized.
                                      await _initializeControllerFuture;

                                      // Construct the path where the image should be saved using the
                                      // pattern package.
                                      final path = join(
                                        // Store the picture in the temp directory.
                                        // Find the temp directory using the `path_provider` plugin.
                                        (await getTemporaryDirectory()).path,
                                        '${DateTime.now()}.png',
                                      );
                                      // Attempt to take a picture and log where it's been saved.
                                      await _controller.takePicture(path);
                                      // If the picture was taken, display it on a new screen.
                              Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DisplayPictureScreen(imagePath: path),
                              ),
                            );
                        },
                      ),
                    ],
                  ),
                );
            } else {
              // Otherwise, display a loading indicator.
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}
uploadImageToServer(File imageFile)async
  {
    print("attempting to connecto server......");
    var stream = new http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
      var length = await imageFile.length();
      print(length);
    var uri = Uri.parse('http://replica-alpha.herokuapp.com/predict');
    print("connection established.");
    var request = new http.MultipartRequest("POST", uri);
      var multipartFile = new http.MultipartFile('file', stream, length,
          filename: basename(imageFile.path));
          //contentType: new MediaType('image', 'png'));

      request.files.add(multipartFile);
      var response = await request.send();
      print(response.statusCode);
  }

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  const DisplayPictureScreen({Key key, this.imagePath}) : super(key: key);
  @override
  _DisplayPictureScreen createState() => _DisplayPictureScreen();
}

class _DisplayPictureScreen extends State<DisplayPictureScreen> {
  File img_Path ;
  var Data;
  String QueryText = 'Query';
  String url = "http://replica-alpha.herokuapp.com/predict";
  String imagePath;
  @override
  void initState() {
    imagePath = widget.imagePath;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    img_Path = File(imagePath);
    return Scaffold(
      appBar: AppBar(title: Text('next question')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FlatButton(
                        child: Text("Call multipart request"),
                        onPressed: () {
                          uploadImageToServer(img_Path);
                        },
                      ),
              FlatButton(
                child: Text("get result"),
                onPressed: () async {
                    Data = await Getdata(url);
                    var DecodedData = jsonDecode(Data);
                    setState(() {
                    QueryText = DecodedData['Query'];
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  QueryText,
                  style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
      ),
    );
  }
}