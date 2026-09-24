import com.sap.gateway.ip.core.customdev.util.Message;

def Message processData(Message message) {
    def headers = message.getHeaders()
    
    // remove ansesrevoke
    if (headers.containsKey("ansesrevoke")) {
        headers.remove("ansesrevoke")
    }    
    
return message;

}