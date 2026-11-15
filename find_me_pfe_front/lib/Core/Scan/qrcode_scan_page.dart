import 'package:find_me/Core/Scan/load_afterScan.dart';
import 'package:find_me/Core/Search/product_detail.dart';
import 'package:find_me/Core/Search/product_not_found.dart';
import 'package:find_me/Core/Search/search_fail.dart';
import 'package:find_me/Models/product_model.dart';
import 'package:find_me/Services/product_api.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  String? scanResult;
  ProductApiCall _productApiCall = ProductApiCall();
   //Future<ProductModel>? _prod ;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDF1E1),
      appBar: AppBar(
        title: Text("QR Code Scanner",style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.black,fontSize: 18),),
        centerTitle: true,
        backgroundColor: Color(0xFFFDF1E1),
        leading: IconButton(onPressed: (){ Navigator.pop(context);}, icon: const Icon(CupertinoIcons.back,color: Colors.black,)),
      ),
      body: SafeArea(
        
        child: Center(
          child: Column(
            
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40,),
              Image.asset("assets/images/scanQr.png",height: 300,),
              SizedBox(height: 30,),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Search Products using\n',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        height: 0,
                      ),
                    ),
                    TextSpan(
                      text: ' QR Code.',
                      style: TextStyle(
                        color: Color(0xFFEFBC73),
                        fontSize: 22,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        height: 0,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20,),
              SizedBox(
                  width: 250,
                  height: 45,
                  child: CupertinoButton(
                    color: const Color(0xFFDF9A4F),
                    onPressed: () {
                      scanBarCode();
                      /*Navigator.push(
                          context,
                          CupertinoPageRoute(
                              builder: ((context) => const BarCodeScan())));*/
                    },
                    child: const Text(
                      "Start Scan",
                      style: TextStyle(
                        color: Color(0xFF965D1A),
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        )),
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
    //_prod = _productApiCall.getProductByBarCode(scanResult) ;
    
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
