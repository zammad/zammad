import json

def JSONReducer(BBDDResponse):

    #Load Mapping files
    with open("data/Rooms.json", "r", encoding="utf-8") as f:
        rooms_json = json.load(f)

    with open("data/Hotels.json", "r", encoding="utf-8") as h:
        hotels_json = json.load(h)

    with open("data/Meals.json", "r", encoding="utf-8") as m:
        meals_json = json.load(m)

    hotels_json = json.loads(BBDDResponse.text)
    for hotel in hotels_json.get('HotelAvailabilities'):
        for room in hotel.get('RoomAvailabilities'):
            room["RoomCode"] = getRoomText(rooms_json, room.get('RoomCode'))

            for rate in room.get('Rates'):
                for meal in rate.get('Meals'):
                    meal["Code"] = getMealText(meals_json, meal.get("Code"))
                    meal.pop('RateKey')
                    meal.pop('PaymentMethod')
                    meal.pop('CancellationPolicies')
                    meal.pop('Price')
                    meal.pop('TotalPriceModifier')
                    meal.pop('IsOnRequest')
                    meal.pop('AdditionalInfo')

    # with open("json_resultante.json", "w", encoding="utf-8") as r:
    #     json.dump(hotels_json, r, ensure_ascii=False, indent=2)

    return hotels_json


def getRoomText(rooms, code):
    for item in rooms:
        if item.get("MTHAB") == code:
            return item.get("MTTEX1")
    return None

def getMealText(rooms, code):
    for item in rooms:
        r = item.get("MRHAB").strip()
        if r == code:
            return item.get("MRTEXT")
    return None








        

