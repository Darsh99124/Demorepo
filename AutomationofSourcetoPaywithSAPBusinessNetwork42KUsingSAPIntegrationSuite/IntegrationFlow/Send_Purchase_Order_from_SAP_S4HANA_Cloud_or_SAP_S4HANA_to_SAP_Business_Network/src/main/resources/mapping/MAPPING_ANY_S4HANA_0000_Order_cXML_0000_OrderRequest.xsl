<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:n0="http://sap.com/xi/EDI"
    xmlns:hci="http://sap.com/it/" xmlns:xop="http://www.w3.org/2004/08/xop/include" version="2.0"
    exclude-result-prefixes="#all">
    <xsl:output method="xml" indent="no" omit-xml-declaration="yes"/>
<!--BPI-147 Start    -->
    <!--<xsl:include href="pd:HCIOWNERPID:FORMAT_S4HANA_0000_cXML_0000:Binary" use-when="doc-available('pd:HCIOWNERPID:FORMAT_S4HANA_0000_cXML_0000:Binary')"/>-->
    <xsl:include href="FORMAT_S4HANA_0000_cXML_0000.xsl" use-when="doc-available('FORMAT_S4HANA_0000_cXML_0000.xsl')"/>
<!--BPI-147 End    -->
<!--    <xsl:include href="FORMAT_S4HANA_0000_cXML_0000.xsl"/>-->
    <xsl:param name="anIsMultiERP"/>
    <xsl:param name="anERPTimeZone"/>
    <xsl:param name="anSenderID"/>
    <xsl:param name="anERPSystemID"/>
    <xsl:param name="anTargetDocumentType"/>
    <xsl:param name="anProviderANID"/>
    <xsl:param name="anPayloadID"/>
    <xsl:param name="anEnvName"/>
    <xsl:param name="exchange"/>
    <xsl:variable name="v_pd">
        <xsl:call-template name="PrepareCrossref">
            <xsl:with-param name="p_doctype" select="$anTargetDocumentType"/>
            <xsl:with-param name="p_erpsysid" select="$anERPSystemID"/>
            <xsl:with-param name="p_ansupplierid" select="$anSenderID"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="v_defaultLang">
        <xsl:call-template name="FillDefaultLang">
            <xsl:with-param name="p_doctype" select="$anTargetDocumentType"/>
            <xsl:with-param name="p_pd" select="$v_pd"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:template match="n0:OrderRequest">
        <xsl:variable name="v_billTo" select="/n0:OrderRequest/Order/Party[@PartyType = 'BillTo']"/>
        <xsl:variable name="v_shipTo" select="/n0:OrderRequest/Order/Party[@PartyType = 'ShipTo']"/>
        <xsl:variable name="v_soldTo" select="/n0:OrderRequest/Order/Party[@PartyType = 'SoldTo']"/>
        <xsl:variable name="v_supplier" select="/n0:OrderRequest/Order/Party[@PartyType = 'Supplier']"/>
        <!--Begin of Changes SBNI-2013-->
        <xsl:variable name="v_copySup" select="/n0:OrderRequest/Order/Party[@PartyType = 'CpySuplr']"/>
        <!--End of Changes SBNI-2013-->
        <xsl:variable name="v_empty" select="''"/>
        <xsl:variable name="v_LineItem">
            <xsl:for-each select="Order/OrderItem">
                <xsl:value-of select="position()"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="v_lineitem_actioncode">
            <xsl:for-each select="Order/OrderItem">
                <!-- BPI-252 PO Enhancements -->
                <xsl:if test="ActionCode = '03' and string-length(normalize-space(IsBlocked))=0">
                    <xsl:value-of select="position()"/>
                </xsl:if>
                <!-- BPI-252 PO Enhancements -->
            </xsl:for-each>
        </xsl:variable>
        <!-- CI-1732  first Item Plant to variables -->
        <xsl:variable name="v_plant">
            <xsl:value-of select="Order/OrderItem[1]/Plant"/>
        </xsl:variable>
        <!-- CI-1732  first Item Storage Location to variables -->
        <xsl:variable name="v_storage_location">
            <xsl:value-of select="Order/OrderItem[1]/StorageLocation"/>
        </xsl:variable>
        <cXML>
            <xsl:attribute name="payloadID">
                <xsl:value-of select="$anPayloadID"/>
            </xsl:attribute>
            <!-- CI-2112 Time Zone Mapping -->
            <xsl:attribute name="timestamp">
                <xsl:variable name="v_curDate">
                    <xsl:value-of select="current-dateTime()"/>
                </xsl:variable>
                <xsl:value-of select="concat(substring-before($v_curDate, 'T'), 'T', substring(substring-after($v_curDate, 'T'), 1, 8), '+00:00')"/>
            </xsl:attribute>
            <!-- CI-2112 -->
            <Header>
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
                        <xsl:attribute name="domain">VendorID</xsl:attribute>
                        <xsl:if test="($v_supplier) or ($v_soldTo)">
                            <Identity>
                                <xsl:choose>
                                    <xsl:when
                                        test="string-length(normalize-space($v_supplier/BuyerPartyID)) > 0">
                                        <xsl:value-of select="$v_supplier/BuyerPartyID"/>
                                    </xsl:when>
                                    <xsl:otherwise>                            
                                        <xsl:value-of select="$v_soldTo/BuyerPartyID"/>                               
                                    </xsl:otherwise>
                                </xsl:choose>                              
                            </Identity>
                        </xsl:if>
                    </Credential>
                    <xsl:if test="$v_supplier">
                        <Correspondent>
                            <Contact>
                                <xsl:attribute name="role">correspondent</xsl:attribute>
                                <Name>
                                    <xsl:call-template name="FillLangOut">
                                        <xsl:with-param name="p_spras_iso" select="$v_empty"/>
                                        <xsl:with-param name="p_spras" select="$v_supplier/Address/CorrespondenceLanguage"/>
                                        <xsl:with-param name="p_lang" select="$v_defaultLang"/>
                                    </xsl:call-template>
                                    <xsl:value-of select="$v_supplier/Address/AddressName"/>
                                </Name>
                                <PostalAddress>
                                    <Street>
                                        <xsl:choose>
                                            <xsl:when
                                                test="string-length(normalize-space($v_supplier/Address/StreetAddressName)) > 0">
                                                <xsl:value-of select="$v_supplier/Address/StreetAddressName"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:choose>
                                                    <xsl:when test="$v_supplier/Address/Country = 'DE'">
                                                        <xsl:value-of select="concat($v_supplier/Address/StreetName, ' ', $v_supplier/Address/HouseNumber)"/>
                                                    </xsl:when>
                                                    <xsl:otherwise>
                                                        <xsl:value-of select="concat($v_supplier/Address/HouseNumber, ' ', $v_supplier/Address/StreetName)"/>
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </Street>
                                    <City>
                                        <xsl:value-of select="$v_supplier/Address/CityName"/>
                                    </City>
                                    <xsl:if test="string-length(normalize-space($v_supplier/Address/Region)) > 0">
                                        <State>
                                        <xsl:value-of select="$v_supplier/Address/Region"/>
                                    </State>
                                    </xsl:if>
                                    <xsl:if test="string-length(normalize-space($v_supplier/Address/PostalCode)) > 0">
                                        <PostalCode>
                                        <xsl:value-of select="$v_supplier/Address/PostalCode"/>
                                    </PostalCode>
                                    </xsl:if>
                                    <Country>
                                        <xsl:attribute name="isoCountryCode">
                                            <xsl:value-of select="$v_supplier/Address/Country"/>
                                        </xsl:attribute>
                                        <xsl:value-of select="$v_supplier/Address/Country"/>
                                    </Country>
                                </PostalAddress>
                                <xsl:if test="string-length(normalize-space($v_supplier/Address/EmailAddress)) > 0">
                                    <Email>
                                        <xsl:attribute name="name">routing</xsl:attribute>
                                        <xsl:value-of select="$v_supplier/Address/EmailAddress"/>
                                    </Email>
                                    </xsl:if>
                                <xsl:if test="string-length(normalize-space($v_supplier/Address/PhoneNumber)) > 0">
                                    <Phone>
                                        <TelephoneNumber>
                                            <CountryCode>
                                                <xsl:attribute name="isoCountryCode">
                                                    <xsl:value-of select="$v_supplier/Address/Country"/>
                                                </xsl:attribute>
                                            </CountryCode>
                                            <AreaOrCityCode/>
                                                <Number>
                                                    <xsl:value-of select="$v_supplier/Address/PhoneNumber"/>
                                                </Number>
                                        </TelephoneNumber>
                                    </Phone>
                                </xsl:if>
                                <!-- CI-2530- Quick enablement: Complete fax number is supported  -->
                                <xsl:if test="string-length(normalize-space($v_supplier/Address/FaxNumber)) > 0 or string-length(normalize-space($v_supplier/Address/FaxDetails/Number)) > 0 
                                    or string-length(normalize-space($v_supplier/Address/FaxCountryDialingCode)) > 0 or string-length(normalize-space($v_supplier/Address/FaxExtension)) > 0 ">
                                    <Fax>
                                        <!-- CI-1543 Quick Enablement of Supplier on AN -->
                                        <xsl:if test="string-length(normalize-space($v_supplier/Address/EmailAddress)) = 0">
                                            <xsl:attribute name="name">routing</xsl:attribute>
                                        </xsl:if>
                                        <!-- CI-1543 -->
                                        <TelephoneNumber>
                                            <CountryCode>
                                                <xsl:attribute name="isoCountryCode">
                                                    <xsl:choose>
                                                        <xsl:when test="string-length(normalize-space($v_supplier/Address/FaxCountry)) > 0">
                                                            <xsl:value-of select="$v_supplier/Address/FaxCountry"/>
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                        <xsl:value-of select="$v_supplier/Address/Country"/>
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                                </xsl:attribute>
                                                <xsl:choose>
                                                    <xsl:when test="string-length(normalize-space($v_supplier/Address/FaxDetails/TelephoneCountryPrefix)) > 0">
                                                        <xsl:value-of
                                                            select="$v_supplier/Address/FaxDetails/TelephoneCountryPrefix"
                                                        />  
                                                    </xsl:when>
                                                    <xsl:otherwise>
                                                        <xsl:value-of
                                                            select="$v_supplier/Address/FaxCountryDialingCode"
                                                        />
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                            </CountryCode>
                                            <AreaOrCityCode/>
                                                <Number>
                                                    <xsl:choose>
                                                        <xsl:when test="string-length(normalize-space($v_supplier/Address/FaxDetails/Number)) > 0">
                                                            <xsl:value-of select="$v_supplier/Address/FaxDetails/Number"/>
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <xsl:value-of select="$v_supplier/Address/FaxNumber"/>
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                                </Number>
                                            <xsl:if test="string-length(normalize-space($v_supplier/Address/FaxDetails/Extension)) > 0 or string-length(normalize-space($v_supplier/Address/FaxExtension)) > 0">
                                            <Extension>
                                                <xsl:choose>
                                                    <xsl:when test="string-length(normalize-space($v_supplier/Address/FaxDetails/Extension)) > 0">
                                                        <xsl:value-of select="$v_supplier/Address/FaxDetails/Extension"/>                              
                                                    </xsl:when>
                                                    <xsl:otherwise>
                                                        <xsl:value-of select="$v_supplier/Address/FaxExtension"/>
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                                 
                                            </Extension>
                                            </xsl:if>
                                        </TelephoneNumber>
                                    </Fax>
                                </xsl:if>
                            </Contact>
                        </Correspondent>
                    </xsl:if>
                </To>
                <Sender>
                    <Credential>
                        <xsl:attribute name="domain">NetworkID</xsl:attribute>
                        <Identity>
                            <xsl:value-of select="$anProviderANID"/>
                        </Identity>
                    </Credential>
