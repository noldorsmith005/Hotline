from flask import Flask, request, jsonify
from flask_cors import CORS
import random
import json
import base64
import time
import os


app = Flask(__name__)
CORS(app, resources={r"*": {"origins": "*"}})

CHARMAP = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "~", "!", "@", "#", "^", "&", "*", "(", ")", "-", "_", "=", "+", "[", "]", "{", "}", "|", ";", ":", ",", ".", "<", ">", "/", "?"]

AUTHENICATION = "#VERIFIED#"
ERROR = "#ERROR#"
DB = "database.json"

APPTOKEN = "ZQM.FS(^f!|WeKA&paZ5].*+u[>efN#s~Z~du98)0:OnVX@),cdRJG1(x|zVn3tC*/EC,)Rj,q,G)<A=U-P[[<i]tY3fTnvxdCC5~J0e#hOlafCG" #111
ADMINTOKEN = "i&if*M>4?ua3PSD3v9S&m6~:vGt|BxXEb>zX1x+wML>+CFr:d_7IH0m=j<gq<=fhAa6Ch<cS[F.QE5Ur_s!#DOXO=hA;h6DI!7xT{#{IEogK}_A,ri8a/6X*h+B^)=2qhH,Un-oZCLAF.7{_RI}5:&?ZQTG1l&Je&s-~eqtoTlDgB!Y#XZ07+Quht1tuZ/DuZ[jrA75t90#w|k8Ub_4#U.,0sOGiTD#h7fOML/~V{aMsnR~VA9~eBn48501U-xmFPTRJ6;.h1IDt4uikcv<ntQk(oxD|!k!.?FjrjjoSxw})B5SE+4_Anw[zkW~l8ygO,TW)/_iWMiF<n2MZ5&SjG*m&VQY1mH5vmeW-39-(AIe<6?z}OGN}G>m3/(me.W?rt;Gy31aZJcYrrrZsx8a+PB}L0-3[CBx@BMEW{1Gx!DScJ]&LIXlfOY*Lu!FkPTA1*PiKaS~c5bxxcD:H;y*[}weB|{)rn}cW;381Kb*~&d{,|hcG+6N0n+6kY3?=9t^y;4>MxC,mc+?~-X4LJ*+3O{3xh1Vv!UtsPt*gw)MI>*K{~YUus^|jM=B>hg_3n?y(y@+R07EtJ[9pjX<=jJ9hDFb^b~*(=Z;!N<bXrMZyB00C),RUtTO7QFy[)^Pd3W#bZJX:=~tyRp.aI=-q(1?z=PduU5.@/NpJAbR]H,ebEk9Mi/5_d.6qp4&DbHy+Y6>JTGKvhv^mwm^i4uD:;hT7<Z]~}RgNepIjwggdSG,nS#GLn>o(LlIn9<=OQg(tN:ThTr2zK/f]N1lc2_hw*TrFzexnCKjsrPS4R=}2Rx4z0iv02TeLVPxp~Zf[M78F8OcBw6@5NAyS[;^,T=RrqwD6Dd=?fwhfw7/CAbQB-9!va}koMrkY4i,7xG]b#NlUEZTq9x9Of<yrfLU)aM>PLb>*cuy#/_vybS7}&(^^1nU^&<C9M1/??rhS:=.c_fdXV+6g^6Ma9nL2uqa9<BIeHHDE*i+tk9Zo}w=iWEnU}o!_" #999

Admin = ["172.66.2.214"]


#--------------------------------------### Server Functions ###--------------------------------------#
def validate(username):
    with open(DB, 'r') as file:
        data = json.load(file)
        users = data["Users"]
        for user in users:
            if username == user["username"]:
                return True
        
        return False
    
def newToken():
    i = 0
    token = ""
    while i <= 100:
        idx = random.randint(0, 87)
        token = token + CHARMAP[idx]

        i += 1

    return token
    
def getProfile(username):
    with open(DB, 'r') as file:
        data = json.load(file)
        users = data["Users"]

        profile = {
            "username": "",
            "displayname": "",
            "profpic": ""
        }

        for user in users:
            if user["username"] == username:
                profile["username"] = user["username"]
                profile["displayname"] = user["displayname"]
                path = user["profpic"]
                with open(path, 'rb') as image_file:
                    image_file.seek(0)
                    image_data = image_file.read()
                    image_data = base64.b64encode(image_data).decode('ascii')
                profile["profpic"] = image_data
            
        return profile
    
def searchString(base, filter):
    base = list(base.lower())
    filter = list(filter.lower())
    matched = []
    char = 0
    subchar = 0
    while char < len(base) and subchar < len(filter):
        if base[char] == filter[subchar]:
            matched.append(filter[subchar])
            char += 1
            subchar += 1
        else :
            if len(matched) > 0:
                matched = []
            char += 1
        if matched == filter:
            return True

    return False

def destroyMessages(id):
    with open(DB, 'r') as file:
        data = json.load(file)
        chats = data["ChatStreams"]
        for chat in chats:
            if chat["id"] == id:
                messages = chat["messages"]
    message_list = []
    index = 0
    for message in messages:
        if index < 25:
            if message["media"] == True:
                try:
                    os.remove(message["content"])
                except:
                    print("error destroying file")

                path = message["content"].split('/')
                suffix = path[4].split('.')
                id = suffix[0]
                id = int(id)
                chat["attachedids"].remove(id)

                with open(DB, 'w') as file:
                    file.seek(0)
                    json.dump(data, file, indent = 4, ensure_ascii=False)
        else :
            message_list.append(message)


    return message_list
   
