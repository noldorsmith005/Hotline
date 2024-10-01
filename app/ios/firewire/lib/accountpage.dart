// ------------------------------------------------------------------------------------
// Account Page -----------------------------------------------------------------------
// ------------------------------------------------------------------------------------ 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Database import
import 'utilities/dbinterface.dart';
// Menu page imports
import 'settings/manageaccount.dart';
import 'settings/privacysettings.dart';
// Vault import 
import './vault.dart';
// Main import
import './main.dart';

import './utilities/encrypter.dart';



class AccountPage extends StatefulWidget {
  @override
  State<AccountPage> createState() => _AccountPageState();
}
class _AccountPageState extends State<AccountPage> {
  DatabaseHandler db = DatabaseHandler();
  final VaultKey = GlobalKey<FormState>();
  final KeyField = TextEditingController();

  var vault_key = "";

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    setupVault() {
      showModalBottomSheet(
        backgroundColor: const Color.fromARGB(255, 25, 25, 25),
        showDragHandle: false,
        isDismissible: true,
        isScrollControlled: true,
        context: context, 
        builder: (BuildContext context) {
          return Padding(
            padding: EdgeInsets.only( bottom: MediaQuery.of(context).viewInsets.bottom),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter stateSetter) {
                return SizedBox(
                  height: 300,
                  child: SingleChildScrollView(
                    child: Form(
                        key: VaultKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text("Set a 4-digit key to open your vault. \nBe sure to remember this key as you will not be able to change it. "),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: ListTile(
                                title: TextFormField(
                                  obscureText: false,
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
                                    else {
                                      setState(() {
                                        vault_key = value;
                                      });
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (VaultKey.currentState!.validate()) {
                                  KeyField.clear();
                                  Future.delayed(Duration(milliseconds: 500), () {
                                      VaultData pushdata = VaultData(true, vault_key);
                                      db.writeVaultData(pushdata);
                                      Navigator.pop(context);
                                  });
                                }
                              },
                              style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Color.fromARGB(255, 140, 45, 20))),
                              child: const Text('Set Key', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ),
                );
              }
            ),
          );
        }
      );
    }

    Future<void> vaultAlert() async {
      final vault = await db.getVault();
      final active = vault.setup;
      if (active) {
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
                              else {
                                setState(() {
                                  vault_key = value;
                                });
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
                  child: const Text("Unlock Vault", style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    if (VaultKey.currentState!.validate()) {
                      KeyField.clear();
                      Future.delayed(Duration(milliseconds: 500), () async {
                        var vault_collection = await db.getVaultCollection();
                        if (context.mounted) {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => VaultPage(collection: vault_collection,))
                          );
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
      else {
        return showDialog<void>(
          context: context.mounted ? context: context,
          barrierDismissible: false, 
          builder: (BuildContext context) {
            return AlertDialog(
              content: const SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text("Vault is not set up. "),
                    Text("Set up vault now? ")
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                  onPressed: () => Navigator.pop(context, 'Cancel'),
                ),
                TextButton(
                  child: const Text("Set up", style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    Navigator.pop(context, 'Set up');
                    setupVault();
                  }
                ),
              ],
            );
          },
        );
      }
    }
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          "Welcome ${appState.userData["displayname"]}",
          style: TextStyle(fontFamily: "Monospace", fontSize: 30, fontWeight: FontWeight.bold),
        ),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, size: 40),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 80,
              child: const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                ),
                child: Text("Settings", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
              ),
            ),
            ListTile(
              title: const Text("Manage Account", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              leading: Icon(Icons.manage_accounts),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageAccount())
                );
              },
            ),
            ListTile(
              title: const Text("Privacy Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              leading: Icon(Icons.visibility_off),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PrivacySettings())
                );
              },
            ),
            ListTile(
              title: const Text("Notification Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              leading: Icon(Icons.edit_notifications),
              onTap: () {
                print("Notification Settings");
              },
            ),
            ListTile(
              title: const Text("User Guide", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              leading: Icon(Icons.info),
              onTap: () {
                print("App Information page");
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Card(
                color: Color.fromARGB(255, 140, 45, 20),
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  splashColor: Colors.deepOrange,
                  child: ListTile(
                    leading: Icon(Icons.lock),
                    title: Center(child: Text("My Vault", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                    trailing: SizedBox(width: 20),
                  ),
                  onTap: () {
                    vaultAlert();
                  },
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Text("No notifications yet"),
              TextButton(
                onPressed: () {
                  final encrypter = EncryptAES();
                  print("encrypting");
                  String teststring = "Test info";
                  var encrypted = encrypter.encryptData(teststring);
                  String encrypted64 = encrypted.base64;
                  print(encrypted64);
                  var decrypted = encrypter.decryptData(encrypted);
                  print(decrypted);
                }, 
                child: Text("Test encryption", style: TextStyle(color: Colors.white))
              )
            ],
          ),
        ),
      ),
    );

  }
}