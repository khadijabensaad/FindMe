import 'package:find_me/Core/Drawer_Items_Pages/category_products.dart';
import 'package:find_me/Models/category_model.dart';
import 'package:find_me/Services/category_api.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CategoriesPage extends StatelessWidget {
  final CategoryApiCall _categoryApiCall = CategoryApiCall();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDF1E1),
      appBar: AppBar(
        title: Text("Categories",style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: Colors.black,
                fontSize: 18)),
                centerTitle: true,
                backgroundColor: Color(0xFFFDF1E1)
      ),
    body: SafeArea(child:
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 10),
        child: FutureBuilder<List<CategoryModel>>(
          future: _categoryApiCall.getAllcategories(),
          builder:(context, snapshot) {
            if(snapshot.hasData){
              return ListView.separated(
                itemBuilder:(context, index) => InkWell(
                  onTap: () {
                    
                    Navigator.push(context, CupertinoPageRoute(builder:(context) => CategoryProducts(id: "${snapshot.data?[index].id}")));
                  },
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    height: 70,
                    width: MediaQuery.of(context).size.width * 0.8,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black, // Set the border color here
                        width: 1, // Set the border width here
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromARGB(255, 248, 228, 201)
                              .withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 3,
                          offset: const Offset(0, 0),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(right:8.0, top: 5, bottom: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                          '${snapshot.data?[index].name}',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,color: Color(0xFF965D1A)),
                          textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    )),
                ),
               separatorBuilder:(context, index) => SizedBox(height:10),
                itemCount: snapshot.data!.length
                );
            }
            else{
              return const  Center(
                child: CircularProgressIndicator(color: Color(0xFF965D1A),), // Display loading indicator
              );
            }
          },
          ),
      )
    ),
    );
  }
}