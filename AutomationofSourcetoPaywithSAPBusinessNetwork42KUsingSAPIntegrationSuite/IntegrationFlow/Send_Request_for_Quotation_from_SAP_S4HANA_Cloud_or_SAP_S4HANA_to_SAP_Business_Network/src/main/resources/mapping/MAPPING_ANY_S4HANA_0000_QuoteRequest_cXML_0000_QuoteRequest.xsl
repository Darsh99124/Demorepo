<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:n0="http://sap.com/xi/Procurement"
    xmlns:hci="http://sap.com/it/" exclude-result-prefixes="xs n0 hci" version="2.0">
    <xsl:output method="xml" indent="no" omit-xml-declaration="yes"/>    
    <xsl:include href="FORMAT_S4HANA_0000_S4HANA_0000.xsl" use-when="doc-available('FORMAT_S4HANA_0000_S4HANA_0000.xsl')"/>
    <!--    <xsl:include href="FORMAT_S4HANA_0000_S4HANA_0000.xsl"/>-->
    <xsl:template match="/n0:RequestForQuotationS4Request">
        <cXML> 
            <xsl:attribute name="timestamp">
                <xsl:variable name="v_curDate">
                    <xsl:value-of select="current-dateTime()"/>
                </xsl:variable>
                <xsl:value-of
                    select="concat(substring($v_curDate, 1, 19), substring($v_curDate, 24, 29))"/>
            </xsl:attribute>
            <xsl:attribute name="payloadID">
                <xsl:value-of select="$anPayloadID"/>
            </xsl:attribute>  
            <Header>
                <xsl:call-template name="Fill_cXML_Header"> </xsl:call-template>   
            </Header>
            <Request>
                <xsl:choose>
                    <xsl:when test="$anEnvName = 'PROD'">
                        <xsl:attribute name="deploymentMode">production</xsl:attribute>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="deploymentMode">test</xsl:attribute>
                    </xsl:otherwise>
                </xsl:choose>
                <QuoteRequest>
                    <QuoteRequestHeader>
                    <xsl:call-template name="Fill_cXML_QuoteRequestHeader">
                        <xsl:with-param name="p_Quotation_header" select="//RequestForQuotation"/>
                        <xsl:with-param name="p_message" select="/n0:RequestForQuotationS4Request"/>
                    </xsl:call-template>
                    </QuoteRequestHeader>
                      <xsl:for-each select="//RequestForQuotationItem">
                          <QuoteItemOut>
                              <xsl:call-template name="Fill_cXML_QuoteRequestItem">
                                  <xsl:with-param name="p_Quotation_header" select="//RequestForQuotation"/>
                                  <xsl:with-param name="p_Quotation_item" select="."/>
                                  <xsl:with-param name="p_Quotation_plant" select="Plant"/>
                                  <xsl:with-param name="p_Quotation_address" select="DeliveryAddress"/>
                              </xsl:call-template>  
                          </QuoteItemOut>
                      </xsl:for-each>
                </QuoteRequest>    
            </Request>  
        </cXML>
    </xsl:template>
</xsl:stylesheet>
