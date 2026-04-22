import requests
import json
import os

from dotenv import load_dotenv

load_dotenv()

class ServiceZammad:

    def __init__(self):
        self.url = os.getenv('SERVER_URL_ZAMMAD')
        self.auth = os.getenv('ZAMMAD_AUTH')

    def postResponseTicket(self, iaresponse, ticketid):
        url = self.url + "api/v1/ticket_articles"

        payload = json.dumps({
            "ticket_id": ticketid,
            "subject": "Call note",
            "body": iaresponse,
            "content_type": "text/html",
            "type": "phone",
            "internal": False,
            "sender": "Agent",
            "time_unit": "15"
        })

        headers = {
            # 'Content-Type': 'application/json',
            'Content-Type': 'application/html',
            'Authorization': self.auth
        }

        response = requests.request("POST", url, headers=headers, data=payload)


    def getTicketArticles(self, ticketid):
        url = self.url + "api/v1/ticket_articles/by_ticket/" + str(ticketid)

        headers = {
            'Content-Type': 'application/json',
            'Authorization': self.auth
        }

        response = requests.request("GET", url, headers=headers)


        return response