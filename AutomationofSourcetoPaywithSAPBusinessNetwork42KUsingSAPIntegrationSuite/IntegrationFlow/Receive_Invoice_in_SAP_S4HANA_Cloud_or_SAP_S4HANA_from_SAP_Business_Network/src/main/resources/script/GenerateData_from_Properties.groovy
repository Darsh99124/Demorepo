import com.sap.gateway.ip.core.customdev.util.Message
import groovy.xml.*

def Message processData(Message message) {

    def properties = message.getProperties()
    def doctype = message.getHeader('SAP_MessageType', String)

    def crossref = properties.findAll { it.key.startsWith('_crossref_') && it.value != '' }
                      .collectEntries { [it.key.substring(10), it.value] }

    if (crossref) {
        def crossrefXml = generate_crossref(crossref, doctype)
        message.setProperty('intPackageCrossRef', crossrefXml)

        if (!crossrefXml?.trim()) {
            // Set to false only if the XML is blank
            message.setProperty('anCrossRefFlag', 'false')
        }
    } else {
        // Set to false only if no crossref data
        message.setProperty('anCrossRefFlag', 'false')
    }

    def lookup = properties.findAll { it.key.startsWith('_lookup_') && it.value != '' }
                    .collectEntries { [it.key.substring(8), it.value] }

    if (lookup) {
        def lookupXml = generate_lookuptable(lookup, doctype)
        message.setProperty('intPackageLookup', lookupXml)

        if (!lookupXml?.trim()) {
            // Set to false only if the XML is blank
            message.setProperty('anLookUpFlag', 'false')
        }
    } else {
        // Set to false only if no lookup data
        message.setProperty('anLookUpFlag', 'false')
    }

    return message
}

// Handler functions for different message contents
String generate_crossref(Map crossref, String doctype) {
    def writer = new StringWriter()
    def xml = new MarkupBuilder(writer)

    xml.ParameterCrossReference() {
        ListOfItems() {
            Item {
                DocumentType("$doctype")
                crossref.each {
                    "${it.key}"("${it.value}")
                }
            }
        }
    }
    return writer.toString()
}

String generate_lookuptable(Map lookup, String doctype) {
    def writer = new StringWriter()
    def xml = new MarkupBuilder(writer)

    xml.LOOKUPTABLE() {
        Parameter() {
            DocumentType("$doctype")
            Name("${lookup.Name}")
            ProductType("${lookup.ProductType}")
            ListOfItems() {
                Item {
                    Name("${lookup.ItemName}")
                    Value("${lookup.ItemValue}")
                }
            }
        }
    }
    return writer.toString()
}

String generate_uom(Map uom) {
    def writer = new StringWriter()
    def xml = new MarkupBuilder(writer)

    xml.UOM() {
        ListOfItems() {
            Item {
                uom.each {
                    "${it.key}"("${it.value}")
                }
            }
        }
    }
    return writer.toString()
}