#----------------------------------------------------------------------------#
#--------------------------------------### Routing Protocols ###--------------------------------------#
#----------------------------------------------------------------------------#

#----------------------------### Home Route (Browser Display) (Admin Access Only) ###----------------------------#
@app.route("/", methods=["GET"])
def home():
    ip_addr = request.remote_addr
    if ip_addr in Admin:
        db = open(DB)
        data = json.load(db)
        db.close()

        return data, 200
    else :
        messsage = f"Unauthorized request to admin-token server functionality from {ip_addr}"
        print(messsage)
        return jsonify(messsage), 200

#--------------------------------------### Log In ###--------------------------------------#
@app.route("/users/", methods=["PUT"]) 
def login():
    ip_addr = request.remote_addr
    data = request.get_json()
    username = data["username"]
    password = data["password"]
    apptoken = request.headers.get("App-Token")

    new_session = {
        "user": "",
        "addr": "",
        "token": ""
    }

    user_data = {
        "public": False,
        "approvedcontacts": False,
        "username": "",
        "displayname": "",
        "password": "",
        "token": ""
    }

    if apptoken == APPTOKEN:
        response = ERROR
        with open(DB, 'r') as file:
            data = json.load(file)
            users = data["Users"]
            Sessions = data["Sessions"]
            for session in Sessions:
                if session["user"] == username:
                    response = jsonify("#DEVICE#")
                    return response, 200
            for user in users:
                if user["username"] == username and user["password"] == password:
                    new_session["user"] = username
                    new_session["addr"] = ip_addr
                    new_session["token"] = newToken()
                    Sessions.append(new_session)

                    with open(DB, 'w') as file:
                        file.seek(0)
                        json.dump(data, file, indent = 4, ensure_ascii=False)

                    user_data["public"] = user["public"]
                    user_data["approvedcontacts"] = user["approvedcontacts"]
                    user_data["username"] = user["username"]
                    user_data["displayname"] = user["displayname"]
                    user_data["password"] = user["password"]
                    user_data["token"] = new_session["token"]

                    response = jsonify(user_data)
                    return response, 200
            
            response = jsonify(ERROR)
            return response, 200

    else :
        print(f"Unauthorized server request detected from {ip_addr}. Invalid app token")
        return jsonify(ERROR), 200

#--------------------------------------### Create Account ###--------------------------------------#
@app.route("/users/", methods=["POST"]) 
def register():
    ip_addr = request.remote_addr
    data = request.get_json()
    displayname = data["displayname"]
    username = data["username"]
    password = data["password"]
    apptoken = request.headers.get("App-Token")

    new_user = {
        "username": "",
        "displayname": "",
        "password": "",
        "public": False,
        "contacts": []
    }

    if apptoken == APPTOKEN:
        with open(DB, 'r') as file:
            data = json.load(file)
            users = data["Users"]
            for user in users:
                if user["username"] == username:
                    response = "Username not available. "
                    response = jsonify(response)
                    return response, 200
            
            if len(password) < 20:
                response = AUTHENICATION
                new_user["displayname"] = displayname
                new_user["username"] = username
                new_user["password"] = password
                users.append(new_user)

                with open(DB, 'w') as file:
                    file.seek(0)
                    json.dump(data, file, indent = 4, ensure_ascii=False)
            else :
                response = ERROR
            

        response = jsonify(response)
        return response, 200

    else :
        print(f"Unauthorized server request detected from {ip_addr}. Invalid app token")
        return jsonify(ERROR), 200
    
#--------------------------------------### Load Profile Picture ###--------------------------------------#
@app.route("/users/<username>/profpic", methods=["GET"]) 
def fetchProfpic(username):
    ip_addr = request.remote_addr
    apptoken = request.headers.get("App-Token")
    usertoken = request.headers.get("User-Token")

    if apptoken == APPTOKEN:
        with open(DB, 'r') as file:
            data = json.load(file)
            users = data["Users"]
            Sessions = data["Sessions"]
            for session in Sessions:
                if session["token"] == usertoken:
                    for user in users:
                        if user["username"] == username:
                            path = user["profpic"]

                            with open(path, 'rb') as image_file:
                                image_file.seek(0)
                                image_data = image_file.read()
                                image_data = base64.b64encode(image_data).decode('ascii')

                            response = jsonify(image_data)
                            return response, 200

                    response = jsonify(ERROR)
                    return response, 200
        
            print(f"Invalid user token from {ip_addr}")
            return jsonify(ERROR), 200
    
    else :
        print(f"Unauthorized server request detected from {ip_addr}. Invalid app token")
        return jsonify(ERROR), 200
    
