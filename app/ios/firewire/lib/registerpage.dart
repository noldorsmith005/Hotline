// ------------------------------------------------------------------------------------
// Register Page ----------------------------------------------------------------------
// ------------------------------------------------------------------------------------ 
//import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
// Main page import
import './main.dart';



class Register extends StatefulWidget {

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool pending = false;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    final formKey = GlobalKey<FormState>();
    final displayField = TextEditingController();
    final userField = TextEditingController();
    final passField = TextEditingController();

    var set_displayname = "";
    var set_username = "";
    var set_password = "";


    Future register(String? displayname, String? username, String? password) async {
      pending = true;
      final response = await http.post(
        Uri.parse('${appState.SERVER}/users/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'App-Token': appState.APPTOKEN,
          //HttpHeaders.authorizationHeader: appState.APPTOKEN,
        },
        body: jsonEncode(<String, String?>{
          "displayname": displayname,
          "username": username,
          "password": password
        }),
      );
      
      if (response.statusCode == 200) {
        print(jsonDecode(response.body));
        var message = jsonDecode(response.body);
        if (message == "#VERIFIED#") {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Account Created. Please return to Login page. ")));
          }
        }
        else if (message == "#ERROR#") {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Password invalid. Please check parameters and try again. ")));
          }
        }
        else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Username unavailable. Please enter a different username and try again. ")));
          }
        }
      } 
      else {
        throw Exception('Server down.');
      }
      pending = false;
    }


    return Scaffold(
      appBar: AppBar(
          title: const Text("Create Account"),
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text("Your display name must be less than 20 characters. You will be able to change this later. "),
                SizedBox(width: 10, height: 10),
                TextFormField(
                  obscureText: false,
                  controller: displayField,
                  decoration: InputDecoration(
                                hintText: 'Enter Display Name',
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
                      set_displayname = value; 
                    }
                    return null;
                  },
                ),
                SizedBox(width: 10, height: 20),
                Text("Your username must be less than 20 characters. You will not be able to change this username once created."),
                SizedBox(width: 10, height: 10),
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
                      set_username = value; 
                    }
                    return null;
                  },
                ),
                SizedBox(width: 10, height: 20),
                Text("Your password must be less than 20 characters. Be sure to make your password strong and memorable. You will be able to change this password later."),
                SizedBox(width: 10, height: 10),
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
                      set_password = value; 
                    }
                    return null;
                  },
                ),
                SizedBox(width: 10, height: 20,),
                ElevatedButton(
                  style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Color.fromARGB(255, 140, 45, 20))),
                  child: const Text('Sign Up', style: TextStyle(color: Colors.white),),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      displayField.clear();
                      userField.clear();
                      passField.clear();
                      register(set_displayname, set_username, set_password); 
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

  }
}