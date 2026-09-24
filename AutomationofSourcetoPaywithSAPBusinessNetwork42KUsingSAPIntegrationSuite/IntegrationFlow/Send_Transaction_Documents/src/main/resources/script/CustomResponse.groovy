import com.sap.gateway.ip.core.customdev.util.Message;
import java.util.HashMap;
def Message processData(Message message) {
    
    def body = message.getBody(java.lang.String);
    
    def headers = message.getHeaders();
    def response = headers.get("Response_Message") 
    
    addCustomHeader(message, "Error Response", response);
    
    return message;
}

def addCustomHeader(Message message, String key, String val) {
    def messageLog = messageLogFactory.getMessageLog(message)
    if (val != null) {
        messageLog.addCustomHeaderProperty(key, val);
    }
}