#--------------------------------------### Update Profile Picture ###--------------------------------------#
@app.route("/users/<username>/profpic", methods=["PATCH"]) 
def updateProfpic(username):
    ip_addr = request.remote_addr
    data = request.get_json()
    image_data = data["imagedata"]
    apptoken = request.headers.get("App-Token")
    usertoken = request.headers.get("User-Token")

    if apptoken == APPTOKEN:
        with open(DB, 'r') as file:
            data = json.load(file)
            users = data["Users"]
            Sessions = data["Sessions"]
            for session in Sessions:
                if session["token"] == usertoken:
                    for user in users:
                        if user["username"] == username:
                            path = f"./assets/profilepics/{username}.png"
                            user["profpic"] = path

                            with open(path, 'wb') as image_file:
                                image_file.seek(0)
                                image_data = base64.b64decode(image_data)
                                image_file.write(image_data)

                            with open(DB, 'w') as file:
                                file.seek(0)
                                json.dump(data, file, indent = 4, ensure_ascii=False)

                            response = jsonify(AUTHENICATION)
                            return response, 200
                        
                    response = jsonify(ERROR)
                    return response, 200
        
            print(f"Invalid user token from {ip_addr}")
            return jsonify(ERROR), 200
    
    else :
        print(f"Unauthorized server request detected from {ip_addr}. Invalid app token")
        return jsonify(ERROR), 200
        
#--------------------------------------### Edit Profile ###--------------------------------------#
@app.route("/users/<username>/profile", methods=["PATCH"]) 
def setProfile(username):
    ip_addr = request.remote_addr
    data = request.get_json()
    new_displayname = data["displayname"]
    apptoken = request.headers.get("App-Token")
    usertoken = request.headers.get("User-Token")

    if apptoken == APPTOKEN:
        with open(DB, 'r') as file:
            data = json.load(file)
            users = data["Users"]
            Sessions = data["Sessions"]
            for session in Sessions:
                if session["token"] == usertoken:
                    with open(DB, 'r') as file:
                        for user in users:
                            if user["username"] == username:
                                user["displayname"] = new_displayname

                                response = AUTHENICATION
                                with open(DB, 'w') as file:
                                    file.seek(0)
                                    json.dump(data, file, indent = 4, ensure_ascii=False)

                    response = jsonify(response)
                    return response, 200
        
            print(f"Invalid user token from {ip_addr}")
            return jsonify(ERROR), 200
    
    else :
        print(f"Unauthorized server request detected from {ip_addr}. Invalid app token")
        return jsonify(ERROR), 200
    
#--------------------------------------### Edit Privacy Settings ###--------------------------------------#
@app.route("/users/<username>/privacy", methods=["PATCH"]) 
def setPrivacy(username):
    ip_addr = request.remote_addr
    data = request.get_json()
    is_public = data["ispublic"]
    approved_contacts = data["approvedcontacts"]
    apptoken = request.headers.get("App-Token")
    usertoken = request.headers.get("User-Token")

    if apptoken == APPTOKEN:
        with open(DB, 'r') as file:
            data = json.load(file)
            users = data["Users"]
            Sessions = data["Sessions"]
            for session in Sessions:
                if session["token"] == usertoken:
                    with open(DB, 'r') as file:
                        for user in users:
                            if user["username"] == username:
                                if isinstance(is_public, bool):
                                    user["public"] = is_public
                                if isinstance(approved_contacts, bool):
                                    user["approvedcontacts"] = approved_contacts

                                response = AUTHENICATION
                                with open(DB, 'w') as file:
                                    file.seek(0)
                                    json.dump(data, file, indent = 4, ensure_ascii=False)

                    response = jsonify(response)
                    return response, 200
        
            print(f"Invalid user token from {ip_addr}")
            return jsonify(ERROR), 200
    
    else :
        print(f"Unauthorized server request detected from {ip_addr}. Invalid app token")
        return jsonify(ERROR), 200

#--------------------------------------### Set New Password ###--------------------------------------#
@app.route("/users/<username>/password", methods=["PATCH"]) 
def setPass(username):
    ip_addr = request.remote_addr
    data = request.get_json()
    new_pass = data["password"]
    apptoken = request.headers.get("App-Token")
    usertoken = request.headers.get("User-Token")

    if apptoken == APPTOKEN:
        with open(DB, 'r') as file:
            data = json.load(file)
            users = data["Users"]
            Sessions = data["Sessions"]
            for session in Sessions:
                if session["token"] == usertoken:
                    if len(new_pass) < 20:
                        with open(DB, 'r') as file:
                            for user in users:
                                if user["username"] == username:
                                    user["password"] = new_pass
                                    response = AUTHENICATION
                                    with open(DB, 'w') as file:
                                        file.seek(0)
                                        json.dump(data, file, indent = 4, ensure_ascii=False)
                    else :
                        response = ERROR

                    response = jsonify(response)
                    return response, 200
        
            print(f"Invalid user token from {ip_addr}")
            return jsonify(ERROR), 200
    
    else :
        print(f"Unauthorized server request detected from {ip_addr}. Invalid app token")
        return jsonify(ERROR), 200
    
#--------------------------------------### Delete Account ###--------------------------------------#
@app.route("/users/<username>", methods=["DELETE"]) 
def deleteAccount(username):
    ip_addr = request.remote_addr
    apptoken = request.headers.get("App-Token")

    if apptoken == APPTOKEN:
        with open(DB, 'r') as file:
            data = json.load(file)
            users = data["Users"]
            chats = data["ChatStreams"]
            for user in users:
                if user["username"] == username:
                    for chat in chats:
                        for chat_user in chat["users"]:
                            if chat_user == username:
                                chat["users"].remove(chat_user)
                    users.remove(user)

                    with open(DB, 'w') as file:
                        file.seek(0)
                        json.dump(data, file, indent = 4, ensure_ascii=False)
            else :
                response = ERROR
            

        response = jsonify(AUTHENICATION)
        return response, 200

    else :
        print(f"Unauthorized server request detected from {ip_addr}. Invalid app token")
        return jsonify(ERROR), 200
    
