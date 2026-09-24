<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="#all">
    <xsl:output method="xml" indent="yes" omit-xml-declaration="no" doctype-system="http://#HOST#.ariba.com/schemas/cXML/#VERSION#/#SCHEMA#.dtd"/>
    
    <!--
		Description: map "XSLT Map to generate CXML Reposne"
		Date: 07/25/2017
		Created: Vinay Avva.
		Version: 1.1
		
		08/09/2018 : CG - Update to fix cXML version and timestamp
	-->
    <xsl:param name="anCorrelationID"/>
    <!--IG-4889 change to correct cXML version case in variable name -->
    <xsl:param name="ancXMLVersion"/> 
    <xsl:param name="anCode"/>
    <xsl:param name="anText"/>
    
    <xsl:template match="*">
        
        <xsl:element name="cXML">
            <xsl:attribute name="payloadID">
                <xsl:value-of select="$anCorrelationID"/>
            </xsl:attribute>
            <!--IG-4889 change on timestamp creation -->
            <xsl:attribute name="timestamp">
                <xsl:value-of select="format-dateTime(current-dateTime(), '[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01][Z]')"/>    
            </xsl:attribute>
            <xsl:attribute name="version">
                <xsl:value-of select="$ancXMLVersion"/>
            </xsl:attribute>			
            <Response>
                <Status>
                    <xsl:choose>
                        <xsl:when test="$anCode = '201'">
                            <xsl:attribute name="code">
                                <xsl:text>201</xsl:text>
                            </xsl:attribute>        
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="code">200</xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:choose>
                        <xsl:when test="$anText='Acknowledged'">
                            <xsl:attribute name="text">Acknowledged</xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="text">Success</xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                        <xsl:choose>
                            <xsl:when test="$anText='Acknowledged'">
                                <xsl:text>Acknowledged</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>Success</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                </Status>
            </Response>			
        </xsl:element>
    </xsl:template>   
</xsl:stylesheet>