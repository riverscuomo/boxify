import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:boxify/app_core.dart';

class NavCubit extends Cubit<int> {
  //NavCubit(int initialIndex) 
  //  : super(initialIndex); // Initial index if want to set advanced and basic differently 
  
  NavCubit() : super(0); // Initial index set to 0 (home) for all app types

  void updateIndex(int newIndex) {
    emit(newIndex); // This updates the current state of the navigation index
  }
}

List<BottomNavigationBarItem> bottomNavigationBarItemAdvanced(
    BuildContext context) {
  return <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      label: 'home'.translate(), // Use .translate() here
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.shopping_cart_outlined),
      label: 'market'.translate(), // Use .translate() here
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.search_outlined),
      label: 'search'.translate(), // Use .translate() here
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.radio_outlined),
      label: 'yourLibrary'.translate(), // Use .translate() here
    ),
  ];
}

List<BottomNavigationBarItem> bottomNavigationBarItemBasic(
    BuildContext context) {
  return <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      label: 'home'.translate(), // Use .translate() here
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.search_outlined),
      label: 'search'.translate(), // Use .translate() here
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.radio_outlined),
      label: 'yourLibrary'.translate(), // Use .translate() here
    ),
  ];
}



// class NavCubit extends Cubit<int> {
//   NavCubit()
//       : super(Core.app.type == AppType.advanced
//             ? bottomNavigationBarItemAdvanced.length - 1
//             : bottomNavigationBarItemBasic.length -
//                 1); // The initial index is for 'Library'

//   void updateIndex(int newIndex) {
//     emit(newIndex); // This updates the current state of the navigation index
//   }
// }

// var bottomNavigationBarItemAdvanced = <BottomNavigationBarItem>[
//   BottomNavigationBarItem(
//     icon: Icon(Icons.home_outlined),
//     label: 'home'.translate(),
//   ),
//   BottomNavigationBarItem(
//     icon: Icon(Icons.shopping_cart_outlined),
//     // Label also changes depending on the AppType
//     label: 'market'.translate(),
//   ),

//   /// Search
//   BottomNavigationBarItem(
//     icon: Icon(Icons.search_outlined),
//     label: 'search'.translate(),
//   ),
//   BottomNavigationBarItem(
//     icon: Icon(Icons.radio_outlined),
//     label: 'yourLibrary'.translate(),
//   ),
// ];

// var bottomNavigationBarItemBasic = <BottomNavigationBarItem>[
//   BottomNavigationBarItem(
//     icon: Icon(Icons.home_outlined),
//     // Label also changes depending on the AppType
//     label: 'home'.translate(),
//   ),

//   /// Search
//   BottomNavigationBarItem(
//     icon: Icon(Icons.search_outlined),
//     label: 'search'.translate(),
//   ),
//   BottomNavigationBarItem(
//     icon: Icon(Icons.radio_outlined),
//     label: 'yourLibrary'.translate(),
//   ),
// ];