#--------------------------------------### Search Profiles ###--------------------------------------#
@app.route("/search/<filter>", methods=["GET"]) 
def searchProfiles(filter):
    ip_addr = request.remote_addr
    filter = filter.lower()
    apptoken = request.headers.get("App-Token")
    usertoken = request.headers.get("User-Token")

    profile_list = []

    if apptoken == APPTOKEN:
        with open(DB, 'r') as file:
            data = json.load(file)
            users = data["Users"]
            Sessions = data["Sessions"]
            for session in Sessions:
                if session["token"] == usertoken:
                    for user in users:
                        if searchString(user["username"], filter) == True or searchString(user["displayname"], filter) == True:
                            if (user["public"] == True):
                                profile_list.append(getProfile(user["username"]))
                        
                    response = jsonify(profile_list)
                    return response, 200
            
            print(f"Invalid user token from {ip_addr}")
            return jsonify(ERROR), 200
    
    else :
        print(f"Unauthorized server request detected from {ip_addr}. Invalid app token")
        return jsonify(ERROR), 200

#--------------------------------------### Fetch Contacts ###--------------------------------------#
@app.route("/users/<username>/contacts", methods=["GET"]) 
def fetchContacts(username):
    ip_addr = request.remote_addr
    apptoken = request.headers.get("App-Token")
    usertoken = request.headers.get("User-Token")

    contact_list = []

    if apptoken == APPTOKEN:
        with open(DB, 'r') as file:
            data = json.load(file)
            users = data["Users"]
            Sessions = data["Sessions"]
            for session in Sessions:
                if session["token"] == usertoken:
                    for user in users:
                        if user["username"] == username:
                            contacts = user["contacts"]
                            for contact in contacts:
                                contact_list.append(getProfile(contact))

                            response = jsonify(contact_list)
                            return response, 200
            
            print(f"Invalid user token from {ip_addr}")
            return jsonify(ERROR), 200
    
    else :
        print(f"Unauthorized server request detected from {ip_addr}. Invalid app token")
        return jsonify(ERROR), 200
    
#--------------------------------------### Add Contact ###--------------------------------------#
@app.route("/users/<username>/contacts", methods=["POST"]) 
def addContact(username):
    ip_addr = request.remote_addr
    data = request.get_json()
    contactuser = data["username"]
    apptoken = request.headers.get("App-Token")
    usertoken = request.headers.get("User-Token")

    if apptoken == APPTOKEN:
        with open(DB, 'r') as file:
            data = json.load(file)
            users = data["Users"]
            Sessions = data["Sessions"]
            for session in Sessions:
                if session["token"] == usertoken:
                    if validate(contactuser) == True:
                        for user in users:
                            if user["username"] == username:
                                user["contacts"].append(contactuser)

                                with open(DB, 'w') as file:
                                    file.seek(0)
                                    json.dump(data, file, indent = 4, ensure_ascii=False)
                                
                                return jsonify(AUTHENICATION), 200
                    else :
                        return jsonify(ERROR), 200
            
            print(f"Invalid user token from {ip_addr}")
            return jsonify(ERROR), 200
    
    else :
        print(f"Unauthorized server request detected from {ip_addr}. Invalid app token")
        return jsonify(ERROR), 200

#--------------------------------------### Remove Contact ###--------------------------------------#
@app.route("/users/<username>/contacts/<contactuser>", methods=["DELETE"]) 
def deleteContact(username, contactuser):
    ip_addr = request.remote_addr
    apptoken = request.headers.get("App-Token")
    usertoken = request.headers.get("User-Token")

    if apptoken == APPTOKEN:
        with open(DB, 'r') as file:
            data = json.load(file)
            users = data["Users"]
            Sessions = data["Sessions"]
            for session in Sessions:
                if session["token"] == usertoken:
                    for user in users:
                        if user["username"] == username:
                            for contact in user["contacts"]:
                                if contact == contactuser:
                                    user["contacts"].remove(contact)

                                    with open(DB, 'w') as file:
                                        file.seek(0)
                                        json.dump(data, file, indent = 4)
                                    
                                    return jsonify(AUTHENICATION), 200
                        
                            return jsonify(ERROR), 200    
                    return jsonify(ERROR), 200
            
            print(f"Invalid user token from {ip_addr}")
            return jsonify(ERROR), 200
    
    else :
        print(f"Unauthorized server request detected from {ip_addr}. Invalid app token")
        return jsonify(ERROR), 200

