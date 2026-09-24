<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:n0="http://sap.com/xi/EDI/Creditor"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs" version="2.0">
    <xsl:output method="xml" indent="no" omit-xml-declaration="yes"/>
    <!--  Start BPI-147-->    
    <xsl:include href="FORMAT_S4HANA_0000_cXML_0000.xsl" use-when="doc-available('FORMAT_S4HANA_0000_cXML_0000.xsl')"/>
    <!-- End BPI-147-->
<!--            <xsl:include href="FORMAT_S4HANA_0000_cXML_0000.xsl"/>-->
    <!-- Main Template-->
    <xsl:template match="Combined/Payload">
        <n0:PayableLineItemPaymentTerms>
            <MessageHeader>
                <ID>
                    <xsl:value-of select="substring-before(cXML/@payloadID, '@')"/>
                </ID>
                <xsl:if test="string-length(normalize-space(cXML/Request/PaymentProposalRequest/@paymentProposalID)) > 0">
                    <ReferenceID>
                        <xsl:value-of
                            select="substring(cXML/Request/PaymentProposalRequest/@paymentProposalID, 1, 35)"/>
                    </ReferenceID>
                </xsl:if>
                <CreationDateTime>
                    <xsl:value-of select="cXML/@timestamp"/>
                </CreationDateTime>
                <ReconciliationIndicator>
                    <xsl:value-of select="'false'"/>
                </ReconciliationIndicator>
                <SenderBusinessSystemID>
                    <xsl:value-of select="'Ariba_Network'"/>
                </SenderBusinessSystemID>
                <RecipientBusinessSystemID>
                    <xsl:value-of select="substring(cXML/Header/To/Credential[@domain = 'NetworkID']/Identity, 1, 60)"/>
                </RecipientBusinessSystemID>
                <SenderParty>
                    <InternalID>
                        <xsl:value-of
                            select="substring(cXML/Header/From/Credential[@domain = 'SystemID']/Identity, 1, 32)"/>
                    </InternalID>
                </SenderParty>
                <!--                cXML Payload for Status Updates.-->
                <BusinessScope>
                    <TypeCode></TypeCode>
                    <InstanceID>
                        <xsl:attribute name="schemeID">
                            <xsl:value-of select="normalize-space(Payload/cXML/@payloadID)"/>
                        </xsl:attribute>
                    </InstanceID>
                </BusinessScope>
                <RecipientParty>
                    <InternalID>
                        <xsl:value-of
                            select="substring(cXML/Header/To/Credential[@domain = 'NetworkID']/Identity, 1, 32)"/>
                    </InternalID>
                </RecipientParty>
                <!--cXML Payload for Status Updates.-->
                <BusinessScope>
                    <InstanceID>
                        <xsl:attribute name="schemeID">
                            <xsl:value-of select="normalize-space(Payload/cXML/@payloadID)"/>
                        </xsl:attribute>
                    </InstanceID>
                </BusinessScope>
            </MessageHeader>
            <PayableLineItemPaymentTerms>
                <DiscountInformationId>
                    <xsl:value-of select="substring(cXML/Request/PaymentProposalRequest/@paymentProposalID, 1, 35)"/>
                </DiscountInformationId>
                <PaymentDate>
                    <xsl:value-of
                        select="substring(cXML/Request/PaymentProposalRequest/@paymentDate, 1, 10)"/>
                </PaymentDate>
                <GrossAmount>
                    <xsl:attribute name="currencyCode">
                        <xsl:value-of select="substring(cXML/Request/PaymentProposalRequest/GrossAmount/Money/@currency, 1, 5)"/>
                    </xsl:attribute>
                    <xsl:value-of select="cXML/Request/PaymentProposalRequest/GrossAmount/Money"/>
                </GrossAmount>
                <DiscountAmount>
                    <xsl:attribute name="currencyCode">
                        <xsl:value-of select="substring(cXML/Request/PaymentProposalRequest/DiscountAmount/Money/@currency, 1, 5)"/>
                    </xsl:attribute>
                    <xsl:value-of select="cXML/Request/PaymentProposalRequest/DiscountAmount/Money"/>
                </DiscountAmount>
                <NetAmount>
                    <xsl:attribute name="currencyCode">
                        <xsl:value-of select="substring(cXML/Request/PaymentProposalRequest/NetAmount/Money/@currency, 1, 5)"/>
                    </xsl:attribute>
                    <xsl:value-of select="cXML/Request/PaymentProposalRequest/NetAmount/Money"/>
                </NetAmount>
            </PayableLineItemPaymentTerms>
        </n0:PayableLineItemPaymentTerms>
    </xsl:template>
</xsl:stylesheet>
