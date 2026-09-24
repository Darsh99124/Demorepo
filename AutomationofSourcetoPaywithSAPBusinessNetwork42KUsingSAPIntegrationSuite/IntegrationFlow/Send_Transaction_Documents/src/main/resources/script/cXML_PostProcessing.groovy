import com.sap.gateway.ip.core.customdev.util.Message
import groovy.xml.*

import com.sap.it.api.ITApiFactory
import com.sap.it.api.securestore.SecureStoreService
import com.sap.it.api.securestore.UserCredential
import com.sap.it.api.securestore.exception.SecureStoreException

def Message processData(Message message) {

	def xml = new XmlParser(false,false).parse(message.getBody(Reader))
    credential_name = message.getHeader('an_credential', String)
    endpoint_name = message.getHeader('endpointID', String)

    //Get Security Material
    def service = ITApiFactory.getApi(SecureStoreService.class, null)
    def cred = service.getUserCredential(credential_name);
    if (cred == null){
        throw new IllegalStateException('No credential found for alias')
    }
 
	//Add SharedSecret to cXML
    sender = xml.'**'.Sender.Credential
    if (sender) sender.replaceNode{
        Credential(domain:'NetworkID') {
            Identity(cred.getUsername())
            SharedSecret(cred.getPassword())
        }
    };
    
	//DeploymentMode for SUR
    if (xml.'**'.StatusUpdateRequest) {
        deployment = (message.getHeader("gateway",String) == "PROD" ? "production" : "test")
        xml.'**'.Request.@deploymentMode = deployment
    }
	
	//Remove CIG Endpoint from cXML
	cig = xml.'**'.Credential.find{it.@domain == 'EndPointID' && it.Identity.text() == 'CIG'}
    
    if (cig) {
    if (endpoint_name?.trim()) {
        // If endpoint_name is NOT blank, replace Identity
        cig.Identity.replaceNode { Identity(endpoint_name) }
        } 
        else {
        // If endpoint_name is blank, remove the entire Credential node
        cig.replaceNode {}
        }
    }
	
    xml_decl = "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
    dtd_decl = "<!DOCTYPE cXML SYSTEM \"http://xml.cxml.org/schemas/cXML/1.2.056/${message.getProperty("dtd")}\">"

	message.setBody(xml_decl + dtd_decl + XmlUtil.serialize(xml).replaceFirst("<\\?xml version=\"1.0\".*\\?>", ""))
    return message;
}
