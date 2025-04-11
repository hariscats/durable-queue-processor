from azure.servicebus import ServiceBusClient, ServiceBusMessage
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

connection_string = os.getenv('SERVICEBUS_CONNECTION_STRING')
queue_name = "messages"

if not connection_string:
    raise ValueError("ServiceBus connection string not found in environment variables")

with ServiceBusClient.from_connection_string(connection_string) as client:
    sender = client.get_queue_sender(queue_name)
    message = ServiceBusMessage("Hello from Service Bus!")
    sender.send_messages(message)
    print("Message sent successfully")
