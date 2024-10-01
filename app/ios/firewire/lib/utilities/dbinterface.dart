import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

// ------------------------------------------------------------------------------------
// User Data Class---------------------------------------------------------------------
// ------------------------------------------------------------------------------------ 
class UserData {
  final String? username;
  final String? displayname;
  final String? password;
  final String? token;
  final bool loggedin;
  final bool publicacct;
  final bool approvedcontacts;

  const UserData(this.username, this.displayname, this.password, this.token, this.loggedin, this.publicacct, this.approvedcontacts);

  Map<String, Object?> toJson() => {
    "username": username,
    "displayname": displayname,
    "password": password,
    "token": token,
    "loggedin": loggedin,
    "publicacct": publicacct,
    "approvedcontacts": approvedcontacts
  };

  factory UserData.fromJson(Map<String, Object?> json) => UserData(
    json["username"] as String?,
    json["displayname"] as String?,
    json["password"] as String?,
    json["token"] as String?,
    json["loggedin"] as bool,
    json["publicacct"] as bool,
    json["approvedcontacts"] as bool
  );
}

// ------------------------------------------------------------------------------------
// Vault Data Class---------------------------------------------------------------------
// ------------------------------------------------------------------------------------ 
class VaultData  {
  final bool setup;
  final String? key;

  const VaultData(this.setup, this.key);

  Map<String, Object?> toJson() => {
    "setup": setup,
    "key": key,
    "collection": []
  };

  factory VaultData.fromJson(Map<String, Object?> json) => VaultData(
    json["setup"] as bool,
    json["key"] as String?,
  );
}

// ------------------------------------------------------------------------------------
// Vault Item Class---------------------------------------------------------------------
// ------------------------------------------------------------------------------------ 
class VaultItem  {
  final String? username;
  final String? content;
  final bool is_media;

  const VaultItem(this.username, this.content, this.is_media);

  Map<String, Object?> toJson() => {
    "username": username,
    "content": content,
    "is_media": is_media
  };

  factory VaultItem.fromJson(Map<String, Object?> json) => VaultItem(
    json["username"] as String?,
    json["content"] as String?,
    json["is_media"] as bool,
  );
}

// ------------------------------------------------------------------------------------
// Database Handler Class--------------------------------------------------------------
// ------------------------------------------------------------------------------------ 
class DatabaseHandler {
  String path = "";

  DatabaseHandler() {
    setUpDatabase();
  }

  Future<void> setUpDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    path = "${dir.path}/localdata.json";
    File file = File(path);
    final exists = await file.exists();
    if (exists == false) {
      print("setting up database...");
      Map<String, dynamic> init_data = {
        "CurrentUser": {
          "loggedin": false,
          "username": "",
          "displayname": "",
          "password": "",
          "token": "",
          "publicacct": false,
          "approvedcontacts": false,
        },
        "Vault": {
          "setup": false,
          "vaultkey": "",
          "collection": []
        },
        "CryptKeys": []
      };

      String json_data = jsonEncode(init_data);
      file.writeAsString(json_data);
    }
  }

  Future<void> writeUserData(UserData data) async {
    File file = File(path);
    final new_data = data.toJson();
    final rawdata = await file.readAsString();
    final filedata = jsonDecode(rawdata) as Map<String, Object?>; 
    filedata["CurrentUser"] = new_data;
    String json_data = jsonEncode(filedata);
    file.writeAsString(json_data);
  }

  Future<UserData> readUserData() async {
    File file = File(path);
    final data = await file.readAsString();
    final filedata = jsonDecode(data) as Map<String, Object?>; 
    final userdata = filedata["CurrentUser"] as Map<String, Object?>;
    final parsedata = UserData.fromJson(userdata);

    return parsedata; 
  }

  Future<VaultData> getVault() async {
    File file = File(path);
    final data = await file.readAsString();
    final filedata = jsonDecode(data) as Map<String, Object?>; 
    final vaultdata = filedata["Vault"] as Map<String, Object?>;
    final parsedata = VaultData.fromJson(vaultdata);

    return parsedata; 
  }

  Future<void> writeVaultData(VaultData data) async {
    File file = File(path);
    final new_data = data.toJson();
    final rawdata = await file.readAsString();
    final filedata = jsonDecode(rawdata) as Map<String, Object?>; 
    filedata["Vault"] = new_data;
    String json_data = jsonEncode(filedata);
    file.writeAsString(json_data);
  }

  Future<List<VaultItem>> getVaultCollection() async {
    File file = File(path);
    List<VaultItem> vaultcollection = [];
    final data = await file.readAsString();
    final filedata = jsonDecode(data) as Map<String, Object?>; 
    final vaultdata = filedata["Vault"] as Map<String, Object?>;
    final collection = vaultdata["collection"] as List;
    for (var i=0; i<collection.length; i++) {
      final coll_item = collection[i];
      vaultcollection.add(VaultItem.fromJson(coll_item));
    }
    return vaultcollection;
  }

  Future<void> addVaultItem(VaultItem data) async {
    File file = File(path);
    final new_data = data.toJson();
    final rawdata = await file.readAsString();
    final filedata = jsonDecode(rawdata) as Map<String, Object?>; 
    final vaultdata = filedata["Vault"] as Map<String, Object?>;
    final collection = vaultdata["collection"] as List;
    collection.add(new_data);
    String json_data = jsonEncode(filedata);
    file.writeAsString(json_data);
  }

  Future<void> removeVaultItem(int idx) async {
    File file = File(path);
    final rawdata = await file.readAsString();
    final filedata = jsonDecode(rawdata) as Map<String, Object?>; 
    final vaultdata = filedata["Vault"] as Map<String, Object?>;
    final collection = vaultdata["collection"] as List;
    collection.removeAt(idx);
    String json_data = jsonEncode(filedata);
    file.writeAsString(json_data);
  }
}