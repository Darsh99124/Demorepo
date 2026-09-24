import com.sap.gateway.ip.core.customdev.util.Message
 
def Message processData(Message message) {
    def body = message.getBody(String)
    message.setProperty("source_payload", body)
    message.setBody(body)
    return message
}