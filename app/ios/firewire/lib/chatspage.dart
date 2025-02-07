// ------------------------------------------------------------------------------------
// Chats Page -------------------------------------------------------------------------
// ------------------------------------------------------------------------------------ 
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
// Chatstream import
import './chatstream.dart';
import './settings/managechat.dart';
// Main import
import './main.dart';

enum ModeLabel {
  group('Group', true),
  dm('Direct Message', false);

  const ModeLabel(this.label, this.isgroup);
  final String label;
  final bool isgroup;
}

class NewChat extends StatefulWidget {
  const NewChat({super.key, required this.groups, required this.chats});
  final int groups;
  final int chats;

  @override
  State<NewChat> createState() => _NewChatState();
}
class _NewChatState extends State<NewChat> {
  final formKey = GlobalKey<FormState>();
  final nameField = TextEditingController();
  final userField = TextEditingController();

  bool pending = false;
  bool is_group = false;

  var chat_created = false;
  var chat_name = "";
  var curr_user = "";
  var chat_users = [];
  var current_label = "Chat type";

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    final TextEditingController modeController = TextEditingController();

    Future createChat(mode) async {
      pending = true;
      final http.Response response;
      if (!chat_users.contains(appState.userData["username"])) {
        chat_users.add(appState.userData["username"]);
      }
      await Future.delayed(const Duration(seconds: 1));
      if (mode == 0) {
        response = await http.post(
          Uri.parse('${appState.SERVER}/chatstreams/groups/${appState.userData["username"]}'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'App-Token': appState.APPTOKEN,
            //HttpHeaders.authorizationHeader: appState.APPTOKEN,
            'User-Token': appState.userData["token"].toString()
          },
          body: jsonEncode(<String, dynamic>{
            "name": chat_name,
            "users": chat_users
          }),
        );
      }
      else {
        response = await http.post(
          Uri.parse('${appState.SERVER}/chatstreams/dms/${appState.userData["username"]}'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'App-Token': appState.APPTOKEN,
            //HttpHeaders.authorizationHeader: appState.APPTOKEN,
            'User-Token': appState.userData["token"].toString()
          },
          body: jsonEncode(<String, dynamic>{
            "users": chat_users
          }),
        );
      }
      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        print(res);
        if (res == "#VERIFIED#") {
          print("Chat created");
          setState(() {
            chat_created = true;
          });
        }
        else {
          print("Invalid username found. Chat create request failed.");
          setState(() {
            chat_created = false;
          });
        }
      } 
      else {
        throw Exception("Server down");
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar (
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: SafeArea(child: Text(
          "New Chat: ",
          style: TextStyle(fontFamily: "Monospace", fontSize: 30, fontWeight: FontWeight.bold))
        ),
        leading: IconButton(
          icon: BackButtonIcon(),
          color: Colors.deepOrange,
          onPressed: () {
            if (pending == false) {
              Navigator.of(context).pop();
            }
          }, 
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Center(
                child: Column(
                  children: [
                    Card(child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(
                          width: 20,
                          height: 20,
                        ),
                        DropdownMenu<ModeLabel>(
                          initialSelection: ModeLabel.dm,
                          controller: modeController,
                          requestFocusOnTap: false,
                          label: Text(current_label),
                          onSelected: (ModeLabel? mode) {
                            setState(() {
                              current_label = mode!.label;
                              is_group = mode.isgroup;
                            });
                          },
                          dropdownMenuEntries: ModeLabel.values
                            .map<DropdownMenuEntry<ModeLabel>>( (ModeLabel mode) {
                            return DropdownMenuEntry<ModeLabel>(
                              value: mode,
                              label: mode.label,
                            );
                          }).toList(),
                        ),
                        Form(
                          key: formKey,
                          child: Column(children: [
                            is_group ? Column(
                              children: [
                                // Set New Chat Name _________________________________________________________________
                                ListTile(
                                  title: Text("Set a name for your new group: "),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: TextFormField(
                                    controller: nameField,
                                    decoration: InputDecoration(
                                                  hintText: 'Enter name',
                                                  contentPadding:
                                                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.all(Radius.circular(32.0)),
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderSide:
                                                        BorderSide(color: Colors.grey, width: 1.0),
                                                    borderRadius: BorderRadius.all(Radius.circular(32.0)),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderSide:
                                                        BorderSide(color: Colors.grey, width: 2.0),
                                                    borderRadius: BorderRadius.all(Radius.circular(32.0)),
                                                  ),
                                                ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'This field cannot be empty';
                                      }
                                      else {
                                        setState(() {
                                          chat_name = value;
                                        });
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ): Container(),
                              ListTile(
                                title: is_group ? Text("Add people to your new chat: "): Text("Enter recipient: "),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: ListTile(
                                  trailing: is_group ? IconButton(
                                              icon: Icon(Icons.add_circle),
                                              onPressed: () {
                                                if (formKey.currentState!.validate()) {
                                                  userField.clear();
                                                  setState(() {
                                                    chat_users.add(curr_user);
                                                  });
                                                }
                                              },
                                            ) : Text("   "),
                                  title: TextFormField(
                                    controller: userField,
                                    decoration: InputDecoration(
                                                  hintText: is_group ? "Enter users": "Enter user",
                                                  contentPadding:
                                                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.all(Radius.circular(32.0)),
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderSide:
                                                        BorderSide(color: Colors.grey, width: 1.0),
                                                    borderRadius: BorderRadius.all(Radius.circular(32.0)),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderSide:
                                                        BorderSide(color: Colors.grey, width: 2.0),
                                                    borderRadius: BorderRadius.all(Radius.circular(32.0)),
                                                  ),
                                                ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'This field cannot be empty';
                                      }
                                      else {
                                        setState(() {
                                          curr_user = value;
                                          if (is_group == false) {
                                            chat_users.add(curr_user);
                                          }
                                        });
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                              is_group ? Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Card(
                                        color: Theme.of(context).colorScheme.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Column(
                                            children: [
                                              Text("Users:", style: TextStyle(fontWeight: FontWeight.bold),),
                                              for (var user in chat_users)
                                                Card(
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Text(user),
                                                  )
                                                )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ) : Container(),
                              Card(
                                color: Color.fromARGB(255, 140, 45, 20),
                                clipBehavior: Clip.hardEdge,
                                child: InkWell(
                                  splashColor: Colors.deepOrange,
                                  child: Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: Row(children: [
                                      Icon(Icons.add_comment),
                                      SizedBox(width: 20, height: 15,),
                                      Text("Create Chat", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                    ],),
                                  ),
                                  onTap: () {
                                    if (is_group == false) {
                                      if (formKey.currentState!.validate()) {
                                        nameField.clear();
                                        userField.clear();
                                        if (chat_users.length > 2) {
                                          print("ERROR: More than two users in a direct message. ");
                                        }
                                        if (widget.chats < 50) {
                                          createChat(1);
                                          Future.delayed(Duration(milliseconds: 2000), () {
                                            if (chat_created == true) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Chat created")));
                                              }
                                            }
                                            else {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text("Invalid user found. Please ensure that all usernames are valid and try again")));
                                              }
                                            }
                                            setState(() {
                                              chat_users.clear();
                                            });
                                            pending = false;
                                          });
                                        }
                                        else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Direct Message limit reached. ")));
                                        }
                                      }
                                    }
                                    else if (chat_name != "" && chat_users.isNotEmpty) { 
                                      nameField.clear();
                                      userField.clear();
                                      if (chat_users.length > 100) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("User limit exceeded. You must have no more than 100 users. ")));
                                      }
                                      if (widget.groups < 20) {
                                        createChat(0);
                                        Future.delayed(Duration(milliseconds: 2000), () {
                                          if (chat_created == true) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Chat created")));
                                            }
                                          }
                                          else {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Invalid user found. Please ensure that all usernames are valid and try again")));
                                            }
                                          }
                                          setState(() {
                                            chat_users.clear();
                                          });
                                          pending = false;
                                        });
                                      }
                                      else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Group Chat limit reached. ")));
                                      }
                                    }
                                    else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Please complete the form before creating chat. ")));
                                    }
                                  },
                                ),
                              ),
                          ],)
                        )
                      ],
                    )),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ChatsPage extends StatefulWidget {
  @override
  State<ChatsPage> createState() => _ChatsPageState();

}
class _ChatsPageState extends State<ChatsPage> {
  bool loaded = false;
  var groups = 0;
  var chats = 0;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    Future<void> pullRefresh() async {
      await Future.delayed(Duration(seconds: 1));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
    }

