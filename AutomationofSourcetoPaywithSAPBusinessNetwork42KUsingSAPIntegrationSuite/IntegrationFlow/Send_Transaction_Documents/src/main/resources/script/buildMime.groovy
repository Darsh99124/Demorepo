import com.sap.gateway.ip.core.customdev.util.Message
import javax.mail.util.ByteArrayDataSource
import javax.mail.internet.MimeBodyPart
import javax.mail.internet.MimeMessage
import javax.mail.internet.MimeMultipart
import javax.activation.DataHandler
import org.apache.commons.io.IOUtils
import org.apache.camel.Attachment
import com.sap.gateway.ip.core.customdev.util.AttachmentWrapper
import org.apache.camel.impl.DefaultAttachment
import java.util.Map.Entry
import java.util.Iterator
import org.apache.http.entity.ContentType

def Message processData(Message message) {
    // Step 1: Clean body and check attachments
    def body = message.getBody(String)?.trim()
    def attMap = message.getAttachments()
    def headers = message.getHeaders()
    def attWrapperMap = message.getAttachmentWrapperObjects()
    def messageLog = messageLogFactory.getMessageLog(message)

    int attCount = attMap.size()
    message.setHeader("anAttCount", attCount.toString())
    message.setHeader("adapterFrom", headers.get("adapterFrom"))

    // If there are attachments, set MIME flags
    if (attCount > 0) {
        message.setHeader("MIME", "true")
        addCustomHeader(message, "anHasAttachment", "True")

        // Validate and wrap Content-ID headers properly
        Iterator<Entry<String, AttachmentWrapper>> iterator = attWrapperMap.entrySet().iterator()
        while (iterator.hasNext()) {
            Entry<String, AttachmentWrapper> entry = iterator.next()
            Attachment attachment = entry.getValue()
            String cid = message.getAttachmentHeader("Content-ID", attachment)
            if (cid && cid.trim()) {
                if (!cid.startsWith("<")) cid = "<" + cid
                if (!cid.endsWith(">")) cid = cid + ">"
                attachment.setHeader("Content-ID", cid)
                messageLog.setStringProperty("Normalized Content-ID", cid)
            }
        }
    } else if (headers.get("MIME")) {
        message.setHeader("MIME", "true")
        addCustomHeader(message, "anHasAttachment", "True")
    }

    message.setHeader("Content-Type", "text/xml; charset=UTF-8")

    // Step 2: Prepare MIME Multipart message
    byte[] payload = body.getBytes("UTF-8")
    MimeMessage mimeMessage = new MimeMessage((javax.mail.Session) null)
    MimeMultipart mimeMultipart = new MimeMultipart("mixed")

    // Add main XML payload
    MimeBodyPart payloadPart = new MimeBodyPart()
    ByteArrayDataSource xmlData = new ByteArrayDataSource(payload, "application/xml")
    payloadPart.setDataHandler(new DataHandler(xmlData))
    payloadPart.setHeader("Content-Type", "text/xml; charset=UTF-8")
    payloadPart.setHeader("Content-Transfer-Encoding", "8bit")
    mimeMultipart.addBodyPart(payloadPart)

    // Add attachments
    attWrapperMap.each { entry ->
        def attachment = entry.value
        DataHandler dh = attachment.getDataHandler()
        def inputStream = dh.getInputStream()
        byte[] bytes = IOUtils.toByteArray(inputStream)
        ByteArrayDataSource encodedAttachment = new ByteArrayDataSource(bytes, attachment.getHeader("Content-Type"))
        MimeBodyPart attachmentPart = new MimeBodyPart()
        attachmentPart.setDataHandler(new DataHandler(encodedAttachment))

        // Set headers on attachment
        attachment.getHeaderNames().each { headerName ->
            def headerVal = attachment.getHeader(headerName)
            if (headerName == "Content-Transfer-Encoding") {
                headerVal = "base64"
            }
            attachmentPart.setHeader(headerName, headerVal)
        }

        mimeMultipart.addBodyPart(attachmentPart)
        inputStream.close()
    }

    // Finalize and write to message body
    ByteArrayOutputStream baos = new ByteArrayOutputStream()
    mimeMultipart.writeTo(baos)

    try {
        def contentType = ContentType.parse(mimeMultipart.getContentType())
        message.setHeader("Content-Type", contentType.toString())
    } catch (Exception ignored) {}

    message.setBody(baos.toByteArray())

    return message
}

// Helper function to add custom header for logging
def addCustomHeader(Message message, String key, String val) {
    def messageLog = messageLogFactory.getMessageLog(message)
    if (val) {
        messageLog.addCustomHeaderProperty(key, "" + val)
    }
}
