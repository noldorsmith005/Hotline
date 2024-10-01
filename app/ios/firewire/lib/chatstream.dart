// ------------------------------------------------------------------------------------
// Chatstream Page -------------------------------------------------------------------------
// ------------------------------------------------------------------------------------ 
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dart_emoji/dart_emoji.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path/path.dart' as pathfinder;
import 'package:http/http.dart' as http;
// Database import
import 'utilities/dbinterface.dart';
// Manage chat import
import './settings/managechat.dart';
// Main import
import './main.dart';

class ChatStream extends StatefulWidget {
  const ChatStream({super.key, required this.chat, required this.RefreshChats});
  final Chat chat;
  final Function RefreshChats;

  @override
  State<ChatStream> createState() => _ChatStreamState();
}
class _ChatStreamState extends State<ChatStream> {
  DatabaseHandler db = DatabaseHandler();
  ScrollController scroller = ScrollController();
  StreamController<List> chatstream = StreamController();

  final VaultKey = GlobalKey<FormState>();
  final KeyField = TextEditingController();

  final formKey = GlobalKey<FormState>();
  final msgField = TextEditingController();

  bool new_locked = false;
  String new_message = "";

  bool streaming = false;
  bool init = true;
  bool pending = false;
  bool scrolling = false;

  var inbox = [];
  var outbox = [];
  var garbage = [];
  var locked = [];
  var curr_locked = [];
  var attached = [];


  void Scroll(mode) {
    if (mode == 0) {
      if (scroller.hasClients) {
        scroller.jumpTo(scroller.position.maxScrollExtent);
      } 
    }
    else {
      if (scroller.hasClients) {
        scroller.animateTo(scroller.position.maxScrollExtent, duration: Duration(milliseconds: 500), curve: Curves.ease);
      } 
    }
  }

  @override
  void initState() {
    super.initState();
    scroller.addListener(() {
      if (scroller.offset != scroller.position.maxScrollExtent) {
        if (scrolling == false) {
          setState(() {
            scrolling = true;
          });
        }
      }
      else {
        setState(() {
          scrolling = false;
        });
      }
    });
  }

  @override 
  void dispose() { 
    chatstream.close();
    super.dispose(); 
  } 

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    Future markRead() async {
      pending = true;
      final http.Response response;
      await Future.delayed(const Duration(seconds: 1));
        response = await http.patch(
        Uri.parse('${appState.SERVER}/chatstreams/${widget.chat.id}/messages/${appState.userData["username"]}'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'App-Token': appState.APPTOKEN,
          //HttpHeaders.authorizationHeader: appState.APPTOKEN,
          'User-Token': appState.userData["token"].toString()
        },
      );
      if (response.statusCode == 200) {
        jsonDecode(response.body);
      } 
      else {
        throw Exception("Server down");
      }
      pending = false;
    }

    Future selfDestruct() async {
      pending = true;
      final http.Response response;
      await Future.delayed(const Duration(seconds: 1));
        response = await http.delete(
        Uri.parse('${appState.SERVER}/chatstreams/${widget.chat.id}/messages/selfdestruct'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'App-Token': appState.APPTOKEN,
          //HttpHeaders.authorizationHeader: appState.APPTOKEN,
          'User-Token': appState.userData["token"].toString()
        },
      );
      if (response.statusCode == 200) {
        jsonDecode(response.body);
      } 
      else {
        throw Exception("Server down");
      }
      pending = false;
    }

    Future sendMessage(var message) async {
      final response = await http.post(
        Uri.parse('${appState.SERVER}/chatstreams/${widget.chat.id}/messages'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'App-Token': appState.APPTOKEN,
          //HttpHeaders.authorizationHeader: appState.APPTOKEN,
          'User-Token': appState.userData["token"].toString()
        },
        body: jsonEncode(<String, dynamic>{
            "source": message["source"]["username"],
            "timestamp": message["timestamp"],
            "content": message["content"],
            "locked": message["locked"]
        }),
      );
      if (response.statusCode == 200) {
        var messages = jsonDecode(response.body);
        if (messages == "#ERROR#") {
          throw Exception("Chat not found");
        }
      } 
      else {
        throw Exception("Server down");
      }
    }