#--------------------------------------### Fetch Chats ###--------------------------------------#
@app.route("/users/<username>/groups", methods=["GET"]) 
def fetchGroups(username):
    ip_addr = request.remote_addr
    apptoken = request.headers.get("App-Token")
    usertoken = request.headers.get("User-Token")

    if apptoken == APPTOKEN:
        with open(DB, 'r') as file:
            data = json.load(file)
            chats = data["ChatStreams"]
            Sessions = data["Sessions"]
            for session in Sessions:
                if session["token"] == usertoken:
                    chat_list = []

                    for chat in chats:
                        if chat["group"] == True:
                            if username in chat["users"]:
                                chat_data = {
                                    "id": "",
                                    "selfdestruct": False,
                                    "picture": "",
                                    "name": "",
                                    "admins": [],
                                    "users": []
                                }
                                chat_data["id"] = chat["id"]
                                chat_data["selfdestruct"] = chat["selfdestructing"]
                                chat_data["name"] = chat["name"]
                                chat_data["admins"] = chat["admins"]

                                path = chat["picture"]
                                with open(path, 'rb') as image_file:
                                    image_file.seek(0)
                                    image_data = image_file.read()
                                    chat_data["picture"] = base64.b64encode(image_data).decode('ascii')

                                chat_data["users"].append(username)
                                for user in chat["users"]:
                                    if user != username:
                                        chat_data["users"].append(user)
                                chat_list.append(chat_data)

                    response = jsonify(chat_list)
                    return response, 200
            
            print(f"Invalid user token from {ip_addr}")
            return jsonify(ERROR), 200
    
    else :
        print(f"Unauthorized server request detected from {ip_addr}. Invalid app token")
        return jsonify(ERROR), 200

@app.route("/users/<username>/dms", methods=["GET"]) 
def fetchChats(username):
    ip_addr = request.remote_addr
    apptoken = request.headers.get("App-Token")
    usertoken = request.headers.get("User-Token")

    if apptoken == APPTOKEN:
        with open(DB, 'r') as file:
            data = json.load(file)
            chats = data["ChatStreams"]
            Sessions = data["Sessions"]
            for session in Sessions:
                if session["token"] == usertoken:
                    chat_list = []

                    for chat in chats:
                        if chat["group"] == False:
                            if username in chat["users"]:
                                chat_data = {
                                    "id": "",
                                    "selfdestruct": False,
                                    "picture": "",
                                    "name": "",
                                    "admins": [],
                                    "users": []
                                }
                                chat_data["id"] = chat["id"]
                                chat_data["selfdestruct"] = chat["selfdestructing"]
                                for user in chat["users"]:
                                    if user != username:
                                        userprofile = getProfile(user)
                                        chat_data["name"] = userprofile["displayname"]
                                        chat_data["picture"] = userprofile["profpic"]
                                chat_data["admins"] = chat["admins"]
                                chat_data["users"] = chat["users"]
                                chat_list.append(chat_data)

                    response = jsonify(chat_list)
                    return response, 200
                
            print(f"Invalid user token from {ip_addr}")
            return jsonify(ERROR), 200
    
    else :
        print(f"Unauthorized server request detected from {ip_addr}. Invalid app token")
        return jsonify(ERROR), 200

#--------------------------------------### Create Chat ###--------------------------------------#
@app.route("/chatstreams/groups/<username>", methods=["POST"]) 
def createGroup(username):
    ip_addr = request.remote_addr
    chat_data = request.get_json()
    chat_name = chat_data["name"]
    new_users = chat_data["users"]
    apptoken = request.headers.get("App-Token")
    usertoken = request.headers.get("User-Token")

    if apptoken == APPTOKEN:
        with open(DB, 'r') as file:
            data = json.load(file)
            chats = data["ChatStreams"]
            Sessions = data["Sessions"]
            for session in Sessions:
                if session["token"] == usertoken:

                    new_chat = {
                        "id": 0,
                        "group": True,
                        "selfdestructing": False,
                        "picture": "",
                        "name": "",
                        "admins": [username],
                        "users": [],
                        "attachedids": [],
                        "messages": []
                    }

                    Ids = data["IDS"]
                    id = random.randint(0, 100)
                    while id in Ids:
                        id = random.randint(0, 100)

                    Ids.append(id)

                    if (not os.path.exists(f"./assets/chat_media/{id}")):
                        os.mkdir(f"./assets/chat_media/{id}")

                    source = "./assets/default.png"
                    with open(source, 'rb') as image_file:
                        image_file.seek(0)
                        default_data = image_file.read()

                        path = f"./assets/chat_media/{id}/profile.png"
                        with open(path, 'wb') as image_file:
                            image_file.seek(0)
                            image_file.write(default_data)

                    new_chat["id"] = id
                    new_chat["picture"] = path
                    new_chat["name"] = chat_name
                    new_chat["users"] = new_users

                    for user in new_users:
                        if validate(user) != True:
                            response = jsonify(ERROR)
                            return response, 200

                    chats.append(new_chat)

                    with open(DB, 'w') as file:
                        file.seek(0)
                        json.dump(data, file, indent = 4, ensure_ascii=False)

                    response = jsonify(AUTHENICATION)
                    return response, 200
                
            print(f"Invalid user token from {ip_addr}")
            return jsonify(ERROR), 200
                
    else :
        print(f"Unauthorized server request detected from {ip_addr}. Invalid app token")
        return jsonify(ERROR), 200

