// ------------------------------------------------------------------------------------
// Login Page -------------------------------------------------------------------------
// ------------------------------------------------------------------------------------ 
import 'dart:convert';
//import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
// Registry import
import './registerpage.dart';
// Main page import
import './main.dart';



class LogIn extends StatefulWidget {
  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  var registered = true;


  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    final formKey = GlobalKey<FormState>();
    final userField = TextEditingController();
    final passField = TextEditingController();
    

    Future authenicate(String? username, String? password) async {
      final response = await http.put(
        Uri.parse('${appState.SERVER}/users/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'App-Token': appState.APPTOKEN,
          //HttpHeaders.authorizationHeader: appState.APPTOKEN,
        },
        body: jsonEncode(<String, String?>{
          "username": username,
          "password": password,
        }),
      );
      
      if (response.statusCode == 200) {
        var userprofile = jsonDecode(response.body);
          if (userprofile == "#ERROR#") {
            print("Authentication failed: Invalid credentials. ");
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Login failed. Please check username and password and try again.")));
            }
          }
          if (userprofile == "#DEVICE#") {
            print("Authentication failed: Device error");
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("This account is already active on another device. ")));
            }
          }
          else {
            print("User authenticated");
            appState.Login(userprofile);
          }
      } else {
        throw Exception('Server down.');
      }
    }


    return Scaffold(
      appBar: AppBar(
          title: const Text("Login"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [ 
              Form(
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextFormField(
                      obscureText: false,
                      controller: userField,
                      decoration: InputDecoration(
                                    hintText: 'Enter Username',
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
                          appState.userData["username"] = value; 
                        }
                        return null;
                      },
                    ),
                    SizedBox(width: 10, height: 10,),
                    TextFormField(
                      obscureText: true,
                      controller: passField,
                      decoration: InputDecoration(
                                    hintText: 'Enter Password',
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
                          appState.userData["password"] = value; 
                        }
                        return null;
                      },
                    ),
                    SizedBox(width: 10, height: 20,),
                    ElevatedButton(
                      style: ButtonStyle(backgroundColor: WidgetStateProperty.all(const Color.fromARGB(255, 140, 45, 20))),
                      child: const Text('Log In', style: TextStyle(color: Colors.white),),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          userField.clear();
                          passField.clear();
                          authenicate(appState.userData["username"], appState.userData["password"]); 
                        }
                      },
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Register())
                  );
                }, 
                child: Text("Don't have an account? Sign up here. ", style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, decorationColor: Colors.blue),)
              )
            ],
          ),
        ),
      ),
    );
    
  }
}