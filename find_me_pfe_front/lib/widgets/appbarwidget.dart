import 'package:find_me/Models/prod_filter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class AppBarWidget extends StatefulWidget implements PreferredSizeWidget {
  final Function(ProductFilter) onFilterSubmitted;
  const AppBarWidget({super.key, required this.title, required this.onFilterSubmitted});
  final String title;

  @override
  State<AppBarWidget> createState() => _AppBArWidgetState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _AppBArWidgetState extends State<AppBarWidget> {
  late ProductFilter _prodFilter;
  //bool showActions = title == 'Home' || title == 'Find Me';
  List<String> locataionList = ['Sousse', 'khezema', 'Sahloul', 'Kalaa Kebira', 'Akouda', 'Msaken'];
  List<String> sizeList = ['XXS', 'XS', 'S', 'M', 'L', 'XL', 'XXL'];
  List<String> colorList = [
    'All',
    'Black',
    'White',
    'Red',
    'Blue',
    'Light Blue',
    'Cream',
    'Pink',
    'Green',
    'Brown',
    'Grey',
    'Beige',
    'Yellow',
    'Orange',
    'Gold',
    'Silver',
    'Bronze',
  ];
  List<String> sortList = ['price', 'rating', 'name', 'brand'];
  String? _selectedColor = 'All';
  String? _selectedSort = 'rating';
  bool _setSortOrder = true;
  String _sortOrder = "desc";
  List<String> _pickedSizeList = [];
  String _pickedRegion = '';
  int _selectedRegionIndex = -1;
  List<bool> _isSelectedSize = [false, false, false, false, false, false, false];

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFFDF1E1),
      title: Text(
        widget.title, // Accessing title through widget property
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: Colors.black),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_alt_outlined),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: const Color(0xFFFDF1E1),
              builder: (BuildContext context) {
                return StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                  return SingleChildScrollView(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(
                                top: 20, bottom: 10, left: 20, right: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Filter your research :",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                      color: Color(0xFF965D1A)),
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                Text(
                                  "Size:", //"Location:"               khedma 9dima
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ), //khedma 9dima

                          /*ListView.builder(
                        itemCount: FiltersList.length,
                        itemBuilder: (BuildContext context, int index) {
                          return ListTile(
                            title: const Text(
                              "Filtrer votre recherche",
                              style: TextStyle(
                                color: Color(0xFF965D1A),
                                fontSize: 20,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              FiltersList[index],
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            leading: IconButton(
                              icon: Icon(Icons.add_location_alt),
                              onPressed: () {},
                            ),
                            onTap: () {
                              setState(() {
                                selectedCategory = FiltersList[index];
                              });
                              Navigator.pop(
                                  context); // Close the modal bottom sheet
                            },
                          );
                        },
                      ),*/
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /*SizedBox(
                                    height: 40,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 25),
                                      child: ElevatedButton.icon(
                                        
                                        onPressed: () {},
                                        icon: const Icon(
                                          Icons.add_location_alt,
                                          color: Color(0xFF965D1A),
                                        ),
                                        label: const Text(
                                          'Sousse',
                                          style: TextStyle(
                                              color: Color(0xFF965D1A),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              fontFamily: 'Poppins'),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),*/
                                    Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: SizedBox(
                                        height: 35, // Adjust the height as needed
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          
                                          itemCount: sizeList
                                              .length, //khedma 9dima locataionList.length
                                          shrinkWrap: true,
                                          separatorBuilder:
                                              (BuildContext context, int index) =>
                                                  const SizedBox(width: 8),
                                          itemBuilder:
                                              (BuildContext context, int index) {
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 0, vertical: 0),
                                              child: OutlinedButton(
                                                style: OutlinedButton.styleFrom(
                                                  backgroundColor:
                                                      _isSelectedSize[index] == true
                                                          ? Color(0xFF965D1A)
                                                          : Color(0xFFFDF1E1),
                                                  side: const BorderSide(
                                                      color: Color(0xFF965D1A)),
                                                ),
                                                onPressed: () {
                                                  setState(
                                                    () {
                                                      String val = sizeList[index];
                                                      print(val);
                                                      if (_pickedSizeList
                                                          .contains(val)) {
                                                        _pickedSizeList.remove(val);
                                                        _isSelectedSize[index] = false;
                                                        print(_pickedSizeList);
                                                      } else {
                                                        _pickedSizeList.add(val);
                                                        _isSelectedSize[index] = true;
                                                        print(_pickedSizeList);
                                                      }
                                                    },
                                                  );
                                                },
                                                child: Text(
                                                  sizeList[
                                                      index], //khedma 9dima locataionList[index]
                                                  style: TextStyle(
                                                    color:
                                                        _isSelectedSize[index] == true
                                                            ? Color(0xFFFDF1E1)
                                                            : Color(0xFF965D1A),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                              ],
                            ),
                            
                          ),
                          //
                          
                          
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 5, left: 20, bottom: 5),
                                child: Text("Region:",style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                ),
                                ),
                              ),
                              SizedBox(height: 10,),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 5, bottom: 5, right: 5),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                  padding: const EdgeInsets.all(0),
                                  child: SizedBox(
                                    height: 35, // Adjust the height as needed
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      
                                      itemCount: locataionList
                                          .length, //khedma 9dima locataionList.length
                                      shrinkWrap: true,
                                      separatorBuilder:
                                          (BuildContext context, int index) =>
                                              const SizedBox(width: 8),
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 0, vertical: 0),
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor:
                                                  _pickedRegion == locataionList[index]
                                                      ? Color(0xFF965D1A)
                                                      : Color(0xFFFDF1E1),
                                              side: const BorderSide(
                                                  color: Color(0xFF965D1A)),
                                            ),
                                            onPressed: () {
                                              setState(
                                                () {
                                                  /*_selectedRegionIndex == index;
                                                  _pickedRegion = locataionList[index];*/
                                                  if(_pickedRegion == locataionList[index]){
                                                    _selectedRegionIndex = -1;
                                                    _pickedRegion = '';
                                                  }else{
                                                    _selectedRegionIndex == index;
                                                  _pickedRegion = locataionList[index];
                                                  }
                                                },
                                              );
                                            },
                                            child: Text(
                                              locataionList[
                                                  index], //khedma 9dima locataionList[index]
                                              style: TextStyle(
                                                color:
                                                    _pickedRegion == locataionList[index]
                                                        ? Color(0xFFFDF1E1)
                                                        : Color(0xFF965D1A),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                          const Divider(
                            color: Colors.grey,
                            thickness: 0.5,
                          ),
                          /*const SizedBox(
                            height: 5,
                          ),
                          const Divider(
                            color: Colors.grey,
                            thickness: 0.5,
                          ),*/
                          
                          Padding(
                            padding:
                                EdgeInsets.only(left: 20, top: 5, bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Colors:", //khedma 9dima "Distance radius:"
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(
                                  height: 15,
                                ),
                                SizedBox(
                                  width: 150,
                                  height: 57,
                                  child: DropdownButtonFormField<String>(
                                    menuMaxHeight: 250,
                                    decoration: InputDecoration(
                                      floatingLabelAlignment:
                                          FloatingLabelAlignment.start,
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.always,
                                      enabledBorder: OutlineInputBorder(
                                          gapPadding: 0,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              width: 1,
                                              color: Color(0xFF965D1A))),
                                      focusedBorder: OutlineInputBorder(
                                          gapPadding: 0,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              width: 1,
                                              color: Color(0xFF965D1A))),
                                    ),
                                    value: _selectedColor,
                                    items: colorList
                                        .map((item) => DropdownMenuItem<String>(
                                            value: item,
                                            child: Text(
                                              item,
                                              style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 12),
                                            )))
                                        .toList(),
                                    onChanged: (item) => {
                                      setState(() => _selectedColor = item),
                                    },
                                  ),
                                ),
                                SizedBox(
                                  height: 15,
                                ),
                                Text(
                                  "Sort By:", //khedma 9dima "Distance radius:"
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(
                                  height: 15,
                                ),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 150,
                                      height: 57,
                                      child: DropdownButtonFormField<String>(
                                        decoration: InputDecoration(
                                          floatingLabelAlignment:
                                              FloatingLabelAlignment.start,
                                          floatingLabelBehavior:
                                              FloatingLabelBehavior.always,
                                          enabledBorder: OutlineInputBorder(
                                              gapPadding: 0,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  width: 1,
                                                  color: Color(0xFF965D1A))),
                                          focusedBorder: OutlineInputBorder(
                                              gapPadding: 0,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  width: 1,
                                                  color: Color(0xFF965D1A))),
                                        ),
                                        value: _selectedSort,
                                        items: sortList
                                            .map((item) =>
                                                DropdownMenuItem<String>(
                                                    value: item,
                                                    child: Text(
                                                      item,
                                                      style: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 12),
                                                    )))
                                            .toList(),
                                        onChanged: (item) => {
                                          setState(() => _selectedSort = item),
                                        },
                                      ),
                                    ),
                                    SizedBox(
                                      width: 20,
                                    ),
                                    IconButton(
                                        onPressed: () {
                                          setState(
                                            () {
                                              _setSortOrder = !_setSortOrder;
                                              if (_setSortOrder == true)
                                                _sortOrder = "desc";
                                              else
                                                _sortOrder = "asc";
                                              print(_sortOrder);
                                            },
                                          );
                                        },
                                        icon: _setSortOrder
                                            ? Icon(CupertinoIcons.arrow_down)
                                            : Icon(CupertinoIcons.arrow_up)),
                                  ],
                                ),
                                SizedBox(height: 20,),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 200,
                                      height: 45,
                                      child: CupertinoButton(
                                        color: const Color(0xFFDF9A4F),
                                        onPressed: () {
                                            String filterColor;
                                            
                                            
                                          if (_selectedColor== 'All') {
                                              filterColor= '';
                                          }else{
                                            filterColor =_selectedColor.toString();
                                          }
                                          
                                          _prodFilter = ProductFilter(size: _pickedSizeList,colors: filterColor,sortBy: _selectedSort,sortOrder: _sortOrder, region: _pickedRegion);
                                          widget.onFilterSubmitted(_prodFilter);
                                          Navigator.of(context).pop();
                                          
                                          print("size: ${_prodFilter.size}");
                                          print(_prodFilter.colors);
                                          print(_prodFilter.sortBy);
                                          print(_prodFilter.sortOrder);
                                          print("region: ${_prodFilter.region}");
                                        },
                                        child: const Text(
                                          "Apply",
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
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                });
              },
            );
          },
        ),
      ],
    );
  }
}