@app.route("/chatstreams/dms/<username>", methods=["POST"]) 
def createChat(username):
    ip_addr = request.remote_addr
    chat_data = request.get_json()
    new_users = chat_data["users"]
    apptoken = request.headers.get("App-Token")
    usertoken = request.headers.get("User-Token")

    if apptoken == APPTOKEN:
        with open(DB, 'r') as file:
            data = json.load(file)
            chats = data["ChatStreams"]
            Sessions = data["Sessions"]
            for session in Sessions:
                if session["token"] == usertoken:

                    new_chat = {
                        "id": 0,
                        "group": False,
                        "selfdestructing": False,
                        "picture": "",
                        "name": "",
                        "admins": [],
                        "users": [],
                        "attachedids": [],
                        "messages": []
                    }

                    Ids = data["IDS"]
                    id = random.randint(0, 100)
                    while id in Ids:
                        id = random.randint(0, 100)

                    Ids.append(id)

                    if (not os.path.exists(f"./assets/chat_media/{id}")):
                        os.mkdir(f"./assets/chat_media/{id}")

                    new_chat["id"] = id
                    new_chat["admins"] = new_users
                    new_chat["users"] = new_users

                    for user in new_users:
                        if validate(user) != True:
                            response = jsonify(ERROR)
                            return response, 200

                    chats.append(new_chat)

                    with open(DB, 'w') as file:
                        file.seek(0)
                        json.dump(data, file, indent = 4)

                    response = jsonify(AUTHENICATION)
                    return response, 200
                    
            print(f"Invalid user token from {ip_addr}")
            return jsonify(ERROR), 200
        
    else :
        print(f"Unauthorized server request detected from {ip_addr}")

#--------------------------------------### Modify Chat ###--------------------------------------#
@app.route("/chatstreams/groups/<id>/settings", methods=["PATCH"]) 
def modifyChat(id):
    ip_addr = request.remote_addr
    chat_data = request.get_json()
    new_pic = chat_data["newpic"]
    new_name = chat_data["newname"]
    new_admins = chat_data["newadmins"]
    new_users = chat_data["newusers"]
    self_destructing = chat_data["selfdestruct"]
    apptoken = request.headers.get("App-Token")
    usertoken = request.headers.get("User-Token")

    if apptoken == APPTOKEN:
        with open(DB, 'r') as file:
            data = json.load(file)
            chats = data["ChatStreams"]
            Sessions = data["Sessions"]
            for session in Sessions:
                if session["token"] == usertoken:
                    id = int(id)
                    for chat in chats:
                        if chat["id"] == id:
                            chat["name"] = new_name
                            chat["admins"] = new_admins
                            chat["selfdestructing"] = self_destructing
                            if new_pic != "":
                                path = chat["picture"]
                                with open(path, 'wb') as image_file:
                                    image_file.seek(0)
                                    image_data = base64.b64decode(new_pic)
                                    image_file.write(image_data)

                            chat["users"] = []
                            for user in new_users:
                                if (validate(user)):
                                    chat["users"].append(user)

                                else :
                                    return jsonify(ERROR), 200
                            for admin in chat["admins"]:
                                if not admin in chat["users"]:
                                    chat["admins"].remove(admin)

                
                            with open(DB, 'w') as file:
                                file.seek(0)
                                json.dump(data, file, indent = 4)

                            response = jsonify(AUTHENICATION)
                            return response, 200
                    
                    response = jsonify(ERROR)
                    return response, 200
                    
            print(f"Invalid user token from {ip_addr}")
            return jsonify(ERROR), 200
        
    else :
        print(f"Unauthorized server request detected from {ip_addr}")

#--------------------------------------### Delete Chat ###--------------------------------------#
@app.route("/chatstreams/<id>", methods=["DELETE"]) 
def deleteChat(id):
    ip_addr = request.remote_addr
    apptoken = request.headers.get("App-Token")
    usertoken = request.headers.get("User-Token")

    if apptoken == APPTOKEN:
        with open(DB, 'r') as file:
            data = json.load(file)
            Ids = data["IDS"]
            chats = data["ChatStreams"]
            Sessions = data["Sessions"]
            for session in Sessions:
                if session["token"] == usertoken:
                    id = int(id)
                    for chat in chats:
                        if chat["id"] == id:
                            Ids.remove(id)
                            chats.remove(chat)

                            if chat["group"] == True:
                                try:
                                    os.rmdir(f"assets/chat_media/{chat['id']}")
                                except:
                                    print("error destroying file")

                
                            with open(DB, 'w') as file:
                                file.seek(0)
                                json.dump(data, file, indent = 4)

                            response = jsonify(AUTHENICATION)
                            return response, 200
                    
                    response = jsonify(ERROR)
                    return response, 200
                    
            print(f"Invalid user token from {ip_addr}")
            return jsonify(ERROR), 200
        
    else :
        print(f"Unauthorized server request detected from {ip_addr}")

#--------------------------------------### Fetch Messages ###--------------------------------------#
@app.route("/chatstreams/<id>/messages/<username>", methods=["GET"]) 
def refreshChat(username, id):
    ip_addr = request.remote_addr
    apptoken = request.headers.get("App-Token")
    usertoken = request.headers.get("User-Token")

    message_list = []

    if apptoken == APPTOKEN:
        with open(DB, 'r') as file:
            data = json.load(file)
            chatstreams = data["ChatStreams"]
            Sessions = data["Sessions"]
            for session in Sessions:
                if session["token"] == usertoken:
                    id = int(id)
                    for chat in chatstreams:
                        if id == chat["id"]:
                            messages = chat["messages"]
                            for message in messages:
                                if (message["media"] == False):
                                    curr_message = {
                                        "source": getProfile(message["source"]),
                                        "timestamp": message["timestamp"],
                                        "content": message["content"],
                                        "media": False,
                                        "locked": message["locked"]
                                    }
                                    message_list.append(curr_message)
                                else :
                                    path = message["content"]
                                    with open(path, 'rb') as media_file:
                                        media_file.seek(0)
                                        media_bytes = media_file.read()
                                        media_data = base64.b64encode(media_bytes).decode('ascii')
                                    
                                    curr_message = {
                                        "source": getProfile(message["source"]),
                                        "timestamp": message["timestamp"],
                                        "content": media_data,
                                        "media": True,
                                        "locked": message["locked"]
                                    }
                                    message_list.append(curr_message)

                            with open(DB, 'w') as file:
                                file.seek(0)
                                json.dump(data, file, indent = 4)
                                
                            response = jsonify(message_list)
                            return response, 200

                    response = jsonify(ERROR)
                    return response, 200
                    
            print(f"Invalid user token from {ip_addr}")
            return jsonify(ERROR), 200
    
    else :
        print(f"Unauthorized server request detected from {ip_addr}")

