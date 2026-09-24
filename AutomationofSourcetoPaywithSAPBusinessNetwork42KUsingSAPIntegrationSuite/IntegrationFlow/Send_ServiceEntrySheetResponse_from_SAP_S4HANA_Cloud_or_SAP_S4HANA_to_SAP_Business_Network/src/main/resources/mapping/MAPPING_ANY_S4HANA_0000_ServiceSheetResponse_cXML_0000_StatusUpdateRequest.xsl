<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:n0="http://sap.com/xi/SAPGlobal20/Global" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all" version="2.0">
    <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>
    <!--BPI-147 start -->
<!--     <xsl:include href="FORMAT_S4HANA_0000_cXML_0000.xsl"/>-->
     <!-- Added changes in pd entries file for BPI-147 feature applied use-when logic-->
    <xsl:include href="FORMAT_S4HANA_0000_cXML_0000.xsl" use-when="doc-available('FORMAT_S4HANA_0000_cXML_0000.xsl')"/>
    <!--BPI-147 end -->
    <xsl:param name="anSenderID"/>
    <xsl:param name="anERPSystemID"/>
    <xsl:param name="anERPTimeZone"/>
    <xsl:param name="anEnvName"/>
    <xsl:param name="anIsMultiERP"/>
    <xsl:param name="anTargetDocumentType"/>
    
    <!--  PD path-->
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
    <xsl:param name="anProviderANID"/>
    <xsl:param name="anPayloadID"/>
    <xsl:template match="n0:ServiceEntrySheetStsNotifMsg">
        <cXML>
            <xsl:attribute name="payloadID">
                <xsl:value-of select="$anPayloadID"/>
            </xsl:attribute>
            <xsl:attribute name="timestamp">
                <xsl:value-of select="concat(substring(string(current-date()), 1, 8), 'T', substring(string(current-time()), 1, 8), $anERPTimeZone)"/>
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
                    <!--End Point Fix for CIG-->
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
                            <xsl:value-of select="ServiceEntrySheetStatusEntity/Supplier"/>
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
                    <xsl:variable name="v_ses" select="ServiceEntrySheetStatusEntity/ServiceEntrySheet"/>
                    <Status>
                        <!-- Set the code to 200, if an Entrysheet was created, else 423 -->
                        <xsl:attribute name="code">
                            <xsl:choose>
                                <xsl:when test="string-length(normalize-space(ServiceEntrySheetStatusEntity/ServiceEntrySheet)) > 0">
                                    <xsl:value-of select="'200'"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="'423'"/>
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
                    <xsl:variable name="v_AppSts"
                        select="ServiceEntrySheetStatusEntity/ApprovalStatus"/>
                    <xsl:if test="exists($v_AppSts)">
                        <DocumentStatus>
                            <xsl:attribute name="type">
                                <xsl:choose>
                                    <xsl:when test="$v_AppSts = '10' and  ServiceEntrySheetStatusEntity/IsDeleted = 'true'">
                                        <xsl:value-of select="'canceled'"/>
                                    </xsl:when>
                                    <xsl:when test="$v_AppSts = '10' or $v_AppSts = '20'">
                                        <xsl:value-of select="'processing'"/>
                                    </xsl:when>
                                    <xsl:when test="$v_AppSts = '30'">
                                        <xsl:value-of select="'approved'"/>
                                    </xsl:when>
                                    <xsl:when test="$v_AppSts = '40'">
                                        <xsl:value-of select="'rejected'"/>
                                    </xsl:when>
                                </xsl:choose>
                            </xsl:attribute>
                            <xsl:if test="exists($v_ses)">
                                <DocumentInfo>
                                    <xsl:attribute name="documentID">
                                        <xsl:value-of select="ServiceEntrySheetStatusEntity/PurgDocExternalReference"/>
                                    </xsl:attribute>
                                    <xsl:attribute name="documentType">
                                        <xsl:value-of select="'ServiceEntryRequest'"/>
                                    </xsl:attribute>
                                    <!-- IG-45613: Time Zone not updated in SUR message - Start -->
                                    <xsl:variable name="externalRevisionDate">
                                        <xsl:if test="string-length(normalize-space(ServiceEntrySheetStatusEntity/ExternalRevisionDateTime)) > 8">
                                            <xsl:value-of select="substring(ServiceEntrySheetStatusEntity/ExternalRevisionDateTime,1,8)"/>
                                        </xsl:if>
                                    </xsl:variable>
                                    <xsl:variable name="externalRevisionTime">
                                        <xsl:if test="string-length(normalize-space(ServiceEntrySheetStatusEntity/ExternalRevisionDateTime)) > 14">
                                            <xsl:value-of select="substring(ServiceEntrySheetStatusEntity/ExternalRevisionDateTime,9,6)"/>
                                        </xsl:if>
                                    </xsl:variable>
                                    <!-- IG-45613: Time Zone not updated in SUR message - End -->
                                    <xsl:attribute name="documentDate">
                                        <xsl:call-template name="ANDateTime">
                                            <!-- IG-45613: Time Zone not updated in SUR message - Start -->
                                            <xsl:with-param name="p_date" select="$externalRevisionDate"/>
                                            <xsl:with-param name="p_time" select="$externalRevisionTime"/>
                                            <!-- IG-45613: Time Zone not updated in SUR message - End -->
                                            <xsl:with-param name="p_timezone" select="$anERPTimeZone"/>
                                        </xsl:call-template>
                                    </xsl:attribute>
                                </DocumentInfo>
                            </xsl:if>
                            <xsl:for-each select="ServiceEntrySheetStatusEntity/LogMessage">
                                <Comments>
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
                                    <xsl:value-of select="LogMessageText"/>
                                </Comments>
                            </xsl:for-each>
                            <xsl:for-each select="ServiceEntrySheetStatusEntity/TextCollection/Text">
                                <Comments>
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
                                    <xsl:attribute name="type">
                                        <xsl:value-of select="NoteTypeCode"/>
                                    </xsl:attribute>
                                    <xsl:value-of select="ContentText"/>
                                </Comments>
                            </xsl:for-each>
                        </DocumentStatus>
                    </xsl:if>
                    <Extrinsic>
                        <xsl:attribute name="name">
                            <xsl:value-of select="'ERP_ENTRYSHEET'"/>
                        </xsl:attribute>
                        <xsl:value-of select="ServiceEntrySheetStatusEntity/ServiceEntrySheet"/>
                    </Extrinsic>
                    <!-- Statement from AN-Side: 
                    We need to receive the milliseconds for the process where a SES approved is revoked.
                    In order to identify which message has to be consumed first.
                    -->
                    <xsl:if test="string-length(normalize-space(ServiceEntrySheetStatusEntity/MessageCreationDateTime))>0">
                        <Extrinsic>
                            <xsl:attribute name="name">
                                <xsl:value-of select="'MessageCreationDateTime'"/>
                            </xsl:attribute>
                            <xsl:value-of select="concat(substring(ServiceEntrySheetStatusEntity/MessageCreationDateTime,1,4),'-',
                                substring(ServiceEntrySheetStatusEntity/MessageCreationDateTime,5,2),'-',
                                substring(ServiceEntrySheetStatusEntity/MessageCreationDateTime,7,2),'T',
                                substring(ServiceEntrySheetStatusEntity/MessageCreationDateTime,9,2),':',
                                substring(ServiceEntrySheetStatusEntity/MessageCreationDateTime,11,2),':',
                                substring(ServiceEntrySheetStatusEntity/MessageCreationDateTime,13,2),'.',
                                substring-after(ServiceEntrySheetStatusEntity/MessageCreationDateTime, '.'),$anERPTimeZone)"/> 
                        </Extrinsic>
                    </xsl:if>
                </StatusUpdateRequest>
            </Request>
        </cXML>
    </xsl:template>
</xsl:stylesheet>