<!--                    Changed this to S4CORE, AN need to  differentiate whether document is coming from MM-SRV or lean-->
                    <UserAgent>S4CORE</UserAgent> 
                </Sender>
                <!--Begin of Changes SBNI-2013-->
                <xsl:if test="exists($v_copySup)">
                    <Path>
                        <Node>
                            <xsl:attribute name="type">
                                <xsl:value-of select="'copy'"/>
                            </xsl:attribute>
                            <Credential>
                                <xsl:attribute name="domain">
                                    <xsl:value-of select="'VendorID'"/>
                                </xsl:attribute>
                                <Identity>
                                    <xsl:value-of select="$v_copySup/SupplierPartyID"/>
                                </Identity>
                            </Credential>
                        </Node>
                    </Path>
                    <OriginalDocument>
                        <xsl:attribute name="payloadID">
                            <xsl:value-of select="$v_empty"/>
                        </xsl:attribute>
                    </OriginalDocument>
                </xsl:if>
                <!--End of Changes SBNI-2013-->
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
                <OrderRequest>
                    <OrderRequestHeader>
                        <xsl:attribute name="orderID">
                            <xsl:value-of select="Order/PurchaseOrderID"/>
                        </xsl:attribute>
                        <!-- CI-2112 Time Zone Mapping -->
                        <xsl:attribute name="orderDate">
                            <xsl:choose>
                                <xsl:when test="exists(Order/PurchaseOrderDocumentDateTime)">
                                    <xsl:value-of select="Order/PurchaseOrderDocumentDateTime"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:if test="string-length(normalize-space(Order/PurchaseOrderCreationDate)) > 0">
                                        <xsl:call-template name="ANDateTime_S4HANA_V1">
                                            <xsl:with-param name="p_date" select="Order/PurchaseOrderCreationDate"/>
                                            <xsl:with-param name="p_time" select="''"/>
                                            <xsl:with-param name="p_timezone" select="$anERPTimeZone"/>
                                        </xsl:call-template>
                                    </xsl:if>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                        <!-- CI-2112 -->
                        <xsl:variable name="v_action">
                            <xsl:value-of select="/n0:OrderRequest/Order/ActionCode"/>
                        </xsl:variable>
                        <xsl:if test="$v_action = '01'">
                            <xsl:attribute name="type">new</xsl:attribute>
                        </xsl:if>
                        <xsl:choose>
                            <xsl:when test="($v_LineItem = $v_lineitem_actioncode)">
                                <xsl:attribute name="type">delete</xsl:attribute>
                            </xsl:when>
                            <xsl:when
                                test="not(string($v_LineItem) = string($v_lineitem_actioncode)) and not(string($v_action) = '01')">
                                <xsl:attribute name="type">update</xsl:attribute>
                            </xsl:when>
                        </xsl:choose>                      
                        <xsl:variable name="v_expamt">
                            <xsl:for-each select="//OrderItem">
                                <!--CI-1634 IG-51656 Return PO -->
                                <xsl:choose>
                                    <xsl:when test="not(ActionCode = '03') and IsReturnsItem = 'true'">
                                        <xsl:choose>
                                            <xsl:when test="string-length(ExpectedNetAmount) > 0">
                                                <value>
                                                    <xsl:value-of select="(-1) * ExpectedNetAmount"/>
                                                </value>
                                            </xsl:when>
                                            <xsl:otherwise>0.00</xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:when>
                                    <xsl:when test= "not(ActionCode = '03')">
                                        <xsl:choose>
                                            <xsl:when test="string-length(ExpectedNetAmount) > 0">
                                                <value>
                                                    <xsl:value-of select="ExpectedNetAmount"/>
                                                </value>
                                            </xsl:when>
                                            <xsl:otherwise>0.00</xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:when>
                                </xsl:choose>
                                <!--CI-1634 IG-51656 Return PO -->
                            </xsl:for-each>
                        </xsl:variable>
                        <!-- Internal Incident: 2170073885 currency mapping changed. -->
                        <Total>
                            <Money>
                                <xsl:attribute name="currency">
                                    <xsl:value-of select="/n0:OrderRequest/Order/TransactionCurrency"/>
                                </xsl:attribute>
                                <xsl:value-of select="format-number(sum($v_expamt/value), '0.00')"/>
                            </Money>
                        </Total>
                        <xsl:if test="$v_shipTo">
                            <ShipTo>
                                <Address>
                                    <xsl:call-template name="FillPartyAddress">
                                        <xsl:with-param name="p_path" select="$v_shipTo" />
                                        <xsl:with-param name="p_lang" select="$v_defaultLang"/>
                                    </xsl:call-template>
                                </Address>
                                <!-- CI-1732  first Item Plant under Ship To Address -->
                                <xsl:if test="string-length(normalize-space($v_plant)) > 0">
                                    <IdReference>
                                        <xsl:attribute name="identifier" select="$v_plant"/>
                                        <xsl:attribute name="domain">buyerLocationID</xsl:attribute>
                                    </IdReference>
                                </xsl:if>
                                <!-- CI-1732  first Item Storage Location under Ship To Address -->
                                <xsl:if
                                    test="string-length(normalize-space($v_storage_location)) > 0">
                                    <IdReference>
                                        <xsl:attribute name="identifier" select="$v_storage_location"/>
                                        <xsl:attribute name="domain">storageLocationID</xsl:attribute>
                                    </IdReference>
                                </xsl:if>
                                <!-- CI-1732 -->
                            </ShipTo>                              
                        </xsl:if>
                        <xsl:if test="exists($v_billTo) and string-length($v_billTo/Address/StreetName) > 0">
                            <BillTo>
                                <Address>
                                    <xsl:call-template name="FillPartyAddress">
                                        <xsl:with-param name="p_path" select="$v_billTo"/>
                                        <xsl:with-param name="p_lang" select="$v_defaultLang"/>
                                    </xsl:call-template>
                                </Address>
                            </BillTo>
                        </xsl:if>
                        <xsl:if test="$v_soldTo">
                            <BusinessPartner>
                                <xsl:attribute name="type">organization</xsl:attribute>
                                <xsl:attribute name="role">soldTo</xsl:attribute>
                                <Address>
                                    <xsl:call-template name="FillPartyAddress">
                                        <xsl:with-param name="p_path" select="$v_soldTo"/>
                                        <xsl:with-param name="p_lang" select="$v_defaultLang"/>
                                    </xsl:call-template>
                                </Address>
                                <xsl:if test="string-length(normalize-space($v_soldTo/BuyerPartyID)) > 0">
                                    <IdReference>
                                        <xsl:attribute name="identifier"
                                            select="$v_soldTo/BuyerPartyID"/>
                                        <xsl:attribute name="domain" select="'buyerAccountID'"/>
                                    </IdReference>
                                </xsl:if>
                                <xsl:if test="string-length(normalize-space($v_soldTo/SupplierPartyID)) > 0">
                                    <IdReference>
                                        <xsl:attribute name="identifier"
                                            select="$v_soldTo/SupplierPartyID"/>
                                        <xsl:attribute name="domain" select="'supplierID'"/>
                                    </IdReference>
                                </xsl:if>
                            </BusinessPartner>
                        </xsl:if>
                        <!-- CI-1637 CompanyCode -->
                        <xsl:if test="string-length(normalize-space(Order/CompanyCode)) > 0">
                            <LegalEntity>
                                <IdReference>
                                    <xsl:attribute name="identifier" select="Order/CompanyCode"/>
                                    <xsl:attribute name="domain" select="'CompanyCode'"/>
                                    <xsl:if test="string-length(normalize-space(Order/CompanyCodeName)) > 0">
                                        <Description>
                                            <xsl:call-template name="FillLangOut">
                                                <xsl:with-param name="p_spras_iso" select="$v_empty"/>
                                                <xsl:with-param name="p_spras" select="$v_soldTo/Address/CorrespondenceLanguage"/>
                                                <xsl:with-param name="p_lang" select="$v_defaultLang"/>
                                            </xsl:call-template>
                                            <xsl:value-of select="Order/CompanyCodeName"/>
                                        </Description>
                                    </xsl:if>
                                </IdReference>
                            </LegalEntity>
                        </xsl:if>
                        <!-- PurchasingOrganization -->
                        <xsl:if test="string-length(normalize-space(Order/PurchasingOrganization)) > 0">
                            <OrganizationalUnit>
                                <IdReference>
                                    <xsl:attribute name="identifier" select="Order/PurchasingOrganization"/>
                                    <xsl:attribute name="domain" select="'PurchasingOrganization'"/>
                                    <xsl:if test="string-length(normalize-space(Order/PurchasingOrganizationName)) > 0">
                                        <Description>
                                            <xsl:call-template name="FillLangOut">
                                                <xsl:with-param name="p_spras_iso" select="$v_empty"/>
                                                <xsl:with-param name="p_spras" select="$v_soldTo/Address/CorrespondenceLanguage"/>
                                                <xsl:with-param name="p_lang" select="$v_defaultLang"/>
                                            </xsl:call-template>
                                            <xsl:value-of select="Order/PurchasingOrganizationName"/>
                                        </Description>
                                    </xsl:if>
                                </IdReference>
                            </OrganizationalUnit>
                        </xsl:if>
                        <!-- PurchasingGroup -->
                        <xsl:if test="string-length(normalize-space(Order/PurchasingGroup)) > 0">
                            <OrganizationalUnit>
                                <IdReference>
                                    <xsl:attribute name="identifier" select="Order/PurchasingGroup"/>
                                    <xsl:attribute name="domain" select="'PurchasingGroup'"/>
                                    <xsl:if test="string-length(normalize-space(Order/PurchasingGroupName)) > 0">
                                        <Description>
                                            <xsl:call-template name="FillLangOut">
                                                <xsl:with-param name="p_spras_iso" select="$v_empty"/>
                                                <xsl:with-param name="p_spras" select="$v_soldTo/Address/CorrespondenceLanguage"/>
                                                <xsl:with-param name="p_lang" select="$v_defaultLang"/>
                                            </xsl:call-template>
                                            <xsl:value-of select="Order/PurchasingGroupName"/>
                                        </Description>
                                    </xsl:if>
                                </IdReference>                                    
                            </OrganizationalUnit>
                        </xsl:if>
                        <!-- CI-1637 -->
                        <xsl:if test="exists(/n0:OrderRequest/Order/PaymentTerms/CashDiscount1Days)">
                            <PaymentTerm>
                                <xsl:attribute name="payInNumberOfDays">
                                    <xsl:value-of select="/n0:OrderRequest/Order/PaymentTerms/CashDiscount1Days"/>
                                </xsl:attribute>
                                <Discount>
                                    <DiscountPercent>
                                        <!-- IG-20111 in Absence of Discount1Percent is blank populate 0.000 -->
                                        <xsl:attribute name="percent">
                                            <xsl:choose>
                                                <xsl:when test="string-length(normalize-space(/n0:OrderRequest/Order/PaymentTerms/CashDiscount1Percent)) > 0">
                                                    <xsl:value-of select="/n0:OrderRequest/Order/PaymentTerms/CashDiscount1Percent"/>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:value-of select="0"/>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:attribute>
                                        <!-- IG-20111-->
                                    </DiscountPercent>
                                </Discount>
                            </PaymentTerm>
                        </xsl:if>
                        <xsl:if test="exists(/n0:OrderRequest/Order/PaymentTerms/CashDiscount2Days)">
                            <PaymentTerm>
                                <xsl:attribute name="payInNumberOfDays">
                                    <xsl:value-of select="/n0:OrderRequest/Order/PaymentTerms/CashDiscount2Days"/>
                                </xsl:attribute>
                                <Discount>
                                    <DiscountPercent>
                                        <xsl:attribute name="percent">
                                            <xsl:if test="exists(/n0:OrderRequest/Order/PaymentTerms/CashDiscount2Percent)">
                                                <xsl:value-of select="/n0:OrderRequest/Order/PaymentTerms/CashDiscount2Percent"/>
                                            </xsl:if>
                                            <xsl:if test="not(exists(/n0:OrderRequest/Order/PaymentTerms/CashDiscount2Percent))">
                                                <xsl:value-of select="0"/>
                                            </xsl:if>
                                        </xsl:attribute>
                                    </DiscountPercent>
                                </Discount>
                            </PaymentTerm>
                        </xsl:if>
                        <xsl:if test="exists(/n0:OrderRequest/Order/PaymentTerms/NetPaymentDays)">
                            <PaymentTerm>
                                <xsl:attribute name="payInNumberOfDays">
                                    <xsl:value-of select="/n0:OrderRequest/Order/PaymentTerms/NetPaymentDays"/>
                                </xsl:attribute>
                                <Discount>
                                    <DiscountPercent>
                                        <xsl:attribute name="percent">
                                            <xsl:value-of select="0"/>
                                        </xsl:attribute>
                                    </DiscountPercent>
                                </Discount>
                            </PaymentTerm>
                        </xsl:if>
                        <xsl:if test="$v_supplier">
                            <Contact>
                                <xsl:attribute name="role">supplierCorporate</xsl:attribute>
                                <xsl:call-template name="FillPartyAddress">
                                    <xsl:with-param name="p_path" select="$v_supplier"/>
                                    <xsl:with-param name="p_lang" select="$v_defaultLang"/>
                                </xsl:call-template>
                                <!-- Begin of changes CI - 2313 | Field parity -->
                                <xsl:if
                                    test="string-length(normalize-space($v_supplier/BuyerPartyID)) > 0">
                                    <IdReference>
                                        <xsl:attribute name="identifier"
                                            select="$v_supplier/BuyerPartyID"/>
                                        <xsl:attribute name="domain" select="'buyerID'"/>
                                    </IdReference>
                                </xsl:if>
                                <!-- End of changes CI - 2313 | Field parity -->                            
                            </Contact>
                        </xsl:if>
                        <!--  CI-1925 Multiple Header Text -->
                        <!--  CI-1922 Comments Section is needed because Attachment element is included   start -->
                        <xsl:if test="not(exists(Order/Text)) and exists(Order/Attachment)">
                            <Comments xml:lang="">
                                <xsl:if test="exists(/n0:OrderRequest/Order/Attachment)">
                                    <xsl:call-template name="OutboundS4Attachment">
                                        <xsl:with-param name="HeaderAttachment" select="/n0:OrderRequest/Order/Attachment"/>
                                    </xsl:call-template>
                                </xsl:if>
                            </Comments>
                        </xsl:if>
                        <!--  CI-1922 Comments Section is needed because Attachment element is included   end -->
                        <xsl:for-each select="Order/Text">
                            <Comments>
                                <xsl:attribute name="xml:lang">
                                    <xsl:value-of select="TextElementLanguage"/>
                                </xsl:attribute>
                                <xsl:attribute name="type">
                                    <xsl:value-of select="@Type"/>
                                </xsl:attribute>
                                <xsl:value-of select="TextElementText"/>
                                <xsl:if test="exists(/n0:OrderRequest/Order/Attachment)">
                                    <xsl:call-template name="OutboundS4Attachment">
                                        <xsl:with-param name="HeaderAttachment" select="/n0:OrderRequest/Order/Attachment"/>
                                    </xsl:call-template>
                                </xsl:if>
                            </Comments>
                        </xsl:for-each>
                        <!--  CI-1925 -->
