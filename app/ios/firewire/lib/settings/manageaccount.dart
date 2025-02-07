// ------------------------------------------------------------------------------------
// Manage Account Page ----------------------------------------------------------------
// ------------------------------------------------------------------------------------ 
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
// Main import
import '../main.dart';


class ManageAccount extends StatefulWidget {
  const ManageAccount({super.key});

  @override
  State<ManageAccount> createState() => _ManageAccountState();
}
class _ManageAccountState extends State<ManageAccount> {
  final passKey = GlobalKey<FormState>();
  final displayKey = GlobalKey<FormState>();
  final displayField = TextEditingController();
  final passField = TextEditingController();

  var new_password = "";
  var new_displayname = "";

  bool pending = false;
  bool showDisplayEdit = false;
  bool showPassEdit = false;
  bool showPassword = false;
  bool showNewPassword = false;
  bool newPasswordSet = false;
  bool newDisplaySet = false;

  File? _file;

  // static Future<void> closeApp({bool? animated}) async {
  //   await SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop', animated);
  // }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    Future<String> fetchProfpic() async {
      pending = true;
      final response = await http.get(
        Uri.parse('${appState.SERVER}/users/${appState.userData["username"]}/profpic'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'App-Token': appState.APPTOKEN,
          //HttpHeaders.authorizationHeader: appState.APPTOKEN,
          'User-Token': appState.userData["token"].toString()
        }
      );

