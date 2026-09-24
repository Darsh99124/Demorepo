import com.sap.gateway.ip.core.customdev.util.AttachmentWrapper;
import com.sap.gateway.ip.core.customdev.util.Message;
import org.apache.camel.impl.DefaultAttachment;
import javax.mail.util.ByteArrayDataSource;
import java.util.HashMap;
import java.util.Map;
import java.util.Map.Entry;
import org.apache.camel.Attachment;
import javax.activation.DataHandler;
import java.util.Iterator;
import org.apache.commons.io.IOUtils;
import java.lang.Byte;
import javax.mail.internet.MimeBodyPart;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.MimeMultipart;
import javax.mail.internet.MimeUtility;
import java.lang.StringBuilder;
import java.util.regex.Pattern;
import java.util.regex.Matcher; 

def Message processData(Message message) {
    //Body 
    
   
    byte[] payload = message.getBody(byte[].class);
    String attType
    String attName
    String attSize
    String attContentId
    String source = null
    def map = message.getHeaders();
    
    String SOAPEnvelopeSize = map.get("Content-Length")
    
    // Data source
    MimeMessage mimeMessage = new MimeMessage(source);
    def MimeMultipart mimeMultipart = new MimeMultipart("related");
    
    //SOAP Payload
    def MimeBodyPart soapapayload = new MimeBodyPart();
    soapapayload.setHeader("Content-Length", SOAPEnvelopeSize)

    ByteArrayDataSource soapDataSource = new ByteArrayDataSource(payload, "application/xop+xml")
    soapapayload.setDataHandler(new DataHandler(soapDataSource));
    soapapayload.setHeader("Content-Type", "application/xop+xml; charset=utf-8; type=\"text/xml\"")
    mimeMultipart.addBodyPart(soapapayload)
    
    //get and set attachments
    def attMap = message.getAttachments();
    def AttCount = attMap.size()
    if(AttCount > 0)
	 {
	    
	    Map<String, AttachmentWrapper> attMapN = message.getAttachmentWrapperObjects();
        Iterator<Entry<String, AttachmentWrapper>> attIteratorN = attMapN.entrySet().iterator();
        int j = 1; 
           while(attIteratorN.hasNext())
	    	{
				
				Entry<String, AttachmentWrapper> entryN = attIteratorN.next();
				AttachmentWrapper attachment = entryN.getValue();
				DataHandler dataHandler = attachment.getDataHandler();
				InputStream inputStream = dataHandler.getInputStream();
				byte[] bytes = IOUtils.toByteArray(inputStream);
  				int EachAttachmentSize = bytes.length
          		attSize = Long.toString(EachAttachmentSize)
          		def MimeBodyPart soapAttachmentBodyPart = new MimeBodyPart();
          		Collection<String> headerList = attachment.getHeaderNames();
				soapAttachmentBodyPart.setDataHandler(dataHandler)
				for (String attachmentHeaderName : headerList) {
					String attachmentHeaderValue = attachment.getHeader(attachmentHeaderName);
					soapAttachmentBodyPart.addHeader(attachmentHeaderName, attachmentHeaderValue);
				}
				soapAttachmentBodyPart.addHeader("Content-Length", attSize);
                mimeMultipart.addBodyPart(soapAttachmentBodyPart)
                j++;
	    	}
	}
	
	StringBuilder builder
	String searchStr
	String replaceStr	
	String resultString	
    
    String mimeContentType = mimeMultipart.getContentType();
    
    builder = new StringBuilder(mimeContentType);
    searchStr = "multipart/related"
    replaceStr = "Multipart/Related;type=\"application/xop+xml\"; start-info=\"text/xml\""
    resultString = stringReplaceAll(builder, searchStr, replaceStr)
   
	message.setHeader("Content-Type",resultString);
	ByteArrayOutputStream boas = new ByteArrayOutputStream();
	mimeMultipart.writeTo(boas);
	message.setBody(boas);
	message.setHeader("accept","application/xop+xml ,text/xml")
	
	String uuid = UUID.randomUUID().toString();
    message.setHeader("MessageId", uuid)
    
	return message;
}

def stringReplaceAll(builder, String from, String to)
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
