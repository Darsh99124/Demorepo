<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:hci="http://sap.com/it/"
    xmlns:xop="http://www.w3.org/2004/08/xop/include" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all" version="2.0">
    <xsl:output method="xml" indent="no" omit-xml-declaration="yes"/>
    <xsl:include href="FORMAT_S4HANA_0000_cXML_0000.xsl"/>
    <!--<xsl:include href="pd:HCIOWNERPID:FORMAT_S4HANA_0000_cXML_0000:Binary"/>-->
    <xsl:param name="anTargetDocumentType"/>
    <xsl:param name="anSupplierANID"/>
    <xsl:param name="anERPTimeZone"/>
    <xsl:param name="anEnvName"/>
    <xsl:param name="exchange"/>
    <xsl:param name="anProviderANID"/>
    <xsl:param name="anIsMultiERP"/>
    <xsl:param name="anERPSystemID"/>
    <xsl:param name="anPayloadID"/>
    <xsl:param name="anSenderID"/>
    <xsl:param name="Document_type" select="'QuoteMessageOrder'"/>
    <xsl:param name="anSourceDocumentType"/>
    <xsl:param name="anReceiverID"/>
    <xsl:param name="cXMLAttachments"/>
    <xsl:param name="anSenderDefaultTimeZone"/>
    <!--PD path-->
    <xsl:variable name="v_pdTarget">
        <xsl:call-template name="PrepareCrossref">
            <xsl:with-param name="p_doctype" select="$anTargetDocumentType"/>
            <xsl:with-param name="p_erpsysid" select="$anERPSystemID"/>
            <xsl:with-param name="p_ansupplierid" select="$anSupplierANID"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="v_pdSource">
        <xsl:call-template name="PrepareCrossref">
            <xsl:with-param name="p_doctype" select="$anSourceDocumentType"/>
            <xsl:with-param name="p_erpsysid" select="$v_sysid"/>
            <xsl:with-param name="p_ansupplierid" select="$anReceiverID"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="v_defaultLang">
        <xsl:call-template name="FillDefaultLang">
            <xsl:with-param name="p_doctype" select="$anTargetDocumentType"/>
            <xsl:with-param name="p_pd" select="$v_pdTarget"/>
        </xsl:call-template>
    </xsl:variable>
    <!--Multi ERP Scenario-->
    <xsl:variable name="v_sysid">
        <xsl:call-template name="MultiErpSysIdIN">
            <xsl:with-param name="p_ansysid"
                select="Combined/Payload/cXML/Header/To/Credential[@domain = 'SystemID']/Identity"/>
            <xsl:with-param name="p_erpsysid" select="$anERPSystemID"/>
        </xsl:call-template>
    </xsl:variable>
    <!--Covert Date coming from An to ERP format-->
    <xsl:variable name="v_date">
        <xsl:call-template name="ERPDateTime">
            <xsl:with-param name="p_date" select="Combined/Payload/cXML/Message/QuoteMessage/QuoteMessageHeader/@quoteDate"/>
            <xsl:with-param name="p_timezone" select="$anERPTimeZone"/>
        </xsl:call-template>
    </xsl:variable>
    <!--        Subcon OutboundDelivery Varialbles-->
    <xsl:variable name="v_currDT">
        <xsl:value-of select="current-dateTime()"/>
    </xsl:variable>
    <xsl:variable name="v_cigDT">
        <xsl:value-of
            select="concat(substring-before($v_currDT, 'T'), 'T', substring(substring-after($v_currDT, 'T'), 1, 8))"
        />
    </xsl:variable>
    <xsl:variable name="v_cigTS">
        <xsl:call-template name="ERPDateTime">
            <xsl:with-param name="p_date" select="$v_cigDT"/>
            <xsl:with-param name="p_timezone" select="$anSenderDefaultTimeZone"/>
        </xsl:call-template>
    </xsl:variable>
    <!--Templates for QuoteRequest-->
    <!--1. Template for the cXML Header: Fill_cXML_Header-->
    <!--2. Template for the Quote Request Header: Fill_cXML_QuoteRequestHeader-->
    <!--3. Template for the Quote Request Item: Fill_cXML_QuoteRequestItem-->
    <!--4. Template for the Addresses in Quote Request: Fill_cXML_Party -->  
    
    <!--cXML_HEADER-->
    <xsl:template name="Fill_cXML_Header">
        <From>
            <xsl:call-template name="MultiERPTemplateOut">
                <xsl:with-param name="p_anIsMultiERP" select="$anIsMultiERP"/>
                <xsl:with-param name="p_anERPSystemID" select="$anERPSystemID"/>
            </xsl:call-template>
            <Credential>
                <xsl:attribute name="domain">NetworkID</xsl:attribute>
                <Identity>
                    <xsl:value-of select="$anSenderID"/>
                </Identity>
            </Credential>
            <!--End Point Fix for CIG-->
            <Credential>
                <xsl:attribute name="domain">EndPointID</xsl:attribute>
                <Identity>CIG</Identity>
            </Credential>
        </From>
        <To>
            <Credential>
                <xsl:attribute name="domain">NetworkID</xsl:attribute>
                <Identity>
                    <xsl:value-of select="$anSenderID"/>
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
    </xsl:template>
    <!--QUOTE_REQUEST HEADER-->
    <xsl:template name="Fill_cXML_QuoteRequestHeader">
        <xsl:param name="p_Quotation_header"/>
        <xsl:param name="p_message"/>
        <xsl:param name="p_indicator"/>
        <xsl:attribute name="requestID">
            <xsl:value-of select="$p_Quotation_header/RequestForQuotationID"/>
        </xsl:attribute>
        <xsl:attribute name="openDate">
            <xsl:value-of select="concat(substring($p_Quotation_header/CreationDate, 1, 19), ('+00:00'))" />
        </xsl:attribute>
        <xsl:attribute name="requestDate">
            <xsl:value-of select="concat(substring($p_Quotation_header/CreationDate, 1, 19), ('+00:00'))" />
        </xsl:attribute>
        <xsl:attribute name="closeDate">
            <xsl:value-of select="concat(substring($p_Quotation_header/QuotationLatestSubmissionDate, 1, 19), ('+00:00'))" />
        </xsl:attribute>
        <xsl:attribute name="type">
            <xsl:value-of select="'new'"/>
        </xsl:attribute>
        <xsl:attribute name="currency">
            <xsl:value-of select="$p_Quotation_header/DocumentCurrency"/>
        </xsl:attribute>
        <xsl:attribute name="xml:lang">
            <xsl:value-of select="$p_Quotation_header/Language"/>
        </xsl:attribute>
        <Name>
            <xsl:attribute name="xml:lang">
                <xsl:value-of select="$p_Quotation_header/Language"/>
            </xsl:attribute>
            <xsl:value-of select="$p_Quotation_header/RequestForQuotationName"/>
        </Name>
        <SupplierSelector>
            <xsl:attribute name="matchingType">
                <xsl:value-of select="$p_Quotation_header/SupplierSelectorMatchingType"/>
            </xsl:attribute>
            <xsl:for-each select="$p_Quotation_header/RFQBidder">
                <SupplierInvitation>
                    <OrganizationID>
                        <Credential>
                            <!-- changed from 'PrivateID' into 'VendorID' for QE 2111 -->
                            <xsl:attribute name="domain">
                                <xsl:value-of select="'VendorID'"/>
                            </xsl:attribute>
                            <Identity>
                                <xsl:value-of select="Supplier"/>
                            </Identity>
                        </Credential>
                    </OrganizationID>
                    <Correspondent>
                        <Contact>
                            <xsl:attribute name="role">
                                <xsl:value-of select="'correspondent'"/>
                            </xsl:attribute>
                            <Name>
                                <xsl:attribute name="xml:lang">
                                    <xsl:value-of select="$p_Quotation_header/Language"/>
                                </xsl:attribute>
                                <xsl:value-of select="SupplierName"/>
                            </Name>
                        <!-- Integration of Quick enablement for QuoteRequest (42K) and CentralQuoteRequest (5JT)/ 2111 --> 
                            <xsl:if test="string-length(normalize-space(Email)) > 0">
                                <Email>
                                    <xsl:value-of select="Email"/>
                                </Email>
                            </xsl:if>
                        </Contact>
                    </Correspondent>
                </SupplierInvitation>
            </xsl:for-each>
        </SupplierSelector>
        <Contact>
            <xsl:attribute name="role">
                <xsl:value-of select="'buyer'"/>
            </xsl:attribute>
            <xsl:call-template name="Fill_cXML_Party">
                <xsl:with-param name="p_path" select="$p_Quotation_header/EmployeeResponsible/Address"/>
            </xsl:call-template>
        </Contact>
        <xsl:if test="exists($p_Quotation_header/Attachment) or exists($p_Quotation_header/TextCollection)">
            <xsl:variable name="v_lang">
                <xsl:choose>
                    <xsl:when test="string-length($p_Quotation_header/Language) > 0">
                        <xsl:value-of select="$p_Quotation_header/Language"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'en'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <Comments>
                <xsl:attribute name="xml:lang">
                    <xsl:value-of select="$v_lang"/>
                </xsl:attribute>
                <xsl:attribute name="type">
                    <xsl:value-of
                        select="$p_Quotation_header/TextCollection[ContentText/@languageCode = $v_lang]/TypeCode"
                    />
                </xsl:attribute>
                <xsl:value-of
                    select="$p_Quotation_header/TextCollection[ContentText/@languageCode = $v_lang]/ContentText"/>
                <xsl:call-template name="OutboundS4Attachment">
                    <xsl:with-param name="HeaderAttachment" select="$p_Quotation_header/Attachment"
                    />
                </xsl:call-template>
            </Comments>
            <!--Send the Fileanme to Platform, since MIME header from S4 doesn't send content/filename in the header.     Format sent to platform.    cid:cidValue1#filename1|cid:cidvalid2#filename2-->
            <xsl:variable name="ancXMLAttachments">
                <xsl:for-each select="$p_Quotation_header/Attachment">
                    <xsl:value-of
                        select="concat(string-join((*[namespace-uri() = 'http://www.w3.org/2004/08/xop/include' and local-name() = 'Include']/@href, @FileName,@MimeType), ';'), '#')"/>
                </xsl:for-each>
            </xsl:variable>
            <xsl:value-of use-when="function-available('hci:setHeader', 3)" select="hci:setHeader($exchange, 'ancXMLAttachments', $ancXMLAttachments)"/>
            <xsl:if test="$ancXMLAttachments">
                <!-- This is to make XSPEC assume that $ancXMLAttachments has some value -->
            </xsl:if>
            <!--                                                        <an><xsl:value-of select="$ancXMLAttachments"/></an>-->
        </xsl:if>
        <QuoteHeaderInfo>
            <LegalEntity>
                <IdReference>
                    <xsl:attribute name="identifier">
                        <xsl:value-of select="$p_Quotation_header/CompanyCode"/>
                    </xsl:attribute>
                    <xsl:attribute name="domain">CompanyCode</xsl:attribute>
                </IdReference>
            </LegalEntity>
            <xsl:if test="string-length(normalize-space($p_Quotation_header/PurchasingOrganization)) > 0">
            <OrganizationalUnit>
                <IdReference>
                    <xsl:attribute name="identifier">
                        <xsl:value-of select="$p_Quotation_header/PurchasingOrganization"/>
                    </xsl:attribute>
                    <xsl:attribute name="domain">PurchasingOrganization</xsl:attribute>
                </IdReference>
            </OrganizationalUnit>
            </xsl:if>
            <xsl:if test="string-length(normalize-space($p_Quotation_header/PurchasingGroup)) > 0">
            <OrganizationalUnit>
                <IdReference>
                    <xsl:attribute name="identifier">
                        <xsl:value-of select="$p_Quotation_header/PurchasingGroup"/>
                    </xsl:attribute>
                    <xsl:attribute name="domain">PurchasingGroup</xsl:attribute>
                </IdReference>
            </OrganizationalUnit>
            </xsl:if>
        </QuoteHeaderInfo>
        <!--        Indicator for CentralQuoteRequest. This flag is also used in XML_EXTRACT_VARIABLES.xsl-->
        <xsl:if test="$p_indicator = 'true'">
            <Extrinsic>
                <xsl:attribute name="name">quoteBusinessObject</xsl:attribute>
                <xsl:value-of select="'central'"/>
            </Extrinsic>
        </xsl:if>
    </xsl:template>
    <!--QUOTE REQUEST ITEM-->
    <xsl:template name="Fill_cXML_QuoteRequestItem">
        <xsl:param name="p_Quotation_item"/>
        <xsl:param name="p_Quotation_header"/>
        <xsl:param name="p_Quotation_address"/>
        <xsl:param name="p_Quotation_plant"/>
        <xsl:attribute name="itemClassification">
            <xsl:value-of select="'material'"/>
        </xsl:attribute>
        <xsl:attribute name="itemType">
            <xsl:value-of select="'item'"/>
        </xsl:attribute>
        <xsl:attribute name="quantity">
            <xsl:value-of select="RequestedQuantity"/>
        </xsl:attribute>
        <xsl:attribute name="lineNumber">
            <xsl:value-of select="replace(RequestForQuotationItemID, '^0+', '')"/>
        </xsl:attribute>
        <xsl:if test="string-length(normalize-space(DeliveryDate)) > 0">
        <xsl:attribute name="requestedDeliveryDate">
            <xsl:value-of select="concat(substring(DeliveryDate, 1, 10), ('T12:00:00'), ('+00:00'))" />
        </xsl:attribute>
        </xsl:if>
        <ItemID>
            <SupplierPartID/>
            <xsl:if test="string-length(normalize-space(Material)) > 0">
            <BuyerPartID>
                <xsl:value-of select="Material"/>
            </BuyerPartID>
            </xsl:if>
        </ItemID>
        <ItemDetail>
            <UnitPrice>
                <Money>
                    <xsl:attribute name="currency">
                        <xsl:value-of select="$p_Quotation_header/DocumentCurrency"/>
                    </xsl:attribute>
                </Money>
            </UnitPrice>
            <Description>
                <xsl:attribute name="xml:lang">
                    <xsl:value-of select="$v_defaultLang"/>
                </xsl:attribute>
                <xsl:value-of select="PurchasingDocumentItemText"/>
            </Description>
            <UnitOfMeasure>
                <xsl:value-of select="RequestedQuantity/@unitCode"/>
            </UnitOfMeasure>
            <Classification>
                <xsl:attribute name="domain">MaterialGroup</xsl:attribute>
                <xsl:value-of select="MaterialGroup"/>
            </Classification>
            <xsl:if test="string-length(normalize-space(ItemIncoterms/IncotermsClassification)) > 0">
                <Extrinsic>
                    <xsl:attribute name="name">Incoterms.Id</xsl:attribute>
                    <xsl:value-of select="ItemIncoterms/IncotermsClassification"/>
                </Extrinsic>
            </xsl:if>
        </ItemDetail>
        <!--       Here the DeliveryAddress comes from RequestForQuotationItem or from CentralRFQItmDistribution -->
        <ShipTo>
            <Address>
                <xsl:call-template name="Fill_cXML_Party">
                    <xsl:with-param name="p_path" select="$p_Quotation_address"/>
                    <xsl:with-param name="p_pathplant" select="$p_Quotation_plant"/>
                </xsl:call-template>
            </Address>
        </ShipTo>
        <xsl:variable name="v_lang">
            <xsl:choose>
                <xsl:when test="exists(../Language) and string-length(../Language) > 0">
                    <xsl:value-of select="../Language"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'en'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test="exists(TextCollection)">
            <Comments>
                <xsl:attribute name="xml:lang">
                    <xsl:value-of select="$v_lang"/>
                </xsl:attribute>
                <xsl:attribute name="type">
                    <xsl:value-of
                        select="TextCollection[ContentText/@languageCode = $v_lang]/TypeCode"/>
                </xsl:attribute>
                <xsl:value-of
                    select="TextCollection[ContentText/@languageCode = $v_lang]/ContentText"/>
            </Comments>
        </xsl:if>
    </xsl:template>