<!-- Send the Fileanme to Platform, since MIME header from S4 doesn't send content/filename in the header.
    Format sent to platform. cid:cidValue1#filename1|cid:cidvalid2#filename2 -->
                         <xsl:variable name="ancXMLAttachments">
                            <xsl:for-each select="Order/Attachment">
                                <xsl:value-of
                                    select="concat(string-join((*[namespace-uri() = 'http://www.w3.org/2004/08/xop/include' and local-name() = 'Include']/@href, @FileName,@MimeType), ';'), '#')"/>
                            </xsl:for-each>
                          </xsl:variable>
                        <!-- keep it for testing purpose! -->
<!--                        <an><xsl:value-of select="$ancXMLAttachments"/></an>  -->
                        <!--   CI-1730 BuyrCorrExternalReference   -->
                        <xsl:if test="string-length(normalize-space(Order/BuyrCorrExternalReference)) > 0">
                            <SupplierOrderInfo>
                                <xsl:attribute name="orderID">
                                    <xsl:value-of select="Order/BuyrCorrExternalReference"/>
                                </xsl:attribute>
                            </SupplierOrderInfo>
                        </xsl:if>
                        <!--   CI-1730   -->                         
                        <xsl:if test="string-length(normalize-space(Order/HeaderIncoterms/IncotermsClassification)) > 0">
                            <TermsOfDelivery>
                                <TermsOfDeliveryCode>
                                    <xsl:attribute name="value">TransportCondition</xsl:attribute>
                                </TermsOfDeliveryCode>
                                <ShippingPaymentMethod>
                                    <xsl:attribute name="value">Other</xsl:attribute>
                                </ShippingPaymentMethod>
                                <TransportTerms>
                                    <xsl:attribute name="value">
                                        <xsl:value-of select="Order/HeaderIncoterms/IncotermsClassification"/>
                                    </xsl:attribute>
                                </TransportTerms>
                                <xsl:if test="string-length(normalize-space(Order/HeaderIncoterms/IncotermsLocation1)) > 0">
                                    <Address>
                                        <Name>
                                            <xsl:call-template name="FillLangOut">
                                                <xsl:with-param name="p_spras_iso" select="$v_empty"/>
                                                <xsl:with-param name="p_spras" select="$v_billTo/Address/CorrespondenceLanguage"/>
                                                <xsl:with-param name="p_lang" select="$v_defaultLang"/>
                                            </xsl:call-template>
                                            <xsl:value-of select="Order/HeaderIncoterms/IncotermsLocation1"/>
                                        </Name>
                                    </Address>
                                </xsl:if>
                            </TermsOfDelivery>
                        </xsl:if>
                        <!--   CI-1730 BuyrCorrOwnReference   -->
                        <xsl:if test="string-length(normalize-space(Order/BuyrCorrOwnReference)) > 0">
                            <IdReference>
                                <xsl:attribute name="domain">OurReference</xsl:attribute>
                                <xsl:attribute name="identifier">
                                    <xsl:value-of select="Order/BuyrCorrOwnReference"/>
                                </xsl:attribute>
                            </IdReference>
                        </xsl:if>
                        <!-- CI-2313 External Document type mapping -->
                        <OrderRequestHeaderIndustry>
                            <ExternalDocumentType>
                                <xsl:attribute name="documentType">
                                    <xsl:value-of select="/n0:OrderRequest/Order/PurchasingDocumentType"/>
                                </xsl:attribute>
                                <xsl:if test="string-length(normalize-space(/n0:OrderRequest/Order/PurchasingDocumentTypeName)) > 0">
                                    <Description>
                                        <xsl:attribute name = "xml:lang">
                                            <xsl:call-template name="FillDefaultLang">
                                                <xsl:with-param name="p_doctype" select="$anTargetDocumentType"/>
                                                <xsl:with-param name="p_pd" select="$v_pd"/>
                                            </xsl:call-template>                                  
                                        </xsl:attribute>
                                        <xsl:value-of select="/n0:OrderRequest/Order/PurchasingDocumentTypeName"/>
                                    </Description>
                                </xsl:if>
                            </ExternalDocumentType>
                        </OrderRequestHeaderIndustry>
                        <!-- CI-2313 Ends -->
                        <!--   CI-1730   -->
                        <xsl:if test="(string-length(normalize-space($v_supplier/BuyerPartyID))) > 0 or (string-length(normalize-space($v_soldTo/BuyerPartyID))) > 0">
                            <!-- This will be used in SD Integration for reference. -->
                            <Extrinsic>
                                <xsl:attribute name="name">partyAdditionalID</xsl:attribute>
                                <xsl:choose>
                                    <xsl:when test="string-length(normalize-space($v_supplier/BuyerPartyID)) > 0">
                                        <xsl:value-of select="$v_supplier/BuyerPartyID"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="$v_soldTo/BuyerPartyID"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </Extrinsic>
                        </xsl:if>
                        <!-- CI-1873 Buyer VAT ID -->
                        <xsl:if test="(string-length(normalize-space(Order/BuyerVATRegistration))) > 0">
                            <Extrinsic>
                                <xsl:attribute name="name">buyerVatID</xsl:attribute>
                                <xsl:value-of select="Order/BuyerVATRegistration"/>
                            </Extrinsic>
                        </xsl:if>
                        <!-- CI-1873 -->
                    </OrderRequestHeader>
                    <!-- Send the Fileanme to Platform, since MIME header from S4 doesn't send content/filename in the header.
    Format sent to platform. cid:cidValue1#filename1|cid:cidvalid2#filename2 -->
                    <xsl:variable name="ancXMLAttachmentsHeader">
                        <xsl:for-each select="Order/Attachment">
                            <xsl:value-of
                                select="concat(string-join((*[namespace-uri() = 'http://www.w3.org/2004/08/xop/include' and local-name() = 'Include']/@href, @FileName, @MimeType), ';'), '#')"
                            />
                        </xsl:for-each>
                    </xsl:variable>
                    <!-- keep it for testing purpose! -->
                    <!-- <an><xsl:value-of select="$ancXMLAttachmentsHeader"/></an>  -->                                        
                    <xsl:for-each select="/n0:OrderRequest/Order/OrderItem">
                        <!-- IG-40684 Change due s4/H sends action codes at Item level, backward compatibility is kept                      -->
                        <!-- BPI-252 PO Enhancements -->
                        <xsl:if test="(($v_LineItem = $v_lineitem_actioncode) or (not($v_LineItem = $v_lineitem_actioncode) and ActionCode != '03') or (not(exists(ActionCode))) or (ActionCode = '03' and string-length(normalize-space(IsBlocked))>0))">
                            <ItemOut>
                                <!-- CI-1672 For limit items, where no Qty is sent, AN needs Qty 1 instead of Qty 0-->
                                <xsl:attribute name="quantity">
                                    <xsl:choose>
                                            <xsl:when test="string-length(normalize-space(RequestedQuantity))>0 and RequestedQuantity>0">
                                            <xsl:value-of select="RequestedQuantity"/>
                                        </xsl:when>
                                        <xsl:otherwise>1</xsl:otherwise>
                                    </xsl:choose>
                                </xsl:attribute>
                                <!-- CI-1672 -->
                                <xsl:attribute name="lineNumber">
                                    <xsl:value-of select="PurchaseOrderItemID"/>
                                </xsl:attribute>
                                <!--BPI-46 Contract Item Reference Mapping for SES Enhanced Limit-->
                                <xsl:if
                                    test="string-length(normalize-space(PurchaseContractItem)) > 0 or string-length(normalize-space(PurContractItemForOverallLimit)) > 0">
                                    <xsl:attribute name="agreementItemNumber">
                                        <xsl:choose>
                                            <xsl:when
                                                test="string-length(normalize-space(PurchaseContractItem)) > 0">
                                                <xsl:value-of select="PurchaseContractItem"/>
                                            </xsl:when>
                                            <xsl:when
                                                test="string-length(normalize-space(PurContractItemForOverallLimit)) > 0">
                                                <xsl:value-of
                                                    select="PurContractItemForOverallLimit"/>
                                            </xsl:when>
                                            <xsl:otherwise/>
                                        </xsl:choose>
                                    </xsl:attribute>
                                </xsl:if>
                                <!--BPI-46-->
                                <!-- CI-2112 Time Zone Mapping -->
                                <xsl:if test="(string-length(normalize-space(ScheduleLine[1]/RequestedDeliveryDate[1])) > 0)">
                                    <xsl:attribute name="requestedDeliveryDate">
                                        <xsl:choose>
                                            <xsl:when test="exists(ScheduleLine[1]/RequestedDeliveryDateTime[1])">
                                                <xsl:value-of select="ScheduleLine[1]/RequestedDeliveryDateTime[1]"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:if test="string-length(normalize-space(ScheduleLine[1]/RequestedDeliveryDate[1])) > 0">
                                                    <xsl:call-template name="ANDateTime_S4HANA_V1">
                                                        <xsl:with-param name="p_date" select="ScheduleLine[1]/RequestedDeliveryDate[1]"/>
                                                        <xsl:with-param name="p_time" select="ScheduleLine[1]/RequestedDeliveryTime[1]"/>
                                                        <xsl:with-param name="p_timezone" select="$anERPTimeZone"/>
                                                    </xsl:call-template>
                                                </xsl:if>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:attribute>
                                </xsl:if>
                                <!-- CI-2112 -->
                                <!--CI-1634 IG-51656 Return PO -->
                                <xsl:if test="IsReturnsItem = 'true'">
                                    <xsl:attribute name="isReturn">
                                        <xsl:value-of select="'yes'"/>
                                    </xsl:attribute>
                                </xsl:if>
                                <!--CI-1634 IG-51656 Return PO -->
                                <!-- CI-2053 Item Hierarchy Reference for parent line -->
                                <xsl:if test="string-length(normalize-space(PurchasingParentItem)) > 0">
                                    <xsl:attribute name="parentLineNumber">
                                        <xsl:value-of select="PurchasingParentItem"/>
                                    </xsl:attribute>
                                </xsl:if>
                                <!-- CI-2053 -->
                                <!-- CI-1639 Unlimited Overdelivery allowed and Quantity, Time Tolerances-->
                                <xsl:if test="./UnlimitedOverdeliveryIsAllowed = 'true'">
                                    <xsl:attribute name="unlimitedDelivery">yes</xsl:attribute>
                                </xsl:if>            
                                <!-- CI-1639 -->
                                <xsl:variable name="v_lean" select="ProductType"/>
                                <!-- CI-1672 Enhanced Limits for Services and Materials -->
                                <xsl:choose>
                                    <!-- CI-2053 Item Hierarchy indicates the parent item -->
                                    <xsl:when test="PurchasingIsItemSet = 'true'">
                                        <xsl:attribute name="itemType">composite</xsl:attribute>
                                    </xsl:when>
                                    <!-- CI-2053 -->
                                    <xsl:when test="ProductType = 1">
                                        <!-- CI-2053 Item Hierarchy indicates child -->
                                        <xsl:attribute name="itemType">item</xsl:attribute>
                                        <!-- CI-2053 -->
                                        <xsl:if test="PurchaseOrderItemCategory = 'A'">
                                            <xsl:attribute name="itemClassification">material</xsl:attribute>
                                        </xsl:if>
                                    </xsl:when>
                                    <xsl:when test="ProductType = 2">
                                        <xsl:if test="PurchaseOrderItemCategory = '0'">
                                            <xsl:attribute name="itemType">lean</xsl:attribute>
                                        </xsl:if>
                                        <xsl:if test="ServiceEntrySheetIsExpected = 'true'">
                                            <xsl:attribute name="requiresServiceEntry">yes</xsl:attribute>
                                        </xsl:if>
                                        <xsl:attribute name="itemClassification">service</xsl:attribute>
                                    </xsl:when>
                                </xsl:choose>
                                <!-- CI-1750 PO Subcontracting -->
                                <xsl:if test="PurchaseOrderItemCategory = '3'">
                                    <xsl:attribute name="itemCategory">subcontract</xsl:attribute>
                                </xsl:if>
                                <!-- CI-1750 PO Subcontracting End-->
                                <xsl:if test="PurchaseOrderItemCategory = 'A'">
                                    <xsl:attribute name="itemCategory">limit</xsl:attribute>
                                </xsl:if>
                                <!-- SOC SBNI-2374 PO Consignment -->
                                <xsl:if test="PurchaseOrderItemCategory = '2'">
                                    <xsl:attribute name="itemCategory">consignment</xsl:attribute>
                                </xsl:if>
                                <!-- EOC SBNI-2374 PO Consignment -->
                                <!-- CI-1672 -->
                                <!-- CI-1873 Delivery Complete Flag -->
                                <xsl:if test="IsCompletelyDelivered = 'true'">
                                    <xsl:attribute name="isDeliveryCompleted">yes</xsl:attribute>
                                </xsl:if>
                                <!-- CI-1873 -->
                                <!-- BPI-252 PO Enhancements -->
                                <xsl:if test="ActionCode = '03' and string-length(normalize-space(IsBlocked))>0">
                                    <xsl:attribute name="operation">block</xsl:attribute>
                                </xsl:if>
                                <!-- BPI-252 PO Enhancements -->
                                <ItemID>
                                    <xsl:choose>
                                        <xsl:when test="string-length(normalize-space(Product/SupplierProductID)) > 0">
                                            <SupplierPartID>
                                                <xsl:value-of select="Product/SupplierProductID"/>
                                            </SupplierPartID>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <SupplierPartID>Non-Catalog-Item</SupplierPartID>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    <xsl:if test="string-length(normalize-space(Product/BuyerProductID)) > 0">
                                        <BuyerPartID>
                                            <xsl:value-of select="Product/BuyerProductID"/>
                                        </BuyerPartID>
                                    </xsl:if>
                                </ItemID>
                                <!-- If it is not a lean Service Line -->
                                <!-- CI-2053 Item Hierarchy need to remove because parent will not have ProductType information -->
                                <xsl:if test="$v_lean != 2">
                                    <!-- CI-2053 -->
                                    <ItemDetail>    
                                        <!-- CI-1920 PBQ alignment-->
                                        <UnitPrice>
                                            <Money>
                                                <xsl:attribute name="currency">
                                             <!--     IG_54981   -->
                                             <!--     <xsl:value-of select="ExpectedNetPrice/Amount/@currencyCode"/>-->
                                                    <xsl:choose>
                                                        <xsl:when test="normalize-space(ExpectedNetPrice/Amount/@currencyCode)">
                                                            <xsl:value-of select="ExpectedNetPrice/Amount/@currencyCode"/>
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <xsl:value-of select="/n0:OrderRequest/Order/TransactionCurrency"/>
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                            <!--     IG_54981   -->       
                                                </xsl:attribute>
                                                <xsl:value-of select="ExpectedNetPrice/Amount"/>
                                            </Money>
                                        </UnitPrice>
                                        <!-- CI-1920 -->
                                        <Description>
                                            <xsl:attribute name="xml:lang">
                                                <xsl:call-template name="FillLangOut">
                                                    <xsl:with-param name="p_spras_iso" select="$v_empty"/>
                                                    <xsl:with-param name="p_spras" select="$v_billTo/Address/CorrespondenceLanguage"/>
                                                    <xsl:with-param name="p_lang" select="$v_defaultLang"/>
                                                </xsl:call-template>
                                            </xsl:attribute>
                                            <xsl:value-of select="OrderItemText"/>
                                        </Description>
                                        <!-- CI-1672 Enhanced Limits for Services and Materials -->
                                        <xsl:if test="string-length(normalize-space(Limits/ExpectedOverallLimitAmount)) > 0">
                                            <ExpectedLimit>
                                                <Money>
                                                    <xsl:attribute name="currency">
                                                        <xsl:value-of select="Limits/ExpectedOverallLimitAmount/@currencyCode"/>
                                                    </xsl:attribute>
                                                    <xsl:value-of select="Limits/ExpectedOverallLimitAmount"/>
                                                </Money>
                                            </ExpectedLimit>
                                        </xsl:if>
                                        <!-- CI-1672 -->
                                        <!-- CI-1920 PBQ, alignment UOM-->
                                        <UnitOfMeasure>
                                            <xsl:value-of select="RequestedQuantity/@unitCode"/>
                                        </UnitOfMeasure>                                       
                                        <xsl:if test="POPriceUnitToPOUnitNumerator and POPriceUnitToPOUnitDenominator">
                                            <PriceBasisQuantity>
                                                <xsl:attribute name="quantity">
                                                    <xsl:value-of select="ExpectedNetPrice/BaseQuantity"/>
                                                </xsl:attribute>
                                                <xsl:attribute name="conversionFactor">
                                                    <xsl:value-of select="POPriceUnitToPOUnitNumerator div POPriceUnitToPOUnitDenominator"/>
                                                </xsl:attribute>
                                                <UnitOfMeasure>
                                                    <xsl:value-of select="ExpectedNetPrice/BaseQuantity/@unitCode"/>
                                                </UnitOfMeasure>
                                            </PriceBasisQuantity>
                                        </xsl:if>
                                        <!-- CI-1920 -->                       
                                        <Classification>
                                            <xsl:attribute name="domain">NotAvailable</xsl:attribute>
                                            <xsl:value-of select="ProductType"/>
                                        </Classification>
                                        <!-- CI-1924 Manufacturer Part ID + Name -->
                                        <xsl:if test="string-length(normalize-space(Product/ManufacturerPartNumber)) > 0">
                                            <ManufacturerPartID>
                                                <xsl:value-of select="Product/ManufacturerPartNumber"/>
                                            </ManufacturerPartID>
                                        </xsl:if>
                                        <xsl:if test="string-length(normalize-space(Product/ManufacturerName)) > 0">
                                            <ManufacturerName>
                                                <xsl:value-of select="Product/ManufacturerName"/>
                                            </ManufacturerName>
                                        </xsl:if>
                                        <!-- CI-1924 -->
                                        <!--CI-1730 Set flags to mask Values in AN-->
                                        <xsl:if test="PriceIsToBePrinted = 'false'">
                                            <Extrinsic>
                                                <xsl:attribute name="name">hideUnitPrice</xsl:attribute>
                                            </Extrinsic>
                                            <Extrinsic>
                                                <xsl:attribute name="name">hideAmount</xsl:attribute>
                                            </Extrinsic>
                                        </xsl:if>
                                        <!-- CI-1730 -->
                                        <!-- CI-2053 Item Hierarchy -->
                                        <xsl:if test="string-length(normalize-space(PurgConfigurableItemNumber)) > 0">
                                            <Extrinsic>
                                                <xsl:attribute name="name">extLineNumber</xsl:attribute>
                                                <xsl:value-of select="PurgExternalSortNumber"/>
                                            </Extrinsic>
                                        </xsl:if>
                                        <!-- CI-2053 -->
                                        <!-- CI-2696 Hierarchy number -->
                                        <xsl:if test="string-length(normalize-space(PurgConfigurableItemNumber)) > 0">
                                            <Extrinsic>
                                                <xsl:attribute name="name">hierarchyLineNumber</xsl:attribute>
                                                <xsl:value-of select="PurgConfigurableItemNumber"/>
                                            </Extrinsic>
                                        </xsl:if>
                                        <!-- CI-2696-->
                                    </ItemDetail>
                                </xsl:if>
                                <!-- CI-2053 Item Hierarchy -->
                                <xsl:if test="exists($v_lean) and $v_lean = 2 or PurchasingIsItemSet = 'true'">
                                 <!-- CI-2053 -->
                                    <BlanketItemDetail>
                                        <Description>
                                            <xsl:attribute name="xml:lang">
                                                <xsl:call-template name="FillLangOut">
                                                    <xsl:with-param name="p_spras_iso" select="$v_empty"/>
                                                    <xsl:with-param name="p_spras" select="$v_billTo/Address/CorrespondenceLanguage"/>
                                                    <xsl:with-param name="p_lang" select="$v_defaultLang"/>
                                                </xsl:call-template>
                                            </xsl:attribute>
                                            <xsl:value-of select="OrderItemText"/>
                                        </Description>
                                        <!-- CI-1672 Enhanced Limits for Services and Materials -->
                                        <xsl:if test="string-length(normalize-space(Limits/ExpectedOverallLimitAmount)) > 0">
                                            <ExpectedLimit>
                                                <Money>
                                                    <xsl:attribute name="currency">
                                                        <xsl:value-of select="Limits/ExpectedOverallLimitAmount/@currencyCode"/>
                                                    </xsl:attribute>
                                                    <xsl:value-of select="Limits/ExpectedOverallLimitAmount"/>
                                                </Money>
                                            </ExpectedLimit>
                                        </xsl:if>
                                        <!-- CI-1672 -->
                                        <!-- BPI-203 Overall Limits for Services and Materials-->
                                        <xsl:if test="string-length(normalize-space(Limits/OverallLimitAmount)) > 0">
                                            <MaxAmount>
                                                <Money>
                                                    <xsl:attribute name="currency">
                                                        <xsl:value-of
                                                            select="Limits/OverallLimitAmount/@currencyCode"/>
                                                    </xsl:attribute>
                                                    <xsl:value-of select="Limits/OverallLimitAmount"/>
                                                </Money>
                                            </MaxAmount>
                                        </xsl:if>
                                        <!-- BPI-203 -->
                                        <xsl:if test="ExpectedNetPrice/Amount">
                                            <!-- CI-1920 PBQ -->
                                            <UnitPrice>
                                                <Money>
                                                    <xsl:attribute name="currency">
                                                        <xsl:value-of select="ExpectedNetPrice/Amount/@currencyCode"/>
                                                    </xsl:attribute>
                                                    <xsl:value-of select="ExpectedNetPrice/Amount"/>
                                                </Money>
                                            </UnitPrice>                                            
                                        </xsl:if>
                                        <!-- CI-1920 -->
                                        <!-- CI-1672 For service limit items, where no Qty/UOM is sent, AN needs UOM -->
                                        <!-- CI-1920 PBQ -->
                                        <UnitOfMeasure>
                                            <xsl:value-of select="RequestedQuantity/@unitCode"/>
                                        </UnitOfMeasure>
                                        <!-- CI-1672 -->
                                        <xsl:if test="POPriceUnitToPOUnitNumerator and POPriceUnitToPOUnitDenominator">
                                            <PriceBasisQuantity>
                                                <xsl:attribute name="quantity">
                                                    <xsl:value-of select="ExpectedNetPrice/BaseQuantity"/>
                                                </xsl:attribute>
                                                <xsl:attribute name="conversionFactor">
                                                    <xsl:value-of select="POPriceUnitToPOUnitNumerator div POPriceUnitToPOUnitDenominator"/>
                                                </xsl:attribute>
                                                <UnitOfMeasure>
                                                    <xsl:value-of select="ExpectedNetPrice/BaseQuantity/@unitCode"/>
                                                </UnitOfMeasure>
                                            </PriceBasisQuantity>
                                        </xsl:if>
                                        <!-- CI-1920 -->
                                        <Classification>
                                            <xsl:attribute name="domain">NotAvailable</xsl:attribute>
                                            <xsl:value-of select="ProductType"/>
                                        </Classification>
                                        <!-- Create Extrinsic ‘ExpectedUnplanned’ only for unplanned lean service -->
                                        <xsl:if test="string-length(normalize-space(Limits/ExpectedOverallLimitAmount)) > 0">
                                            <Extrinsic>
                                                <xsl:attribute name="name">ExpectedUnplanned</xsl:attribute>
                                                <Money>
                                                    <xsl:attribute name="currency">
                                                        <xsl:value-of select="Limits/ExpectedOverallLimitAmount/@currencyCode"/>
                                                    </xsl:attribute>
                                                    <xsl:value-of select="Limits/ExpectedOverallLimitAmount"/>
                                                </Money>
                                            </Extrinsic>
                                        </xsl:if> 
                                        <!--CI-1730 Set flags to mask Values in AN-->
                                        <xsl:if test="PriceIsToBePrinted = 'false'">
                                            <Extrinsic>
                                                <xsl:attribute name="name">hideUnitPrice</xsl:attribute>
                                            </Extrinsic>
                                            <Extrinsic>
                                                <xsl:attribute name="name">hideAmount</xsl:attribute>
                                            </Extrinsic>
                                        </xsl:if>
                                        <!-- CI-1730 -->
                                        <!-- CI-2053 Item Hierarchy -->
                                        <xsl:if test="string-length(normalize-space(PurgConfigurableItemNumber)) > 0">
                                            <Extrinsic>
                                                <xsl:attribute name="name">extLineNumber</xsl:attribute>
                                                <xsl:value-of select="PurgExternalSortNumber"/>
                                            </Extrinsic>
                                        </xsl:if>
                                        <!-- CI-2053 -->
                                        <!-- CI-2696 Hierarchy number -->
                                        <xsl:if test="string-length(normalize-space(PurgConfigurableItemNumber)) > 0">
                                            <Extrinsic>
                                                <xsl:attribute name="name">hierarchyLineNumber</xsl:attribute>
                                                <xsl:value-of select="PurgConfigurableItemNumber"/>
                                            </Extrinsic>
                                        </xsl:if>
                                        <!-- CI-2696-->
                                    <!-- CI-2050 send SOW ID to Fieldglass.............................................................. -->
                                        <xsl:for-each select="ExternalReferences">
                                            <xsl:if test="string-length(normalize-space(PurgDocExternalReference)) > 0">
                                                <xsl:if test="PurgDocExternalSystem  = 'FIELDGLASS'">
                                            <Extrinsic>                                           
                                                <xsl:attribute name="name"> 
                                                    <xsl:value-of select="'FG.SOWnumber'"/>
                                                </xsl:attribute>
                                                <xsl:value-of select="PurgDocExternalReference"/>
                                            </Extrinsic>
                                        </xsl:if>
                                            </xsl:if>
                                        </xsl:for-each>
                                        <!-- CI-2050 end..................................................................................... -->
                                    </BlanketItemDetail>
                                </xsl:if>
                                <xsl:if test="exists(Party[@PartyType = 'ShipTo']) and string-length((Party[@PartyType = 'ShipTo'])/Address/StreetName) > 0">
                                    <ShipTo>
                                        <Address>
                                            <xsl:call-template name="FillPartyAddress">
                                                <xsl:with-param name="p_path" select="Party[@PartyType = 'ShipTo']"/>
                                                <xsl:with-param name="p_lang" select="$v_defaultLang"/>
                                            </xsl:call-template>
                                        </Address>
                                        <!-- CI-1732 Plant under Ship To Address -->
                                        <xsl:if test="string-length(normalize-space(Plant)) > 0">
                                            <IdReference>
                                                <xsl:attribute name="identifier" select="Plant"/>
                                                <xsl:attribute name="domain">buyerLocationID</xsl:attribute>
                                            </IdReference>
                                        </xsl:if>
                                        <!-- CI-1732 Storage Location under Ship To Address -->
                                        <xsl:if
                                            test="string-length(normalize-space(StorageLocation)) > 0">
                                            <IdReference>
                                                <xsl:attribute name="identifier" select="StorageLocation"/>
                                                <xsl:attribute name="domain">storageLocationID</xsl:attribute>
                                            </IdReference>
                                        </xsl:if>
                                        <!-- CI-1732 -->
                                    </ShipTo>
                                </xsl:if>
                                <xsl:if test="string-length(normalize-space(TaxDetails)) > 0">
                                              <Tax>
                                                    <Money>
                                                          <xsl:attribute name="currency">
                                                                <xsl:value-of select="TaxDetails/TotalTaxAmount/@currencyCode"/>
                                                           </xsl:attribute>
                                                        <!--  IG-53864  -->
                                                        <xsl:choose>
                                                            <xsl:when test="IsReturnsItem = 'true'">
                                                                <xsl:value-of select="concat('-', TaxDetails/TotalTaxAmount)"/>
                                                            </xsl:when>
                                                            <xsl:otherwise>
                                                                <xsl:value-of select="TaxDetails/TotalTaxAmount"/>
                                                            </xsl:otherwise>
                                                        </xsl:choose>
                                                        <!--  IG-53864  -->
                                                    </Money>
