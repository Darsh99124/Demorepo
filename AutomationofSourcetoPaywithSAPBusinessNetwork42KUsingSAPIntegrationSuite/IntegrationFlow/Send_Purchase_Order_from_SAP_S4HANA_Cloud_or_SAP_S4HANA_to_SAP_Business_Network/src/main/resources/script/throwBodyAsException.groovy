import com.sap.gateway.ip.core.customdev.util.Message

def Message processData(Message message) {
    
    String body = message.getBody(String)
    
    throw new Exception(body);
}