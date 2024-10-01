// ------------------------------------------------------------------------------------
// Contacts Page ----------------------------------------------------------------------
// ------------------------------------------------------------------------------------ 
//import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
// Main import
import './main.dart';

class Profile {
  final String username; 
  final String displayname;
  final String profpic;

  const Profile(this.username, this.displayname, this.profpic);
  
  // Map<String, Object?> toMap() {
  //   return {
  //     "username": username,
  //     "displayname": displayname,
  //     "profpic": profpic,
  //   };
  // }
}

class ContactsPage extends StatefulWidget {
  @override
  State<ContactsPage> createState() => _ContactsPageState();
}
class _ContactsPageState extends State<ContactsPage> {
  bool pending = false;
  var searchfilter = "";
  var searchresults = [];
  var current_contacts = [];

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    Future<void> pullRefresh() async {
      await Future.delayed(Duration(seconds: 1));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
    }

    Future<List> fetchContacts() async {
      final http.Response response;
      response = await http.get(
        Uri.parse('${appState.SERVER}/users/${appState.userData["username"]}/contacts'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'App-Token': appState.APPTOKEN,
          //HttpHeaders.authorizationHeader: appState.APPTOKEN,
          'User-Token': appState.userData["token"].toString()
        },

      );
      if (response.statusCode == 200) {
        var contacts = jsonDecode(response.body);
        var contact_list = [];
        current_contacts = [];
        for (var contact in contacts) {
          current_contacts.add(contact["username"]);
          contact_list.add(Profile(contact["username"], contact["displayname"], contact["profpic"]));
        }
        return contact_list;
      }
      else {
        throw Exception("Server down");
      }
    }

