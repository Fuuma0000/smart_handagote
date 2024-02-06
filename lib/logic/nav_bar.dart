import 'dart:developer';

import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:smart_handagote/view/history_page.dart';
import 'package:smart_handagote/view/home_page.dart';
import 'package:smart_handagote/view/setting_page.dart';

import '../constant.dart';

class NavBar extends StatefulWidget {
  final String userID;

  const NavBar({super.key, required this.userID});

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
      SettingPage(
        myID: widget.userID,
      ),
      // const UserManagementPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Center(
          child: Text(
            'KOTE Alert',
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              fontFamily: 'Quicksand',
            ),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
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
              color: Theme.of(context).colorScheme.primary,
              showLabel: false,
              notchColor: Theme.of(context).colorScheme.primary,

              /// restart app if you change removeMargins
              removeMargins: false,
              bottomBarWidth: 500,
              durationInMilliSeconds: 300,
              bottomBarItems: [
                BottomBarItem(
                  inActiveItem: Icon(
                    Icons.history,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  activeItem: Icon(
                    Icons.history,
                    color: Constant.yellow,
                  ),
                  itemLabel: 'Page 1',
                ),
                BottomBarItem(
                  inActiveItem: Icon(
                    Icons.home_filled,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  activeItem: Icon(
                    Icons.home_filled,
                    color: Constant.yellow,
                  ),
                  itemLabel: 'Page 2',
                ),
                BottomBarItem(
                  inActiveItem: Icon(
                    Icons.settings,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  activeItem: Icon(
                    Icons.settings,
                    color: Constant.yellow,
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
