import requests
import json
import os

from dotenv import load_dotenv

load_dotenv()

class ServiceDispo:

    def __init__(self):
        self.baseUrl = os.getenv('SERVER_URL_CONNECT')

    def getDispo(self, hotelcod, datefrom, dateto, adultnum):
        url = self.baseUrl + "/api/v1/availability/byhotel"

        payload = json.dumps({
            "IncludeOriginalAvailabilityRequest": False,
            "IncludeChannelRequestResponse": True,
            "DestinationType": 0,
            "DestinationCodes": [
                hotelcod
            ],
            "AccommodationDates": {
                "From": datefrom,
                "To": dateto
            },
            "MarketCode": None,
            "LanguageIsoCode": "ES",
            "CommissionCode": "",
            "RoomConfiguration": [
                {
                    "RoomCode": "",
                    "Occupancy": {
                        "Adults": {
                            "Number": adultnum,
                            "Ages": [
                                30,
                                30
                            ]
                        }
                    },
                    "MealCodes": [
                        ""
                    ]
                }
            ],
            "AdditionalInfo": None,
            "PromotionalCode": None,
            "StaticDataDetailLevel": 0,
            "IncludeAvailabilityWithoutQuota": True,
            "IncludeAlternativeHotels": False,
            "IncludeAlternativeDays": False,
            "IncludeCrossSellingProducts": False,
            "IncludeOnRequestAvailability": True
        })
        headers = {
            'Username': os.getenv('PRO_USER'),
            'Password': os.getenv('PRO_PASSWORD'),
            'Content-Type': 'application/json'
        }

        response = requests.request("POST", url, headers=headers, data=payload)

        return response