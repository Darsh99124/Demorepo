<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:n0="http://sap.com/xi/EDI"
    exclude-result-prefixes="#all" version="2.0">
    <xsl:output method="xml" indent="no" omit-xml-declaration="yes"/>
    <xsl:param name="anProviderANID"/>    
    <xsl:param name="anIsMultiERP"/>
    <xsl:param name="anSenderID"/>
    <xsl:param name="anERPSystemID"/>
    <xsl:param name="anEnvName"/>
    <xsl:param name="anSourceDocumentType"/>
    <xsl:param name="anTargetDocumentType"/>
    <xsl:param name="anReceiverID"/>
<!--    <xsl:include href="FORMAT_S4HANA_0000_cXML_0000.xsl"/>-->
    <xsl:include href="FORMAT_S4HANA_0000_cXML_0000.xsl" use-when="doc-available('FORMAT_S4HANA_0000_cXML_0000.xsl')"/>   <!-- BPI-147 feature added logic for pd entries file applied use when logic -->
    <!-- Get the System Id -->
    <xsl:variable name="v_sysid">
        <xsl:call-template name="MultiErpSysIdIN">
            <xsl:with-param name="p_ansysid"
                select="cXML/Header/To/Credential[@domain = 'SystemID']/Identity"/>
            <xsl:with-param name="p_erpsysid" select="$anERPSystemID"/>
        </xsl:call-template>
    </xsl:variable>
    <!-- Prepare the CrossRef path -->
    <xsl:variable name="v_pd">
        <xsl:call-template name="PrepareCrossref">
            <xsl:with-param name="p_doctype" select="$anSourceDocumentType"/>
            <xsl:with-param name="p_erpsysid" select="$v_sysid"/>
            <xsl:with-param name="p_ansupplierid" select="$anReceiverID"/>
        </xsl:call-template>
    </xsl:variable>
    <!-- Get the Language code -->
    <xsl:variable name="v_lang">
        <xsl:call-template name="FillDefaultLang">
            <xsl:with-param name="p_doctype" select="$anSourceDocumentType"/>
            <xsl:with-param name="p_pd" select="$v_pd"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:template match="/n0:PaymentAdviceNotification">
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
                <xsl:value-of select="concat(MessageHeader/RecipientParty/InternalID, PaymentAdviceNotification/PaymentAdviceID, $anSenderID)"/>
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
                            <xsl:value-of select="PaymentAdviceNotification/Party/SupplierPartyID"/>
                        </Identity>
                    </Credential>
                    <!-- IG-51214 start -->
                    <Correspondent>
                        <Contact role="correspondent">
                            <Name>
                                <xsl:attribute name="xml:lang">
                                    <xsl:choose>
                                        <xsl:when test="string-length(normalize-space(PaymentAdviceNotification/Party[@PartyType='PAYEE']/Address/CorrespondenceLanguage)) > 0">
                                            <xsl:value-of select="PaymentAdviceNotification/Party[@PartyType='PAYEE']/Address/CorrespondenceLanguage"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:call-template name="FillDefaultLang">
                                                <xsl:with-param name="p_doctype" select="$anTargetDocumentType"/>
                                                <xsl:with-param name="p_pd" select="$v_pd"/>
                                            </xsl:call-template>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:attribute>
                                <xsl:value-of select="PaymentAdviceNotification/Party[@PartyType='PAYEE']/Address/AddressName"/>
                            </Name>
                            <xsl:if test="string-length(normalize-space(PaymentAdviceNotification/Party[@PartyType='PAYEE']/Address/EmailAddress))>0">
                                <Email name="routing">
                                    <xsl:value-of select="PaymentAdviceNotification/Party[@PartyType='PAYEE']/Address/EmailAddress"/>
                                </Email>
                            </xsl:if>
                            <xsl:if test="string-length(normalize-space(PaymentAdviceNotification/Party[@PartyType='PAYEE']/Address/FaxNumber))>0">
                                <Fax name="">
                                    <TelephoneNumber>
                                        <CountryCode>
                                            <xsl:attribute name="isoCountryCode">
                                                <xsl:value-of select="PaymentAdviceNotification/Party[@PartyType='PAYEE']/Address/FaxCountry"/> 
                                            </xsl:attribute>
                                        </CountryCode>
                                        <AreaOrCityCode><xsl:value-of select="PaymentAdviceNotification/Party[@PartyType='PAYEE']/Address/FaxCountryDialingCode"/> </AreaOrCityCode>
                                        <Number>
                                            <xsl:value-of select="PaymentAdviceNotification/Party[@PartyType='PAYEE']/Address/FaxNumber"/>
                                        </Number>
                                    </TelephoneNumber>
                                </Fax>
                            </xsl:if>
                        </Contact>
                    </Correspondent>
                    <!--  IG-51214 end  -->
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
                <PaymentRemittanceRequest>
                    <PaymentRemittanceRequestHeader>
                        <xsl:attribute name="paymentRemittanceID">
                            <xsl:value-of select="PaymentAdviceNotification/PaymentAdviceID"/>
                        </xsl:attribute>
                        <xsl:attribute name="paymentDate">
                            <xsl:value-of select="PaymentAdviceNotification/PaymentDate"/>
                        </xsl:attribute>
                        <xsl:attribute name="paymentReferenceNumber">
                            <xsl:value-of
                                select="substring(PaymentAdviceNotification/PaymentAdviceID, 5, 10)"
                            />
                        </xsl:attribute>
                        <PaymentMethod>
                            <xsl:attribute name="type">
                                <xsl:choose>
                                    <xsl:when test="PaymentAdviceNotification/PaymentFormCode = 04">
                                        <xsl:value-of select="'ach'"/>
                                    </xsl:when>
                                    <xsl:when test="PaymentAdviceNotification/PaymentFormCode = 05">
                                        <xsl:value-of select="'wire'"/>
                                    </xsl:when>
                                    <xsl:when test="PaymentAdviceNotification/PaymentFormCode = 06">
                                        <xsl:value-of select="'check'"/>
                                    </xsl:when>
                                </xsl:choose>

                            </xsl:attribute>
                        </PaymentMethod>
                        <xsl:for-each select="PaymentAdviceNotification/Party">
                            <PaymentPartner>
                                <Contact>
                                    <xsl:attribute name="role">
                                        <xsl:value-of select="@PartyType"/>
                                    </xsl:attribute>
                                    <Name>
                                        <xsl:attribute name="xml:lang">
                                            <xsl:value-of select="$v_lang"/>
                                        </xsl:attribute>
                                    </Name>
                                    <PostalAddress>
                                        <Street>
                                            <xsl:value-of select="Address/StreetName"/>
                                        </Street>
                                        <City>
                                            <xsl:value-of select="Address/CityName"/>
                                        </City>
                                        <State>
                                            <xsl:value-of select="Address/Region"/>
                                        </State>
                                        <PostalCode>
                                            <xsl:value-of select="Address/PostalCode"/>
                                        </PostalCode>
                                        <Country>
                                            <xsl:attribute name="isoCountryCode">
                                                <xsl:value-of select="Address/Country"/>
                                            </xsl:attribute>
                                        </Country>
                                    </PostalAddress>
                                    <Phone>
                                        <TelephoneNumber>
                                            <CountryCode>
                                                <xsl:attribute name="isoCountryCode">
                                                  <xsl:value-of select="Address/Country"/>
                                                </xsl:attribute>
                                            </CountryCode>
                                            <AreaOrCityCode>
                                                <xsl:value-of select="Address/City"/>
                                            </AreaOrCityCode>
                                            <Number>
                                                <xsl:value-of select="Address/PhoneNumber"/>
                                            </Number>
                                        </TelephoneNumber>
                                    </Phone>
                                </Contact>
                            </PaymentPartner>
                        </xsl:for-each>
                        <PaymentPartner>
                            <Contact>
                                <xsl:attribute name="role">
                                    <xsl:value-of select="'originatingBank'"/>
                                </xsl:attribute>
                                <Name>
                                    <xsl:attribute name="xml:lang">
                                        <xsl:value-of select="$v_lang"/>
                                    </xsl:attribute>
                                    <xsl:value-of
                                        select="/PaymentAdviceNotification/PaymentTransactionInitiatorBankAccount/BankName"
                                    />
                                </Name>
                            </Contact>
                        </PaymentPartner>
                        <PaymentPartner>
                            <Contact>
                                <xsl:attribute name="role">
                                    <xsl:value-of select="'recievingBank'"/>
                                </xsl:attribute>
                                <Name>
                                    <xsl:attribute name="xml:lang">
                                        <xsl:value-of select="$v_lang"/>
                                    </xsl:attribute>
                                    <xsl:value-of
                                        select="PaymentAdviceNotification/PaymentTransactionInitiatorBankAccount/BankName"
                                    />
                                </Name>
                            </Contact>
                            <IdReference>
                                <xsl:attribute name="identifier">
                                    <xsl:value-of
                                        select="PaymentAdviceNotification/PaymentTransactionInitiatorBankAccount/BankAccountID"
                                    />
                                </xsl:attribute>
                                <xsl:attribute name="domain">
                                    <xsl:value-of select="'bankAccountID'"/>
                                </xsl:attribute>
                            </IdReference>
                            <IdReference>
                                <xsl:attribute name="identifier">
                                    <xsl:value-of
                                        select="PaymentAdviceNotification/PaymentTransactionInitiatorBankAccount/SwiftID"
                                    />
                                </xsl:attribute>
                                <xsl:attribute name="domain">
                                    <xsl:value-of select="'swiftID'"/>
                                </xsl:attribute>
                            </IdReference>
                            <IdReference>
                                <xsl:attribute name="identifier">
                                    <xsl:value-of
                                        select="PaymentAdviceNotification/PaymentTransactionInitiatorBankAccount/BankRoutingID"
                                    />
                                </xsl:attribute>
                                <xsl:attribute name="domain">
                                    <xsl:value-of select="'bankRoutingID'"/>
                                </xsl:attribute>
                            </IdReference>
                        </PaymentPartner>
                    </PaymentRemittanceRequestHeader>
                    <PaymentRemittanceSummary>
                        <NetAmount>
                            <Money>
                                <xsl:attribute name="currency">
                                    <xsl:value-of
                                        select="PaymentAdviceNotification/NetAmount/@currencyCode"/>
                                </xsl:attribute>
                                <xsl:value-of select="PaymentAdviceNotification/NetAmount"/>
                            </Money>
                        </NetAmount>
                        <GrossAmount>
                            <Money>
                                <xsl:attribute name="currency">
                                    <xsl:value-of
                                        select="PaymentAdviceNotification/GrossAmount/@currencyCode"
                                    />
                                </xsl:attribute>
                                <xsl:value-of select="PaymentAdviceNotification/GrossAmount"/>
                            </Money>
                        </GrossAmount>
                        <DiscountAmount>
                            <Money>
                                <xsl:attribute name="currency">
                                    <xsl:value-of
                                        select="PaymentAdviceNotification/CashDiscountAmount/@currencyCode"
                                    />
                                </xsl:attribute>
                                <xsl:value-of select="PaymentAdviceNotification/CashDiscountAmount"
                                />
                            </Money>
                        </DiscountAmount>
                    </PaymentRemittanceSummary>
                    <xsl:for-each select="PaymentAdviceNotification/PaymentExplanationItem">
                        <RemittanceDetail>
                            <xsl:attribute name="lineNumber">
                                <xsl:value-of select="normalize-space(PaymentAdviceItemID)"/>
                            </xsl:attribute>
                            <PayableInfo>
                                <PayableInvoiceInfo>
                                    <InvoiceIDInfo>
                                        <xsl:attribute name="invoiceID">
                                            <xsl:value-of select="PaymentReferenceID/ID"/>
                                        </xsl:attribute>
                                        <xsl:attribute name="invoiceDate">
                                            <xsl:value-of select="BusinessTransactionDocumentDate"/>
                                        </xsl:attribute>
                                    </InvoiceIDInfo>
                                </PayableInvoiceInfo>
                            </PayableInfo>
                            <NetAmount>
                                <Money>
                                    <xsl:attribute name="currency">
                                        <xsl:value-of select="NetAmount/@currencyCode"/>
                                    </xsl:attribute>
                                    <xsl:value-of select="NetAmount"/>
                                </Money>
                            </NetAmount>
                            <GrossAmount>
                                <Money>
                                    <xsl:attribute name="currency">
                                        <xsl:value-of
                                            select="TransactionCurrencyGrossAmount/@currencyCode"/>
                                    </xsl:attribute>
                                    <xsl:value-of select="TransactionCurrencyGrossAmount"/>
                                </Money>
                            </GrossAmount>
                            <DiscountAmount>
                                <Money>
                                    <xsl:attribute name="currency">
                                        <xsl:value-of
                                            select="TransactionCurrencyCashDiscountAmount/@currencyCode"
                                        />
                                    </xsl:attribute>
                                    <xsl:value-of select="TransactionCurrencyCashDiscountAmount"/>
                                </Money>
                            </DiscountAmount>
                        </RemittanceDetail>
                    </xsl:for-each>
                </PaymentRemittanceRequest>
            </Request>
        </cXML>
        <!--</Payload>
        </Combined>-->
    </xsl:template>
</xsl:stylesheet>