    Future newContact(username, displayname) async {
      pending = true;
      final http.Response response;
      await Future.delayed(const Duration(seconds: 1));
      response = await http.post(
        Uri.parse('${appState.SERVER}/users/${appState.userData["username"]}/contacts'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'App-Token': appState.APPTOKEN,
          //HttpHeaders.authorizationHeader: appState.APPTOKEN,
          'User-Token': appState.userData["token"].toString()
        },
        body: jsonEncode(<String, dynamic>{
            "username": username,
            "displayname": displayname
        }),
      );
      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        if (res == "#VERIFIED#") {
          setState(() {});
        }
        else {
          print("something went wrong. ");
        }
      } 
      else {
        throw Exception("Server down");
      }
      pending = false;
    }

    Future removeContact(username) async {
      pending = true;
      final http.Response response;
      await Future.delayed(const Duration(seconds: 1));
      response = await http.delete(
        Uri.parse('${appState.SERVER}/users/${appState.userData["username"]}/contacts/$username'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'App-Token': appState.APPTOKEN,
          //HttpHeaders.authorizationHeader: appState.APPTOKEN,
          'User-Token': appState.userData["token"].toString()
        },
      );
      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        if (res == "#VERIFIED#") {
          if (context.mounted) {
            setState(() {});
          }
        }
        else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Something went wrong. Please refresh the page and try again. ")));
          }
        }
      } 
      else {
        throw Exception("Server down");
      }
      pending = false;
    }

    Future<void> searchProfiles(filter) async {
      if (filter == "") {
        filter = "null";
      }
      final http.Response response;
      response = await http.get(
        Uri.parse('${appState.SERVER}/search/$filter'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'App-Token': appState.APPTOKEN,
          //HttpHeaders.authorizationHeader: appState.APPTOKEN,
          'User-Token': appState.userData["token"].toString()
        },

      );
      if (response.statusCode == 200) {
        var profiles = jsonDecode(response.body);
        searchresults = [];
        for (var profile in profiles) {
          searchresults.add(Profile(profile["username"], profile["displayname"], profile["profpic"]));
        }
      } 
      else {
        throw Exception("Server down");
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: 
        SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text("Find people: ", style: TextStyle(fontSize: 23),),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SearchAnchor(
                  isFullScreen: false,
                  viewOnChanged: (value) {
                    searchfilter = value;
                  },
                  viewConstraints: BoxConstraints(
                    minHeight: 200,
                    minWidth: 200,
                    maxWidth: 1500
                  ),
                  builder: (BuildContext context, SearchController controller) {
                    return SearchBar(
                      controller: controller,
                      leading: Icon(Icons.search),
                      hintText: "Search users",
                      padding: const WidgetStatePropertyAll<EdgeInsets>(
                          EdgeInsets.symmetric(horizontal: 16.0)),
                      onTap: () {
                        controller.openView();
                      },
                    );
                  }, 
                  suggestionsBuilder: (BuildContext context, SearchController controller) async {
                    await searchProfiles(searchfilter);
                    return List<Widget>.generate(searchresults.length, (int idx) {
                      if (searchresults.isEmpty) {
                        print("loading...");
                        return CircularProgressIndicator(color: Colors.white);
                      }
                      else {
                        if (searchresults[idx].username == appState.userData["username"]) {
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.deepOrange,
                                foregroundImage: MemoryImage(base64Decode(searchresults[idx].profpic as String)),
                              ),
                              title: Text(searchresults[idx].displayname),
                              subtitle: Text(searchresults[idx].username),
                            );
                        }
                        if (current_contacts.contains(searchresults[idx].username)) {
                          return ListTile(
                            leading: GestureDetector(
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey,
                                foregroundImage: MemoryImage(base64Decode(searchresults[idx].profpic as String)),
                              ),
                              onTap: () {
                                var selected_image = Image(image: MemoryImage(base64Decode(searchresults[idx].profpic as String)) );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => MediaDisplay(display_image: selected_image))
                                );
                              },
                            ),
                            title: Text(searchresults[idx].displayname),
                            subtitle: Text(searchresults[idx].username),
                          );
                        }
                        else {
                          return ListTile(
                            leading: GestureDetector(
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.deepOrange,
                                foregroundImage: MemoryImage(base64Decode(searchresults[idx].profpic as String)),
                              ),
                              onTap: () {
                                var selected_image = Image(image: MemoryImage(base64Decode(searchresults[idx].profpic as String)) );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => MediaDisplay(display_image: selected_image))
                                );
                              },
                            ),
                            title: Text(searchresults[idx].displayname),
                            subtitle: Text(searchresults[idx].username),
                            trailing: IconButton(
                              icon: Icon(Icons.person_add),
                              onPressed: () {
                                newContact(searchresults[idx].username, searchresults[idx].displayname);
                              },
                            ),
                          );
                        }
                      }
                    });
                  }
                ),
              ),
              Text("Contacts: ", style: TextStyle(fontSize: 23)),
              SizedBox(
                height: 330,
                child: FutureBuilder<List>(
                  future: fetchContacts(),
                  builder: (context, data) {
                    List<Widget> children;
                    if (data.hasData) {
                      data.data!.isEmpty ? children = <Widget>[ Center(child: Text("No contacts yet")) ] :
                      children = <Widget>[
                        for (var contact in data.data!)
                          Card.filled(
                            child: ListTile(
                              leading: GestureDetector(
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey,
                                  foregroundImage: MemoryImage(base64Decode(contact.profpic as String)),
                                ),
                                onTap: () {
                                  var selected_image = Image(image: MemoryImage(base64Decode(contact.profpic as String)) );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => MediaDisplay(display_image: selected_image))
                                  );
                                },
                              ),
                              title: Text(contact.displayname),
                              subtitle: Text(contact.username),
                              trailing: PopupMenuButton<int>( 
                                icon: Icon(Icons.more_vert),
                                onSelected: (value) { 
                                  if (value == 0) { 
                                    removeContact(contact.username);
                                  } 
                                  else {
                                    print("index exceeded menu length");
                                  }
                                }, 
                                itemBuilder: (BuildContext context) { 
                                  return <PopupMenuEntry<int>>[ 
                                    PopupMenuItem<int>( 
                                      value: 0, 
                                      child: Row(children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        Text("Remove Contact", style: TextStyle(color: Colors.red))
                                      ]),  
                                    )
                                  ]; 
                                }, 
                              ), 
                            ),
                          ),
                      ];
                    }
                    else if (data.hasError) {
                      children = <Widget>[
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text('${data.error}'),
                        ),
                      ];
                    }
                    else {
                      children = <Widget>[
                        Center(
                          child: Column(children: [
                            Text("Loading Contacts...", style: TextStyle(fontSize: 20),),
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(color: const Color.fromARGB(255, 15, 70, 110),),
                            ),
                          ],),
                        )
                      ];
                    }
                    return RefreshIndicator(
                      onRefresh: pullRefresh,
                      child: ListView(
                        children: [
                          SizedBox(width: 20.0, height: 20.0),
                          Column(
                            children: children,
                          )
                        ],
                      ),
                    );
                  }
                ),
              ),
            ],
          ),
        ),
    );

  }
}

class MediaDisplay extends StatefulWidget {
  const MediaDisplay({super.key, required this.display_image});
  final Image display_image;

  @override
  State<MediaDisplay> createState() => _MediaDisplayState();
}
class _MediaDisplayState extends State<MediaDisplay> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar (
        backgroundColor: Color.fromARGB(49, 130, 130, 130),
        elevation: 0.0,
        leading: IconButton(
          icon: Icon(Icons.close),
          color: Colors.white,
          onPressed: () {
            Navigator.of(context).pop();
          }
        ),
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: widget.display_image,
      ),
    );

  }
}