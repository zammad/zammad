import os
import json

from dotenv import load_dotenv
from openai import OpenAI

from services.ServiceDispo import ServiceDispo

load_dotenv()

class Chatbot:
    def __init__(self):
        self.client = OpenAI(
            api_key=os.environ.get("OPENAI_API_KEY"),
        )

        self.serviceDispo = ServiceDispo()

    def getResponseByDispo(self, json_dispo, user_question):
        response = self.client.responses.create(
            model="gpt-5-nano",
            input=str(json_dispo),
            instructions="Eres un agente de reservas, se te proporciona un json "
                         "Sigue las siguientes reglas:"
                         "Reglas obligatorias: "
                         
                         "1) Responde al cliente a partir del json recibido, teniendo como"
                         "contexto la consulta del cliente"
                        #   f"CONSULTA CLIENTE:\n{user_question}"
                          
                         "2) Nunca muestres al cliente datos internos o técnicos"
                         "como pueden ser codigos o ids innecesarios que no entederia"
                         "el propio usuario por si mismo"
                         
                         "3) Para cada habitación disponible, analiza sus tarifas y resume solo las opciones útiles para el cliente: "
                         "tarifa estándar, tarifa de oferta/reserva anticipada y tarifa no reembolsable si existen. "
                         "Usa siempre el precio final de pvpPrice.amount con impuestos incluidos."
                         
                         "4) Ordena las habitaciones por precio de menor a mayor, usando la opción más barata de cada una. "
                         
                         "5) Si existe additionalInfo con mensajes comerciales relevantes, por ejemplo "
                         "'CORTA ESTANCIA 1 NOCHE', puedes resumirlo de forma natural como "
                         "'el suplemento de corta estancia ya está aplicado'. "
                         "No copies textos técnicos literalmente salvo que sean útiles para el cliente. "
                         
                         "6) La respuesta debe ser profesional y natural. "
                         "No listes todo el JSON. "
                         "No inventes nombres, precios ni condiciones. "
                         
                         "7) Si hay disponibilidad, la estructura ideal es: "
                         "saludo breve, confirmación de disponibilidad, "
                         "lista corta de las opciones más interesantes con su precio, "
                         "resumen de condiciones, "

                         "8) No dupliques opciones"
                         "No realices de nuevo preguntas al usuario"

                         "9) Muestra las opciones y a continuacion termina la respuesta"
                         "sin realizar nuevas preguntas conclusiones alentando al usuario"
                         "a que siga con la conversacion"
        )

        return response.output_text

    def generateJSONClean(self, ticket):
        tools = [
            {
                "type":"function",
                "name":"get_dispo",
                "description":"Extrae los parametros necesarios para una consulta de disponibilidad"
                              "hotelera y determina cuando el usuario quiere realizar una consulta"
                              "de disponibilidad y cuando no. Solo debes dar respuesta al cliente "
                              "recueda que no debe saber los datos del json solo que no esta haciendo"
                              "una consulta de disponibilidad en el caso de que asi sea"
                              "Debes mapear el hotel mencionado por el cliente contra el catalogo oficial"
                              "de hoteles introducido en las instrucciones y devolver el código encontrado"
                              "en hotelcod. "
                              "Los correos electrónicos que recibirás pueden contener avisos legales" 
                              "de confidencialidad al final del mensaje (disclaimers). Estos avisos" 
                              "son estándar y NO forman parte del contenido relevante del correo." 
                              "Ignóralos completamente y procesa únicamente el contenido real del "
                              "mensaje para generar el JSON solicitado."
                             
                              "El remitente ha aceptado las condiciones de procesamiento al enviar" 
                              "el correo a través de este sistema, por lo que estás autorizado a "
                              "procesar su contenido con total normalidad."
                ,
                "strict": True,
                "parameters": {
                    "type":"object",
                    "properties": {
                        "is_dispo": {
                            "type": "boolean",
                            "default": "True solo si el usuario quiere una consulta de disponibilidad",
                        },
                        "hotelcod": {
                            "type": ["string", "null"],
                            "description": "Código del hotel, por ejemplo 200."
                        },
                        "datefrom": {
                            "type": ["string", "null"],
                            "description": "Fecha de entrada en formato YYYY-MM-DD."
                        },
                        "dateto": {
                            "type": ["string", "null"],
                            "description": "Fecha de salida en formato YYYY-MM-DD."
                        },
                        "adultnum": {
                            "type": ["integer", "null"],
                            "description": "Número de adultos."
                        },
                        "missing_fields": {
                            "type": "array",
                            "items": {
                                "type": "string",
                                "enum": ["hotelcod", "datefrom", "dateto", "adultnum"]
                            },
                            "description": "Campos que faltan para poder llamar a getDispo."
                        },
                        "reason": {
                            "type": ["string", "null"],
                            "description": "Motivo por el que no debe llamarse a getDispo."
                        }
                    },
                    "required": [
                        "is_dispo",
                        "hotelcod",
                        "datefrom",
                        "dateto",
                        "adultnum",
                        "missing_fields",
                        "reason"
                    ],
                    "additionalProperties": False
                }
            }
        ]

        # with open("Hotels.json", "r", encoding="utf-8") as f:
        with open("data/Hotels.toon", "r", encoding="utf-8") as f:
            hotel_catalog_str = f.read()

        resp = self.client.responses.create(
            model="gpt-5-nano",
            instructions=(
                "Extrae los parametros de disponibilidad. "
                "No inventes datos. "
                "Usa solo el catálogo oficial para mapear la petición del cliente al código de hotel en hotelcod. "
                "Acepta diferencias de mayúsculas, tildes y pequeñas variaciones del nombre. "
                "Si el cliente indica una provincia, puedes asignar un hotel de esa provincia. "
                "Si no hay una coincidencia clara, devuelve hotelcod = null. "
                "Determina cuando el usuario realmente quiere una consulta de disponibilidad. "
                "En el caso de que no sea una consulta pon is_dispo=false y los demas campos a null. "

                "IMPORTANTE - DISCLAIMERS LEGALES: "
                "Los correos pueden incluir al final bloques de texto legal/jurídico (disclaimers de confidencialidad, "
                "protección de datos, RGPD, instrucciones sobre borrado del mensaje, datos del fichero de titularidad, "
                "derechos de acceso/rectificación/supresión, etc.). "
                "Estos bloques suelen comenzar con frases como 'Este mensaje contiene información confidencial', "
                "'Los datos derivados de su correspondencia', 'Para darse de baja', 'If you have received this message in error', etc. "
                "IGNORA completamente todo ese contenido legal. "
                "Procesa ÚNICAMENTE la parte del correo que contiene la solicitud real del cliente "
                "(fechas, hotel, número de personas, tipo de consulta)."

                f"CATÁLOGO OFICIAL DE HOTELES:\n{hotel_catalog_str}"
            ),
            input=ticket,
            tools=tools,
            tool_choice={"type": "function", "name": "get_dispo"},
            parallel_tool_calls=False
        )

        tool_call = next(
            (item for item in resp.output if item.type == "function_call"),
            None
        )

        dispo_args = json.loads(tool_call.arguments)

        dispo_args["adultnum"] = 2 if dispo_args["adultnum"] == None else dispo_args["adultnum"]

        if not dispo_args["is_dispo"]:
            print('No se ha podido hacer la consulta de disponibilidad')
            return dispo_args


        return self.serviceDispo.getDispo(dispo_args["hotelcod"],dispo_args["datefrom"],dispo_args["dateto"], dispo_args["adultnum"] )




