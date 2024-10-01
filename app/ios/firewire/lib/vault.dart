// ------------------------------------------------------------------------------------
// Vault Page -------------------------------------------------------------------------
// ------------------------------------------------------------------------------------ 
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Database import
import 'utilities/dbinterface.dart';
// Main import
import './main.dart';



class VaultPage extends StatefulWidget {
  const VaultPage({super.key, required this.collection});
  final List<VaultItem> collection;

  @override
  State<VaultPage> createState() => _VaultPageState();
}
class _VaultPageState extends State<VaultPage> {
  DatabaseHandler db = DatabaseHandler();


  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    List<VaultItem> collection = widget.collection;
      
    Future<void> removeItem(idx) async {
      await db.removeVaultItem(idx);
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          "${appState.userData["displayname"]}'s Vault",
          style: TextStyle(fontFamily: "Monospace", fontSize: 30, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: BackButtonIcon(),
          color: Colors.deepOrange,
          onPressed: () {
            Navigator.of(context).pop();
          }, 
        ),
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(
              height: 20,
            ),
            collection.isNotEmpty ?
            Expanded(
              flex: 8,
              child: ListView.builder(
                itemCount: collection.length,
                itemBuilder: (BuildContext context, int idx) {
                  var item = collection[idx];
                  if (item.is_media == false) {
                    return Column(
                      children: [
                        ListTile(
                          title: Text(item.username as String),
                          subtitle: Text(item.content as String),
                          trailing: PopupMenuButton<int>( 
                            icon: Icon(Icons.more_vert),
                            onSelected: (value) { 
                              if (value == 0) { 
                                removeItem(idx);
                                Navigator.pop(context);
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
                                    Text("Remove from Vault", style: TextStyle(color: Colors.red))
                                  ]),  
                                )
                              ]; 
                            }, 
                          ), 
                        ),
                        Divider(
                          thickness: 0.5, 
                          indent: 20, 
                          endIndent: 20, 
                          color: Colors.black, 
                        ),
                      ],
                    );
                  }
                  else {
                    return Column(
                      children: [
                        ListTile(
                          title: Text(item.username as String),
                          subtitle: GestureDetector(
                            onTap: () {
                              var selected_image = Image(image: MemoryImage(base64Decode("${item.content}")));
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => MediaDisplay(display_image: selected_image))
                              );
                            },
                            child: Image(
                              width: 200,
                              height: 200,
                              image: MemoryImage(base64Decode("${item.content}")),
                            ),
                          ),
                          trailing: PopupMenuButton<int>( 
                            icon: Icon(Icons.more_vert),
                            onSelected: (value) { 
                              if (value == 0) { 
                                removeItem(idx);
                                Navigator.pop(context);
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
                                    Text("Remove from Vault", style: TextStyle(color: Colors.red))
                                  ]),  
                                )
                              ]; 
                            }, 
                          ), 
                        ),
                        Divider(
                          thickness: 0.5, 
                          indent: 20, 
                          endIndent: 20, 
                          color: Colors.black, 
                        ),
                      ],
                    );
                  }
                }
              ),
            ) :
            Text("No items in vault yet. ")
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