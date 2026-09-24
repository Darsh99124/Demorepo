<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" exclude-result-prefixes="#all"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:n0="http://sap.com/xi/EDI/Debtor">
    <xsl:output method="xml" omit-xml-declaration="yes" indent="no"/>
    <!--BPI-147 start -->    
    <xsl:include href="FORMAT_S4HANA_0000_cXML_0000.xsl" use-when="doc-available('FORMAT_S4HANA_0000_cXML_0000.xsl')"/>
    <!--    <xsl:include href="FORMAT_S4HANA_0000_cXML_0000.xsl"/>-->
    <!--BPI-147 end -->
    <!-- Parameter declaration -->    
    <xsl:param name="p_path"/>
    <xsl:param name="anIsMultiERP"/>
    <xsl:param name="anProviderANID"/>    
    <xsl:param name="anSenderID"/>
    <xsl:param name="anERPSystemID"/>
    <xsl:param name="anPayloadID"/>
    <xsl:param name="anEnvName"/>    
    <!-- Main Template -->
    <xsl:template match="n0:PayableLineItemPaymentTerms">
        <cXML>
            <xsl:attribute name="payloadID">
                <xsl:value-of select="$anPayloadID"/>
            </xsl:attribute>
            <xsl:attribute name="timestamp">
                <xsl:variable name="curDate">
                    <xsl:value-of select="current-dateTime()"/>
                </xsl:variable>
                <xsl:value-of select="concat(substring-before($curDate, 'T'), 'T', substring(substring-after($curDate, 'T'), 1, 8), '+00:00')"/>
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
                        <xsl:if test="MessageHeader/RecipientParty/InternalID">
                            <Identity>
                                <xsl:value-of select="MessageHeader/RecipientParty/InternalID"/>
                            </Identity>
                        </xsl:if>
                    </Credential>
                </To>
                <Sender>
                    <Credential>
                        <xsl:attribute name="domain">
                            <xsl:value-of select="'NetworkID'"/>
                        </xsl:attribute>
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
                <PaymentProposalRequest>
                    <xsl:attribute name="paymentProposalID">
                        <xsl:value-of select="PayableLineItemPaymentTerms/DiscountInformationId"/>
                    </xsl:attribute>
                    <xsl:attribute name="operation">
                        <xsl:value-of select="PayableLineItemPaymentTerms/Operation"/>
                    </xsl:attribute>
                    <xsl:if test="string-length(normalize-space(PayableLineItemPaymentTerms/PaymentDate)) > 0">
                        <xsl:attribute name="paymentDate">
                            <xsl:call-template name="ANDateTime_S4HANA">
                                <xsl:with-param name="p_date" select="PayableLineItemPaymentTerms/PaymentDate"/>
                            </xsl:call-template>
                        </xsl:attribute>
                    </xsl:if>
                    <xsl:if test="string-length(normalize-space(PayableLineItemPaymentTerms/InvoiceData/BuyerOrganizationalUnit)) > 0">
                        <xsl:attribute name="companyCode">
                            <xsl:value-of select="PayableLineItemPaymentTerms/InvoiceData/BuyerOrganizationalUnit"/>
                        </xsl:attribute>
                    </xsl:if>
                    <PayableInfo>
                        <PayableInvoiceInfo>
                            <InvoiceIDInfo>
                                <xsl:attribute name="invoiceID">
                                    <xsl:value-of select="PayableLineItemPaymentTerms/InvoiceData/SupplierInvoiceId"/>
                                </xsl:attribute>
                                <xsl:if test="string-length(normalize-space(PayableLineItemPaymentTerms/InvoiceData/InvoiceDate)) > 0">
                                    <xsl:attribute name="invoiceDate">
                                        <xsl:call-template name="ANDateTime_S4HANA">
                                            <xsl:with-param name="p_date" select="PayableLineItemPaymentTerms/InvoiceData/InvoiceDate"/>
                                        </xsl:call-template>
                                    </xsl:attribute>
                                </xsl:if>
                            </InvoiceIDInfo>
                        </PayableInvoiceInfo>
                    </PayableInfo>
                    <PaymentMethod>
                        <xsl:attribute name="type">
                            <xsl:choose>
                                <xsl:when test="string-length(normalize-space(PayableLineItemPaymentTerms/PaymentFormCode)) > 0">
                                    <xsl:value-of select="PayableLineItemPaymentTerms/PaymentFormCode"/>
                                </xsl:when>                                
                                <xsl:otherwise>
                                    <xsl:value-of select="'other'"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                    </PaymentMethod>
                    <!-- create node only if Party PAYER available -->
                    <xsl:if test="PayableLineItemPaymentTerms/Party[@PartyType = 'PAYER']">
                        <PaymentPartner>
                            <Contact>
                                <xsl:attribute name="role">
                                    <xsl:value-of select="'payer'"/>
                                </xsl:attribute>
                                <xsl:attribute name="addressID">
                                    <xsl:value-of select="PayableLineItemPaymentTerms/Party[@PartyType = 'PAYER']/BuyerPartyID"/>
                                </xsl:attribute>
                                <xsl:call-template name="FillContactAddress">
                                    <xsl:with-param name="p_path" select="PayableLineItemPaymentTerms/Party[@PartyType = 'PAYER']"/>
                                </xsl:call-template>
                            </Contact>
                        </PaymentPartner>
                    </xsl:if>
                    <!-- create node only if Party PAYEE available -->
                    <xsl:if test="PayableLineItemPaymentTerms/Party[@PartyType = 'PAYEE']">
                        <PaymentPartner>
                            <Contact>
                                <xsl:attribute name="role">
                                    <xsl:value-of select="'payee'"/>
                                </xsl:attribute>
                                <xsl:attribute name="addressID">
                                    <xsl:value-of select="PayableLineItemPaymentTerms/Party[@PartyType = 'PAYEE']/SupplierPartyID"/>
                                </xsl:attribute>
                                <xsl:call-template name="FillContactAddress">
                                    <xsl:with-param name="p_path" select="PayableLineItemPaymentTerms/Party[@PartyType = 'PAYEE']"/>
                                </xsl:call-template>
                            </Contact>
                        </PaymentPartner>
                    </xsl:if>
                    <xsl:if test="string-length(normalize-space(PayableLineItemPaymentTerms/GrossAmount)) > 0">
                        <GrossAmount>
                            <Money>
                                <xsl:attribute name="currency">
                                    <xsl:value-of select="PayableLineItemPaymentTerms/GrossAmount/@currencyCode"/>
                                </xsl:attribute>
                                <xsl:value-of select="PayableLineItemPaymentTerms/GrossAmount"/>
                            </Money>
                        </GrossAmount>
                    </xsl:if>
                    <xsl:if test="string-length(normalize-space(PayableLineItemPaymentTerms/DiscountAmount)) > 0">
                        <DiscountAmount>
                            <Money>
                                <xsl:attribute name="currency">
                                    <xsl:value-of select="PayableLineItemPaymentTerms/DiscountAmount/@currencyCode"/>
                                </xsl:attribute>
                                <xsl:value-of select="PayableLineItemPaymentTerms/DiscountAmount"/>
                            </Money>
                        </DiscountAmount>
                    </xsl:if>
                    <xsl:if test="string-length(normalize-space(PayableLineItemPaymentTerms/NetAmount)) > 0">
                        <NetAmount>
                            <Money>
                                <xsl:attribute name="currency">
                                    <xsl:value-of select="PayableLineItemPaymentTerms/NetAmount/@currencyCode"/>
                                </xsl:attribute>
                                <xsl:value-of select="PayableLineItemPaymentTerms/NetAmount"/>
                            </Money>
                        </NetAmount>
                    </xsl:if>
                    <Extrinsic>
                        <xsl:attribute name="name">
                            <xsl:value-of select="'immediatepay'"/>
                        </xsl:attribute>
                        <xsl:value-of select="'yes'"/>
                    </Extrinsic>
                    <Extrinsic>
                        <xsl:attribute name="name">
                            <xsl:value-of select="'Ariba.relaxedOperationCheck'"/>
                        </xsl:attribute>
                    </Extrinsic>
                    <xsl:if test="string-length(normalize-space(PayableLineItemPaymentTerms/InvoiceData/BuyerOrganizationalUnit)) > 0">
                        <Extrinsic>
                            <xsl:attribute name="name">
                                <xsl:value-of select="'organizationUnit'"/>
                            </xsl:attribute>
                            <xsl:value-of select="PayableLineItemPaymentTerms/InvoiceData/BuyerOrganizationalUnit"/>
                        </Extrinsic>
                    </xsl:if>
                    <xsl:if test="string-length(normalize-space(PayableLineItemPaymentTerms/InvoiceData/SupplierInvoiceId)) > 0">
                        <Extrinsic>
                            <xsl:attribute name="name">
                                <xsl:value-of select="'originalInvoiceNo'"/>
                            </xsl:attribute>
                            <xsl:value-of select="PayableLineItemPaymentTerms/InvoiceData/SupplierInvoiceId"/>
                        </Extrinsic>
                    </xsl:if>
                    <xsl:if test="string-length(normalize-space(PayableLineItemPaymentTerms/InvoiceData/BuyerInvoiceId)) > 0">
                        <Extrinsic>
                            <xsl:attribute name="name">
                                <xsl:value-of select="'buyerInvoiceID'"/>
                            </xsl:attribute>
                            <xsl:value-of select="PayableLineItemPaymentTerms/InvoiceData/BuyerInvoiceId"/>
                        </Extrinsic>
                    </xsl:if>
                    <xsl:if test="string-length(normalize-space(PayableLineItemPaymentTerms/InvoiceData/BuyerFiscalYear)) > 0">
                        <Extrinsic>
                            <xsl:attribute name="name">
                                <xsl:value-of select="'fiscalYear'"/>
                            </xsl:attribute>
                            <xsl:value-of select="PayableLineItemPaymentTerms/InvoiceData/BuyerFiscalYear"/>
                        </Extrinsic>
                    </xsl:if>
                    <xsl:if test="string-length(normalize-space(PayableLineItemPaymentTerms/DiscountAmount)) > 0">
                        <Extrinsic>
                            <xsl:attribute name="name">
                                <xsl:value-of select="'earlyPaymentDiscount'"/>
                            </xsl:attribute>
                            <Money>
                                <xsl:attribute name="currency">
                                    <xsl:value-of select="PayableLineItemPaymentTerms/DiscountAmount/@currencyCode"/>
                                </xsl:attribute>
                                <xsl:value-of select="PayableLineItemPaymentTerms/DiscountAmount"/>
                            </Money>
                        </Extrinsic>
                    </xsl:if>
                </PaymentProposalRequest>
            </Request>
        </cXML>
    </xsl:template>
</xsl:stylesheet>
