import json
import base64

DB = "database.json"
   
with open(DB, 'r') as file:
    data = json.load(file)
    users = data["Users"]

    for user in users:
        image_data = base64.b64decode(user["profpic"])
        with open(f"./assets/profilepics/{user['username']}.png", 'wb') as image_file:
            image_file.seek(0)
            image_file.write(image_data)
        user["profpic"] = f"./assets/profilepics/{user['username']}.png"

    with open(DB, 'w') as file:
        file.seek(0)
        json.dump(data, file, indent = 4, ensure_ascii=False)
            

            