    Future sendMedia(var attached) async {
      var media = attached["content"];
      var filetype = pathfinder.extension(media!.path);
      var image_bytes = await media.readAsBytes();
      String image_data = base64Encode(image_bytes);
      await Future.delayed(const Duration(milliseconds: 500));
      final response = await http.post(
        Uri.parse('${appState.SERVER}/chatstreams/${widget.chat.id}/multimedia'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'App-Token': appState.APPTOKEN,
          //HttpHeaders.authorizationHeader: appState.APPTOKEN,
          'User-Token': appState.userData["token"].toString()
        },
        body: jsonEncode(<String, dynamic>{
            "source": appState.userData["username"],
            "timestamp": attached["timestamp"],
            "content": image_data,
            "filetype": filetype,
            "locked": attached["locked"]
        }),
      );
      if (response.statusCode == 200) {
        var messages = jsonDecode(response.body);
        if (messages == "#ERROR#") {
          throw Exception("Chat not found");
        }
      } 
      else {
        throw Exception("Server down");
      }
    }

    Future deleteMessage(var index) async {
      final response = await http.delete(
        Uri.parse('${appState.SERVER}/chatstreams/${widget.chat.id}/messages/$index'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'App-Token': appState.APPTOKEN,
          //HttpHeaders.authorizationHeader: appState.APPTOKEN,
          'User-Token': appState.userData["token"].toString()
        },
      );
      if (response.statusCode == 200) {
        var messages = jsonDecode(response.body);
        if (messages == "#ERROR#") {
          throw Exception("Chat not found");
        }
      } 
      else {
        throw Exception("Server down");
      }
    }

    void updateMessages() async {
      bool init = true;
      while (streaming == true) {
        if (init == true) {
          init = false;
        }
        else {
          await Future.delayed(const Duration(seconds: 5));
        }
        pending = true;
        for (var index in garbage) {
          await deleteMessage(index);
        }
        garbage.clear();
        for (var message in outbox) {
          if (message["media"] == false) {
            await sendMessage(message);
          }
          else {
            await sendMedia(message);
          }
        }
        outbox.clear();
        final response = await http.get(
          Uri.parse('${appState.SERVER}/chatstreams/${widget.chat.id}/messages/${appState.userData["username"]}'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'App-Token': appState.APPTOKEN,
            //HttpHeaders.authorizationHeader: appState.APPTOKEN,
            'User-Token': appState.userData["token"].toString()
          },
        );
        if (response.statusCode == 200) {
          var messages = jsonDecode(response.body);
          if (messages == "#ERROR#") {
            if (context.mounted) {
              Navigator.pop(context);
            }
            else {
              throw Exception("Chat not located in database. Please refresh the page and try again. ");
            }
          }
          pending = false;
          for (var msg in messages) {
            if (msg["locked"] == true) {
              locked.add(msg);
              curr_locked.add(msg);
            }
          }
          if (messages.length == 0) {
            if (!chatstream.isClosed) {
              chatstream.sink.add(messages);
            }
          }
          if (inbox.length != messages.length) {
            inbox = messages;
            if (!chatstream.isClosed) {
              chatstream.sink.add(messages);
            }
          }
        } 
        else {
          pending = false;
          throw Exception("Server down");
        }
      }
    }

    Future<void> Alert(String alert) async {
      return showDialog(
        context: context.mounted ? context: context,
        barrierDismissible: true, 
        builder: (BuildContext context) {
          return AlertDialog(
            content: Padding(
              padding: const EdgeInsets.all(50.0),
              child: Text(alert, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text("Ok", style: TextStyle(color: Colors.white)),
                onPressed: () => Navigator.pop(context, 'Cancel'),
              )
            ],
          );
        },
      );
    }

