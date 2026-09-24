/* Script to Override the attachment filename  using the filenmae provided in the SOAP XML payload */
import com.sap.gateway.ip.core.customdev.util.Message;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Map.Entry;
import javax.activation.DataHandler;
import org.apache.camel.Attachment;
import com.sap.gateway.ip.core.customdev.util.AttachmentWrapper;
import org.apache.camel.impl.DefaultAttachment;
import java.util.regex.Pattern;
import java.util.regex.Matcher; 
import java.lang.StringBuilder;
import com.sap.it.api.ITApiFactory;
import com.sap.it.api.*;
import com.sap.it.api.pd.*;
import java.net.URLEncoder;

def Message processData(Message message) {
	def service = ITApiFactory.getApi(PartnerDirectoryService.class, null);	
	if (service == null){
	  message.setHeader("anExceptionCode","CIG-PLT-00601")
      throw new IllegalStateException("Partner Directory Service not found");
      }
	def map = message.getHeaders();
	def messageLog = messageLogFactory.getMessageLog(message)	

	def attMap = message.getAttachments();
	def anEnvelopeAttachmentList = map.get("ancXMLAttachments")
	String [] anATTList
	
	if (anEnvelopeAttachmentList)
	{
    	anATTList = anEnvelopeAttachmentList.split('#')	
	}
	def anAttCount = attMap.size()
	if(anAttCount > 0 && anEnvelopeAttachmentList)
	   {
			String attachmentStr = ''
			message.setHeader("hasAttachments", "YES")
			Map<String, AttachmentWrapper> attMapN = message.getAttachmentWrapperObjects();
    		Iterator<Entry<String, AttachmentWrapper>> attIteratorN = attMapN.entrySet().iterator();
			int j = 1;
			while(attIteratorN.hasNext())
				{
					Entry<String, AttachmentWrapper> entryN = attIteratorN.next();
					AttachmentWrapper attachment = entryN.getValue();
					String anAttachmentName;
					String anContentDisposition
					String attContentID = message.getAttachmentHeader("Content-ID", attachment);		//Get the Current Content-ID associated to the attachments
					builder = new StringBuilder(attContentID);
					searchStr = "<"				
					replaceStr = ""		 
					resultString = rmReplaceAll(builder, searchStr, replaceStr)
					builder = new StringBuilder(resultString);
					searchStr = ">"				
					replaceStr = ""
					attContentID = rmReplaceAll(builder, searchStr, replaceStr)		
					for (int n = 0; n < anAttCount; n++)
						{
							String [] anAttDetails = anATTList[n].split(';')
							def anExchangeAttContentID = anAttDetails[0]
							def anExchangeAttFilename = anAttDetails[1]
							builder = new StringBuilder(anExchangeAttContentID);
							searchStr = "cid:"				
							replaceStr = ""		 
							anExchangeAttContentID = rmReplaceAll(builder, searchStr, replaceStr)
							if (anExchangeAttContentID == attContentID)
							{
								message.removeAttachmentHeader("Content-Disposition", attachment)
								attachment.setHeader("Content-Disposition","attachment; filename=\""+URLEncoder.encode(anExchangeAttFilename, "UTF-8")+"\"")
							}
						}

                    j++;
				}
			
	   }
	  
	return message;
}


def rmReplaceAll(builder, String from, String to)
{
 	int index = builder.indexOf(from);
 	while (index != -1)
 	{
   		builder.replace(index, index + from.length(), to);
   		index += to.length();
   		index = builder.indexOf(from, index);
	}		
	String replacedString = new String(builder);
	return replacedString;	 	   
}

     