      if (response.statusCode == 200) {
        var image = jsonDecode(response.body);
        String profpic = image.toString();
        pending = false;
        return profpic;
      } else {
        throw Exception('Server down.');
      }
    }

    Future updateProfpic(File newpic) async {
      pending = true;
      var image_bytes = await newpic.readAsBytes();
      String image_data = base64Encode(image_bytes);
      final response = await http.patch(
        Uri.parse('${appState.SERVER}/users/${appState.userData["username"]}/profpic'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'App-Token': appState.APPTOKEN,
          //HttpHeaders.authorizationHeader: appState.APPTOKEN,
          'User-Token': appState.userData["token"].toString()
        },
        body: jsonEncode(<String, String?>{
          "imagedata": image_data
        }),
      );

      if (response.statusCode == 200) {
        setState(() {});
      } else {
        throw Exception('Server down.');
      }
    }

    Future setPass(String? password) async {
      pending = true;
      final response = await http.patch(
        Uri.parse('${appState.SERVER}/users/${appState.userData["username"]}/password'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'App-Token': appState.APPTOKEN,
          //HttpHeaders.authorizationHeader: appState.APPTOKEN,
          'User-Token': appState.userData["token"].toString()
        },
        body: jsonEncode(<String, String?>{
          "password": password
        }),
      );

      if (response.statusCode == 200) {
        print(jsonDecode(response.body));
        var message = jsonDecode(response.body);
          if (message == "#VERIFIED#") {
            setState(() {
              newPasswordSet = true;
            });
          }
          else {
            print("Request failed");
          }
      } else {
        throw Exception('Server down.');
      }
    }

    Future editProfile(String? newdisplay) async {
      pending = true;
      final response = await http.patch(
        Uri.parse('${appState.SERVER}/users/${appState.userData["username"]}/profile'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'App-Token': appState.APPTOKEN,
          //HttpHeaders.authorizationHeader: appState.APPTOKEN,
          'User-Token': appState.userData["token"].toString()
        },
        body: jsonEncode(<String, dynamic>{
          "displayname": newdisplay,
        }),
      );

      if (response.statusCode == 200) {
        print(jsonDecode(response.body));
        var message = jsonDecode(response.body);
          if (message == "#VERIFIED#") {
            setState(() {
              newDisplaySet = true;
            });
          }
          else {
            print("Request failed");
          }
      } else {
        throw Exception('Server down.');
      }
    }

    Future deleteAccount() async {
      pending = true;
      final response = await http.delete(
        Uri.parse('${appState.SERVER}/users/${appState.userData["username"]}'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'App-Token': appState.APPTOKEN,
          //HttpHeaders.authorizationHeader: appState.APPTOKEN,
          'User-Token': appState.userData["token"].toString()
        },
      );

      if (response.statusCode == 200) {
        print(jsonDecode(response.body));
        var message = jsonDecode(response.body);
          if (message == "#VERIFIED#") {
            print("Account deleted");
            if (context.mounted) {
              Navigator.pop(context);
              appState.Logout(0);
            }
            else {
              exit(0);
            }
          }
          else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Something went wrong. Please refresh the page and try again. ")));
            }
            pending = false;
          }
      } else {
        throw Exception('Server down.');
      }
    }

    Future<void> deleteAlert() async {
      return showDialog<void>(
        context: context,
        barrierDismissible: false, 
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("WARNING"),
            content: const SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text("This action is permanent. Deleting an account results in all associated data being lost. You will not be able to recover this account. "),
                  Text("Are you sure you want to continue? "),
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
                  Navigator.pop(context, 'Delete');
                  deleteAccount();
                },
              ),
            ],
          );
        },
      );
    }

    editProfpic(File profpic) {
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
                        updateProfpic(profpic);
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
        editProfpic(_file as File);

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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Text("Manage Account", style: TextStyle(fontWeight: FontWeight.bold)),
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
              SizedBox(
                width: 20,
                height: 20,
              ),
              Center(
                child: Column(
                  children: [
                    // Profile Picture ____________________________________________________________
                    FutureBuilder(
                      future: fetchProfpic(),
                      builder: (context, data) {
                        if (data.hasData) {
                          return GestureDetector(
                            onTap: () {
                              pickImage();
                            },
                            child: CircleAvatar(
                              radius: 75,
                              backgroundColor: Colors.grey,
                              //backgroundImage: AssetImage("/assets/images/defaultprof.png"),
                              foregroundImage: MemoryImage(base64Decode(data.data as String)),
                            ),
                          );
                        }
                        else if (data.hasError) {
                          return Column(
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
                            ]
                          );
                        }
                        else {
                          return Center(
                            child: CircularProgressIndicator(color: const Color.fromARGB(255, 15, 70, 110),),    
                          );
                        }
                      }
                    ),
                    SizedBox(width: 10, height: 20),
                    // Username ___________________________________________________________________
                    Card(child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          title: Text("Username: ${appState.userData["username"]}"),
                        ),
                      ],
                    )),
                    // Display Name ___________________________________________________________________
                    Card(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          title: Text("Displayname: ${appState.userData["displayname"]}"),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              child: Text(showDisplayEdit ? "Hide" : "Edit", style: TextStyle(color: Colors.blue),),
                              onPressed: () {
                                setState(() {
                                  showDisplayEdit = !showDisplayEdit;
                                });
                              },
                            )
                          ],
                        ),
                        // New Display Name Field
                        showDisplayEdit ?
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Form(
                            key: displayKey,
                            child: Column(
                              children: [
                                Text("Your Display Name is the main name visible on your profile. "),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: ListTile(
                                    title: TextFormField(
                                      obscureText: false,
                                      controller: displayField,
                                      decoration: InputDecoration(
                                                    hintText: 'New Display Name',
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
                                            new_displayname = value;
                                          });
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    if (displayKey.currentState!.validate()) {
                                      displayField.clear();
                                      editProfile(new_displayname);
                                      Future.delayed(Duration(milliseconds: 1500), () {
                                        if (newDisplaySet == true) {
                                          appState.setDisplay(new_displayname);
                                        }
                                        else {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Update failed. Please try again.")));
                                          }
                                        }
                                        pending = false;
                                      });
                                    }
                                  },
                                  style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Color.fromARGB(255, 140, 45, 20))),
                                  child: const Text('Update', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        ): Container(),
                      ],
                    )),
                    // Password ___________________________________________________________________
                    Card(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          title: showPassword ? Text("Password: ${appState.userData["password"]}") : Text("Password: ********"),
                          trailing: IconButton(
                            icon: showPassword ? Icon(Icons.visibility) : Icon(Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                showPassword = !showPassword;
                              });
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              child: Text(showPassEdit ? "Hide" : "Edit", style: TextStyle(color: Colors.blue),),
                              onPressed: () {
                                setState(() {
                                  showPassEdit = !showPassEdit;
                                });
                              },
                            )
                          ],
                        ),
                        // New Password Field
                        showPassEdit ?
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Form(
                            key: passKey,
                            child: Column(
                              children: [
                                Text("New password must be less than 20 characters. Be sure to make your password strong and memorable."),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: ListTile(
                                    trailing: IconButton(
                                                icon: showNewPassword ? Icon(Icons.visibility): Icon(Icons.visibility_off),
                                                onPressed: () {
                                                  setState(() {
                                                    showNewPassword = !showNewPassword;
                                                  });
                                                },
                                              ),
                                    title: TextFormField(
                                      obscureText: showNewPassword ? false : true,
                                      controller: passField,
                                      decoration: InputDecoration(
                                                    hintText: 'Enter new Password',
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
                                            new_password = value;
                                          });
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    if (passKey.currentState!.validate()) {
                                      passField.clear();
                                      setPass(new_password); 
                                      Future.delayed(Duration(milliseconds: 1500), () {
                                        if (newPasswordSet == true) {
                                          appState.setPassword(new_password);
                                        }
                                        else {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Password update failed. Please try again.")));
                                          }
                                        }
                                        pending = false;
                                      });
                                    }
                                  },
                                  style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Color.fromARGB(255, 140, 45, 20))),
                                  child: const Text('Update', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        ): Container(),
                      ],
                    )),
                    Card(
                      color: Colors.red,
                      clipBehavior: Clip.hardEdge,
                      child: InkWell(
                        splashColor: Color.fromARGB(255, 115, 30, 25),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Row(children: [
                            Icon(Icons.delete_forever),
                            SizedBox(width: 20, height: 15,),
                            Text("DELETE ACCOUNT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],),
                        ),
                        onTap: () {
                          deleteAlert();
                        },
                      ),
                    ),
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