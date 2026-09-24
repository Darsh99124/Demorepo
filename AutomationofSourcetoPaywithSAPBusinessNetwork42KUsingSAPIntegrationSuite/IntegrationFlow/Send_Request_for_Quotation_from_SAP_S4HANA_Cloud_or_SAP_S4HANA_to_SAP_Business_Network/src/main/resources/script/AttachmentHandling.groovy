import com.sap.gateway.ip.core.customdev.util.Message
import com.sap.gateway.ip.core.customdev.util.AttachmentWrapper
import java.util.Map
import javax.activation.DataHandler
import org.apache.camel.impl.DefaultAttachment
import javax.mail.util.ByteArrayDataSource
import groovy.xml.*

def Message StoreMIME(Message message) {

    Map<String, DataHandler> attachments = message.getAttachments()
    if (!attachments.isEmpty()) {

        def writer = new StringWriter()
        def listxml = new MarkupBuilder(writer)
		String liststring = ""
       
        listxml.AttachmentList(){
            for ( object in attachments ) {
				attName = object.value.getName()
				attType = object.value.getContentType()
				attByteContent = object.value.getContent().bytes
				attCid = object.key
				
				liststring += "cid:" + attCid + ";" + attName + ";" + attType + ";" + attByteContent.length + "|"
                Attachment(){
                    AttachmentName(attName)
                    AttachmentType(attType)
                    AttachmentID(attCid)
                    AttachmentContent(attByteContent.encodeBase64().toString())
                }
	    	}
        }
        message.setProperty("AttachmentList",writer.toString())
		message.setProperty("cXMLAttachments",liststring)
		message.setHeader("hasAttachments", "YES")
    }

	//clear attachments from message
	return clearAttachments(message)
}

def Message StoreMTOM(Message message) {

    Map<String, DataHandler> attachments = message.getAttachments()
    if (!attachments.isEmpty()) {

        def cxml = new XmlSlurper().parse(message.getBody(Reader))

        def writer = new StringWriter()
        def listxml = new MarkupBuilder(writer)
       
        listxml.AttachmentList(){
            for ( object in attachments ) {
				cid = object.key
				mtom = cxml.'**'.find{it.Include.@href == ("cid:" + cid)}
				if (mtom) {
                Attachment(){
                    AttachmentName(mtom.@FileName)
                    AttachmentType(mtom.@MimeType)
                    AttachmentID(cid)
                    AttachmentContent(object.value.getContent().bytes.encodeBase64().toString())
                }
				}
	    	}
        }
        message.setProperty("AttachmentList",writer.toString())
		message.setHeader("hasAttachments", "YES")
    }

	//clear attachments from message
	return clearAttachments(message)
}

def Message ReadMIME(Message message) {
	
	def ListText = message.getProperty("AttachmentList")
	if (ListText) {
		
		def AttachmentList = new XmlSlurper().parseText(ListText)
		AttachmentList.Attachment.each{

            def attachmentDataSource = new ByteArrayDataSource(it.AttachmentContent.text().decodeBase64(), it.AttachmentType.text())
            attachmentDataSource.setName(it.AttachmentName.text())
            def attachment = new DefaultAttachment(attachmentDataSource)
			attachment.setHeader('Content-Transfer-Encoding', 'base64')
            attachment.setHeader('Content-Disposition', 'attachment; filename=\"' + java.net.URLEncoder.encode(it.AttachmentName.text(), "UTF-8") + '\"')
            attachment.setHeader('Content-ID', '<' + it.AttachmentID.text() + '>')
            message.addAttachmentObject(it.AttachmentName.text(), attachment)

        }
		
		message.setHeader("hasAttachments", "YES")
    }
	
	message.setHeader("Content-Type", "text/xml; charset=UTF-8")
	
    return message
}

def Message ReadMTOM(Message message) {
	
	def ListText = message.getProperty("AttachmentList")
	if (ListText) {
		
		def AttachmentList = new XmlSlurper().parseText(ListText)
		AttachmentList.Attachment.each{

            def attachmentDataSource = new ByteArrayDataSource(it.AttachmentContent.text().decodeBase64(), it.AttachmentType.text())
            def attachment = new DefaultAttachment(attachmentDataSource)
			attachment.setHeader('Content-Transfer-Encoding', 'binary')
            attachment.setHeader('Content-ID', '<' + it.AttachmentID.text() + '>')
            message.addAttachmentObject(it.AttachmentName.text(), attachment)

        }
		
		message.setHeader("Content-Type", "application/xop+xml; charset=UTF-8; type=\"text/xml\"")
		message.setHeader("hasAttachments", "YES")
    }
	
	
	return message
	
}

def Message CopyRequest(Message message) {

	def target = message.getBody(String)
	def cc = message.getHeader("cXMLEnvelope",String)
	
	def attachmentDataSource = new ByteArrayDataSource(target, "text/xml")
    def attachment = new DefaultAttachment(attachmentDataSource)
	attachment.setHeader('Content-Transfer-Encoding', 'base64')
    attachment.setHeader('Content-ID', '<' + message.getProperty("anContentID") + '>')
	
    message.addAttachmentObject(message.getHeader("anAttachmentName",String), attachment)
	message.setBody(cc)
	return message
	
}

def Message clearAttachments(Message message) {

	Map<String, DataHandler> attachments = message.getAttachments();
	Map<String, AttachmentWrapper> attachmentWrappers = message.getAttachmentWrapperObjects();

	attachmentWrappers.clear();
	attachments.clear();

	message.setAttachments(attachments);
	message.setAttachmentWrapperObjects(attachmentWrappers);
	
	return message
}