<!--    Template for Addresses in QuoteRequest.-->
<!--   It is in use for Contact in Header, ShipTo in RequestForQuotationItem and CentralRFQItmDistribution.-->
    <xsl:template name="Fill_cXML_Party">
        <xsl:param name="p_path"/>
        <xsl:param name="p_pathplant"/>
        <xsl:if test="string-length(normalize-space($p_path/Country)) > 0">
            <xsl:attribute name="isoCountryCode">
            <xsl:value-of select="$p_path/Country"/>
        </xsl:attribute>
            </xsl:if>
            <xsl:if test="$p_pathplant">
        <xsl:attribute name="addressIDDomain">
            <xsl:value-of select="'buyerLocationID'"/>
        </xsl:attribute>
        <xsl:attribute name="addressID">
            <xsl:value-of select="$p_pathplant"/>
        </xsl:attribute>
        </xsl:if>
        <Name>
            <xsl:attribute name="xml:lang">
                <xsl:value-of select="$v_defaultLang"/>
            </xsl:attribute>
            <xsl:value-of select="$p_path/FullName"/>
        </Name>
        <xsl:if test="string-length(normalize-space($p_path/StreetName)) > 0">
        <PostalAddress>
            <Street>
                <xsl:choose>
                    <xsl:when test="string-length(normalize-space($p_path/StreetAddressName)) > 0">
                        <xsl:value-of select="$p_path/StreetAddressName"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:choose>
                            <xsl:when test="$p_path/Country = 'DE'">
                                <xsl:value-of
                                    select="concat($p_path/StreetName, ' ', $p_path/HouseNumber)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of
                                    select="concat($p_path/HouseNumber, ' ', $p_path/StreetName)"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>   
                </xsl:choose>
            </Street>
            <City>
                <xsl:value-of select="$p_path/CityName"/>
            </City>
            <xsl:if test="string-length(normalize-space($p_path/Region)) > 0">
                <State>
                    <xsl:value-of select="$p_path/Region"/>
                </State>
            </xsl:if>
            <xsl:if test="string-length(normalize-space($p_path/PostalCode)) > 0">
                <PostalCode>
                    <xsl:value-of select="$p_path/PostalCode"/>
                </PostalCode>
            </xsl:if>
            <Country>
                <xsl:attribute name="isoCountryCode">
                    <xsl:value-of select="$p_path/Country"/>
                </xsl:attribute>
                <xsl:value-of select="$p_path/Country"/>
            </Country>
        </PostalAddress>
        </xsl:if>
        <xsl:if test="string-length(normalize-space($p_path/EmailAddress)) > 0">
            <Email>
                <xsl:if test="string-length(normalize-space($p_path/CorrespondenceLanguage)) > 0">
                <xsl:attribute name="preferredLang">
                    <xsl:value-of select="$p_path/CorrespondenceLanguage"/>
                </xsl:attribute>
                </xsl:if>
                <xsl:value-of select="$p_path/EmailAddress"/>
            </Email>
        </xsl:if>
        <xsl:if test="string-length(normalize-space($p_path/FormattedPhoneNumber)) > 0 or string-length(normalize-space($p_path/PhoneNumber/SubscriberID)) > 0">
                <Phone>
                    <TelephoneNumber>
                        <CountryCode>
                            <xsl:attribute name="isoCountryCode">
                                <xsl:choose>
                                    <xsl:when test="$p_path/PhoneNumber/CountryCode != ''">
                                        <xsl:value-of select="$p_path/PhoneNumber/CountryCode"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="$p_path/Country"/>
                                    </xsl:otherwise>
                                </xsl:choose> 
                            </xsl:attribute>
                            <xsl:value-of select="$p_path/PhoneNumber/CountryDiallingCode"/>
                        </CountryCode>
                        <AreaOrCityCode> 
                            <xsl:value-of select="$p_path/PhoneNumber/AreaID"/>
                        </AreaOrCityCode>
                        <Number>
                            <xsl:choose>
                                <xsl:when test="string-length(normalize-space($p_path/PhoneNumber/SubscriberID)) > 0">
                                    <xsl:value-of select="$p_path//PhoneNumber/SubscriberID"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$p_path/FormattedPhoneNumber"/>
                                </xsl:otherwise>
                            </xsl:choose> 
                        </Number>
                        <xsl:if test="string-length(normalize-space($p_path/PhoneNumber/ExtensionID)) > 0">
                        <Extension>
                            <xsl:value-of select="$p_path/PhoneNumber/ExtensionID"/>
                        </Extension>
                        </xsl:if>
                    </TelephoneNumber>
                </Phone>
            </xsl:if>
        <xsl:if test="string-length(normalize-space($p_path/FormattedFaxNumber)) > 0 or string-length(normalize-space($p_path/FaxNumber/SubscriberID)) > 0">
                <Fax>
                    <TelephoneNumber>
                        <CountryCode>
                            <xsl:attribute name="isoCountryCode">
                                <xsl:choose>
                                    <xsl:when test="$p_path/FaxNumber/CountryCode != ''">
                                        <xsl:value-of select="$p_path/FaxNumber/CountryCode"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="$p_path/Country"/>
                                    </xsl:otherwise>
                                </xsl:choose> 
                            </xsl:attribute>
                            <xsl:value-of select="$p_path/FaxNumber/CountryDiallingCode"/>
                        </CountryCode>
                        <AreaOrCityCode> 
                            <xsl:value-of select="$p_path/FaxNumber/AreaID"/>
                        </AreaOrCityCode>
                        <Number>
                            <xsl:choose>
                                <xsl:when test="string-length(normalize-space($p_path/FaxNumber/SubscriberID)) > 0">
                                    <xsl:value-of select="$p_path//FaxNumber/SubscriberID"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$p_path/FormattedFaxNumber"/>
                                </xsl:otherwise>
                            </xsl:choose> 
                        </Number>
                        <xsl:if test="string-length(normalize-space($p_path/FaxNumber/ExtensionID)) > 0">
                        <Extension>
                            <xsl:value-of select="$p_path/FaxNumber/ExtensionID"/>
                        </Extension>
                        </xsl:if>
                    </TelephoneNumber>
                </Fax>
            </xsl:if> 
    </xsl:template>
    
    <!--Templates for QuoteMessgeOrder-->
    <!--1. Template for the Soap Header: Fill_Proxy_Header-->
    <!--2. Template for the Quote Message Header: Fill_Proxy_QuoteMessageHeader-->
    <!--3. Template for the Quote Message Item: Fill_QuoteMessage_Item-->   

