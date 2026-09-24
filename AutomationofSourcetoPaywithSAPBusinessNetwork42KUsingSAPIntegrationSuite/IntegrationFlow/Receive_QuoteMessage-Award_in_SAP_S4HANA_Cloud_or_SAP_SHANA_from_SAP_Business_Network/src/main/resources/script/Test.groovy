import com.sap.gateway.ip.core.customdev.util.Message
import groovy.xml.*

def Message processData(Message message) {
    def properties = message.getProperties()
    def doctype = message.getHeader('SAP_MessageType', String)

    def crossref = properties.findAll { it.key.startsWith('_crossref_') && it.value != '' }.collectEntries { [it.key.substring(10), it.value] }
    if (crossref) {
        def xmlString = generateXmlString(doctype, crossref, 'ParameterCrossReference', 'ListOfItems', 'Item')
        def xmlSlurper = new XmlSlurper().parseText(xmlString)
        message.setProperty('intPackageCrossRef', xmlSlurper)
    }

    def lookup = properties.findAll { it.key.startsWith('_lookup_') && it.value != '' }.collectEntries { [it.key.substring(8), it.value] }
    if (lookup) {
        def xmlString = generateXmlString(doctype, lookup, 'LOOKUPTABLE', 'Parameter', 'ListOfItems', 'Item')
        def xmlSlurper = new XmlSlurper().parseText(xmlString)
        message.setProperty('intPackageLookup', xmlSlurper)
    }

    return message
}

// Function to generate XML string
String generateXmlString(String doctype, Map<String, String> contentMap, String... elements) {
    def writer = new StringWriter()
    def xml = new MarkupBuilder(writer)

    xml."${elements[0]}"() {
        contentMap.each { key, value ->
            "${elements[1]}"() {
                "${elements[2]}"(DocumentType: doctype)
                value.tokenize(',').each { item ->
                    "${elements[3]}"(key: item.split(':')[0], value: item.split(':')[1])
                }
            }
        }
    }

    // Return the unescaped XML string
    return unescapeXml(writer.toString())
}

// Function to unescape XML string
String unescapeXml(String xmlString) {
    def unescapedString = xmlString.replaceAll('&lt;', '<').replaceAll('&gt;', '>')
    return unescapedString
}
