import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Page Imports
import './loginpage.dart';
import './chatspage.dart';
import './contactspage.dart';
import 'accountpage.dart';
// Database import
import 'utilities/dbinterface.dart';


void main() {
  runApp(Hotline());
}

class Hotline extends StatelessWidget {
  const Hotline({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: "Hotline",
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color.fromARGB(255, 50, 50, 50),
            outline: Colors.black,
            primary: Color.fromARGB(255, 80, 80, 80),
            onPrimary: Colors.white,
            primaryContainer: Color.fromARGB(255, 50, 50, 50),
            surfaceContainerLow: Color.fromARGB(255, 50, 50, 50),
            onSurface: Colors.white,
            secondaryContainer: Colors.grey,
            brightness: Brightness.dark
          ),
        ),
        home: HomePage(),
      ),
    );
  }
}


// ------------------------------------------------------------------------------------
// App State --------------------------------------------------------------------------
// ------------------------------------------------------------------------------------ 
class AppState extends ChangeNotifier {
  DatabaseHandler db = DatabaseHandler();
  final SERVER = "http://172.66.4.8:9000";
  final APPTOKEN = "ZQM.FS(^f!|WeKA&paZ5].*+u[>efN#s~Z~du98)0:OnVX@),cdRJG1(x|zVn3tC*/EC,)Rj,q,G)<A=U-P[[<i]tY3fTnvxdCC5~J0e#hOlafCG";
  bool loggedIn = false;
  bool publicAcct = false;
  bool approvedContacts = false;
  var userData = {
    "username": "",
    "displayname": "",
    "password": "",
    "token": "",
  };
  var page = 0;

  Future<bool> loadData() async {
    await Future.delayed(const Duration(seconds: 1));
    final data = await db.readUserData();
    loggedIn = data.loggedin;
    publicAcct = data.publicacct;
    userData["username"] = data.username as String;
    userData["displayname"] = data.displayname as String;
    userData["password"] = data.password as String;
    userData["token"] = data.token as String;

    return loggedIn;
  }

  Future<void> persistData() async {
    UserData pushdata = UserData(userData["username"], userData["displayname"], userData["password"], userData["token"], loggedIn, publicAcct, approvedContacts);
    db.writeUserData(pushdata);
  }

  Page(index) {
    page = index;
    notifyListeners();
  }

  setPassword(new_pass) {
    userData["password"] = new_pass;
    persistData();
    notifyListeners();
  }

  setDisplay(new_displayname) {
    userData["displayname"] = new_displayname;
    persistData();
    notifyListeners();
  }

  setPrivacySettings(ispublic, approvedcontacts) {
    publicAcct = ispublic;
    approvedContacts = approvedcontacts;
    persistData();
    notifyListeners();
  }

  Login(userprofile) {
    Future.delayed(Duration(milliseconds: 1000), () {
      loggedIn = true;
      publicAcct = userprofile["public"];
      approvedContacts = userprofile["approvedcontacts"];
      userData["username"] = userprofile["username"];
      userData["displayname"] = userprofile["displayname"];
      userData["password"] = userprofile["password"];
      userData["token"] = userprofile["token"];
      persistData();
      notifyListeners();
    });
  }
  
  Logout(delay) {
    Future.delayed(Duration(milliseconds: delay), () {
      loggedIn = false;
      notifyListeners();
      userData["username"] = "";
      userData["password"] = "";
      userData["token"] = "";
      publicAcct = false;
      approvedContacts = false;
      persistData();
      Page(0);
    });
  }
}

// ------------------------------------------------------------------------------------
// Home Page --------------------------------------------------------------------------
// ------------------------------------------------------------------------------------ 
class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    //bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom != 0.0;

    void navbarPressed(int index) {
      setState(() {
        appState.page = index;
      });
    }

    Widget page;
      switch (appState.page) {
        case 0:
          page = ChatsPage();
        case 1:
          page = ContactsPage();
        case 2:
          page = AccountPage();
        default:
          throw UnimplementedError('Error: No page at ${appState.page}');
    }

    return FutureBuilder<bool> ( 
      future: appState.loadData(),
      builder: (context, data) {
        Widget main;
        if (data.hasData) {
          if (appState.loggedIn == true) {
            main = Scaffold(
              // App header with title
              resizeToAvoidBottomInset: false,
              appBar: AppBar (
                backgroundColor: Colors.black,
                title: SafeArea(
                  child: const Text(
                    "Hotline",
                    style: TextStyle(color: Colors.white, fontFamily: "Monospace", fontSize: 40),
                  ),
                ),
              ),
              body: Column(
                children: [
                  // Container for main window
                  Expanded(
                    flex: 9,
                    child: Container(
                      color: Theme.of(context).colorScheme.primary,
                      child: page,
                    ),
                  ),
                  // Container for menu bar
                  Expanded(
                    flex: 1,
                    child: BottomNavigationBar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      showSelectedLabels: false,
                      showUnselectedLabels: false,
                      items: const <BottomNavigationBarItem>[
                        BottomNavigationBarItem(
                          icon: Icon(Icons.question_answer),
                          label: 'Chats',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.contacts),
                          label: 'Contacts',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.account_circle),
                          label: 'Manage Account',
                        ),
                      ],
                      currentIndex: appState.page,
                      selectedItemColor: Colors.deepOrange,
                      onTap: navbarPressed,
                    ),
                  ),
                ],
              ),
            ); 
          }
          else {
            main = LogIn();
          }
        }
        else if (data.hasError) {
          main = Column(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('${data.error}'),
              ),
            ],
          );
        }
        else {
          main = Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Starting...", style: TextStyle(fontSize: 20)),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(color: const Color.fromARGB(255, 15, 70, 110),),
                  ),
                ],
              ),
            ),
          );
        }
        return 
          main;
      }
    );

  }
}

