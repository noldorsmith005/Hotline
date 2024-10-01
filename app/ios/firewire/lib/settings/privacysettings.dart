// ------------------------------------------------------------------------------------
// Privacy Settings Page --------------------------------------------------------------
// ------------------------------------------------------------------------------------ 
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
// Main import
import '../main.dart';


class PrivacySettings extends StatefulWidget {
  const PrivacySettings({super.key});

  @override
  State<PrivacySettings> createState() => _PrivacySettingsState();
}
class _PrivacySettingsState extends State<PrivacySettings> {
  var visibility = "Private";

  bool pending = false;
  bool newDisplaySet = false;


  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    Future editPrivacy(bool is_public, bool approved_contacts) async {
      pending = true;
      final response = await http.patch(
        Uri.parse('${appState.SERVER}/users/${appState.userData["username"]}/privacy'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'App-Token': appState.APPTOKEN,
          //HttpHeaders.authorizationHeader: appState.APPTOKEN,
          'User-Token': appState.userData["token"].toString()
        },
        body: jsonEncode(<String, dynamic>{
          "ispublic": is_public,
          "approvedcontacts": approved_contacts
        }),
      );

      if (response.statusCode == 200) {
        print(jsonDecode(response.body));
        var message = jsonDecode(response.body);
          if (message == "#VERIFIED#") {
            setState(() {
              newDisplaySet = true;
            });
            appState.setPrivacySettings(is_public, approved_contacts);
          }
          else {
            print("Request failed");
          }
      } else {
        throw Exception('Server down.');
      }
      pending = false;
    }


    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Text("Privacy Settings", style: TextStyle(fontWeight: FontWeight.bold)),
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
                    // Set account visibility 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(child: Text("Account visibility: ", style: TextStyle(fontSize: 18),))
                      ]
                    ),
                    SizedBox(height: 10),
                    Card(child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text("If set to private. People will still be able to create and interact with chats to your account, but your account will not be listed in public account searching. "),
                        ),
                        Row(
                          children: <Widget>[
                            Radio(
                              value: 'Public',
                              fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                                return Colors.deepOrange;
                              }),
                              groupValue: appState.publicAcct ? "Public" : "Private",
                              onChanged: (value) {
                                editPrivacy(true, appState.approvedContacts);
                              },
                            ),
                            Text('Public'),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Radio(
                              value: 'Private',
                              fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                                return Colors.deepOrange;
                              }),
                              groupValue: appState.publicAcct ? "Public" : "Private",
                              onChanged: (value) {
                                editPrivacy(false, appState.approvedContacts);
                              },
                            ),
                            Text('Private'),
                          ],
                        ),
                      ],
                    )),
                    SizedBox(height: 10),
                    // Set approved contacts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(child: Text("Additional Privacy: ", style: TextStyle(fontSize: 18),))
                      ]
                    ),
                    SizedBox(height: 10),
                    Card(child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text("Set who can add you to Groups and Direct Message you: "),
                        ),
                        Row(
                          children: <Widget>[
                            Radio(
                              value: 'Anyone',
                              fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                                return Colors.deepOrange;
                              }),
                              groupValue: appState.approvedContacts ? "My Contacts" : "Anyone",
                              onChanged: (value) {
                                editPrivacy(appState.publicAcct, false);
                              },
                            ),
                            Text('Anyone'),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Radio(
                              value: 'My Contacts',
                              fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                                return Colors.deepOrange;
                              }),
                              groupValue: appState.approvedContacts ? "My Contacts" : "Anyone",
                              onChanged: (value) {
                                editPrivacy(appState.publicAcct, true);
                              },
                            ),
                            Text('My Contacts'),
                          ],
                        ),
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