<!--                                                  <xsl:for-each select="TaxDetails/TaxConditionDetails">-->
                                                    <Description>
                                                        <xsl:attribute name="xml:lang">
                                                            <xsl:value-of select="TaxDetails/TaxCodeName/@languageCode"/>
                                                        </xsl:attribute>
                                                        <xsl:value-of select="TaxDetails/TaxCodeName"/>
                                                    </Description>
                                                  <!--</xsl:for-each>-->   
                                                    <xsl:for-each select="TaxDetails/TaxConditionDetails">
                                                        <xsl:if test="exists(TaxCategory)">
                                                            <TaxDetail>
                                                                <xsl:attribute name="category">
                                                                    <xsl:value-of select="TaxCategory"/>
                                                                </xsl:attribute>
                                                                 <xsl:attribute name="percentageRate">
                                                                     <xsl:value-of select="ConditionRateValue"/>
                                                                 </xsl:attribute>
                                                                <TaxableAmount>
                                                                    <Money>
                                                                        <xsl:attribute name="currency">
                                                                            <xsl:value-of select="ConditionBaseAmount/@currencyCode"/>
                                                                        </xsl:attribute>
                                                                        <!--  IG-53864  -->
                                                                        <xsl:choose>
                                                                            <xsl:when test="../../IsReturnsItem = 'true'">
                                                                                <xsl:value-of select="concat('-', ConditionBaseAmount)"/>
                                                                            </xsl:when>
                                                                            <xsl:otherwise>
                                                                                <xsl:value-of select="ConditionBaseAmount"/>
                                                                            </xsl:otherwise>
                                                                        </xsl:choose>
                                                                        <!--  IG-53864  -->
                                                                    </Money>
                                                                </TaxableAmount>
                                                                <TaxAmount>
                                                                <Money>
                                                                    <xsl:attribute name="currency">
                                                                        <xsl:value-of select="ConditionAmount/@currencyCode"/>
                                                                    </xsl:attribute>
                                                                    <!--  IG-53864  -->
                                                                    <xsl:choose>
                                                                        <xsl:when test="../../IsReturnsItem = 'true'">
                                                                            <xsl:value-of select="concat('-', ConditionAmount)"/>
                                                                        </xsl:when>
                                                                        <xsl:otherwise>
                                                                            <xsl:value-of select="ConditionAmount"/>
                                                                        </xsl:otherwise>
                                                                    </xsl:choose>
                                                                    <!--  IG-53864  -->
                                                                </Money>
                                                            </TaxAmount>
                                                            <Description>
                                                                <xsl:attribute name="xml:lang">
                                                                    <xsl:value-of select="TaxCategoryName/@languageCode"/>
                                                                </xsl:attribute>
                                                                <xsl:value-of select="TaxCategoryName"/>
                                                            </Description>
                                                        </TaxDetail>
                                                    </xsl:if>
                                                    </xsl:for-each>      
                                              </Tax>
                                        </xsl:if>                              
                                <!-- CI-1672 Enhanced Limits for Services and Materials -->
                                <xsl:if test="ScheduleLine/Service">
                                <!-- CI-1672 -->
                                    <SpendDetail>
                                        <Extrinsic>
                                            <xsl:attribute name="name">ServicePeriod</xsl:attribute>
                                            <xsl:for-each select="ScheduleLine">
                                                <Period>
                                                    <!-- CI-2112 Time Zone Mapping -->
                                                    <xsl:attribute name="startDate">
                                                        <xsl:choose>
                                                            <xsl:when test="exists(Service/ServicePerfPeriodStartDateTime)">
                                                                <xsl:value-of select="Service/ServicePerfPeriodStartDateTime"/>
                                                            </xsl:when>
                                                            <xsl:otherwise>
                                                                <xsl:if test="string-length(normalize-space(Service/PerformancePeriodStartDate)) > 0">
                                                                    <xsl:call-template name="ANDateTime_S4HANA_V1">
                                                                        <xsl:with-param name="p_date" select="Service/PerformancePeriodStartDate"/>
                                                                        <xsl:with-param name="p_time" select="''"/>
                                                                        <xsl:with-param name="p_timezone" select="$anERPTimeZone"/>
                                                                    </xsl:call-template>
                                                                </xsl:if>
                                                            </xsl:otherwise>
                                                        </xsl:choose>
                                                    </xsl:attribute>
                                                    <xsl:attribute name="endDate">
                                                        <xsl:choose>
                                                            <xsl:when test="exists(Service/SrvcPerformancePeriodEndDteTme)">
                                                                <xsl:value-of select="Service/SrvcPerformancePeriodEndDteTme"/>
                                                            </xsl:when>
                                                            <xsl:otherwise>
                                                                <xsl:if test="string-length(normalize-space(Service/PerformancePeriodEndDate)) > 0">
                                                                    <xsl:call-template name="ANDateTime_S4HANA_V1">
                                                                        <xsl:with-param name="p_date" select="Service/PerformancePeriodEndDate"/>
                                                                        <xsl:with-param name="p_time" select="''"/>
                                                                        <xsl:with-param name="p_timezone" select="$anERPTimeZone"/>
                                                                    </xsl:call-template>
                                                                </xsl:if>
                                                            </xsl:otherwise>
                                                        </xsl:choose>
                                                    </xsl:attribute>
                                                    <!-- CI-2112 -->
                                                </Period>
                                            </xsl:for-each>
                                        </Extrinsic>
                                    </SpendDetail>
                                </xsl:if>
                                <!-- CI-1922 Line Item Attachment start -->
                                <!-- Comments Section is needed because Attachment element is included -->
                                <xsl:if test="not(exists(Text)) and exists(Attachment)">
                                    <Comments xml:lang="">
                                        <xsl:if test="exists(Attachment)">
                                            <xsl:for-each select="Attachment">
                                                <Attachment>
                                                    <URL>
                                                        <xsl:value-of select="normalize-space(*[namespace-uri() = 'http://www.w3.org/2004/08/xop/include' and local-name() = 'Include']/@href)"/>
                                                    </URL>
                                                </Attachment>
                                            </xsl:for-each>
                                        </xsl:if>
                                    </Comments>
                                </xsl:if>
                                <!--  CI-1925 Multiple Line Item Text -->
                                <xsl:for-each select="Text">
                                    <xsl:variable name="TextCount" select="position()"/>
                                    <Comments>
                                        <xsl:attribute name="xml:lang">
                                            <xsl:value-of select="TextElementLanguage"/>
                                        </xsl:attribute>
                                        <xsl:attribute name="type">
                                            <xsl:value-of select="@Type"/>
                                        </xsl:attribute>
                                        <xsl:value-of select="TextElementText"/>
                                        <!-- CI-1922 Line Item Attachment start -->
                                        <xsl:if test="exists(../Attachment)">
                                            <xsl:for-each select="../Attachment">