    void refresh() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
    }

    Future<List> updateChats(mode) async {
      final http.Response response;
      if (mode == 0) {
        response = await http.get(
          Uri.parse('${appState.SERVER}/users/${appState.userData["username"]}/groups'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'App-Token': appState.APPTOKEN,
            //HttpHeaders.authorizationHeader: appState.APPTOKEN,
            'User-Token': appState.userData["token"].toString()
          },
  
        );
      }
      else {
        response = await http.get(
          Uri.parse('${appState.SERVER}/users/${appState.userData["username"]}/dms'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'App-Token': appState.APPTOKEN,
            //HttpHeaders.authorizationHeader: appState.APPTOKEN,
            'User-Token': appState.userData["token"].toString()
          },
        );
      }
      if (response.statusCode == 200) {
        var chats = jsonDecode(response.body);
        return chats;
      } 
      else {
        throw Exception("Server down");
      }
    }

    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        appBar: AppBar (
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          title: Text("Chats"),
          bottom: TabBar.secondary(
            indicatorWeight: 5.0,
            indicatorPadding: EdgeInsets.all(3),
            tabs: <Widget>[
              Tab(
                text: "Groups",
              ),
              Tab(
                text: "Direct Messages",
              )
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () { 
            if (loaded) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NewChat(groups: groups, chats: chats))
              );
            }
            else {
              print("Button disabled");
            }
          },
          foregroundColor: Colors.white,
          backgroundColor: Color.fromARGB(255, 140, 45, 20),
          shape: CircleBorder(),
          child: const Icon(Icons.add),
        ),
        body: TabBarView(
          children: <Widget>[
            FutureBuilder<List>(
              future: updateChats(0),
              builder: (context, data) {
                List<Widget> children;
                if (data.hasData) {
                  List chatstreams = data.data!;
                  for (var i=0; i<chatstreams.length; i++) {
                    groups += 1;
                  }
                  loaded = true;
                  data.data!.isEmpty ? children = <Widget>[ Center(child: Text("No groups yet")) ] :
                  children = <Widget>[
                    for (var chat in data.data!)
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: ListTile(
                              title: Text(chat["name"]),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image(image: MemoryImage(base64Decode("${chat["picture"]}"))),
                              ),
                              trailing: Icon(Icons.chevron_right),
                              onTap: () {
                                Chat target;
                                Image picture = Image(image: MemoryImage(base64Decode("${chat["picture"]}")));
                                if (chat["admins"].contains(appState.userData["username"])) {
                                  target = Chat(chat["id"], true, picture , chat["name"], true, chat["selfdestruct"], chat["admins"], chat["users"]);
                                }
                                else {
                                  target = Chat(chat["id"], true, picture, chat["name"], false, chat["selfdestruct"], chat["admins"], chat["users"]);
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ChatStream(chat: target, RefreshChats: refresh))
                                );
                              },
                            ),
                          ),
                          Divider(
                            thickness: 0.5,
                            indent: 10,
                            endIndent: 10,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ],
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
                        Text("Loading Chats...", style: TextStyle(fontSize: 20),),
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
            FutureBuilder<List>(
              future: updateChats(1),
              builder: (context, data) {
                List<Widget> children;
                if (data.hasData) {
                  List chatstreams = data.data!;
                  for (var i=0; i<chatstreams.length; i++) {
                    chats += 1;
                  }
                  loaded = true;
                  data.data!.isEmpty ? children = <Widget>[ Center(child: Text("No direct messages yet")) ] :
                  children = <Widget>[
                    for (var chat in data.data!)
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: ListTile(
                              title: Text(chat["name"]),
                              leading: CircleAvatar(
                                radius: 35,
                                backgroundColor: Colors.grey,
                                foregroundImage: MemoryImage(base64Decode("${chat["picture"]}")),
                              ),
                              trailing: Icon(Icons.chevron_right),
                              onTap: () {
                                Chat target;
                                Image picture = Image(image: MemoryImage(base64Decode("${chat["picture"]}")));
                                if (chat["admins"].contains(appState.userData["username"])) {
                                  target = Chat(chat["id"], false, picture, chat["name"], true, chat["selfdestruct"], chat["admins"], chat["users"]);
                                }
                                else {
                                  target = Chat(chat["id"], false, picture, chat["name"], false, chat["selfdestruct"], chat["admins"], chat["users"]);
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ChatStream(chat: target, RefreshChats: refresh,))
                                );
                              },
                            ),
                          ),
                          Divider(
                            thickness: 0.5,
                            indent: 10,
                            endIndent: 10,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ],
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
                        Text("Loading Chats...", style: TextStyle(fontSize: 20),),
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
          ],
        ),
      ),
    );
  }
}