import com.sap.gateway.ip.core.customdev.util.Message;
import java.util.HashMap;

def Message processData(Message message)
{
    def msgBodyOrig = message.getBody(java.lang.String) as String;
    def xml = new XmlSlurper().parseText(msgBodyOrig);

    map = message.getProperties();
    MessageType = map.get("MessageType");

    def Prefix = xml.Body.'*'[0].MessageHeader.SenderBusinessSystemID.text();


    //CompanyCode prefixing
    if (MessageType == "CompanyCode") {
      msgBodyModCC = msgBodyOrig.replaceAll(/<CompanyCode><CompanyCode>/,"<CompanyCode><CompanyCode>${Prefix}_");
    } else {
      msgBodyModCC = msgBodyOrig.replaceAll(/<CompanyCode>/,"<CompanyCode>${Prefix}_");
    }

    //Plant prefixing
    msgBodyModPL = msgBodyModCC.replaceAll(/<PlantID>/,"<PlantID>${Prefix}_");

    //PurchasingOrg prefixing
    msgBodyModPO = msgBodyModPL.replaceAll(/<PurchasingOrgID>/,"<PurchasingOrgID>${Prefix}_");


    message.setBody(msgBodyModPO);
    return message;
    }