<!--This is executed only once for a line item even though there are multiple commments-->
                                                <xsl:if test="$TextCount=1">
                                                    <Attachment>
                                                        <URL>
                                                            <xsl:value-of select="normalize-space(*[namespace-uri() = 'http://www.w3.org/2004/08/xop/include' and local-name() = 'Include']/@href)"/>
                                                        </URL>
                                                    </Attachment>
                                                </xsl:if>  
                                            </xsl:for-each>
                                        </xsl:if>
                                    </Comments>
                                </xsl:for-each>
                                <!-- CI-1922 Line Item Attachment end -->
                                <!--  CI-1925 -->
                                <!-- 2008 CI-1513 Control Keys. Need to be downward compatible 2005, populate only if <ConfirmationControlKey> exist --> 
                                <xsl:if test="ConfirmationControlKey">
                                    <ControlKeys>
                                        <OCInstruction>
                                            <xsl:choose>
                                                <xsl:when test="OrderAcknowledgementRequired='true' and ExpectedConfirmations/ConfirmationSequence/ConfirmationCategory='1'">
                                                    <xsl:attribute name="value">requiredBeforeASN</xsl:attribute>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:choose>
                                                        <xsl:when test="ExpectedConfirmations/ConfirmationSequence/ConfirmationCategory='1'">
                                                            <xsl:attribute name="value">allowed</xsl:attribute>
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <xsl:attribute name="value">notAllowed</xsl:attribute>
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                            <!-- CI-1639 Unlimited Overdelivery allowed and Quantity, Time Tolerances-->
                                            <Lower>
                                                <Tolerances>
                                                    <xsl:if test="string-length(normalize-space(PurgUnderdelivTolLmtRatioInPct))>0">
                                                        <!-- CI-2007 Price Tolerance & SESInstructions -->
                                                        <xsl:choose> 
                                                            <xsl:when test="(ProductType = '1' or ProductType = '2')">
                                                                <xsl:choose>
                                                                    <xsl:when test="(ProductType = '2' and not(exists(ServiceEntrySheetIsExpected)))"/>
                                                                    <xsl:otherwise>
                                                        <!-- CI-2007 -->
                                                        <QuantityTolerance>
                                                            <Percentage>
                                                                <xsl:attribute name="percent">
                                                                    <xsl:value-of select="PurgUnderdelivTolLmtRatioInPct"/>
                                                                </xsl:attribute>
                                                            </Percentage>
                                                        </QuantityTolerance>
                                                        <!-- CI-2007 Price Tolerance & SESInstructions -->
                                                                    </xsl:otherwise>
                                                                </xsl:choose>
                                                            </xsl:when>
                                                        </xsl:choose>    
                                                        <!-- CI-2007 -->                
                                                    </xsl:if>
                                                    <!-- CI-2007 Price Tolerance & SESInstructions -->
                                                    <xsl:for-each select="ExpectedConfirmations/ConfirmationSequence">
                                                        <xsl:if test="ConfirmationCategory = '1'">
                                                            <xsl:for-each select="Tolerance">
                                                                <xsl:if test="string-length(normalize-space(PermittedPriceShortFallInPct))>0">
                                                                    <PriceTolerance>
                                                                        <Percentage>
                                                                            <xsl:attribute name="percent">
                                                                                <xsl:value-of select="PermittedPriceShortFallInPct"/>
                                                                            </xsl:attribute>
                                                                        </Percentage>
                                                                    </PriceTolerance>
                                                                </xsl:if> 
                                                            </xsl:for-each>    
                                                        </xsl:if>           
                                                    </xsl:for-each> 
                                                    <!-- CI-2007 -->
                                                    <xsl:for-each select="ExpectedConfirmations/ConfirmationSequence">
                                                        <xsl:if test="ConfirmationCategory = '1'">
                                                            <xsl:for-each select="Tolerance">
                                                              <xsl:if test="string-length(normalize-space(LowerConfDateToleranceInDays))>0">
                                                                  <!-- CI-2007 Price Tolerance & SESInstructions -->
                                                                  <xsl:if test="../../../ProductType = '1'">
                                                                  <!-- CI-2007 -->    
                                                                  <TimeTolerance>
                                                                      <xsl:attribute name="limit">
                                                                          <xsl:value-of select="LowerConfDateToleranceInDays"/>
                                                                       </xsl:attribute>
                                                                       <xsl:attribute name="type">days</xsl:attribute>
                                                                   </TimeTolerance>
                                                                  <!-- CI-2007 Price Tolerance & SESInstructions -->
                                                                  </xsl:if> 
                                                                  <!-- CI-2007 -->   
                                                               </xsl:if> 
                                                            </xsl:for-each>    
                                                        </xsl:if>           
                                                    </xsl:for-each>        
                                                </Tolerances>
                                            </Lower>      
                                            <Upper>
                                                <Tolerances>
                                                    <xsl:if test="string-length(normalize-space(PurgOvrdelivTolLmtRatioInPct))>0">
                                                        <!-- CI-2007 Price Tolerance & SESInstructions -->
                                                        <xsl:choose> 
                                                            <xsl:when test="(ProductType = '1' or ProductType = '2')">
                                                                <xsl:choose>
                                                                    <xsl:when test="(ProductType = '2' and not(exists(ServiceEntrySheetIsExpected)))"/>
                                                                    <xsl:otherwise>
                                                        <!-- CI-2007 -->
                                                        <QuantityTolerance>
                                                            <Percentage>
                                                                <xsl:attribute name="percent">
                                                                    <xsl:value-of select="PurgOvrdelivTolLmtRatioInPct"/>
                                                                </xsl:attribute>
                                                            </Percentage>
                                                        </QuantityTolerance>
                                                        <!-- CI-2007 Price Tolerance & SESInstructions -->
                                                                    </xsl:otherwise>
                                                                </xsl:choose>
                                                            </xsl:when>
                                                        </xsl:choose>    
                                                        <!-- CI-2007 -->                 
                                                    </xsl:if>
                                                    <!-- CI-2007 Price Tolerance & SESInstructions -->
                                                    <xsl:for-each select="ExpectedConfirmations/ConfirmationSequence">
                                                        <xsl:if test="ConfirmationCategory = '1'">
                                                            <xsl:for-each select="Tolerance">
                                                                <xsl:if test="string-length(normalize-space(PermittedPriceOverrunInPct))>0">
                                                                    <PriceTolerance>
                                                                        <Percentage>
                                                                            <xsl:attribute name="percent">
                                                                                <xsl:value-of select="PermittedPriceOverrunInPct"/>
                                                                            </xsl:attribute>
                                                                        </Percentage>
                                                                    </PriceTolerance>
                                                                </xsl:if> 
                                                            </xsl:for-each>    
                                                        </xsl:if>           
                                                    </xsl:for-each>  
                                                    <!-- CI-2007 -->
                                                    <xsl:for-each select="ExpectedConfirmations/ConfirmationSequence">
                                                        <xsl:if test="ConfirmationCategory = '1'">
                                                            <xsl:for-each select="Tolerance"> 
                                                                <xsl:if test="string-length(normalize-space(UpperConfDateToleranceInDays))>0">
                                                                    <!-- CI-2007 Price Tolerance & SESInstructions -->
                                                                    <xsl:if test="../../../ProductType = '1'">
                                                                    <!-- CI-2007 -->    
                                                        <TimeTolerance>
                                                            <xsl:attribute name="limit">
                                                                <xsl:value-of select="UpperConfDateToleranceInDays"/>
                                                            </xsl:attribute>
                                                            <xsl:attribute name="type">days</xsl:attribute>
                                                        </TimeTolerance>
                                                                    <!-- CI-2007 Price Tolerance & SESInstructions -->
                                                                    </xsl:if> 
                                                                    <!-- CI-2007 -->    
                                                            </xsl:if>    
                                                            </xsl:for-each>     
                                                        </xsl:if>           
                                                    </xsl:for-each>     
                                                </Tolerances>
                                            </Upper>                                            
                                            <!-- CI-1639 -->
                                        </OCInstruction>
                                        <!-- CI-2007 Price Tolerance & SESInstructions -->
                                        <xsl:if test="ProductType = '1'">
                                        <!-- CI-2007 -->
                                        <ASNInstruction>
                                            <xsl:choose>
                                                <xsl:when test="ExpectedConfirmations/ConfirmationSequence/ConfirmationCategory='2'">
                                                    <xsl:attribute name="value">allowed</xsl:attribute>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:attribute name="value">notAllowed</xsl:attribute>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                            <!-- CI-1639 Unlimited Overdelivery allowed and Quantity, Time Tolerances-->
                                            <Lower>
                                                <Tolerances>
                                                    <xsl:if test="string-length(normalize-space(PurgUnderdelivTolLmtRatioInPct))>0">
                                                        <QuantityTolerance>
                                                            <Percentage>
                                                                <xsl:attribute name="percent">
                                                                    <xsl:value-of select="PurgUnderdelivTolLmtRatioInPct"/>
                                                                </xsl:attribute>
                                                            </Percentage>
                                                        </QuantityTolerance>
                                                    </xsl:if> 
                                                    <xsl:for-each select="ExpectedConfirmations/ConfirmationSequence">
                                                        <xsl:if test="ConfirmationCategory = '2'">
                                                            <xsl:for-each select="Tolerance"> 
                                                    <xsl:if test="string-length(normalize-space(LowerConfDateToleranceInDays))>0">
                                                        <TimeTolerance>
                                                            <xsl:attribute name="limit">
                                                                <xsl:value-of select="LowerConfDateToleranceInDays"/>
                                                            </xsl:attribute>
                                                            <xsl:attribute name="type">days</xsl:attribute>
                                                        </TimeTolerance>
                                                    </xsl:if>    
                                                            </xsl:for-each>     
                                                        </xsl:if>           
                                                    </xsl:for-each>                                                   
                                                </Tolerances>
                                            </Lower>      
                                            <Upper>
                                                <Tolerances>
                                                    <xsl:if test="string-length(normalize-space(PurgOvrdelivTolLmtRatioInPct))>0">
                                                        <QuantityTolerance>
                                                            <Percentage>
                                                                <xsl:attribute name="percent">
                                                                    <xsl:value-of select="PurgOvrdelivTolLmtRatioInPct"/>
                                                                </xsl:attribute>
                                                            </Percentage>
                                                        </QuantityTolerance>
                                                    </xsl:if>  
                                                    <xsl:for-each select="ExpectedConfirmations/ConfirmationSequence">
                                                        <xsl:if test="ConfirmationCategory = '2'">
                                                            <xsl:for-each select="Tolerance"> 
                                                    <xsl:if test="string-length(normalize-space(UpperConfDateToleranceInDays))>0">
                                                        <TimeTolerance>
                                                            <xsl:attribute name="limit">
                                                                <xsl:value-of select="UpperConfDateToleranceInDays"/>
                                                            </xsl:attribute>
                                                            <xsl:attribute name="type">days</xsl:attribute>
                                                        </TimeTolerance>
                                                    </xsl:if>
                                                            </xsl:for-each>     
                                                        </xsl:if>           
                                                    </xsl:for-each>                                                  
                                                </Tolerances>
                                            </Upper>                                            
                                            <!-- CI-1639 -->                                            
                                        </ASNInstruction>
                                        <!-- CI-2007 Price Tolerance & SESInstructions --> 
                                        </xsl:if> 
                                        <!-- CI-2007 -->        
                                        <!-- CI-1873 Evaluated Receipt Settlement Flag -->
                                        <!-- CI-1730 Set flag for Purchasing Price is estimated-->
                                        <xsl:if test="PurchasingPriceIsEstimated = 'true' or EvaldRcptSettlmtIsAllowed = 'true'">
                                            <InvoiceInstruction>
                                                <xsl:if test="EvaldRcptSettlmtIsAllowed = 'true'">
                                                    <xsl:attribute name="value">isERS</xsl:attribute>
                                                </xsl:if>
                                                <!-- CI-1873 -->
                                                <xsl:if test="PurchasingPriceIsEstimated = 'true'">
                                                    <TemporaryPrice>
                                                        <xsl:attribute name="value">yes</xsl:attribute>
                                                    </TemporaryPrice>
                                                </xsl:if>   
                                            </InvoiceInstruction>
                                        </xsl:if>
                                        <!-- CI-1730 --> 
                                        <!-- CI-2007 Price Tolerance & SESInstructions -->
                                        <xsl:if test="ProductType = '2'">
                                            <!-- IG-53900 (Auto SES Feature) 
                                                 SESInstruction control key new logic 
                                                 - notAllowed -> Manual and Auto SES disabled (Sent when SES is not expected)
                                                 - allowed -> Only Manual SES enabled (Older scenario) (REMOVED for IG-53900) 
                                                 - nothing sent -> Both Manual and Auto SES enabled (When SES is expected)
                                            -->
                                            <xsl:if test="not(ServiceEntrySheetIsExpected = 'true')">
                                                <SESInstruction value="notAllowed">
                                                    <Lower>
                                                        <Tolerances>
                                                            <xsl:if test="string-length(normalize-space(PurgUnderdelivTolLmtRatioInPct))>0">
                                                                <QuantityTolerance>
                                                                    <Percentage>
                                                                        <xsl:attribute name="percent">
                                                                            <xsl:value-of select="PurgUnderdelivTolLmtRatioInPct"/>
                                                                        </xsl:attribute>
                                                                    </Percentage>
                                                                </QuantityTolerance>
                                                            </xsl:if>
                                                        </Tolerances>
                                                    </Lower>      
                                                    <Upper>
                                                        <Tolerances>
                                                            <xsl:if test="string-length(normalize-space(PurgOvrdelivTolLmtRatioInPct))>0">
                                                                <QuantityTolerance>
                                                                    <Percentage>
                                                                        <xsl:attribute name="percent">
                                                                            <xsl:value-of select="PurgOvrdelivTolLmtRatioInPct"/>
                                                                        </xsl:attribute>
                                                                    </Percentage>
                                                                </QuantityTolerance>
                                                            </xsl:if>
                                                        </Tolerances>
                                                    </Upper>
                                                </SESInstruction>
                                            </xsl:if>
                                            <!-- IG-53900 -->
                                        </xsl:if>
                                        <!-- CI-2007 -->
                                    </ControlKeys>
                                </xsl:if>
                                <xsl:for-each select="ScheduleLine">
                                    <ScheduleLine>
                                        <!-- CI-1672 For limit items, where no Qty is sent, AN needs Qty 1 instead of Qty 0-->
                                        <xsl:attribute name="quantity">
                                            <xsl:if test="exists(ScheduleLineOrderQuantity)">
                                                <xsl:value-of select="ScheduleLineOrderQuantity"/>
                                            </xsl:if>
                                            <xsl:if test="not(ScheduleLineOrderQuantity)">1</xsl:if>
                                        </xsl:attribute>
                                        <!-- CI-1672 -->
                                        <xsl:attribute name="lineNumber">
                                            <xsl:value-of select="position()"/>
                                        </xsl:attribute>
                                        <!-- CI-2112 Time Zone Mapping -->
                                        <xsl:attribute name="requestedDeliveryDate">
                                            <xsl:choose>
                                                <xsl:when test="exists(RequestedDeliveryDateTime)">
                                                    <xsl:value-of select="RequestedDeliveryDateTime"/>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:if test="string-length(normalize-space(RequestedDeliveryDate)) > 0">
                                                        <xsl:call-template name="ANDateTime_S4HANA_V1">
                                                            <xsl:with-param name="p_date"
                                                                select="RequestedDeliveryDate"/>
                                                            <xsl:with-param name="p_time"
                                                                select="RequestedDeliveryTime"/>
                                                            <xsl:with-param name="p_timezone"
                                                                select="$anERPTimeZone"/>
                                                        </xsl:call-template>
                                                    </xsl:if>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:attribute>
                                        <!-- CI-2112 -->
                                        <UnitOfMeasure>
                                            <xsl:value-of select="ScheduleLineOrderQuantity/@unitCode"/>
                                        </UnitOfMeasure>
                                        <!-- CI-1750 PO Subcontracting -->
                                        <xsl:if test="exists(SubcontractingComponentDetails)">
                                            <xsl:for-each select="SubcontractingComponentDetails">
                                            <SubcontractingComponent>
                                                <xsl:attribute name="quantity">
                                                    <xsl:value-of select="QuantityInEntryUnit"/>
                                                </xsl:attribute>
                                                    <xsl:if test="string-length(normalize-space(RequirementDate)) > 0">
                                                        <xsl:attribute name="requirementDate">
                                                        <xsl:call-template name="ANDateTime_S4HANA">
                                                            <xsl:with-param name="p_date"
                                                                select="RequirementDate"/>
                                                            <xsl:with-param name="p_timezone"
                                                                select="$anERPTimeZone"/>
                                                        </xsl:call-template>
                                                        </xsl:attribute>
                                                    </xsl:if>
                                                <ComponentID>
                                                    <xsl:value-of select="ReservationItem"/>
                                                </ComponentID>
                                                <UnitOfMeasure>
                                                    <xsl:value-of select="QuantityInEntryUnit/@unitCode"/>
                                                </UnitOfMeasure>
                                                <xsl:if test="string-length(normalize-space(MaterialName)) > 0">
                                                <Description>
                                                    <xsl:attribute name="xml:lang">
                                                        <xsl:value-of select="MaterialName/@languageCode"/>
                                                    </xsl:attribute>
                                                    <xsl:value-of select="MaterialName"/>
                                                </Description>
                                                </xsl:if>
                                                <xsl:if test="string-length(normalize-space(SubcontractingComponentProduct)) > 0">
                                                <Product>
                                                    <BuyerPartID>
                                                            <xsl:value-of select="SubcontractingComponentProduct"/>
                                                    </BuyerPartID>
                                                </Product>
                                                </xsl:if>
                                                <xsl:if test="string-length(normalize-space(Batch)) > 0">
                                                <Batch>
                                                    <BuyerBatchID>
                                                        <xsl:value-of select="Batch"/>
                                                    </BuyerBatchID>
                                                </Batch>
                                                </xsl:if>
                                            </SubcontractingComponent>
                                            </xsl:for-each>
                                        </xsl:if>
                                        <!-- CI-1750 PO Subcontracting End-->
                                    </ScheduleLine>
                                </xsl:for-each>
                                <!-- CI-1742 Contract ID -->
                                <xsl:if test="string-length(normalize-space(PurchaseContract)) > 0 or string-length(normalize-space(PurContractForOverallLimit)) > 0">
                                    <MasterAgreementIDInfo>
                                        <xsl:attribute name="agreementID">
                                            <xsl:choose>
                                                <xsl:when test="string-length(normalize-space(PurchaseContract)) > 0">
                                                    <xsl:value-of select="PurchaseContract"/>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:value-of select="PurContractForOverallLimit"/>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:attribute>
                                    </MasterAgreementIDInfo>
                                </xsl:if>
                                <!-- CI-1742 -->
                                <!-- CI-2413 SerialNumber -->
                                <xsl:if test="string-length(normalize-space(SerialNumber/SerialNumber[1])) > 0">
                                <ItemOutIndustry>
                                    <SerialNumberInfo>
                                        <xsl:attribute name="type">
                                            <xsl:value-of select="'list'"/>
                                        </xsl:attribute>
                                        <!--Begin of Changes SBNI-2565-->
                                        <xsl:if test="PurchaseOrderItemCategory = '3'">
                                            <xsl:attribute name="requiresSerialNumber">
                                                <xsl:value-of select="'yes'"/>
                                            </xsl:attribute>
                                        </xsl:if>
                                        <!--End of Changes SBNI-2565-->
                                        <xsl:for-each select="SerialNumber/SerialNumber">
                                                <SerialNumber>
                                                    <xsl:value-of select="."/>
                                               </SerialNumber>
                                    </xsl:for-each>
                                    </SerialNumberInfo>
                                </ItemOutIndustry>
                                </xsl:if> 
                                <!-- CI-2413 SerialNumber -->
                                <!-- CI-2413 BatchNumber -->
                                <xsl:if test="string-length(normalize-space(Batch/BuyerPartyBatch)) > 0 or string-length(normalize-space(Batch/SupplierPartyBatch)) > 0">
                                    <Batch>
                                        <xsl:if test="string-length(normalize-space(Batch/BuyerPartyBatch)) > 0">
                                        <BuyerBatchID>
                                            <xsl:value-of select="Batch/BuyerPartyBatch"/>
                                        </BuyerBatchID>
                                        </xsl:if>
                                        <xsl:if test="string-length(normalize-space(Batch/SupplierPartyBatch)) > 0">
                                        <SupplierBatchID>
                                            <xsl:value-of select="Batch/SupplierPartyBatch"/>
                                        </SupplierBatchID>
                                        </xsl:if>
                                    </Batch>
                                </xsl:if> 
                                <!-- CI-2413 BatchNumber -->
                            </ItemOut>
                        </xsl:if>
                    </xsl:for-each>
                    <!-- CI-1922 Line Item Attachment start -->
                    <xsl:variable name="ancXMLLineAttachments">
                        <xsl:if test="exists(/n0:OrderRequest/Order/OrderItem/Attachment)">
                            <xsl:for-each select="/n0:OrderRequest/Order/OrderItem/Attachment">
                                <xsl:value-of select="concat(string-join((*[namespace-uri() = 'http://www.w3.org/2004/08/xop/include' and local-name() = 'Include']/@href, @FileName, @MimeType), ';'), '#')"/>
                            </xsl:for-each>
                        </xsl:if>
                    </xsl:variable>
                    <xsl:variable name="ancXMLAttachments">
                        <xsl:value-of select="concat($ancXMLAttachmentsHeader, $ancXMLLineAttachments)"/>
                    </xsl:variable>
                    <xsl:if test="string-length(normalize-space($ancXMLAttachments)) &gt; 0">
                        <!-- keep it for testing purpose! -->
<!--                        <an><xsl:value-of select="concat($ancXMLAttachmentsHeader, $ancXMLLineAttachments)"/></an>-->
                        <xsl:value-of select="hci:setHeader($exchange, 'ancXMLAttachments', $ancXMLAttachments)"/>
                    </xsl:if>
                    <!-- CI-1922 Line Item Attachment end -->
                </OrderRequest>
            </Request>
        </cXML>
    </xsl:template>
</xsl:stylesheet>