#--------------------------------------### Mark as Read ###--------------------------------------#
@app.route("/chatstreams/<id>/messages/<username>", methods=["PATCH"]) 
def markRead(username, id):
    ip_addr = request.remote_addr
    apptoken = request.headers.get("App-Token")
    usertoken = request.headers.get("User-Token")

    if apptoken == APPTOKEN:
        with open(DB, 'r') as file:
            data = json.load(file)
            chatstreams = data["ChatStreams"]
            Sessions = data["Sessions"]
            for session in Sessions:
                if session["token"] == usertoken:
                    id = int(id)
                    for chat in chatstreams:
                        if id == chat["id"]:
                            messages = chat["messages"]
                            for message in messages:
                                if not username in message["read"]:
                                    message["read"].append(username)

                            with open(DB, 'w') as file:
                                file.seek(0)
                                json.dump(data, file, indent = 4)
                                
                            response = jsonify(AUTHENICATION)
                            return response, 200

                    response = jsonify(ERROR)
                    return response, 200
                    
            print(f"Invalid user token from {ip_addr}")
            return jsonify(ERROR), 200
    
    else :
        print(f"Unauthorized server request detected from {ip_addr}")

#--------------------------------------### Self-Destruct Messages ###--------------------------------------#
@app.route("/chatstreams/<id>/messages/selfdestruct", methods=["DELETE"]) 
def selfDestruct(id):
    ip_addr = request.remote_addr
    apptoken = request.headers.get("App-Token")
    usertoken = request.headers.get("User-Token")

    if apptoken == APPTOKEN:
        with open(DB, 'r') as file:
            data = json.load(file)
            chatstreams = data["ChatStreams"]
            Sessions = data["Sessions"]
            for session in Sessions:
                if session["token"] == usertoken:
                    id = int(id)
                    for chat in chatstreams:
                        if id == chat["id"]:
                            messages = chat["messages"]
                            for message in messages:
                                all_read = True
                                for user in chat["users"]:
                                    if not user in message["read"]:
                                        all_read = False
                                if all_read == True:
                                    if message["media"] == True:
                                        try:
                                            os.remove(message["content"])
                                        except:
                                            print("error destroying file")

                                        path = message["content"].split('/')
                                        id = path[4].split('.')
                                        id = int(id)
                                        chat["attachedids"].remove(id)
                                    chat["messages"].remove(message)

                            with open(DB, 'w') as file:
                                file.seek(0)
                                json.dump(data, file, indent = 4)
                                
                            response = jsonify(AUTHENICATION)
                            return response, 200

                    response = jsonify(ERROR)
                    return response, 200
                    
            print(f"Invalid user token from {ip_addr}")
            return jsonify(ERROR), 200
    
    else :
        print(f"Unauthorized server request detected from {ip_addr}")
    
#--------------------------------------### Post Message ###--------------------------------------#
@app.route("/chatstreams/<id>/messages", methods=["POST"]) 
def postMessage(id):
    ip_addr = request.remote_addr
    apptoken = request.headers.get("App-Token")
    usertoken = request.headers.get("User-Token")

    if apptoken == APPTOKEN:
        with open(DB, 'r') as file:
            data = json.load(file)
            chatstreams = data["ChatStreams"]
            Sessions = data["Sessions"]
            for session in Sessions:
                if session["token"] == usertoken:

                    id = int(id)
                    json_data = request.get_json()
                    source = json_data["source"]
                    timestamp = json_data["timestamp"]
                    content = json_data["content"]
                    locked = json_data["locked"]


                    new_message = {
                        "source": source,
                        "timestamp": timestamp,
                        "content": content,
                        "media": False,
                        "locked": locked,
                        "read": [source]
                    }

                    for chat in chatstreams:
                        if id == chat["id"]:
                            if len(chat["messages"]) > 50:
                                chat["messages"] = destroyMessages(id)
                            chat["messages"].append(new_message)
                            with open(DB, 'w') as file:
                                file.seek(0)
                                json.dump(data, file, indent = 4, ensure_ascii=False)
                            
                            response = jsonify(AUTHENICATION)
                            return response, 200

                    response = jsonify(ERROR)
                    return response, 200
                    
            print(f"Invalid user token from {ip_addr}")
            return jsonify(ERROR), 200
        
    else :
        print(f"Unauthorized server request detected from {ip_addr}")

