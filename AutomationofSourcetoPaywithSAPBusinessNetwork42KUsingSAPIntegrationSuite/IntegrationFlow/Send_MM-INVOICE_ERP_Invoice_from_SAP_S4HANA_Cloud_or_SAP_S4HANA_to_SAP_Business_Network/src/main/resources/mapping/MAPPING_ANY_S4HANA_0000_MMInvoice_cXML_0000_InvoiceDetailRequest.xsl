<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:hci="http://sap.com/it/"
    xmlns:n0="http://sap.com/xi/Procurement" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all" version="2.0">
    <xsl:output method="xml" indent="no" omit-xml-declaration="yes"/>    
    <xsl:param name="exchange"/>    
    <xsl:param name="anIsMultiERP"/>
    <xsl:param name="anSharedSecrete"/>
    <xsl:param name="ancxmlversion"/>
    <xsl:param name="anSupplierANID"/>
    <xsl:param name="anProviderANID"/>
    <xsl:param name="anContentID"/>
    <!--BPI-147 start -->
    
    <xsl:include href="FORMAT_S4HANA_0000_cXML_0000.xsl" use-when="doc-available('FORMAT_S4HANA_0000_cXML_0000.xsl')"/>
    <!--    <xsl:include href="../../../common/FORMAT_S4HANA_0000_cXML_0000.xsl"/>-->
    <!--BPI-147 end -->
    <xsl:param name="anPayloadID"/>
    <xsl:param name="anERPTimeZone"/>
    <xsl:param name="anEnvName"/>
    <xsl:param name="anERPSystemID"/>
    <xsl:param name="anTargetDocumentType"/>
    <xsl:param name="anSenderID"/>
    <xsl:variable name="v_ers"
        select="normalize-space(/n0:SupplierInvoiceCollaborationNotification/SupplierInvoice/SupplierInvoiceOrigin)"/>
    <xsl:template match="n0:SupplierInvoiceCollaborationNotification">
        <xsl:variable name="v_vendorId">
            <xsl:value-of select="SupplierInvoice/InvoicingParty"/>
        </xsl:variable>
        <xsl:variable name="v_curDate">
            <xsl:value-of select="current-dateTime()"/>
        </xsl:variable>
        <xsl:variable name="v_timestamp">
            <xsl:value-of
                select="concat(substring($v_curDate, 1, 19), substring($v_curDate, 24, 29))"/>
        </xsl:variable> 
        <xsl:variable name="v_tax">
            <xsl:for-each select="SupplierInvoice/TaxData/InvoiceTaxDetails">
                <value>
                    <xsl:value-of select="sum(TaxAmount)"/>
                </value>    
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="v_inv_sub">
            <xsl:for-each select="SupplierInvoice/SupplierInvoiceItemPurOrdRef">
                <value>
                    <xsl:value-of select="SupplierInvoiceItemAmount"/>
                </value>
            </xsl:for-each>
        </xsl:variable>    
        <xsl:variable name="cXMLEnvelopeHeader">
            <xsl:choose>
                <xsl:when test="upper-case($anIsMultiERP) = 'TRUE'">
                    <xsl:value-of
                        select="concat('&lt;cXML payloadID=&quot;', $anPayloadID, '&quot; timestamp=&quot;', $v_timestamp, '&quot; version=&quot;', $ancxmlversion, '&quot; xml:lang=&quot;en-US&quot;&gt; &lt;Header&gt;&lt;From&gt;&lt;Credential domain=&quot;NetworkID&quot;&gt;&lt;Identity&gt;', $anSenderID, '&lt;/Identity&gt;&lt;/Credential&gt;&lt;Credential domain=&quot;SystemID&quot;&gt;&lt;Identity&gt;', $anERPSystemID, '&lt;/Identity&gt;&lt;/Credential&gt;&lt;/From&gt;&lt;To&gt;&lt;Credential domain=&quot;VendorID&quot;&gt;&lt;Identity&gt;', $v_vendorId, '&lt;/Identity&gt;&lt;/Credential&gt;&lt;/To&gt;&lt;Sender&gt;&lt;Credential domain=&quot;NetworkID&quot;&gt;&lt;Identity&gt;', $anProviderANID, '&lt;/Identity&gt;&lt;SharedSecret&gt;', $anSharedSecrete, '&lt;/SharedSecret&gt;&lt;/Credential&gt;&lt;UserAgent&gt;Ariba SN Buyer Adapter&lt;/UserAgent&gt;&lt;/Sender&gt;&lt;/Header&gt;')"
                    />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of
                        select="concat('&lt;cXML payloadID=&quot;', $anPayloadID, '&quot; timestamp=&quot;', $v_timestamp, '&quot; version=&quot;', $ancxmlversion, '&quot; xml:lang=&quot;en-US&quot;&gt; &lt;Header&gt;&lt;From&gt;&lt;Credential domain=&quot;NetworkID&quot;&gt;&lt;Identity&gt;', $anSenderID, '&lt;/Identity&gt;&lt;/Credential&gt;&lt;/From&gt;&lt;To&gt;&lt;Credential domain=&quot;VendorID&quot;&gt;&lt;Identity&gt;', $v_vendorId, '&lt;/Identity&gt;&lt;/Credential&gt;&lt;/To&gt;&lt;Sender&gt;&lt;Credential domain=&quot;NetworkID&quot;&gt;&lt;Identity&gt;', $anProviderANID, '&lt;/Identity&gt;&lt;SharedSecret&gt;', $anSharedSecrete, '&lt;/SharedSecret&gt;&lt;/Credential&gt;&lt;UserAgent&gt;Ariba SN Buyer Adapter&lt;/UserAgent&gt;&lt;/Sender&gt;&lt;/Header&gt;')"
                    />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="cXMLEnvelopeRequest">
            <xsl:value-of
                select="concat('&lt;Request&gt; &lt;CopyRequest&gt; &lt;cXMLAttachment&gt; &lt;Attachment&gt;&lt;URL&gt;', 'cid:', $anContentID, '&lt;/URL&gt; &lt;/Attachment&gt; &lt;/cXMLAttachment&gt; &lt;/CopyRequest&gt; &lt;/Request&gt; &lt;/cXML&gt;')"
            />
        </xsl:variable>
        <xsl:variable name="cXMLEnvelope"> 
                    <xsl:value-of select="concat($cXMLEnvelopeHeader, ' ', $cXMLEnvelopeRequest)"/>
            <!--BPI-147 end -->
        </xsl:variable>
        <xsl:value-of select="hci:setHeader($exchange, 'cXMLEnvelope', $cXMLEnvelope)"/>
        <xsl:value-of select="hci:setHeader($exchange, 'anAttachmentName', 'MMInvoice.xml')"/>
        <xsl:value-of select="hci:setHeader($exchange, 'isANAttachment', 'YES')"/>
      <!--  <an><xsl:value-of select="$cXMLEnvelopeHeader"/></an>
        <an1><xsl:value-of select="$cXMLEnvelopeRequest"/></an1>-->
                <cXML>
                    <xsl:attribute name="payloadID">
                        <xsl:value-of select="concat($anPayloadID, $v_timestamp)"/>
                    </xsl:attribute>
                    <xsl:attribute name="timestamp">
                        <xsl:value-of select="$v_timestamp"/>
                    </xsl:attribute>
                    <Header>
                        <From>
                            <Credential domain="VendorID">
                                <Identity>
                                    <xsl:value-of select="$v_vendorId"/>
                                </Identity>
                            </Credential>
                            <!--End Point Fix for CIG-->
                            <Credential>
                                <xsl:attribute name="domain">EndPointID</xsl:attribute>
                                <Identity>CIG</Identity>
                            </Credential>
                            <Correspondent>
                                <Contact role="correspondent">
                                    <Name>
                                        <xsl:attribute name="xml:lang">

                                            <xsl:if
                                                test="string-length(normalize-space(SupplierInvoice/InvoicingPartyDetails/Address/CorrespondenceLanguage)) > 0">
                                                <xsl:value-of
                                                  select="SupplierInvoice/InvoicingPartyDetails/Address/CorrespondenceLanguage"
                                                />
                                            </xsl:if>

                                        </xsl:attribute>
                                        <xsl:value-of
                                            select="SupplierInvoice/InvoicingPartyDetails/Address/FullName"
                                        />
                                    </Name>
                                    <Email name="routing">
                                        <xsl:value-of
                                            select="SupplierInvoice/InvoicingPartyDetails/Address/EmailAddress"
                                        />
                                    </Email>
                                </Contact>
                            </Correspondent>
                        </From>
                        <To>
                            <!-- Multi ERP check-->
                            <xsl:call-template name="MultiERPTemplateOut">
                                <xsl:with-param name="p_anIsMultiERP" select="$anIsMultiERP"/>
                                <xsl:with-param name="p_anERPSystemID" select="$anERPSystemID"/>
                            </xsl:call-template>
                            <Credential domain="NetworkID">
                                <Identity>
                                    <xsl:value-of select="$anSenderID"/>
                                </Identity>
                            </Credential>
                        </To>
                        <Sender>
                            <Credential domain="NetworkID">
                                <Identity>
                                    <xsl:value-of select="$anSenderID"/>
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
                                <xsl:attribute name="deploymentMode">production</xsl:attribute>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:attribute name="deploymentMode">test</xsl:attribute>
                            </xsl:otherwise>
                        </xsl:choose>
                        <InvoiceDetailRequest>
                            <InvoiceDetailRequestHeader>
                                <xsl:if
                                    test="string-length(normalize-space(SupplierInvoice/SupplierInvoiceIDByInvcgParty)) > 0">
                                    <xsl:attribute name="invoiceID">
                                        <xsl:value-of
                                            select="SupplierInvoice/SupplierInvoiceIDByInvcgParty"/>
                                    </xsl:attribute>
                                </xsl:if>
                                <xsl:attribute name="purpose">standard</xsl:attribute>
                                <xsl:attribute name="operation">new</xsl:attribute>
                                <xsl:attribute name="invoiceDate">
                                    <xsl:if
                                        test="string-length(normalize-space(SupplierInvoice/DocumentDate)) > 0">
                                        <xsl:call-template name="ANDateTime_S4HANA">
                                            <xsl:with-param name="p_date"
                                                select="SupplierInvoice/DocumentDate"/>
                                            <xsl:with-param name="p_time" select="''"/>
                                            <xsl:with-param name="p_timezone"
                                                select="$anERPTimeZone"/>
                                        </xsl:call-template>
                                    </xsl:if>
                                </xsl:attribute>
                                <xsl:attribute name="invoiceOrigin">supplier</xsl:attribute>
                                <xsl:if test="string-length($v_ers) > 0">
                                    <xsl:attribute name="isERS">
                                        <xsl:value-of select="'yes'"/>
                                    </xsl:attribute>
                                </xsl:if>
                                <InvoiceDetailHeaderIndicator/>
                                <InvoiceDetailLineIndicator/>
                                <InvoicePartner>
                                    <Contact>
                                        <xsl:attribute name="role">billTo</xsl:attribute>
                                        <xsl:attribute name="addressID">
                                            <xsl:value-of select="SupplierInvoice/CompanyCode"/>
                                        </xsl:attribute>
                                        <Name>
                                            <xsl:attribute name="xml:lang">
                                                <xsl:if
                                                  test="string-length(normalize-space(SupplierInvoice/CompanyCodeDetails/Address/CorrespondenceLanguage)) > 0">
                                                  <xsl:value-of
                                                  select="SupplierInvoice/CompanyCodeDetails/Address/CorrespondenceLanguage"
                                                  />
                                                </xsl:if>
                                            </xsl:attribute>
                                            <xsl:value-of
                                                select="SupplierInvoice/CompanyCodeDetails/Address/FullName"
                                            />
                                        </Name>
                                        <PostalAddress>
                                            <Street>
                                                <xsl:value-of
                                                  select="SupplierInvoice/CompanyCodeDetails/Address/StreetName"
                                                />
                                            </Street>
                                            <City>
                                                <xsl:value-of
                                                  select="SupplierInvoice/CompanyCodeDetails/Address/CityName"
                                                />
                                            </City>
                                            <State>
                                                <xsl:value-of
                                                  select="SupplierInvoice/CompanyCodeDetails/Address/Region"
                                                />
                                            </State>
                                            <PostalCode>
                                                <xsl:value-of
                                                  select="SupplierInvoice/CompanyCodeDetails/Address/PostalCode"
                                                />
                                            </PostalCode>
                                            <Country>
                                                <xsl:attribute name="isoCountryCode">
                                                  <xsl:value-of
                                                  select="SupplierInvoice/CompanyCodeDetails/Address/Country"
                                                  />
                                                </xsl:attribute>
                                                <xsl:value-of
                                                  select="SupplierInvoice/CompanyCodeDetails/Address/Country"
                                                />
                                            </Country>
                                        </PostalAddress>
                                        <xsl:if
                                            test="SupplierInvoice/CompanyCodeDetails/Address/PhoneNumber">
                                            <Phone>
                                                <TelephoneNumber>
                                                  <CountryCode>
                                                  <xsl:attribute name="isoCountryCode">
                                                  <xsl:value-of
                                                  select="SupplierInvoice/CompanyCodeDetails/Address/PhoneNumber/CountryCode"
                                                  />
                                                  </xsl:attribute>
                                                  </CountryCode>
                                                  <xsl:if
                                                  test="SupplierInvoice/CompanyCodeDetails/Address/PhoneNumber/AreaID">
                                                  <AreaOrCityCode>
                                                  <xsl:value-of
                                                  select="SupplierInvoice/CompanyCodeDetails/Address/PhoneNumber/AreaID"
                                                  />
                                                  </AreaOrCityCode>
                                                  </xsl:if>
                                                  <Number>
                                                  <xsl:value-of
                                                  select="SupplierInvoice/CompanyCodeDetails/Address/PhoneNumber/FormattedPhoneNumber"
                                                  />
                                                  </Number>
                                                  <xsl:if
                                                  test="SupplierInvoice/CompanyCodeDetails/Address/PhoneNumber/ExtensionID">
                                                  <Extension>
                                                  <xsl:value-of
                                                  select="SupplierInvoice/CompanyCodeDetails/Address/PhoneNumber/ExtensionID"
                                                  />
                                                  </Extension>
                                                  </xsl:if>
                                                </TelephoneNumber>
                                            </Phone>
                                        </xsl:if>
                                        <xsl:if
                                            test="SupplierInvoice/CompanyCodeDetails/Address/FaxNumber">
                                            <Fax>
                                                <TelephoneNumber>
                                                  <CountryCode>
                                                  <xsl:attribute name="isoCountryCode">
                                                  <xsl:value-of
                                                  select="SupplierInvoice/CompanyCodeDetails/Address/FaxNumber/CountryCode"
                                                  />
                                                  </xsl:attribute>
                                                  </CountryCode>
                                                  <xsl:if
                                                  test="SupplierInvoice/CompanyCodeDetails/Address/FaxNumber/AreaID">
                                                  <AreaOrCityCode>
                                                  <xsl:value-of
                                                  select="SupplierInvoice/CompanyCodeDetails/Address/FaxNumber/AreaID"
                                                  />
                                                  </AreaOrCityCode>
                                                  </xsl:if>
                                                  <Number>
                                                  <xsl:value-of
                                                  select="SupplierInvoice/CompanyCodeDetails/Address/FormattedFaxNumber"
                                                  />
                                                  </Number>
                                                  <xsl:if
                                                  test="SupplierInvoice/CompanyCodeDetails/Address/FaxNumber/ExtensionID">
                                                  <Extension>
                                                  <xsl:value-of
                                                  select="SupplierInvoice/CompanyCodeDetails/Address/FaxNumber/ExtensionID"
                                                  />
                                                  </Extension>
                                                  </xsl:if>
                                                </TelephoneNumber>
                                            </Fax>
                                        </xsl:if>
                                    </Contact>
                                </InvoicePartner>
                                <xsl:if test="SupplierInvoice/InvoicingParty">
                                    <InvoicePartner>
                                        <Contact role="remitTo">
                                            <xsl:attribute name="addressID">
                                                <xsl:value-of
                                                  select="SupplierInvoice/InvoicingParty"/>
                                            </xsl:attribute>
                                            <xsl:attribute name="addressIDDomain"
                                                >billToID</xsl:attribute>
                                            <Name>
                                                <xsl:attribute name="xml:lang">
                                                  <xsl:if
                                                  test="string-length(normalize-space(SupplierInvoice/InvoicingPartyDetails/Address/CorrespondenceLanguage)) > 0">
                                                  <xsl:value-of
                                                  select="SupplierInvoice/InvoicingPartyDetails/Address/CorrespondenceLanguage"
                                                  />
                                                  </xsl:if>
                                                </xsl:attribute>
                                                <xsl:value-of
                                                  select="SupplierInvoice/InvoicingPartyDetails/Address/FullName"
                                                />
                                            </Name>
                                            <PostalAddress>
                                                <Street>
                                                  <xsl:value-of
                                                  select="SupplierInvoice/InvoicingPartyDetails/Address/StreetName"
                                                  />
                                                </Street>
                                                <City>
                                                  <xsl:value-of
                                                  select="SupplierInvoice/InvoicingPartyDetails/Address/CityName"
                                                  />
                                                </City>
                                                <State>
                                                  <xsl:value-of
                                                  select="SupplierInvoice/InvoicingPartyDetails/Address/Region"
                                                  />
                                                </State>
                                                <PostalCode>
                                                  <xsl:value-of
                                                  select="SupplierInvoice/InvoicingPartyDetails/Address/PostalCode"
                                                  />
                                                </PostalCode>
                                                <Country>
                                                  <xsl:attribute name="isoCountryCode">
                                                  <xsl:value-of
                                                  select="SupplierInvoice/InvoicingPartyDetails/Address/Country"
                                                  />
                                                  </xsl:attribute>
                                                  <xsl:value-of
                                                  select="SupplierInvoice/InvoicingPartyDetails/Address/Country"
                                                  />
                                                </Country>
                                            </PostalAddress>
                                            <Email name="default">
                                                <xsl:value-of
                                                  select="SupplierInvoice/InvoicingPartyDetails/Address/EmailAddress"
                                                />
                                            </Email>
                                        </Contact>
                                    </InvoicePartner>
                                </xsl:if>
                                <xsl:if test="SupplierInvoice/InvoicingParty">
                                    <InvoicePartner>
                                        <Contact role="from">
                                            <xsl:attribute name="addressID">
                                                <xsl:value-of
                                                  select="SupplierInvoice/InvoicingParty"/>
                                            </xsl:attribute>
                                            <xsl:attribute name="addressIDDomain"
                                                >billToID</xsl:attribute>
                                            <Name>
                                                <xsl:attribute name="xml:lang">
                                                  <xsl:if
                                                  test="string-length(normalize-space(SupplierInvoice/InvoicingPartyDetails/Address/CorrespondenceLanguage)) > 0">
                                                  <xsl:value-of
                                                  select="SupplierInvoice/InvoicingPartyDetails/Address/CorrespondenceLanguage"
                                                  />
                                                  </xsl:if>
                                                </xsl:attribute>
                                                <xsl:value-of
                                                  select="SupplierInvoice/InvoicingPartyDetails/Address/FullName"
                                                />
                                            </Name>
                                            <PostalAddress>
                                                <Street>
                                                  <xsl:value-of
                                                  select="SupplierInvoice/InvoicingPartyDetails/Address/StreetName"
                                                  />
                                                </Street>
                                                <City>
                                                  <xsl:value-of
                                                  select="SupplierInvoice/InvoicingPartyDetails/Address/CityName"
                                                  />
                                                </City>
                                                <State>
                                                  <xsl:value-of
                                                  select="SupplierInvoice/InvoicingPartyDetails/Address/Region"
                                                  />
                                                </State>
                                                <PostalCode>
                                                  <xsl:value-of
                                                  select="SupplierInvoice/InvoicingPartyDetails/Address/PostalCode"
                                                  />
                                                </PostalCode>
                                                <Country>
                                                  <xsl:attribute name="isoCountryCode">
                                                  <xsl:value-of
                                                  select="SupplierInvoice/InvoicingPartyDetails/Address/Country"
                                                  />
                                                  </xsl:attribute>
                                                  <xsl:value-of
                                                  select="SupplierInvoice/InvoicingPartyDetails/Address/Country"
                                                  />
                                                </Country>
                                            </PostalAddress>
                                            <Email name="default">
                                                <xsl:value-of
                                                  select="SupplierInvoice/InvoicingPartyDetails/Address/EmailAddress"
                                                />
                                            </Email>
                                        </Contact>
                                    </InvoicePartner>
                                </xsl:if>
                                <xsl:if test="string-length(normalize-space(SupplierInvoice/PaymentTerms/CashDiscount1Percent))">
                                    <PaymentTerm>
                                        <xsl:attribute name="payInNumberOfDays">
                                            <xsl:value-of select="SupplierInvoice/PaymentTerms/CashDiscount1Days"/>
                                        </xsl:attribute>
                                        <Discount>
                                            <DiscountPercent>
                                                <!--Absence of Discount1Percent is blank populate 0.000 -->
                                                <xsl:attribute name="percent">
                                                    <xsl:choose>
                                                        <xsl:when test="string-length(normalize-space(SupplierInvoice/PaymentTerms/CashDiscount1Percent)) > 0">
                                                            <xsl:value-of select="SupplierInvoice/PaymentTerms/CashDiscount1Percent"/>
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <xsl:value-of select="0"/>
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                                </xsl:attribute>
                                            </DiscountPercent>
                                        </Discount>
                                    </PaymentTerm>
                                </xsl:if>
                                <xsl:if test="string-length(normalize-space(SupplierInvoice/PaymentTerms/CashDiscount2Percent))">
                                    <PaymentTerm>
                                        <xsl:attribute name="payInNumberOfDays">
                                            <xsl:value-of select="SupplierInvoice/PaymentTerms/CashDiscount2Days"/>
                                        </xsl:attribute>
                                        <Discount>
                                            <DiscountPercent>
                                                <xsl:attribute name="percent">
                                                    <xsl:choose>
                                                        <xsl:when test="string-length(normalize-space(SupplierInvoice/PaymentTerms/CashDiscount2Percent)) > 0">
                                                            <xsl:value-of select="SupplierInvoice/PaymentTerms/CashDiscount2Percent"/>
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <xsl:value-of select="0"/>
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                                </xsl:attribute>
                                            </DiscountPercent>
                                        </Discount>
                                    </PaymentTerm>
                                </xsl:if>
                                <xsl:if test="string-length(normalize-space(SupplierInvoice/PaymentTerms/NetPaymentDays))">
                                    <PaymentTerm>
                                        <xsl:attribute name="payInNumberOfDays">
                                            <xsl:value-of select="SupplierInvoice/PaymentTerms/NetPaymentDays"/>
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
                                <xsl:if
                                    test="string-length(normalize-space(SupplierInvoice/PaymentTerms/DueCalculationBaseDate)) > 0">
                                    <PaymentInformation>
                                        <xsl:attribute name="paymentNetDueDate">
                                            <xsl:call-template name="ANDateTime_S4HANA">
                                                <xsl:with-param name="p_date"
                                                  select="SupplierInvoice/PaymentTerms/DueCalculationBaseDate"/>
                                                <xsl:with-param name="p_time" select="''"/>
                                                <xsl:with-param name="p_timezone"
                                                  select="$anERPTimeZone"/>
                                            </xsl:call-template>
                                        </xsl:attribute>
                                    </PaymentInformation>
                                </xsl:if>
                                <Extrinsic name="buyerInvoiceID">
                                    <xsl:if
                                        test="string-length(normalize-space(SupplierInvoice/SupplierInvoiceID)) > 0">
                                        <xsl:value-of select="SupplierInvoice/SupplierInvoiceID"/>
                                    </xsl:if>
                                </Extrinsic>
                                <Extrinsic name="CompanyCode">
                                    <xsl:value-of select="SupplierInvoice/CompanyCode"/>
                                </Extrinsic>
                                <Extrinsic name="fiscalYear">
                                    <xsl:if test="SupplierInvoice/FiscalYear">
                                        <xsl:value-of select="SupplierInvoice/FiscalYear"/>
                                    </xsl:if>
                                </Extrinsic>
                                <Extrinsic name="invoiceSourceDocument">
                                    <xsl:value-of select="'PurchaseOrder'"/>
                                </Extrinsic>
                                <Extrinsic name="invoiceSubmissionMethod">
                                    <xsl:value-of select="'Online'"/>
                                </Extrinsic>
                                <Extrinsic name="ERS">
                                    <xsl:value-of select="'Self-Billing'"/>
                                </Extrinsic>
                            </InvoiceDetailRequestHeader>
                            <xsl:for-each select="SupplierInvoice/SupplierInvoiceItemPurOrdRef">
                                <InvoiceDetailOrder>
                                    <InvoiceDetailOrderInfo>
                                        <xsl:if test="PurchaseOrderReference">
                                            <OrderIDInfo>
                                                <xsl:attribute name="orderID">
                                                  <xsl:value-of
                                                  select="PurchaseOrderReference/PurchaseOrderID"/>
                                                </xsl:attribute>
                                            </OrderIDInfo>
                                        </xsl:if>
                                    </InvoiceDetailOrderInfo>
                                    <!--For the Material Line items-->
                                    <xsl:if
                                        test="string-length(normalize-space(GoodsReceiptReference)) > 0">
                                        <InvoiceDetailItem>
                                            <xsl:attribute name="invoiceLineNumber">
                                                <xsl:value-of select="SupplierInvoiceItem"/>
                                            </xsl:attribute>
                                            <xsl:attribute name="quantity">
                                                <xsl:value-of select="QtyInPurchaseOrderPriceUnit"/>
                                            </xsl:attribute>
                                            <UnitOfMeasure>
                                                <xsl:value-of
                                                  select="QuantityInPurchaseOrderUnit/@unitCode"/>
                                            </UnitOfMeasure>
                                            <UnitPrice>
                                                <Money>
                                                  <xsl:attribute name="currency">
                                                  <xsl:value-of
                                                  select="SupplierInvoiceItemAmount/@currencyCode"/>
                                                  </xsl:attribute>
                                                  <xsl:value-of
                                                  select="normalize-space(format-number(SupplierInvoiceItemAmount div QuantityInPurchaseOrderUnit, '###,###,##0.00'))"
                                                  />
                                                </Money>
                                            </UnitPrice>
                                            <InvoiceDetailItemReference>
                                                <xsl:attribute name="lineNumber">
                                                    <xsl:value-of select="normalize-space(PurchaseOrderReference/PurchaseOrderItem)"/>
                                                </xsl:attribute>
                                                <ItemID>
                                                    <SupplierPartID>
                                                        <xsl:value-of select="Product/SupplierProductID"/>
                                                    </SupplierPartID>
                                                    <xsl:if
                                                        test="(string-length(normalize-space(Product/BuyerProductID)) > 0)">
                                                        <BuyerPartID>
                                                            <xsl:value-of select="Product/BuyerProductID"/>
                                                        </BuyerPartID>
                                                    </xsl:if>
                                                </ItemID>
                                                <Description>
                                                    <xsl:attribute name="xml:lang">
                                                        <xsl:value-of
                                                            select="SupplierInvoice/InvoicingPartyDetails/Address/CorrespondenceLanguage"
                                                        />
                                                    </xsl:attribute>
                                                    <xsl:value-of select="concat('Settlement for purchasing document ', PurchaseOrderReference/PurchaseOrderID, ', ', PurchaseOrderReference/PurchaseOrderItem)"/>
                                                </Description>
                                            </InvoiceDetailItemReference>
                                            <SubtotalAmount>
                                                <Money>
                                                    <xsl:attribute name="currency">
                                                        <xsl:choose>
                                                            <xsl:when test="string-length(SupplierInvoiceItemPurOrdRefAcctAssgmt/SuplrInvcAcctAssignmentAmount/@currencyCode) > 0">
                                                                <xsl:value-of
                                                                    select="SupplierInvoiceItemPurOrdRefAcctAssgmt/SuplrInvcAcctAssignmentAmount/@currencyCode"/>
                                                            </xsl:when>
                                                            <xsl:otherwise>
                                                                <xsl:value-of select="SupplierInvoiceItemAmount/@currencyCode"/>
                                                            </xsl:otherwise>
                                                        </xsl:choose>
                                                    </xsl:attribute>
                                                    <xsl:choose>
                                                        <xsl:when test="string-length(SupplierInvoiceItemPurOrdRefAcctAssgmt/SuplrInvcAcctAssignmentAmount) > 0">
                                                            <xsl:value-of
                                                                select="SupplierInvoiceItemPurOrdRefAcctAssgmt/SuplrInvcAcctAssignmentAmount"/>
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <xsl:value-of select="SupplierInvoiceItemAmount"/>
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                                </Money>
                                            </SubtotalAmount>
                                            <GrossAmount>
                                                <Money>
                                                    <xsl:attribute name="currency">
                                                        <xsl:choose>
                                                            <xsl:when test="string-length(SupplierInvoiceItemPurOrdRefAcctAssgmt/SuplrInvcAcctAssignmentAmount/@currencyCode) > 0">
                                                                <xsl:value-of
                                                                    select="SupplierInvoiceItemPurOrdRefAcctAssgmt/SuplrInvcAcctAssignmentAmount/@currencyCode"/>
                                                            </xsl:when>
                                                            <xsl:otherwise>
                                                                <xsl:value-of select="SupplierInvoiceItemAmount/@currencyCode"/>
                                                            </xsl:otherwise>
                                                        </xsl:choose>
                                                    </xsl:attribute>
                                                    <xsl:choose>
                                                        <xsl:when test="string-length(SupplierInvoiceItemPurOrdRefAcctAssgmt/SuplrInvcAcctAssignmentAmount) > 0">
                                                            <xsl:value-of
                                                                select="SupplierInvoiceItemPurOrdRefAcctAssgmt/SuplrInvcAcctAssignmentAmount"/>
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <xsl:value-of select="SupplierInvoiceItemAmount"/>
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                                </Money>
                                            </GrossAmount>
                                            <NetAmount>
                                                <Money>
                                                    <xsl:attribute name="currency">
                                                        <xsl:choose>
                                                            <xsl:when test="string-length(SupplierInvoiceItemPurOrdRefAcctAssgmt/SuplrInvcAcctAssignmentAmount/@currencyCode) > 0">
                                                                <xsl:value-of
                                                                    select="SupplierInvoiceItemPurOrdRefAcctAssgmt/SuplrInvcAcctAssignmentAmount/@currencyCode"/>
                                                            </xsl:when>
                                                            <xsl:otherwise>
                                                                <xsl:value-of select="SupplierInvoiceItemAmount/@currencyCode"/>
                                                            </xsl:otherwise>
                                                        </xsl:choose>
                                                    </xsl:attribute>
                                                    <xsl:choose>
                                                        <xsl:when test="string-length(SupplierInvoiceItemPurOrdRefAcctAssgmt/SuplrInvcAcctAssignmentAmount) > 0">
                                                            <xsl:value-of
                                                                select="SupplierInvoiceItemPurOrdRefAcctAssgmt/SuplrInvcAcctAssignmentAmount"/>
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <xsl:value-of select="SupplierInvoiceItemAmount"/>
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                                </Money>
                                            </NetAmount>
                                        </InvoiceDetailItem>
                                    </xsl:if>
                                    <!--For the lean service line items-->
                                    <xsl:if
                                        test="string-length(normalize-space(ServiceEntrySheetReference)) > 0">
                                        <InvoiceDetailServiceItem>
                                            <xsl:attribute name="invoiceLineNumber">
                                                <xsl:value-of select="SupplierInvoiceItem"/>
                                            </xsl:attribute>
                                            <xsl:attribute name="quantity">
                                                <xsl:value-of select="QtyInPurchaseOrderPriceUnit"/>
                                            </xsl:attribute>
                                            <InvoiceDetailServiceItemReference>
                                                <xsl:attribute name="lineNumber">
                                                    <xsl:value-of select="PurchaseOrderReference/PurchaseOrderItem"/>
                                                </xsl:attribute>
                                                <ItemID>
                                                  <SupplierPartID>
                                                  <xsl:value-of select="Product/SupplierProductID"/>
                                                  </SupplierPartID>
                                                  <xsl:if
                                                  test="(string-length(normalize-space(Product/BuyerProductID)) > 0)">
                                                  <BuyerPartID>
                                                  <xsl:value-of select="Product/BuyerProductID"/>
                                                  </BuyerPartID>
                                                  </xsl:if>
                                                </ItemID>
                                            </InvoiceDetailServiceItemReference>
                                            <ServiceEntryItemIDInfo>
                                                <xsl:attribute name="serviceLineNumber">
                                                  <xsl:value-of
                                                  select="ServiceEntrySheetReference/ServiceEntrySheetItem"
                                                  />
                                                </xsl:attribute>
                                                <xsl:attribute name="serviceEntryID">
                                                    <!-- Start CI-2793-->
                                                    <xsl:choose>
                                                        <xsl:when
                                                            test="(string-length(normalize-space(ServiceEntrySheetReference/SESExternalReference)) > 0)">
                                                            <xsl:value-of
                                                                select="ServiceEntrySheetReference/SESExternalReference"
                                                            />
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <xsl:value-of
                                                                select="ServiceEntrySheetReference/ServiceEntrySheetID"
                                                            />
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                                    <!-- End CI-2793-->
                                                </xsl:attribute>
                                            </ServiceEntryItemIDInfo>
                                            <SubtotalAmount>
                                                <Money>
                                                  <xsl:attribute name="currency">
                                                  <xsl:value-of
                                                  select="SupplierInvoiceItemPurOrdRefAcctAssgmt/SuplrInvcAcctAssignmentAmount/@currencyCode"
                                                  />
                                                  </xsl:attribute>
                                                  <xsl:value-of
                                                  select="SupplierInvoiceItemPurOrdRefAcctAssgmt/SuplrInvcAcctAssignmentAmount"
                                                  />
                                                </Money>
                                            </SubtotalAmount>
                                            <UnitOfMeasure>
                                                <xsl:value-of
                                                  select="QuantityInPurchaseOrderUnit/@unitCode"/>
                                            </UnitOfMeasure>
                                            <UnitPrice>
                                                <Money>
                                                  <xsl:attribute name="currency">
                                                  <xsl:value-of
                                                  select="SupplierInvoiceItemAmount/@currencyCode"/>
                                                  </xsl:attribute>
                                                  <xsl:value-of
                                                  select="normalize-space(format-number(SupplierInvoiceItemAmount div QuantityInPurchaseOrderUnit, '###,###,##0.00'))"
                                                  />
                                                </Money>
                                            </UnitPrice>
                                            <GrossAmount>
                                                <Money>
                                                  <xsl:attribute name="currency">
                                                  <xsl:value-of
                                                  select="SupplierInvoiceItemPurOrdRefAcctAssgmt/SuplrInvcAcctAssignmentAmount/@currencyCode"
                                                  />
                                                  </xsl:attribute>
                                                  <xsl:value-of
                                                  select="SupplierInvoiceItemPurOrdRefAcctAssgmt/SuplrInvcAcctAssignmentAmount"
                                                  />
                                                </Money>
                                            </GrossAmount>
                                            <NetAmount>
                                                <Money>
                                                  <xsl:attribute name="currency">
                                                  <xsl:value-of
                                                  select="SupplierInvoiceItemPurOrdRefAcctAssgmt/SuplrInvcAcctAssignmentAmount/@currencyCode"
                                                  />
                                                  </xsl:attribute>
                                                  <xsl:value-of
                                                  select="SupplierInvoiceItemPurOrdRefAcctAssgmt/SuplrInvcAcctAssignmentAmount"
                                                  />
                                                </Money>
                                            </NetAmount>
                                            <Extrinsic name="punchinItemFromCatalog">
                                                <xsl:value-of select="'no'"/>
                                            </Extrinsic>
                                        </InvoiceDetailServiceItem>
                                    </xsl:if>
                                </InvoiceDetailOrder>
                            </xsl:for-each>
                            <InvoiceDetailSummary>
                                <SubtotalAmount>
                                    <Money>
                                        <xsl:attribute name="currency">
                                            <xsl:value-of
                                                select="SupplierInvoice/InvoiceGrossAmount/@currencyCode"
                                            />
                                        </xsl:attribute>
                                            <xsl:value-of select="sum($v_inv_sub/value)"/>
                                    </Money>
                                </SubtotalAmount>
                                <Tax>
                                    <Money>
                                        <xsl:attribute name="currency">
                                            <xsl:value-of
                                                select="SupplierInvoice/TaxData/InvoiceTaxDetails[1]/TaxBaseAmountInTransCrcy/@currencyCode"
                                            />
                                        </xsl:attribute>
                                        <xsl:value-of
                                            select="sum($v_tax/value)"
                                        />
                                    </Money>
                                    <Description>
                                        <xsl:attribute name="xml:lang">
                                            <xsl:value-of select="normalize-space(SupplierInvoice/InvoicingPartyDetails/Address/CorrespondenceLanguage)"/>
                                        </xsl:attribute>
                                    </Description>    
                                    <xsl:for-each select="SupplierInvoice/TaxData/InvoiceTaxDetails">
                                        <xsl:variable name="v_Desc_Position" select="position()"/>
                                        <TaxDetail>
                                            <xsl:attribute name="category">
                                                <xsl:for-each select="Extrinsic">
                                                    <xsl:if test="Name = 'TAXCATEGORY'">
                                                        <xsl:value-of select="normalize-space(Value)"/>
                                                    </xsl:if>
                                                </xsl:for-each>
                                            </xsl:attribute>
                                            <xsl:attribute name="percentageRate">
                                                <xsl:for-each select="Extrinsic">
                                                    <xsl:if test="Name = 'TAXRATE'">
                                                        <xsl:value-of select="normalize-space(Value)"/>
                                                    </xsl:if>
                                                </xsl:for-each>
                                            </xsl:attribute>
                                            <TaxableAmount>
                                                <Money>
                                                  <xsl:attribute name="currency">
                                                  <xsl:value-of
                                                  select="TaxBaseAmountInTransCrcy/@currencyCode"/>
                                                  </xsl:attribute>
                                                  <xsl:value-of select="TaxBaseAmountInTransCrcy"/>
                                                </Money>
                                            </TaxableAmount>
                                            <TaxAmount>
                                                <Money>
                                                  <xsl:attribute name="currency">
                                                      <xsl:value-of select="TaxBaseAmountInTransCrcy/@currencyCode"/>
                                                  </xsl:attribute>
                                                  <xsl:value-of select="TaxAmount"/>
                                                </Money>
                                            </TaxAmount>
                                            <Description>
                                                <xsl:attribute name="xml:lang">
                                                    <xsl:value-of select="SupplierInvoice/InvoicingPartyDetails/Address/CorrespondenceLanguage"/>
                                                </xsl:attribute>
                                            </Description>    
                                        </TaxDetail>
                                    </xsl:for-each>
                                </Tax>
                                <GrossAmount>
                                    <Money>
                                        <xsl:attribute name="currency">
                                            <xsl:value-of
                                                select="SupplierInvoice/InvoiceGrossAmount/@currencyCode"/>
                                        </xsl:attribute>
                                        <xsl:value-of select="SupplierInvoice/InvoiceGrossAmount"/>
                                    </Money>
                                </GrossAmount>
                                <NetAmount>
                                    <Money>
                                        <xsl:attribute name="currency">
                                            <xsl:value-of
                                                select="SupplierInvoice/InvoiceGrossAmount/@currencyCode"/>
                                        </xsl:attribute>
                                        <xsl:value-of select="SupplierInvoice/InvoiceGrossAmount"/>
                                    </Money>
                                </NetAmount>
                            </InvoiceDetailSummary>
                        </InvoiceDetailRequest>
                    </Request>
                </cXML>
    </xsl:template>
</xsl:stylesheet>
