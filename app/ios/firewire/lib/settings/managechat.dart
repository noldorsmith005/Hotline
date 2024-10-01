// ------------------------------------------------------------------------------------
// Manage Chat Page -------------------------------------------------------------------
// ------------------------------------------------------------------------------------ 
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
// Main import
import '../main.dart';

class Chat {
  final int id;
  final bool group;
  Image picture;
  String name;
  bool admin;
  bool self_destructing;
  List<dynamic> admins;
  List<dynamic> users;

  Chat(this.id, this.group, this.picture, this.name, this.admin, this.self_destructing, this.admins, this.users);
}

class Menu extends StatefulWidget {
  const Menu({super.key, required this.chat, required this.RefreshChats});
  final Chat chat;
  final Function RefreshChats;

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  final nameformKey = GlobalKey<FormState>();
  final uformKey = GlobalKey<FormState>();
  final nameField = TextEditingController();
  final userformKey = GlobalKey<FormState>();
  final userField = TextEditingController();

  bool pending = false;
  bool show_nameupdate = false;

  var chat_name = "";
  var new_user = "";

  File? _file;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    Future modifyChat(new_pic, new_name, new_users, new_admins, self_destructing) async {
      pending = true;
      String image_data;
      if (new_pic == null) {
        image_data = "";
      }
      else {
        var image_bytes = await new_pic.readAsBytes();
        image_data = base64Encode(image_bytes);
      }
      final http.Response response;
      await Future.delayed(const Duration(seconds: 1));
      response = await http.patch(
        Uri.parse('${appState.SERVER}/chatstreams/groups/${widget.chat.id}/settings'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'App-Token': appState.APPTOKEN,
          //HttpHeaders.authorizationHeader: appState.APPTOKEN,
          'User-Token': appState.userData["token"].toString()
        },
        body: jsonEncode(<String, dynamic>{
          "newpic": image_data,
          "newname": new_name,
          "newusers": new_users,
          "newadmins": new_admins,
          "selfdestruct": self_destructing
        }),
      );
      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        if (res == "#VERIFIED#") {
          if (context.mounted) {
            setState(() {
              if (new_pic != null) {
                widget.chat.picture = Image.file(new_pic);
              }
              widget.chat.name = new_name;
              widget.chat.users = new_users;
              widget.chat.admins = new_admins;
              widget.chat.self_destructing = self_destructing;
            });
          }
        }
        else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Something went wrong. Ensure all usernames are valid and try again. ")));
          }
        }
      } 
      else {
        throw Exception("Server down");
      }
      pending = false;
    }

    Future<void> leaveAlert(user) async {
      return showDialog<void>(
        context: context,
        barrierDismissible: false, 
        builder: (BuildContext context) {
          return AlertDialog(
            content: const SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text("Are you sure you want to leave this group? "),
                  Text("This action cannot be undone. "),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                onPressed: () => Navigator.pop(context, 'Cancel'),
              ),
              TextButton(
                child: const Text("Leave", style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  widget.chat.users.remove(user);
                  widget.chat.admins.remove(user);
                  await modifyChat(null, widget.chat.name, widget.chat.users, widget.chat.admins, widget.chat.self_destructing);
                  if (context.mounted) {
                    Navigator.pop(context, 'Leave');
                    Navigator.of(context)..pop()..pop();
                  }
                  widget.RefreshChats.call();
                },
              ),
            ],
          );
        },
      );
    }

    Future deleteChat() async {
      pending = true;
      await Future.delayed(const Duration(seconds: 1));
      final response = await http.delete(
        Uri.parse('${appState.SERVER}/chatstreams/${widget.chat.id}'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'App-Token': appState.APPTOKEN,
          //HttpHeaders.authorizationHeader: appState.APPTOKEN,
          'User-Token': appState.userData["token"].toString()
        },
      );
      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        print(res);
        if (res == "#VERIFIED#") {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Chat deleted")));
            pending = false;
            Navigator.of(context)..pop()..pop();
            widget.RefreshChats.call();
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

    Future purgeContents() async {
      pending = true;
      await Future.delayed(const Duration(seconds: 1));
      final response = await http.delete(
        Uri.parse('${appState.SERVER}/chatstreams/${widget.chat.id}/messages'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'App-Token': appState.APPTOKEN,
          //HttpHeaders.authorizationHeader: appState.APPTOKEN,
          'User-Token': appState.userData["token"].toString()
        },
      );
      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        print(res);
        if (res == "#VERIFIED#") {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Chat contents have been purged. ")));
            pending = false;
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

    Future<void> deleteAlert() async {
      return showDialog<void>(
        context: context,
        barrierDismissible: false, 
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Warning"),
            content: const SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text("Are you sure you want to delete this chat? "),
                  Text("This action cannot be undone. "),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                onPressed: () => Navigator.pop(context, 'Cancel'),
              ),
              TextButton(
                child: const Text("Delete", style: TextStyle(color: Colors.red)),
                onPressed: () {
                  deleteChat();
                  Navigator.pop(context, 'Delete');
                },
              ),
            ],
          );
        },
      );
    }

    Future<void> purgeAlert() async {
      return showDialog<void>(
        context: context,
        barrierDismissible: false, 
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Warning"),
            content: const SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text("Are you sure you want to purge all chat contents? "),
                  Text("These contents will not be recoverable. "),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                onPressed: () => Navigator.pop(context, 'Cancel'),
              ),
              TextButton(
                child: const Text("Purge", style: TextStyle(color: Colors.red)),
                onPressed: () {
                  purgeContents();
                  Navigator.pop(context, 'Purge');
                },
              ),
            ],
          );
        },
      );
    }

    editPicture(File profpic) {
      showModalBottomSheet(
        showDragHandle: false,
        isDismissible: true,
        context: context, 
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter stateSetter) {
              return SizedBox(
                height: 500,
                width: 500,
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Image(
                      width: 250,
                      height: 250,
                      image: FileImage(profpic),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            return Colors.deepOrange;
                          },
                        )
                      ),
                      onPressed: () {
                        modifyChat(_file, widget.chat.name, widget.chat.users, widget.chat.admins, widget.chat.self_destructing);
                        Navigator.pop(context);
                      }, 
                      child: Text("Select", style: TextStyle(color: Colors.white))
                    ),
                  ],
                ),
              );
            },
          );
        }
      );
    }

  Future<File?> cropImage(File imageFile) async {
      try {
        CroppedFile? croppedImg = await ImageCropper().cropImage(
          sourcePath: imageFile.path, 
          compressQuality: 100,
          aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        );
        _file = File(croppedImg!.path);
        editPicture(_file as File);

      } catch (e) {
        print(e);
      }
      return null;
  }

    Future pickImage() async {
      try {
        final image = await ImagePicker().pickImage(source: ImageSource.gallery);
        final File picked = File(image!.path);
        cropImage(picked);
      }
      catch(error) {
        print("error: $error");
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar (
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: SafeArea(child: Text(
          "Chat Settings: ",
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
              SizedBox(height: 20),
              // Set Chat Picture _________________________________________________________________
              widget.chat.group ? GestureDetector(
                onTap: () {
                  if (widget.chat.admin == true) {
                    pickImage();
                  }
                  else {
                    print("unauthorized");
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: 
                  Image(
                    height: 150,
                    width: 150,
                    image: widget.chat.picture.image
                  ),
                ),
              ) : Container(),
              SizedBox(height: 20),
              // Set Chat Name ____________________________________________________________________
              widget.chat.group? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Chat Name: ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ) : Container(),
              Card(child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  widget.chat.group ?  ListTile(
                    title: Text(widget.chat.name),
                    trailing: widget.chat.admin ? IconButton(
                      icon: Icon(Icons.edit),
                      color: Colors.lightBlue,
                      onPressed: () {
                        setState(() {
                          show_nameupdate = !show_nameupdate;
                        });
                      },
                    ): SizedBox(width: 10),
                  ) : Container(),
                  show_nameupdate ? Form(
                    key: nameformKey,
                    child: Column(children: [
                      Column(
                        children: [
                          ListTile(
                            title: Text("Enter the new name for this chat. "),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              controller: nameField,
                              decoration: InputDecoration(
                                            hintText: 'Enter new chat name',
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
                      ),
                      Card(
                        color: Color.fromARGB(255, 140, 45, 20),
                        clipBehavior: Clip.hardEdge,
                        child: InkWell(
                          splashColor: Colors.deepOrange,
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Text("Update", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          ),
                          onTap: () {
                            if (nameformKey.currentState!.validate()) {
                              nameField.clear();
                              modifyChat(null, chat_name, widget.chat.users, widget.chat.admins, widget.chat.self_destructing);
                            }
                          },
                        ),
                      ),
                      SizedBox(height: 10)
                    ],)
                  ) : Container(),
                ],
              )),
              // Manage Chat Users ______________________________________________________________
              widget.chat.group ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: widget.chat.admin ? Text("Manage Users: ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)) : Text("Users: ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ) : Container(),
              widget.chat.group ? Card(child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.chat.admin ? Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: widget.chat.users.length,
                          itemBuilder: (context, index) {
                            var curr_user = widget.chat.users[index];
                            if (widget.chat.admins.contains(curr_user)) {
                              return ListTile(
                                title: Text("${widget.chat.users[index]}"),
                                leading: IconButton(
                                  icon : Icon(Icons.admin_panel_settings, color: Colors.deepOrange),
                                  onPressed: () async {
                                    if (widget.chat.admins.length > 1) {
                                      var user = widget.chat.users[index];
                                      widget.chat.admins.remove(user);
                                      await modifyChat(null, widget.chat.name, widget.chat.users, widget.chat.admins, widget.chat.self_destructing);
                                      if (user == appState.userData["username"]) {
                                        if (context.mounted) {
                                          Navigator.of(context)..pop()..pop();
                                        }
                                        widget.RefreshChats.call();
                                      }
                                    }
                                    else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("There must be at least one admin user per group. ")));
                                    }
                                  }, 
                                ),
                                trailing: () {
                                  if (curr_user == appState.userData["username"]) {
                                    return SizedBox.shrink();
                                  }
                                  else {
                                    return TextButton(
                                      onPressed: () {
                                        if (widget.chat.admins.length > 1) {
                                          widget.chat.users.remove(curr_user);
                                          widget.chat.admins.remove(curr_user);
                                          modifyChat(null, widget.chat.name, widget.chat.users, widget.chat.admins, widget.chat.self_destructing);
                                        }
                                        else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("There must be at least one admin user per group. ")));
                                        }
                                      }, 
                                      child: 
                                        Text("Remove", style: TextStyle(color: Colors.blue, decorationColor: Colors.blue))
                                    );
                                  }
                                } ()
                              );
                            }
                            else {
                              return ListTile(
                                title: Text("${widget.chat.users[index]}"),
                                leading: IconButton(
                                  icon : Icon(Icons.person, color: Colors.grey),
                                  onPressed: () {
                                    var user = widget.chat.users[index];
                                    widget.chat.admins.add(user);
                                    modifyChat(null, widget.chat.name, widget.chat.users, widget.chat.admins, widget.chat.self_destructing);
                                  }, 
                                ),
                                trailing: TextButton(
                                  onPressed: () {
                                    var user = widget.chat.users[index];
                                    if (user == appState.userData["username"]) {
                                      leaveAlert(user);
                                    }
                                    else {
                                      widget.chat.users.remove(user);
                                      modifyChat(null, widget.chat.name, widget.chat.users, widget.chat.admins, widget.chat.self_destructing);
                                    }
                                  }, 
                                  child: 
                                    Text("Remove", style: TextStyle(color: Colors.blue, decorationColor: Colors.blue))
                                ),
                              );
                            }
                          }
                        ),
                      ),
                      Divider(
                        thickness: 1.5,
                        indent: 10,
                        endIndent: 10,
                        color: Theme.of(context).colorScheme.outline,
                      )
                    ],
                  ) :
                  Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: widget.chat.users.length,
                          itemBuilder: (context, index) {
                            if (widget.chat.admins.contains(widget.chat.users[index])) {
                              return ListTile(
                                title: Text("${widget.chat.users[index]}"),
                                leading: Icon(Icons.admin_panel_settings, color: Colors.deepOrange),
                              );
                            }
                            else {
                              return ListTile(
                                title: Text("${widget.chat.users[index]}"),
                                leading: Icon(Icons.person, color: Colors.grey),
                              );
                            }
                          }
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      )
                    ],
                  ),
                  widget.chat.admin ? Column(
                    children: [
                      Form(
                        key: userformKey,
                        child: ListTile(
                          title: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              controller: userField,
                              decoration: InputDecoration(
                                            hintText: 'Enter username',
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
                                    new_user = value;
                                  });
                                }
                                return null;
                              },
                            ),
                          ),
                          trailing: IconButton(
                              icon: Icon(Icons.group_add, size: 30),
                              onPressed: () {
                                if (userformKey.currentState!.validate()) {
                                  userField.clear();
                                  if (widget.chat.users.length < 100) {
                                    List new_users = [];
                                    for (var user in widget.chat.users) {
                                      new_users.add(user);
                                    }
                                    if (new_user != appState.userData["username"]) {
                                      new_users.add(new_user);
                                    }
                                    modifyChat(null, widget.chat.name, new_users, widget.chat.admins, widget.chat.self_destructing);
                                  }
                                  else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("User limit exceeded. You must have no more than 100 users. ")));
                                  }
                                }
                              },
                          ),
                        ),
                      ),
                    ],
                  ): Container(),
                ],
              )): Container(),
              // Toggle Self-Destruct ___________________________________________________________________
              Card(
                child: Row(children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text("Self-Destructing Messages: ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                  ),
                  widget.chat.admin ? Switch.adaptive(
                    activeColor: Colors.deepOrange,
                    value: widget.chat.self_destructing,
                    onChanged: (bool value) {
                      setState(() {
                        widget.chat.self_destructing = value;
                      });
                      if (widget.chat.self_destructing == true) {
                        modifyChat(null, widget.chat.name, widget.chat.users, widget.chat.admins, true);
                      }
                      else {
                        modifyChat(null, widget.chat.name, widget.chat.users, widget.chat.admins, false);
                      }
                    },
                  ) :
                  Icon(
                    widget.chat.self_destructing ? Icons.toggle_on : Icons.toggle_off,
                    color: widget.chat.self_destructing ? Colors.deepOrange : Colors.grey,
                    size: 55,
                  )
                ],),
              ),
              // Purge Chat Contents ___________________________________________________________________
              Card(
                child: Row(children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text("Purge Chat Contents: ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                  ),
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Color.fromARGB(255, 140, 45, 20)),
                      padding: WidgetStateProperty.all(EdgeInsets.all(0)),
                    ),
                    child: Icon(Icons.delete_sweep, color: Colors.white),
                    onPressed: () {
                      purgeAlert();
                    },
                  )
                ],),
              ),
              // Leave Chat ___________________________________________________________________
              Card(
                color: Theme.of(context).colorScheme.primary,
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  splashColor: Color.fromARGB(255, 115, 30, 25),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(children: [
                      Icon(Icons.exit_to_app, color: Colors.redAccent),
                      SizedBox(width: 20, height: 15,),
                      Text("Leave Chat", style: TextStyle(color: Colors.redAccent, fontSize: 17, fontWeight: FontWeight.bold)),
                    ],),
                  ),
                  onTap: () {
                    if (widget.chat.admin && widget.chat.admins.length <= 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("There must be at least one admin user per group. ")));
                    }
                    else {
                      leaveAlert(appState.userData["username"]);
                    }
                  },
                ),
              ),
              // Delete Chat ___________________________________________________________________
              widget.chat.admin ? Card(
                color: Colors.red,
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  splashColor: Color.fromARGB(255, 115, 30, 25),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(children: [
                      Icon(Icons.delete),
                      SizedBox(width: 20, height: 15,),
                      Text("Delete Chat", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ],),
                  ),
                  onTap: () {
                    deleteAlert();
                  },
                ),
              ): Container(),
            ],
          ),
        ),
      ),
    );
  }
}