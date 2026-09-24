<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:n0="http://sap.com/xi/Procurement" exclude-result-prefixes="#all" version="2.0">
    <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>    
    <xsl:param name="anProviderANID"/>
<!--    <xsl:include href="FORMAT_S4HANA_0000_cXML_0000.xsl"/>-->
    <!--BPI-147 start -->
    <xsl:include href="FORMAT_S4HANA_0000_cXML_0000.xsl" use-when="doc-available('FORMAT_S4HANA_0000_cXML_0000.xsl')"/>
    <!-- IG-51632 S4 HANA ISU is failing in CIG Begin-->
    <xsl:param name="anERPTimeZone"/>
    <xsl:param name="anSenderDefaultTimeZone"/>
    <xsl:param name="anSenderID"/>
    <xsl:param name="anPayloadID"/>
    <xsl:param name="anERPSystemID"/>
    <xsl:param name="anTargetDocumentType"/>
    <xsl:param name="anEnvName"/>
    <xsl:param name="anIsMultiERP"/>
    <xsl:variable name="v_pd">
        <xsl:call-template name="PrepareCrossref">
            <xsl:with-param name="p_doctype" select="$anTargetDocumentType"/>
            <xsl:with-param name="p_erpsysid" select="$anERPSystemID"/>
            <xsl:with-param name="p_ansupplierid" select="$anSenderID"/>
        </xsl:call-template>
    </xsl:variable>
    <!--  Default lang-->
    <xsl:variable name="v_lang">
        <xsl:call-template name="FillDefaultLang">
            <xsl:with-param name="p_doctype" select="$anTargetDocumentType"/>
            <xsl:with-param name="p_pd" select="$v_pd"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="v_currDT">
        <xsl:value-of select="current-dateTime()"/>
    </xsl:variable>
    <xsl:variable name="v_cigDT">
        <xsl:value-of select="concat(substring-before($v_currDT, 'T'), 'T', substring(substring-after($v_currDT, 'T'), 1 , 8))"/>
    </xsl:variable>
    <xsl:variable name="v_cigTS">
        <xsl:call-template name="ERPDateTime">
            <xsl:with-param name="p_date" select="$v_cigDT"/>
            <!--IG-51632: Begin-->
            <xsl:with-param name="p_timezone">
                <xsl:choose>
                    <xsl:when test="$anSenderDefaultTimeZone != ''">
                        <xsl:value-of select="$anSenderDefaultTimeZone"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$anERPTimeZone"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
            <!--IG-51632: End-->
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="v_erpDT">
        <xsl:call-template name="ERPDateTime">
            <xsl:with-param name="p_date"
                select="n0:InvoiceStatusUpdateNotification/MessageHeader/CreationDateTime"/>
            <!--IG-51632: Begin-->
            <xsl:with-param name="p_timezone">
                <xsl:choose>
                    <xsl:when test="$anSenderDefaultTimeZone != ''">
                        <xsl:value-of select="$anSenderDefaultTimeZone"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$anERPTimeZone"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
            <!--IG-51632: End-->
        </xsl:call-template>
    </xsl:variable>
    <xsl:template match="n0:InvoiceStatusUpdateNotification">
        <cXML>
            <xsl:attribute name="payloadID">
                <xsl:value-of select="$anPayloadID"/>
            </xsl:attribute>
            <xsl:attribute name="timestamp">
                <xsl:value-of select="$v_cigTS"/>
            </xsl:attribute>
            <Header>
                <From>
                    <xsl:call-template name="MultiERPTemplateOut">
                        <xsl:with-param name="p_anIsMultiERP" select="$anIsMultiERP"/>
                        <xsl:with-param name="p_anERPSystemID" select="$anERPSystemID"/>
                    </xsl:call-template>
                    <Credential>
                        <xsl:attribute name="domain">
                            <xsl:value-of select="'NetworkID'"/>
                        </xsl:attribute>
                        <Identity>
                            <xsl:value-of select="$anSenderID"/>
                        </Identity>
                    </Credential>
                    <Credential>
                        <xsl:attribute name="domain">
                            <xsl:value-of select="'EndPointID'"/>
                        </xsl:attribute>
                        <Identity>
                            <xsl:value-of select="'CIG'"/>
                        </Identity>
                    </Credential>
                </From>
                <To>
                    <Credential>
                        <xsl:attribute name="domain">
                            <xsl:value-of select="'VendorID'"/>
                        </xsl:attribute>
                        <Identity>
                            <xsl:value-of select="replace(MessageHeader/RecipientParty/InternalID/@schemeID, '^0+', '')"/>
                        </Identity>
                    </Credential>
                </To>
                <Sender>
                    <Credential domain="NetworkID">
                        <Identity>
                            <xsl:value-of select="$anProviderANID"/>
                        </Identity>
                    </Credential>
                    <UserAgent>
                        <xsl:value-of select="'Ariba Supplier'"/>
                    </UserAgent>
                </Sender>
            </Header>
            <Request>
                <xsl:choose>
                    <xsl:when test="$anEnvName = 'PROD'">
                        <xsl:attribute name="deploymentMode">
                            <xsl:value-of select="'production'"/>
                        </xsl:attribute>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="deploymentMode">
                            <xsl:value-of select="'test'"/>
                        </xsl:attribute>
                    </xsl:otherwise>
                </xsl:choose>
                <StatusUpdateRequest>
                    <Status>
                        <xsl:attribute name="code">
                            <xsl:choose>
                                <xsl:when test="(InvoiceStatus/SupplierInvoiceStatusDesc = 'REJECTED') or (InvoiceStatus/SupplierInvoiceStatusDesc = 'FAILED')">
                                    <xsl:value-of select="'423'"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="'200'"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                        <xsl:attribute name="text">
                            <xsl:value-of select="'OK'"/>
                        </xsl:attribute>
                        <!-- Fallback default is "en" -->
                        <xsl:choose>
                            <xsl:when test="string-length(normalize-space($v_lang)) > 0">
                                <xsl:attribute name="xml:lang">
                                    <xsl:value-of select="$v_lang"/>
                                </xsl:attribute>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:attribute name="xml:lang">
                                    <xsl:value-of select="'en'"/>
                                </xsl:attribute>
                            </xsl:otherwise>
                        </xsl:choose>
                    </Status>
                    <InvoiceStatus>
                        <xsl:attribute name="type">
                            <xsl:choose>
                                <xsl:when test="InvoiceStatus/SupplierInvoiceStatusDesc = 'CANCELLED'">
                                    <xsl:value-of select="'rejected'"/>
                                </xsl:when>
                                <xsl:when test="InvoiceStatus/SupplierInvoiceStatusDesc = 'FAILED'">
                                    <xsl:value-of select="'canceled'"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="lower-case(InvoiceStatus/SupplierInvoiceStatusDesc)"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                        <xsl:if test="string-length(normalize-space(InvoiceStatus/DocumentReferenceID)) > 0">
                            <InvoiceIDInfo>
                                <xsl:attribute name="invoiceID">
                                    <xsl:value-of select="InvoiceStatus/DocumentReferenceID"/>
                                </xsl:attribute>
                                <xsl:if test="string-length(normalize-space($v_erpDT)) > 0">
                                    <xsl:attribute name="invoiceDate">
                                        <xsl:value-of select="$v_erpDT"/>
                                    </xsl:attribute>
                                </xsl:if>
                            </InvoiceIDInfo>
                        </xsl:if>
                        <xsl:if test="string-length(normalize-space(InvoiceStatus/Comments)) > 0">
                            <Comments>
                                <xsl:if test="string-length(normalize-space(InvoiceStatus/Comments/@languageCode)) > 0">
                                    <xsl:attribute name="xml:lang">
                                        <xsl:value-of
                                            select="lower-case(InvoiceStatus/Comments/@languageCode)"/>
                                    </xsl:attribute>
                                </xsl:if>
                                <xsl:value-of select="InvoiceStatus/Comments"/>
                            </Comments>
                        </xsl:if>
                    </InvoiceStatus>
                    <xsl:if
                        test="string-length(normalize-space(InvoiceStatus/SupplierInvoice)) > 0 and string-length(normalize-space(InvoiceStatus/SupplierInvoice)) > 0">
                        <Extrinsic>
                            <xsl:attribute name="name">
                                <xsl:value-of select="'Ariba.ERPInvoiceNumber'"/>
                            </xsl:attribute>
                            <xsl:value-of select="concat(InvoiceStatus/SupplierInvoice, InvoiceStatus/FiscalYear)"/>
                        </Extrinsic>
                    </xsl:if>
                </StatusUpdateRequest>
            </Request>
        </cXML>
    </xsl:template>
</xsl:stylesheet>