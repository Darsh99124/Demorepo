import com.sap.gateway.ip.core.customdev.util.Message;
import java.util.HashMap;

def Message processData(Message message)
{
    def msgBodyOrig = message.getBody(java.lang.String) as String;

    map = message.getProperties();
    DocumentType = map.get("DocumentType");


    //Set Document Type
    msgBodyMod = msgBodyOrig.replaceAll(/"PurchaseRequisitionType":"NB"/,"\"PurchaseRequisitionType\":\"${DocumentType}\"");


    message.setBody(msgBodyMod);
    return message;
    }
