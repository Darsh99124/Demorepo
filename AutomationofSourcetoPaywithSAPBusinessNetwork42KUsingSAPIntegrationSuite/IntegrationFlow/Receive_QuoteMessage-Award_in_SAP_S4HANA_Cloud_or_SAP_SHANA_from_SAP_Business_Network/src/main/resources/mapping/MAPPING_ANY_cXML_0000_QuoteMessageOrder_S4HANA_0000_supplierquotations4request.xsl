<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:n1="http://sap.com/xi/Procurement" xmlns:xop="http://www.w3.org/2004/08/xop/include"
    exclude-result-prefixes="#all">
    <xsl:output method="xml" indent="no" omit-xml-declaration="yes"/>
    <xsl:include href="FORMAT_S4HANA_0000_S4HANA_0000.xsl"
        use-when="doc-available('FORMAT_S4HANA_0000_S4HANA_0000.xsl')"/>
    <!--    <xsl:include href="FORMAT_S4HANA_0000_S4HANA_0000.xsl"/>-->
    <xsl:template match="Combined">
        <n1:SupplierQuotationS4Request>
            <MessageHeader>
                <xsl:call-template name="Fill_Proxy_Header"> </xsl:call-template>
            </MessageHeader>
            <SupplierQuotationS4>
                <xsl:call-template name="Fill_Proxy_QuoteMessageHeader">
                    <xsl:with-param name="p_QuoteMessage_header"
                        select="Payload/cXML/Message/QuoteMessage/QuoteMessageHeader"/>
                </xsl:call-template>
                <!--loop over all the items-->
                <xsl:for-each select="Payload/cXML/Message/QuoteMessage/QuoteItemIn">
                    <SupplierQuotationItem>
                        <xsl:call-template name="Fill_QuoteMessage_Item">
                            <xsl:with-param name="p_QuoteMessage_Item" select="."/>
                            <xsl:with-param name="p_QuoteMessage_header"
                                select="//QuoteMessageHeader"/>
                        </xsl:call-template>
                    </SupplierQuotationItem>
                </xsl:for-each>
            </SupplierQuotationS4>
        </n1:SupplierQuotationS4Request>
    </xsl:template>
</xsl:stylesheet>
