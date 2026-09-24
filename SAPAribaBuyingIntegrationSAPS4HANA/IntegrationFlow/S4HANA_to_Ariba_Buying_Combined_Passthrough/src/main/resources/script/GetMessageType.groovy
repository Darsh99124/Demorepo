import com.sap.gateway.ip.core.customdev.util.Message;
import java.util.HashMap;

def Message processData(Message message)
{
    def msgBodyOrig = message.getBody(java.lang.String) as String;
    def xml = new XmlSlurper().parseText(msgBodyOrig);

    def MessageType = xml.Body.'*'[0].name();

    message.setProperty("MessageType",MessageType);
    message.setHeader("SAP_MessageType",MessageType);
    return message;
    }