#--------------------------------------### Post Media ###--------------------------------------#
@app.route("/chatstreams/<id>/multimedia", methods=["POST"]) 
def postMedia(id):
    ip_addr = request.remote_addr
    apptoken = request.headers.get("App-Token")
    usertoken = request.headers.get("User-Token")

    if apptoken == APPTOKEN:
        with open(DB, 'r') as file:
            data = json.load(file)
            chatstreams = data["ChatStreams"]
            Sessions = data["Sessions"]
            for session in Sessions:
                if session["token"] == usertoken:

                    id = int(id)
                    json_data = request.get_json()
                    source = json_data["source"]
                    timestamp = json_data["timestamp"]
                    filetype = json_data["filetype"]
                    content = json_data["content"]
                    content_data = base64.b64decode(content)
                    locked = json_data["locked"]

                    for chat in chatstreams:
                        if id == chat['id']:
                            if len(chat["messages"]) > 50:
                                print("destroying")
                                chat["messages"] = destroyMessages(chat)

                            if (not os.path.exists(f"./assets/chat_media/{chat['id']}/media")):
                                os.mkdir(f"./assets/chat_media/{chat['id']}/media")

                            Ids = chat["attachedids"]
                            new_id = random.randint(0, 100)
                            while new_id in Ids:
                                new_id = random.randint(0, 100)

                            path = f"./assets/chat_media/{chat['id']}/media/{new_id}{filetype}"
                            new_message = {
                                "source": source,
                                "timestamp": timestamp,
                                "content": path,
                                "media": True,
                                "locked": locked,
                                "read": [source]
                            }
                            chat["attachedids"].append(new_id)
                            chat["messages"].append(new_message)

                            with open(path, 'wb') as media_file:
                                media_file.seek(0)
                                media_file.write(content_data)

                            with open(DB, 'w') as file:
                                file.seek(0)
                                json.dump(data, file, indent = 4, ensure_ascii=False)
                            
                            response = jsonify(AUTHENICATION)
                            return response, 200

                    response = jsonify(ERROR)
                    return response, 200
                    
            print(f"Invalid user token from {ip_addr}")
            return jsonify(ERROR), 200
        
    else :
        print(f"Unauthorized server request detected from {ip_addr}")
    
#--------------------------------------### Purge Message ###--------------------------------------#
@app.route("/chatstreams/<id>/messages/<index>", methods=["DELETE"]) 
def purgeMessage(id, index):
    ip_addr = request.remote_addr
    apptoken = request.headers.get("App-Token")
    usertoken = request.headers.get("User-Token")

    if apptoken == APPTOKEN:
        with open(DB, 'r') as file:
            data = json.load(file)
            chatstreams = data["ChatStreams"]
            Sessions = data["Sessions"]
            for session in Sessions:
                if session["token"] == usertoken:
                    id = int(id)
                    index = int(index)
                    for chat in chatstreams:
                        if id == chat["id"]:
                            message = chat["messages"][index]
                            if message["media"] == True:
                                try:
                                    os.remove(message["content"])
                                except:
                                    print("error destroying file")

                                path = message["content"].split('/')
                                suffix = path[5].split('.')
                                attached_id = suffix[0]
                                attached_id = int(attached_id)
                                print(attached_id)
                                chat["attachedids"].remove(attached_id)

                            chat["messages"].remove(message)

                            with open(DB, 'w') as file:
                                file.seek(0)
                                json.dump(data, file, indent = 4, ensure_ascii=False)
                            
                            response = jsonify(AUTHENICATION)
                            return response, 200

                    response = jsonify(ERROR)
                    return response, 200
                    
            print(f"Invalid user token from {ip_addr}")
            return jsonify(ERROR), 200
        
    else :
        print(f"Unauthorized server request detected from {ip_addr}")

#--------------------------------------### Purge Chat Contents ###--------------------------------------#
@app.route("/chatstreams/<id>/messages", methods=["DELETE"]) 
def purgeChat(id):
    ip_addr = request.remote_addr
    apptoken = request.headers.get("App-Token")
    usertoken = request.headers.get("User-Token")

    if apptoken == APPTOKEN:
        with open(DB, 'r') as file:
            data = json.load(file)
            chatstreams = data["ChatStreams"]
            Sessions = data["Sessions"]
            for session in Sessions:
                if session["token"] == usertoken:
                    id = int(id)
                    for chat in chatstreams:
                        if id == chat["id"]:
                            for message in chat["messages"]:
                                if message["media"] == True:
                                    try:
                                        os.remove(message["content"])
                                    except:
                                        print("error destroying file")

                                    path = message["content"].split('/')
                                    suffix = path[5].split('.')
                                    attached_id = suffix[0]
                                    attached_id = int(attached_id)
                                    chat["attachedids"].remove(attached_id)

                            chat["messages"] = []

                            with open(DB, 'w') as file:
                                file.seek(0)
                                json.dump(data, file, indent = 4, ensure_ascii=False)
                            
                            response = jsonify(AUTHENICATION)
                            return response, 200

                    response = jsonify(ERROR)
                    return response, 200
                    
            print(f"Invalid user token from {ip_addr}")
            return jsonify(ERROR), 200
        
    else :
        print(f"Unauthorized server request detected from {ip_addr}")


#----------------------------------------------------------------------------#
#--------------------------------------### Entry-Point ###--------------------------------------#
#----------------------------------------------------------------------------#
if __name__ == "__main__":
    app.run(host='0.0.0.0', port=9000, debug=True)