<!--    PROXY HEADER-->
    <xsl:template name="Fill_Proxy_Header">
    <CreationDateTime>
        <xsl:value-of select="$v_date"/>
    </CreationDateTime>
    <SenderBusinessSystemID>
        <xsl:value-of
            select="Payload/cXML/Header/From/Credential[@domain = 'NetworkID']/Identity"
        />
    </SenderBusinessSystemID>
    <RecipientBusinessSystemID>
        <xsl:value-of select="$v_sysid"/>
    </RecipientBusinessSystemID>
    </xsl:template>
<!--    QUOTEMESSAGE HEADER-->
    <xsl:template name="Fill_Proxy_QuoteMessageHeader">
        <xsl:param name="p_QuoteMessage_header"/>
        <SupplierQuotationExternalId>
            <xsl:value-of
                select="substring($p_QuoteMessage_header/@quoteID, string-length($p_QuoteMessage_header/@quoteID) - 9, 10)"/>
        </SupplierQuotationExternalId>
        <!--Populate the extra fields for Ariba Quote Message-->
        <!--format RFQ ID to 10 digits-->
            <RequestForQuotationId>
                <xsl:value-of
                    select="format-number($p_QuoteMessage_header/QuoteRequestReference/@requestID, '0000000000')" />
            </RequestForQuotationId>
        <SupplierQuotationExternalStatus>
            <xsl:value-of select="$p_QuoteMessage_header/@type"/>
        </SupplierQuotationExternalStatus>
        <SupplierQuotationSubmissionDate>
            <xsl:value-of select="$v_date"/>
        </SupplierQuotationSubmissionDate>
        <BindingPeriodEndDate>
            <xsl:value-of select="$v_date"/>
        </BindingPeriodEndDate>
        <FollowOnDocumentCategory>F</FollowOnDocumentCategory>
        <FollowOnDocumentType>
            <xsl:value-of>
                <xsl:call-template name="ReadQuote">
                    <xsl:with-param name="p_doctype" select="$Document_type"/>
                    <xsl:with-param name="p_pd" select="$v_pdSource"/>
                    <xsl:with-param name="p_attribute" select="'DocType'"/>
                </xsl:call-template>
            </xsl:value-of>
        </FollowOnDocumentType>
        <Supplier>
            <xsl:choose>
                <xsl:when test="Payload/cXML/Header/From/Credential/@domain = 'PrivateID'">
                    <xsl:value-of
                        select="Payload/cXML/Header/From/Credential[@domain = 'PrivateID']/Identity"
                    />
                </xsl:when>
                <xsl:when test="Payload/cXML/Header/From/Credential/@domain = 'VendorID'">
                    <xsl:value-of
                        select="Payload/cXML/Header/From/Credential[@domain = 'VendorID']/Identity"
                    />
                </xsl:when>
            </xsl:choose>
        </Supplier>
        <Language>
            <xsl:value-of select="substring(upper-case($p_QuoteMessage_header/@xml:lang), 1, 2)"/>
        </Language>
        <!--               Attachments Processing for 2005 release.
                   Only Header Level Attachments -->
        <xsl:if test="string-length($cXMLAttachments) > 0">
            <xsl:variable name = "HeaderAttachmentList" select="$cXMLAttachments"/>
            <xsl:variable name="HeaderAttachmentList">
                <xsl:call-template name="InboundS4Attachment">
                    <xsl:with-param name="AttachmentList">
                        <xsl:value-of select="$HeaderAttachmentList"/>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:variable>
            <xsl:copy-of select="$HeaderAttachmentList"/>
        </xsl:if>
    </xsl:template>
        
    <!--    QUOTEMESSAGE ITEM-->
    <xsl:template name="Fill_QuoteMessage_Item">       
        <xsl:param name="p_QuoteMessage_Item" />
        <xsl:param name="p_QuoteMessage_header" />
                <SupplierQuotationExternalItemID>
                    <xsl:value-of select="@lineNumber"/>
                </SupplierQuotationExternalItemID>
                <RequestForQuotationItemID>
                    <xsl:value-of select="@lineNumber"/>
                </RequestForQuotationItemID>
                <OfferedQuantity>
                    <xsl:attribute name="unitCode">
                        <xsl:value-of select="ItemDetail/UnitOfMeasure"/>
                    </xsl:attribute>
                    <xsl:value-of select="@quantity"/>
                </OfferedQuantity>
                <xsl:if test="string-length(normalize-space(ItemID/SupplierPartID)) > 0">
                    <SupplierMaterialNumber>
                        <xsl:value-of select="ItemID/SupplierPartID"/>
                    </SupplierMaterialNumber>
                </xsl:if>
                <xsl:if test="string-length(normalize-space(ItemDetail/ManufacturerName)) > 0">
                    <Manufacturer>
                        <xsl:value-of select="ItemDetail/ManufacturerName"/>
                    </Manufacturer>
                </xsl:if>
               <xsl:if test="string-length(normalize-space(ItemDetail/ManufacturerPartID)) > 0">
                    <ManufacturerPartNmbr>
                        <xsl:value-of select="ItemDetail/ManufacturerPartID"/>
                    </ManufacturerPartNmbr>
                </xsl:if>
                <PricingElements>
                    <ConditionTypeName>ORIGINALPRICE</ConditionTypeName>
                    <ConditionRateValue>
                        <xsl:value-of select="ItemDetail/UnitPrice/Money"/>
                    </ConditionRateValue>
                    <ConditionCurrency>
                        <xsl:value-of select="ItemDetail/UnitPrice/Money/@currency"/>
                    </ConditionCurrency>
                </PricingElements>
                <xsl:if test="Shipping/Money != ''">
                    <PricingElements>
                        <ConditionTypeName>SHIPPING</ConditionTypeName>
                        <ConditionRateValue>
                            <xsl:value-of select="Shipping/Money"/>
                        </ConditionRateValue>
                        <ConditionCurrency>
                            <xsl:value-of select="Shipping/Money/@currency"/>
                        </ConditionCurrency>
                    </PricingElements>
                </xsl:if>
        <xsl:if test="string-length(normalize-space(Comments)) > 0">
                    <TextCollection>
                        <ContentText>
                            <xsl:attribute name="languageCode">
                                <xsl:value-of select="substring(upper-case($p_QuoteMessage_header/@xml:lang), 1, 2)"/>
                            </xsl:attribute>                                    
                            <xsl:value-of select="Comments/text()"/>                                    
                        </ContentText>
                        <TypeCode>O01</TypeCode>                                
                    </TextCollection>
                </xsl:if>
        </xsl:template>  
    <!--Templates for Subcon OutboundDelivery-->
    <!--1. Template for Header Credentials: ASNHeader-->
    <!--2. Template for Deployment Mode: Deployment Mode-->
    <!--3. Template for Ship Notice Header: Ship Notice Header-->
    <!--4. Template for Contact Details: Contact Details-->
    <!--5. Template for Item Level Details: Item Level Details-->
    <xsl:template name="ASNHeader">
        <xsl:attribute name="timestamp">
            <xsl:value-of select="$v_cigTS"/>
        </xsl:attribute>
        <xsl:attribute name="payloadID">
            <xsl:value-of select="$anPayloadID"/>
        </xsl:attribute>
        <Header>
            <xsl:choose>
                <xsl:when test="Delivery/DeliveryItem[1]/DeliveryCategory[1] = 'LB'">
                    <From>
