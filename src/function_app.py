import azure.functions as func
import azure.durable_functions as df
import logging

app = func.FunctionApp()

# Entry point: Triggered when a message arrives in Service Bus queue
# This function initiates the durable orchestration process
@app.function_name(name="ServiceBusQueueTrigger")
@app.service_bus_queue_trigger(arg_name="message", 
                             queue_name="messages",
                             connection="ServiceBusConnection")
@app.durable_client_input(client_name="durableClient")
async def orchestrator_trigger(message: func.ServiceBusMessage,
                             durableClient: df.DurableOrchestrationClient):
    # Decode message from bytes to string for processing
    message_body = message.get_body().decode('utf-8')
    logging.info(f"Service Bus message received: {message_body}")
    
    # Start a new orchestration instance for this message
    # This allows for tracking and managing the message processing lifecycle
    instance_id = await durableClient.start_new("DurableFunctionsOrchestrator", None, message_body)
    logging.info(f"Started orchestration with ID = '{instance_id}'")

# Orchestrator function: Coordinates the execution steps
# Acts as a workflow manager, determining the sequence of activities
@app.function_name(name="DurableFunctionsOrchestrator")
@app.orchestration_trigger(context_name="context")
def orchestrator_function(context: df.DurableOrchestrationContext):
    # Get the input message passed from the trigger
    message = context.get_input()
    # Call the activity function to process the message
    # Using yield ensures the state is maintained if the function is interrupted
    result = yield context.call_activity("ProcessMessage", message)
    return result

# Activity function: Performs the actual message processing work
# Isolated, single-purpose function that can be monitored and retried independently
@app.function_name(name="ProcessMessage")
@app.activity_trigger(input_name="message")
def process_message(message: str) -> str:
    # Log the processing attempt for monitoring and debugging
    logging.info(f"Processing message: {message}")
    # Return the processed message - in a real app, this would contain business logic
    return f"Processed message: {message}"
