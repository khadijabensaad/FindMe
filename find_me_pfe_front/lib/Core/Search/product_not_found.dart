import 'package:find_me/Core/Scan/load_afterScan.dart';
import 'package:find_me/Core/Search/product_detail.dart';
import 'package:find_me/Core/Search/search_fail.dart';
import 'package:find_me/Models/product_model.dart';
import 'package:find_me/Services/product_api.dart';
import 'package:find_me/main_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class ProductNotFound extends StatefulWidget {
  const ProductNotFound({super.key, required this.barcode});
  final String barcode;



  @override
  State<ProductNotFound> createState() => _SearchState();
}

class _SearchState extends State<ProductNotFound> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
  String? scanResult;
  ProductApiCall _productApiCall = ProductApiCall();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDF1E1),
      appBar: AppBar(
        backgroundColor: Color(0xFFFDF1E1),
        title: Text("Error",style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.black),),
        centerTitle: true,
        leading: IconButton(onPressed: (){ Navigator.pop(context);}, icon: const Icon(CupertinoIcons.back,color: Colors.black,)),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: SizedBox(),flex: 1,),
                Image.asset("assets/images/404_error.png",width: 250,),
                SizedBox(height: 10,),
                Text("Oops, This product doesn't exist \nin the database",textAlign: TextAlign.center,
                  style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                        ),),
                        SizedBox(height: 50,),
                SizedBox(
                    width: 300,
                    height: 50,
                    child: CupertinoButton(
                      color: const Color(0xFFDF9A4F),
                      onPressed: () {
                        scanBarCode();
                      },
                      child: const Text(
                        "Scan Again",
                        style: TextStyle(
                          color: Color(0xFF965D1A),
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10,),
                  SizedBox(
                    width: 300,
                    height: 50,
                    child: CupertinoButton(
                      color: const Color(0xFFDF9A4F),
                      onPressed: () {
                        //scanBarCode();
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: ((context) => MainScreenPage())));
                      },
                      child: const Text(
                        "Return To Home Page",
                        style: TextStyle(
                          color: Color(0xFF965D1A),
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                Expanded(child: SizedBox(),flex: 3,),
              ],
            ),
          )
          /*Text(
            barcode == "-1" ? "Unable to read data": barcode
          ),*/
        ),
      ),
    );
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
    if(scanResult=='-1'){
    Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => SearchFail(barcode: scanResult),));
    }
    else{
      Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => LoadAfterScan()));
      fetchData(scanResult);
      
    }
  }

  Future<void> fetchData(String scanResult) async {
  try {
    Future<ProductModel>? productFuture = _productApiCall.getProductByBarCode(scanResult);
    ProductModel product = await productFuture;

    // Check if the barcode value is -1
    if (product.barcode == -1) {
      // Barcode value is -1
      print('Barcode value is -1');
      Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => ProductNotFound(barcode: scanResult)));
    }else{
      Navigator.pushReplacement(context,  CupertinoPageRoute(builder: (context) =>ProductDetail(identifier: scanResult)));
    }
  } catch (error) {
    print('$error');
    // Handle the error
  }
}
}