import com.sap.gateway.ip.core.customdev.util.Message;
import java.util.HashMap;
import org.apache.camel.Exchange
import org.apache.http.entity.ContentType

def Message processData(Message message) {
    String encodingExchange = message.getProperty(Exchange.CHARSET_NAME);
 
    def encoding =  encodingExchange == null ?  "UTF-8" : encodingExchnage;
     def body = message.getBody()
    if (body instanceof String){
        def size = body.getBytes(encoding).length
        message.setHeader("Content-Length", size);
    } else {
        message.setHeader("Content-Length", message.getBodySize())
    }
    
    
    // Parse existing Content-Type header and re-set properly
    def contentTypeStr = message.getHeader("Content-Type", String)
    if (contentTypeStr) {
        
        def normalizedContentType = contentTypeStr.replaceAll("[\\n\\r\\t]", "")

        ContentType parsedType = ContentType.parse(normalizedContentType)
        message.setHeader("Content-Type", parsedType.toString())
    }
    
    return message;
}

