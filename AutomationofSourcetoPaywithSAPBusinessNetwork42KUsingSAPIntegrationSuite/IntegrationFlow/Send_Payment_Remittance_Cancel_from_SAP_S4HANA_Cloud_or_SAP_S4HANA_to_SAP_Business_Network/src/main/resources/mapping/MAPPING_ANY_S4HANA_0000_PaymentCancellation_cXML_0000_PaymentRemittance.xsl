<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:n0="http://sap.com/xi/EDI"
    exclude-result-prefixes="#all" version="2.0">
    <xsl:output method="xml" indent="no" omit-xml-declaration="yes"/>
    <xsl:param name="anIsMultiERP"/>
    <xsl:param name="anProviderANID"/>
    <xsl:param name="anPayloadID"/>
    <xsl:param name="anSenderID"/>
    <xsl:param name="anERPSystemID"/>
    <xsl:param name="anEnvName"/>
    <!--BPI-147 start -->
<!--    <xsl:include href="FORMAT_S4HANA_0000_cXML_0000.xsl"/>-->
    <xsl:include href="FORMAT_S4HANA_0000_cXML_0000.xsl" use-when="doc-available('FORMAT_S4HANA_0000_cXML_0000.xsl')"/>  <!-- Added changes in pd entries file for BPI-147 feature applied use-when logic-->
    <!--BPI-147 end -->
    <xsl:template match="/n0:PaymentAdviceCancellationNotification">
        <!--<Combined>
            <Payload>-->
        <cXML>
            <xsl:attribute name="timestamp">
                <xsl:variable name="curDate">
                    <xsl:value-of select="current-dateTime()"/>
                </xsl:variable>
                <xsl:value-of
                    select="concat(substring($curDate, 1, 19), substring($curDate, 24, 29))"/>
            </xsl:attribute>
            <xsl:attribute name="payloadID">
                <xsl:value-of select="$anPayloadID"/>
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
                    <Credential domain="VendorID">
                        <Identity>
                            <xsl:value-of select="replace(MessageHeader/RecipientParty/InternalID, '^0+','')"/>
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
                <PaymentRemittanceStatusUpdateRequest>
                    <DocumentReference>
                        <xsl:attribute name="payloadID">
                            <xsl:value-of select="concat(MessageHeader/RecipientParty/InternalID, PaymentAdviceCancellation/PaymentAdviceID, $anSenderID)"/>
                        </xsl:attribute>
                    </DocumentReference>
                    <PaymentRemittanceStatus>
                        <xsl:attribute name="type">
                            <xsl:value-of select="'canceled'"/>
                        </xsl:attribute>
                        <xsl:attribute name="paymentReferenceNumber">
                            <xsl:value-of select="substring(PaymentAdviceCancellation/PaymentAdviceID, 5, 10)"/>
                        </xsl:attribute>
                    </PaymentRemittanceStatus>
                </PaymentRemittanceStatusUpdateRequest>   
            </Request>
        </cXML>
        <!--</Payload>
        </Combined>-->
    </xsl:template>
</xsl:stylesheet>
