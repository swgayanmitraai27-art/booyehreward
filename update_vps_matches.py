import json
import os

db_path = '/home/ubuntu/booyah-backend/data/db.json'
with open(db_path, 'r', encoding='utf-8') as f:
    db = json.load(f)

db['matches'] = [
    {
        "id": "match_1791508080284",
        "title": "Free Fire Clash Squad Championship",
        "bannerUrl": "https://i.ibb.co/9ktcjYSX/lonewolfhomescreen.png",
        "bannerImage": "https://i.ibb.co/9ktcjYSX/lonewolfhomescreen.png",
        "gameType": "freeFire",
        "matchType": "free",
        "mode": "loneWolf",
        "teamType": "solo",
        "matchFormat": "solo",
        "map": "bermuda",
        "entryFeeType": "adCoins",
        "entryFee": 0,
        "prizePool": {
            "totalPool": 0,
            "firstPlace": 0,
            "secondPlace": 0,
            "thirdPlace": 0,
            "perKill": 0
        },
        "maxSlots": 2,
        "filledSlots": 0,
        "status": "upcoming",
        "matchTime": "2026-10-09T03:00:00.000Z",
        "credentials": {
            "roomId": "",
            "roomPassword": ""
        },
        "participants": [],
        "registeredTeams": [],
        "hostName": "Booyah Esports Official"
    }
]

with open(db_path, 'w', encoding='utf-8') as f:
    json.dump(db, f, indent=2)

print(f"SUCCESS_UPDATED_MATCHES_COUNT: {len(db['matches'])}")
