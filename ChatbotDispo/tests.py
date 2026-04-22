import lambda_function
import re
import chatbot.Chatbot as Chatbot
import chatbot.utils as utils
import sys
import chatbot.Logger as Logger

from services.ServiceDispo import ServiceDispo
from chatbot.utils import JSONReducer
import services.ServiceZammad as ServiceZammad

def handler(ticketId):

    #Initializations
    logger = Logger.Logger("MainHandler")
    zammad_service = ServiceZammad.ServiceZammad()
    chatbot = Chatbot.Chatbot()

    logger.info(f"Processing ticket ID: {ticketId}")
    body = zammad_service.getTicketArticles(ticketId)
    logger.info(f"Retrieved ticket body: {body}")

    if body is None:
        logger.error("No ticket articles found.")
        return {
            'statusCode': 400,
            'error':'No se ha encontrado el ticket del cliente!'
        }

    #Clean Body and determine if it's from a client
    cleanBody = getBody(body)

    if cleanBody is None:
        logger.error("Retrieved body is not from a client.")
        return {
            'statusCode': 400,
            'error':'El usuario no es un cliente, es un agente!'
        }
    
    #Get a dispo response
    response = chatbot.generateJSONClean(cleanBody)
    logger.info(f"Generated JSON response: {response}")

    if response.status_code != 200:
        logger.error("Failed to access the dispo API.")
        return {
            'statusCode': response.status_code,
            'error': 'No se ha podido accedeer a la API de dispo'
        }
    
    response = utils.JSONReducer(response)
    
    #Generate client response based on dispo response
    finalResponse = chatbot.getResponseByDispo(response, cleanBody)

    logger.info(f"Final response: {finalResponse}")

    zammad_service.postResponseTicket(finalResponse, ticketId)

    return 'Hello from AWS Lambda using Python' + sys.version + '!'

def getBody(response):
    for item in response.json():
        if item["sender"] == 'Customer':
            return cleanBody(item["body"])

    return None

def cleanBody(body):
    body = body.replace('<br>', ' ')
    return re.sub(r'(?is)<[^>]+>', '', body)



handler(50)

