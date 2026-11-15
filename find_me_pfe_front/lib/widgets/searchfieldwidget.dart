import 'dart:io';
import 'package:find_me/Core/Scan/qrcode_scan_page.dart';
import 'package:find_me/Core/Search/search_fail.dart';
import 'package:find_me/Core/Search/search_products.dart';
import 'package:find_me/voice_search.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class SearchFieldWidget extends StatefulWidget {
  final TextEditingController cntrl;
  const SearchFieldWidget({super.key, required this.cntrl});

  @override
  State<SearchFieldWidget> createState() => _SearchFieldWidgetState();
}

class _SearchFieldWidgetState extends State<SearchFieldWidget> {

  Uint8List? _image; //allows to convert to various image format
  File? selectedImage; //Xfile fih file type w size path
  String? scanResult;
  

  


  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.cntrl,
      cursorColor: const Color(0xFFDF9A4F),
      style:
          const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
      textAlignVertical: TextAlignVertical.top,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
        // labelText: "Search",
        hintText: "Search product",
        prefixIcon: /*IconButton(
          icon: const Icon(
            CupertinoIcons.search,
            size: 25,
            color: Color.fromARGB(255, 97, 84, 72),
          ),
          splashRadius: 10,
          onPressed: () {
           /* Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: ((context) => SearchFakeProducts())));*/
          },
        ),*/
        Icon(CupertinoIcons.search,size: 25,color: Color.fromARGB(255, 97, 84, 72)),
        suffixIcon:  Row( // Wrap icons in a Row
      mainAxisSize: MainAxisSize.min, // Minimize the row size
      children: [
        IconButton(
          icon: const Icon(
            Icons.qr_code_scanner_rounded,
            size: 23,
            color: Color.fromARGB(255, 97, 84, 72),
          ),
          splashRadius: 10,
          onPressed: () {
            //scanBarCode();
            Navigator.push(context,
                CupertinoPageRoute(builder: ((context) => QRScanPage())));
          },
        ),
        IconButton(
          icon: const Icon(
            Icons.mic_outlined,
            size: 23,
            color: Color.fromARGB(255, 97, 84, 72),
          ),
          splashRadius: 10,
          onPressed: () {
            Navigator.push(context, CupertinoPageRoute(builder: (context) => const VoiceSearch(),));
            //showImagePickerOption(context);
            setState(() {});
          },
        ),
      ],
    ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFDF9A4F), width: 2),
            gapPadding: 10),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFDF9A4F), width: 2),
            gapPadding: 10),
      ),
      onChanged: (value) {
        setState(() {});
      },
      onTap: () {
        setState(() {});
      },
    );
  }

  void showImagePickerOption(BuildContext context) {
    showModalBottomSheet(
        backgroundColor: const Color(0xFFFDF1E1),
        context: context,
        builder: (builder) {
          return SizedBox(
            height: 90,
            width: double.infinity,
            child: Column(
              children: [
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 0),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          PermissionStatus camerStatus =
                              await Permission.camera.request();

                          if (camerStatus == PermissionStatus.granted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Permission Granted"),
                              ),
                            );
                          }
                          if (camerStatus == PermissionStatus.denied) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content:
                                  Text("You need to provide camera permission"),
                            ));
                          }
                          if (camerStatus ==
                              PermissionStatus.permanentlyDenied) {
                            openAppSettings();
                          }
                          _pickImageFromCamera(); //camera
                        },
                        icon: const Icon(
                          CupertinoIcons.camera_fill,
                          color: Color(0xFF965D1A),
                        ),
                        label: const Text(
                          'Camera',
                          style: TextStyle(
                              color: Color(0xFF965D1A),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              fontFamily: 'Poppins'),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _pickImageFromGallery();
                        },
                        icon: const Icon(
                          CupertinoIcons.photo_fill_on_rectangle_fill,
                          color: Color(0xFF965D1A),
                        ),
                        label: const Text(
                          'Gallery',
                          style: TextStyle(
                              color: Color(0xFF965D1A),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              fontFamily: 'Poppins'),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        });
  }

  Future _pickImageFromGallery() async {
    final returnImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnImage == null) return;
    setState(() {
      selectedImage = File(returnImage.path);
      _image = File(returnImage.path).readAsBytesSync();
    });
    Navigator.of(context).pop();
  }

  Future _pickImageFromCamera() async {
    final returnImage =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (returnImage == null) return;
    setState(() {
      selectedImage = File(returnImage.path);
      _image = File(returnImage.path).readAsBytesSync();
    });
    Navigator.of(context).pop();
  }




  Future<void> scanBarCode() async {
    String scanResult;
    try {
      // Use the FlutterBarCodeScanner plugin to scan barcodes
      scanResult = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", //coul il khat mtaa
        "Cancel",
        true, // Display flash
        ScanMode.BARCODE,
      );
    } on PlatformException {
      scanResult = 'Failed to get platform version.';
    }
    //ensures that the setState call is only executed if the widget is still part of the widget maaneha il widget mtaa barcode not supp taamalaik update mich hiya supprime w taamalik update wa9itha erreur
    if (!mounted) return;
    setState(() => this.scanResult = scanResult);
    //nwalliw lenna na3mlou des if selon resultat mta3 scan
    Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => SearchFail(barcode: scanResult)));
  }

  
}
 /*  Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: Stack(
                children: [
                  CupertinoSearchTextField(
                      placeholder: "Search products",
                      placeholderStyle:
                          const TextStyle(fontSize: 16, color: Colors.grey),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Color(0xFF965D1A), width: 1.4),
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      suffixIcon:
                          const Icon(Icons.now_wallpaper, color: Colors.black),
                      suffixInsets: const EdgeInsets.only(right: 8.0),
                      suffixMode: OverlayVisibilityMode.always,
                    ),
                    Positioned(
                      child: IconButton(
                          onPressed: () {},
                          icon: const Icon(CupertinoIcons.mic_fill,
                              color: Colors.black)),
                      left: 230,
                      bottom: -5,
                    )
                  ],
                ),
              ),
            */


            