<!--                        Begin of change SBNI-1304-\\->-\->-->
<!--                        Add the ERPsystemID for MultiERP system-->
                        <xsl:call-template name="MultiERPTemplateOut">
                            <xsl:with-param name="p_anIsMultiERP" select="$anIsMultiERP"/>
                            <xsl:with-param name="p_anERPSystemID" select="$anERPSystemID"/>
                        </xsl:call-template>
<!--                        End of change SBNI-1304-\->-->
                        <Credential>
                            <xsl:attribute name="domain">NetworkID</xsl:attribute>
                            <Identity>
                                <xsl:value-of select="$anSenderID"/>
                            </Identity>
                        </Credential>
                        <Credential>
                            <xsl:attribute name="domain">EndPointID</xsl:attribute>
                            <Identity>
                                <xsl:value-of select="'CIG'"/>
                            </Identity>
                        </Credential>
                    </From>
                </xsl:when>
                <xsl:otherwise>
                    <From>
                        <Credential>
                            <xsl:attribute name="domain">NetworkID</xsl:attribute>
                            <Identity>
                                <xsl:choose>
                                    <xsl:when test="string-length(normalize-space(Delivery/SupplierSystemID)) > 0">
                                        <xsl:value-of select="Delivery/SupplierSystemID"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="$anSenderID" />
                                    </xsl:otherwise>
                                </xsl:choose>
                            </Identity>
                        </Credential>
                    </From>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="Delivery/DeliveryItem[1]/DeliveryCategory[1] = 'LB'">
            <To>
                <Credential>
                    <xsl:attribute name="domain">VendorID</xsl:attribute>
                    <Identity>
                        <xsl:value-of select="$anReceiverID"/>
                    </Identity>
                </Credential>
            </To>
                </xsl:when>
                <xsl:otherwise>
                    <To>
                        <Credential>
                            <xsl:attribute name="domain">NetworkID</xsl:attribute>
                            <Identity>
                                <xsl:choose>
                                    <xsl:when test="string-length(normalize-space(Delivery/BuyerSystemID)) > 0">
                                        <xsl:value-of select="Delivery/BuyerSystemID"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="$anReceiverID" />
                                    </xsl:otherwise>
                                </xsl:choose>
                            </Identity>
                        </Credential>
                    </To>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="Delivery/DeliveryItem[1]/DeliveryCategory[1] = 'LB'">
            <Sender>
                <Credential>
                    <xsl:attribute name="domain">NetworkID</xsl:attribute>
                    <Identity>
                        <xsl:value-of select="$anProviderANID"/>
                    </Identity>
                </Credential>
                <UserAgent>Ariba Supplier</UserAgent>
            </Sender>
                </xsl:when>
                <xsl:otherwise>
                    <Sender>
                    <Credential>
                        <xsl:attribute name="domain">NetworkID</xsl:attribute>
                        <Identity>
                            <xsl:value-of select="$anProviderANID"/>
                        </Identity>
                    </Credential>
                    <UserAgent>Ariba_Supplier</UserAgent>
                    </Sender>
                </xsl:otherwise>
            </xsl:choose>
        </Header>
    </xsl:template>
    <!--    Deployment Mode-->
    <xsl:template name="ASNDeployMode">
        <xsl:choose>
            <xsl:when test="$anEnvName = 'PROD'">
                <xsl:attribute name="deploymentMode">production</xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="deploymentMode">test</xsl:attribute>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!--    Ship Notice Header-->
    <xsl:template name="ASNShipNoticeHeader">
        <xsl:param name="p_path"/>
        <xsl:variable name="v_erpDT">
            <xsl:call-template name="ERPDateTime">
                <xsl:with-param name="p_date" select="./MessageHeader/CreationDateTime"/>
                <xsl:with-param name="p_timezone" select="$anSenderDefaultTimeZone"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:attribute name="deliveryDate">
            <xsl:value-of
                select="concat(substring(Delivery/DeliveryDateTime, 1, 19), $anSenderDefaultTimeZone)"
            />
        </xsl:attribute>
        <xsl:attribute name="shipmentDate">
            <xsl:value-of
                select="concat(substring(Delivery/GoodsIssueDateTime, 1, 19), $anSenderDefaultTimeZone)"
            />
        </xsl:attribute>
        <xsl:attribute name="noticeDate">
            <xsl:value-of select="concat(substring($v_erpDT, 1, 19), $anSenderDefaultTimeZone)"/>
        </xsl:attribute>
        <xsl:attribute name="operation">
            <xsl:value-of select="'new'"/>
        </xsl:attribute>
        <xsl:choose>
            <xsl:when test="Delivery/DeliveryItem[1]/DeliveryCategory[1] = 'LB'">
                <xsl:attribute name="shipmentID">
                    <xsl:value-of select="Delivery/DeliveryDocument"/>
                </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="shipmentID">
                    <xsl:value-of select="concat('ASN_', Delivery/DeliveryDocument)"/>
                </xsl:attribute>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!--    Contact Details-->
    <xsl:template name="ASNContact">
        <xsl:param name="p_path"/>
        <xsl:variable name="v_path" select="$p_path/Delivery/Party[@PartyType = 'AG']"/>
        <xsl:for-each select="$v_path">
            <Contact>
                <xsl:call-template name="FillContactAddress">
                    <xsl:with-param name="p_path" select="$v_path"/>
                </xsl:call-template>
            </Contact>
        </xsl:for-each>
    </xsl:template>
    <!--    Item Level Details-->
    <xsl:template name="ASNItemDetail">
        <xsl:param name="p_path"/>
        <Description>
            <xsl:attribute name="xml:lang">
                <xsl:value-of select="$v_defaultLang"/>
            </xsl:attribute>
            <xsl:value-of select="DeliveryDocumentItemText"/>
        </Description>
        <UnitOfMeasure>
            <xsl:value-of select="ActualDeliveredQtyInBaseUnit/@unitCode"/>
        </UnitOfMeasure>
    </xsl:template>
</xsl:stylesheet>