    selectedMessageOptions(dynamic message) {
      showModalBottomSheet(
        backgroundColor: const Color.fromARGB(255, 25, 25, 25),
        showDragHandle: false,
        isDismissible: true,
        context: context, 
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter stateSetter) {
              return SizedBox(
                height: 200,
                child: Column(
                  children: [
                    ListTile(
                      tileColor: Colors.transparent,
                      title: Text("Timestamp: ${message["timestamp"]}"),
                    ),
                    ListTile(
                      tileColor: Colors.transparent,
                      leading: Icon(Icons.enhanced_encryption_outlined, color: Colors.deepOrange),
                      title: Text("Add To Vault"),
                      onTap: () async {
                        var vault = await db.getVault();
                        List collection = await db.getVaultCollection();
                        if (vault.setup == true) {
                          if (collection.length < 100) {
                            var vault_item = VaultItem(message["source"]["displayname"], message["content"], message["media"]);
                            db.addVaultItem(vault_item);
                            await Future.delayed(const Duration(milliseconds: 1000));
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Message added to vault")));
                            }
                          }
                          else {
                            if (context.mounted) {
                              Navigator.pop(context);
                              Alert("Vault storage full. ");
                            }
                          }
                        }
                        else {
                          if (context.mounted) {
                            Navigator.pop(context);
                            Alert("Vault is not set up. ");
                          }
                        }
                      },
                    ),
                    Divider(
                      thickness: 0.5, 
                      indent: 0, 
                      endIndent: 0, 
                      color: Colors.black, 
                    ),
                    ListTile(
                      tileColor: Colors.transparent,
                      leading: Icon(Icons.delete, color: Color.fromARGB(255, 200, 30, 20)),
                      title: Text("Delete Message", style: TextStyle(color: Color.fromARGB(255, 200, 30, 20))),
                      onTap: () async {
                        var vault = await db.getVault();
                        if (vault.setup == true) {
                          if (message["source"]["username"] == appState.userData["username"]) {
                            List message_list = [];
                            var index = inbox.indexOf(message);
                            garbage.add(index);
                            for (var i=0; i<inbox.length; i++) {
                              message_list.add(inbox[i]);
                            }
                            message_list.removeAt(index);
                            if (!chatstream.isClosed) {
                              chatstream.sink.add(message_list);
                            }
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          }
                          else {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("You can only delete messages that you sent. ")));
                            }
                          }
                        }
                        else {
                          if (context.mounted) {
                            Navigator.pop(context);
                            Alert("Vault is not set up. ");
                          }
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        }
      );
    }

    Future<void> lockedAlert(int index) async {
      final vault = await db.getVault();
      return showDialog(
        context: context.mounted ? context: context,
        barrierDismissible: false, 
        builder: (BuildContext context) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Form(
                key: VaultKey,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(10.0),
                      child: ListTile(
                        title: TextFormField(
                          obscuringCharacter: '*',
                          obscureText: true,
                          controller: KeyField,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter 4-digit key',
                          ),
                          validator: (value) {
                            List nums = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
                            if (value == null || value.isEmpty) {
                              return 'This field cannot be empty';
                            }
                            for (var char in value.characters) {
                              if (!nums.contains(char)) {
                                return 'Invalid type. ';
                              }
                            }
                            if (value.length != 4) {
                              return 'Key must be 4 digits. ';
                            }
                            if (value != vault.key) {
                              return 'Invalid key. ';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                onPressed: () => Navigator.pop(context, 'Cancel'),
              ),
              TextButton(
                child: const Text("Unlock", style: TextStyle(color: Colors.white)),
                onPressed: () {
                  if (VaultKey.currentState!.validate()) {
                    KeyField.clear();
                    Future.delayed(Duration(milliseconds: 500), () async {
                      if (context.mounted) {
                        Navigator.pop(context);
                        setState(() {
                          curr_locked.removeAt(index);
                        });
                      }
                    });
                  }
                },
              ),
            ],
          );
        },
      );
    }

    Future pickImages() async {
      try {
        final images = await ImagePicker().pickMultiImage();
        if (images.isNotEmpty) {
          if (images.length < 5) {
            setState(() {
              for (var image in images) {
                attached.add(image);
              }
            });
          }
          else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Data limit exceeded. Please re-select media. ")));
            }
          }
        }
      }
      catch(error) {
        print("error: $error");
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      floatingActionButton: scrolling ? Container(
        margin: attached.isEmpty ? EdgeInsets.only(bottom: 75, right: 20.0): EdgeInsets.only(bottom: 330, right: 20.0),
        child: FloatingActionButton.small(
          foregroundColor: Colors.deepOrange,
          onPressed: () { 
            Scroll(1); 
          },
          child: const Icon(Icons.expand_more),
        ),
      ) : Container(),
      appBar: AppBar (
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        scrolledUnderElevation: 0,
        title: SafeArea(child: Text(widget.chat.name)),
        leading: IconButton(
          icon: BackButtonIcon(),
          color: Colors.deepOrange,
          onPressed: () {
            if (pending == false) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                streaming = false;
                await markRead();
                if (widget.chat.self_destructing == true) {
                  selfDestruct();
                }
              });
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          }, 
        ),
        actions: <Widget>[
          SafeArea(
            child: IconButton(
              iconSize: 35,
              icon: const Icon(Icons.menu),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Menu(chat: widget.chat, RefreshChats: widget.RefreshChats))
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List>(
              stream: chatstream.stream, 
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                if (init == true) {
                  init = false;
                  streaming = true;
                  updateMessages();
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (scrolling == false) {
                    Scroll(0);
                  }
                });
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text("Loading messages..."); 
                } 
                else if (snapshot.hasError) {
                  return Column(
                    children: [
                      const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text('${snapshot.error}'),
                      ),
                    ],
                  );
                } 
                else if (snapshot.data.isEmpty) {
                  return Text("No messages yet"); 
                } 
                else {
                  return ListView.builder(
                    controller: scroller,
                    itemCount: snapshot.data.length,
                    itemBuilder: (context, idx) {
                      var curr_message = snapshot.data[idx];
                      if (curr_message["media"] == false) {
                        String contents = curr_message["content"];
                        if (outbox.contains(curr_message)) {
                          return ListTile(
                            contentPadding: EdgeInsets.all(10),
                            trailing: Icon(Icons.publish, color: Colors.green),
                            title: Text(curr_message["source"]["displayname"], style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            subtitle: Text(curr_message["content"], style: TextStyle(fontSize: EmojiUtil.hasOnlyEmojis(contents) ? 40 : 15))
                          );
                        }
                        else {
                          if (!locked.contains(curr_message)) {
                            return ListTile(
                              contentPadding: EdgeInsets.all(10),
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey,
                                foregroundImage: MemoryImage(base64Decode("${curr_message["source"]["profpic"]}")),
                              ),
                              title: Text(curr_message["source"]["displayname"], style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              subtitle: GestureDetector(
                                onLongPress: () {
                                  selectedMessageOptions(curr_message);
                                },
                                child: Text(curr_message["content"], style: TextStyle(fontSize: EmojiUtil.hasOnlyEmojis(contents) ? 40 : 15))
                              ),
                            );
                          }
                          else {
                            if (curr_locked.contains(curr_message)) {
                              var index = curr_locked.indexOf(curr_message);
                              return ListTile(
                                contentPadding: EdgeInsets.all(10),
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey,
                                  foregroundImage: MemoryImage(base64Decode("${curr_message["source"]["profpic"]}")),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.lock, color: Colors.deepOrangeAccent),
                                  onPressed: () async {
                                    var vault = await db.getVault();
                                    if (vault.setup == true) {
                                      lockedAlert(index);
                                    }
                                    else {
                                      Alert("Vault is not set up. ");
                                    }
                                  },
                                ),
                                title: Text(curr_message["source"]["displayname"], style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                subtitle: Text("##########", style: TextStyle(fontSize: 15, color: Colors.deepOrange))
                              );
                            }
                            else {
                              return ListTile(
                                contentPadding: EdgeInsets.all(10),
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey,
                                  foregroundImage: MemoryImage(base64Decode("${curr_message["source"]["profpic"]}")),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.lock_open, color: Colors.deepOrangeAccent),
                                  onPressed: () {
                                    setState(() {
                                      curr_locked.clear();
                                      for (var i=0; i<locked.length; i++) {
                                        var msg = locked[i];
                                        curr_locked.add(msg);
                                      }
                                    });
                                  }
                                ),
                                title: Text(curr_message["source"]["displayname"], style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                subtitle: GestureDetector(
                                  onLongPress: () {
                                    selectedMessageOptions(curr_message);
                                  },
                                  child: Text(curr_message["content"], style: TextStyle(fontSize: EmojiUtil.hasOnlyEmojis(contents) ? 40 : 15))
                                ),
                              );
                            }
                          }
                        }
                      }
                      else {
                        if (outbox.contains(curr_message)) {
                          return ListTile(
                            contentPadding: EdgeInsets.all(10),
                            trailing: Icon(Icons.publish, color: Colors.green),
                            title: Text(curr_message["source"]["displayname"], style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            subtitle: GestureDetector(
                              onLongPress: () {
                                selectedMessageOptions(curr_message);
                              },
                              child: Image(
                                height: 100,
                                width: 100,
                                image: FileImage(curr_message["content"])
                              ),
                            ),
                          );
                        }
                        else {
                          if (!locked.contains(curr_message)) {
                            return ListTile(
                              contentPadding: EdgeInsets.all(10),
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey,
                                foregroundImage: MemoryImage(base64Decode("${curr_message["source"]["profpic"]}")),
                              ),
                              title: Text(curr_message["source"]["displayname"], style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              subtitle: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      var selected_image = Image(image: MemoryImage(base64Decode("${curr_message["content"]}")) );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => MediaDisplay(display_image: selected_image))
                                      );
                                    },
                                    onLongPress: () {
                                      selectedMessageOptions(curr_message);
                                    },
                                    child: Image(
                                      height: 200,
                                      width: 200,
                                      image: MemoryImage(base64Decode("${curr_message["content"]}")),
                                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  IconButton( 
                                    icon: Icon(Icons.download, color: Colors.deepOrange),
                                    onPressed: () async {
                                      Uint8List selected_media = base64Decode("${curr_message["content"]}");
                                      await ImageGallerySaver.saveImage(selected_media.buffer.asUint8List());
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Media saved to gallery. ")));
                                      }
                                    },
                                  )
                                ],
                              ),
                            );
                          }
                          else {
                            if (curr_locked.contains(curr_message)) {
                              var index = curr_locked.indexOf(curr_message);
                              return ListTile(
                                contentPadding: EdgeInsets.all(10),
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey,
                                  foregroundImage: MemoryImage(base64Decode("${curr_message["source"]["profpic"]}")),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.lock, color: Colors.deepOrangeAccent),
                                  onPressed: () async {
                                    var vault = await db.getVault();
                                    if (vault.setup == true) {
                                      lockedAlert(index);
                                    }
                                    else {
                                      Alert("Vault is not set up. ");
                                    }
                                  },
                                ),
                                title: Text(curr_message["source"]["displayname"], style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                subtitle: Text("##########", style: TextStyle(color: Colors.deepOrange))
                              );
                            }
                            else {
                              return ListTile(
                                contentPadding: EdgeInsets.all(10),
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey,
                                  foregroundImage: MemoryImage(base64Decode("${curr_message["source"]["profpic"]}")),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.lock_open, color: Colors.deepOrangeAccent),
                                  onPressed: () {
                                    setState(() {
                                      curr_locked.clear();
                                      for (var i=0; i<locked.length; i++) {
                                        var msg = locked[i];
                                        curr_locked.add(msg);
                                      }
                                    });
                                  }
                                ),
                                title: Text(curr_message["source"]["displayname"], style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                subtitle: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        var selected_image = Image(image: MemoryImage(base64Decode("${curr_message["content"]}")) );
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => MediaDisplay(display_image: selected_image))
                                        );
                                      },
                                      onLongPress: () {
                                        selectedMessageOptions(curr_message);
                                      },
                                      child: Image(
                                        height: 175,
                                        width: 175,
                                        image: MemoryImage(base64Decode("${curr_message["content"]}")),
                                        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    IconButton( 
                                      icon: Icon(Icons.download, color: Colors.deepOrange),
                                      onPressed: () async {
                                        Uint8List selected_media = base64Decode("${curr_message["content"]}");
                                        await ImageGallerySaver.saveImage(selected_media.buffer.asUint8List());
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Media saved to gallery. ")));
                                        }
                                      },
                                    )
                                  ],
                                ),
                              );
                            }
                          }
                        }
                      }
                    },
                  );
                }
              },
            ),
          ),
          SizedBox(height: 10),
          Align(
            alignment: FractionalOffset.bottomCenter,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                )
              ),
              margin: EdgeInsets.all(0),
              child: Form(
                key: formKey,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      attached.isNotEmpty ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: TextButton(
                              child: Text("Clear", style: TextStyle(color: Colors.blue)),
                              onPressed: () {
                                setState(() {
                                  attached.clear();
                                });
                              }
                            ),
                          ),
                          SizedBox(
                            height: 200,
                            width: 500,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: attached.length,
                              itemBuilder: (context, idx) {
                                var img = attached[idx];
                                return Row(
                                  children: [
                                    Image(
                                      width: 150,
                                      height: 150,
                                      image: FileImage(File(img.path)),
                                    ),
                                    SizedBox(width: 10)
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ) : Container(),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.attach_file, color: Colors.white),
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              pickImages();
                            },
                          ),
                          IconButton(
                            icon: new_locked ? Icon(Icons.lock, color: Colors.deepOrangeAccent) : Icon(Icons.lock_open, color: Colors.deepOrangeAccent),
                            onPressed: () async {
                              var vault = await db.getVault();
                              if (vault.setup == true) {
                                setState(() {
                                  new_locked = !new_locked;
                                });
                              }
                              else {
                                Alert("Vault is not set up. ");
                              }
                            },
                          ),
                          SizedBox(
                            width: 200, 
                            child: TextFormField(
                              controller: msgField,
                              minLines: 1,
                              maxLines: 5,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                            hintText: 'Enter message',
                                            contentPadding:
                                                EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(Radius.zero),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide:
                                                  BorderSide(color: Colors.grey, width: 0.5),
                                              borderRadius: BorderRadius.all(Radius.zero),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide:
                                                  BorderSide(color: Colors.grey, width: 0.5),
                                              borderRadius: BorderRadius.all(Radius.zero),
                                            ),
                                          ),
                              validator: (value) {
                                if (value != null || attached.isNotEmpty) {
                                  setState(() {
                                    new_message = value as String;
                                  });
                                }
                                else {
                                  return "Please enter a message";
                                }
                                return null;
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.send, color: Colors.deepOrange),
                            onPressed: () {
                              if (formKey.currentState!.validate() || attached.isNotEmpty) {
                                msgField.clear();
                                List messagelist = [];
                                final DateTime time = DateTime.now();
                                var timestamp = "${time.month}/${time.day}/${time.year} ${time.hour}:${time.minute}";
                                var message = {
                                  "source": {
                                    "username": appState.userData["username"],
                                    "displayname": appState.userData["displayname"]
                                  },
                                  "timestamp": timestamp,
                                  "content": new_message, 
                                  "media": false,
                                  "locked": new_locked
                                };
                                for (var i=0; i<attached.length; i++) {
                                  final DateTime time = DateTime.now();
                                  var timestamp = "${time.month}/${time.day}/${time.year} ${time.hour}:${time.minute}";
                                  var media_message = {
                                    "source": {
                                      "username": appState.userData["username"],
                                      "displayname": appState.userData["displayname"]
                                    },
                                    "timestamp": timestamp,
                                    "content": File(attached[i].path), 
                                    "media": true,
                                    "locked": new_locked
                                  };
                                  outbox.add(media_message);
                                }
                                if (new_message != "") {
                                  outbox.add(message);
                                }
                                for (var i=0; i<inbox.length; i++) {
                                  var msg = inbox[i];
                                  messagelist.add(msg);
                                }
                                for (var i=0; i<outbox.length; i++) {
                                  var msg = outbox[i];
                                  messagelist.add(msg);
                                }
                                if (!chatstream.isClosed) {
                                  chatstream.sink.add(messagelist);
                                }
                              }
                              setState(() {
                                new_message = "";
                                attached.clear();
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
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