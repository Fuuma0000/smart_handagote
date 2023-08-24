import 'dart:developer';

import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:smart_handagote/view/history_page.dart';
import 'package:smart_handagote/view/home_page.dart';
import 'package:smart_handagote/view/setting_page.dart';

import '../constant.dart';
import '../view/test_update_role_page.dart';

class NavBar extends StatefulWidget {
  String userID;

  NavBar({super.key, required this.userID});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  List<Widget> bottomBarPages = [];

  /// Controller to handle PageView and also handles initial page
  final _pageController = PageController(initialPage: 1);

  /// Controller to handle bottom nav bar and also handles initial page
  final _controller = NotchBottomBarController(index: 1);

  int maxCount = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    /// widget list
    bottomBarPages = [
      HistoryPage(
        myID: widget.userID,
      ),
      HomePage(myID: widget.userID),
      const SettingPage(),
      // const UserManagementPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'KOTE Alert',
            style: TextStyle(color: Constant.lightGray),
          ),
        ),
        backgroundColor: Constant.darkGray,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
            bottomBarPages.length, (index) => bottomBarPages[index]),
      ),
      extendBody: true,
      bottomNavigationBar: (bottomBarPages.length <= maxCount)
          ? AnimatedNotchBottomBar(
              /// Provide NotchBottomBarController
              notchBottomBarController: _controller,
              color: Constant.darkGray,
              showLabel: false,
              notchColor: Constant.darkGray,

              /// restart app if you change removeMargins
              removeMargins: false,
              bottomBarWidth: 500,
              durationInMilliSeconds: 300,
              bottomBarItems: const [
                BottomBarItem(
                  inActiveItem: Icon(
                    Icons.history,
                    color: Constant.lightGray,
                  ),
                  activeItem: Icon(
                    Icons.history,
                    color: Constant.lightGray,
                  ),
                  itemLabel: 'Page 1',
                ),
                BottomBarItem(
                  inActiveItem: Icon(
                    Icons.home_filled,
                    color: Constant.lightGray,
                  ),
                  activeItem: Icon(
                    Icons.home_filled,
                    color: Constant.lightGray,
                  ),
                  itemLabel: 'Page 2',
                ),
                BottomBarItem(
                  inActiveItem: Icon(
                    Icons.settings,
                    color: Constant.lightGray,
                  ),
                  activeItem: Icon(
                    Icons.settings,
                    color: Constant.lightGray,
                  ),
                  itemLabel: 'Page 3',
                ),
              ],
              onTap: (index) {
                /// perform action on tab change and to update pages you can update pages without pages
                log('current selected index $index');
                _pageController.jumpToPage(index);
              },
            )
          : null,
    );
  }
}

class Page1 extends StatelessWidget {
  const Page1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Constant.black, child: const Center(child: Text('Page 1')));
  }
}

class Page2 extends StatelessWidget {
  const Page2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Constant.black, child: const Center(child: Text('Page 2')));
  }
}

class Page3 extends StatelessWidget {
  const Page3({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Constant.black, child: const Center(child: Text('Page 3')));
  }
}
