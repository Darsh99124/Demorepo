<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xop="http://www.w3.org/2004/08/xop/include" exclude-result-prefixes="#all" version="2.0">
    <xsl:output method="xml" indent="no" omit-xml-declaration="yes"/>
    <!-- Indent No is made on purpose, else attachments will fail in S4 Cloud -->        
    <xsl:param name="cXMLAttachments"/>
<!--    <xsl:include href="FORMAT_S4HANA_0000_cXML_0000.xsl"/>-->
    <!--BPI-147 start -->    
    <xsl:include href="FORMAT_S4HANA_0000_cXML_0000.xsl" use-when="doc-available('FORMAT_S4HANA_0000_cXML_0000.xsl')"/>
    <!--BPI-147 end -->
    <xsl:param name="anERPTimeZone"/>
    <xsl:param name="anSourceDocumentType"/>
    <xsl:param name="anReceiverID"/>
    <xsl:param name="anERPSystemID"/>

    <xsl:template match="Combined/Payload">
        <xsl:variable name="v_erpdate">
            <xsl:call-template name="ERPDateTime">
                <xsl:with-param name="p_date"
                    select="cXML/Request/InvoiceDetailRequest/InvoiceDetailRequestHeader/@invoiceDate"/>
                <xsl:with-param name="p_timezone" select="$anERPTimeZone"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="v_inv_typ"
            select="cXML/Request/InvoiceDetailRequest/InvoiceDetailRequestHeader/@purpose"/>
        <!-- Get the type of inovoice, need to flip the sign, only positive values are allowed -->
         <xsl:variable name="v_sign">
            <xsl:choose>
                <xsl:when test="$v_inv_typ = 'standard'">
                    <xsl:value-of select="number(1)"/>
                </xsl:when>
                <xsl:when test="$v_inv_typ = 'lineLevelCreditMemo'">
                    <xsl:value-of select="number(-1)"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
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
        <n0:InvoiceRequest xmlns:n0="http://sap.com/xi/EDI">
            <MessageHeader>
                <ID>
                    <xsl:value-of select="substring-before(cXML/@payloadID, '@')"/>
                </ID>
                <CreationDateTime>
                    <xsl:value-of select="$v_erpdate"/>
                </CreationDateTime>
                <SenderBusinessSystemID>
                    <xsl:value-of select="'ARIBA_NETWORK'"/>
                </SenderBusinessSystemID>
                <RecipientBusinessSystemID>
                    <xsl:value-of select="substring($v_sysid, 1, 60)"/>
                </RecipientBusinessSystemID>
                <SenderParty>
                    <InternalID>
                        <xsl:value-of select="substring(cXML/Header/To/Credential[@domain = 'NetworkID']/Identity, 1, 32)"/>
                    </InternalID>
                </SenderParty>
                <!--cXML Payload for Status Updates.-->
                <BusinessScope>
                    <TypeCode></TypeCode>
                    <InstanceID>
                        <xsl:attribute name="schemeID">
                            <xsl:value-of select="normalize-space(cXML/@payloadID)"/>
                        </xsl:attribute>
                    </InstanceID>
                </BusinessScope>
            </MessageHeader>
            <Invoice>
                <SupplierInvoiceID>
                    <xsl:value-of
                        select="substring(cXML/Request/InvoiceDetailRequest/InvoiceDetailRequestHeader/@invoiceID, 1, 35)"/>
                </SupplierInvoiceID>
                <SupplierInvoiceTypeCode>
                    <xsl:choose>
                        <xsl:when test="$v_inv_typ = 'standard'">
                            <xsl:value-of select="'004'"/>
                        </xsl:when>
                        <xsl:when test="$v_inv_typ = 'lineLevelCreditMemo'">
                            <xsl:value-of select="'005'"/>
                        </xsl:when>
                    </xsl:choose>
                </SupplierInvoiceTypeCode>
                <DocumentDate>
                    <xsl:value-of select="substring($v_erpdate, 1, 10)"/>
                </DocumentDate>
<!--                IG-36976-->
                <GrossAmount>
                    <xsl:attribute name="currencyCode">
                        <xsl:value-of
                            select="substring(cXML/Request/InvoiceDetailRequest/InvoiceDetailSummary/NetAmount/Money/@currency, 1, 5)"/>
                    </xsl:attribute>
                    <xsl:value-of
                        select="format-number(number(cXML/Request/InvoiceDetailRequest/InvoiceDetailSummary/NetAmount/Money * $v_sign),'0.######')"/>
                </GrossAmount>
<!--                IG-36976-->
                <Party>
                    <xsl:attribute name="PartyType">
                        <xsl:value-of select="'BillFrom'"/>
                    </xsl:attribute>
                    <BuyerPartyID>
                        <xsl:value-of
                            select="substring(cXML/Header/From/Credential[@domain = 'VendorID']/Identity, 1, 60)"/>
                    </BuyerPartyID>
                    <Address>
                        <AddressName>
                            <xsl:value-of
                                select="substring(cXML/Request/InvoiceDetailRequest/InvoiceDetailRequestHeader/InvoicePartner/Contact[@role = 'billFrom']/Name, 1, 40)"/>
                        </AddressName>
                    </Address>
                </Party>
                <Party>
                    <xsl:attribute name="PartyType">
                        <xsl:value-of select="'BillTo'"/>
                    </xsl:attribute>
                    <Address>
                        <AddressName>
                            <xsl:choose>
                                <xsl:when
                                    test="string-length(normalize-space(cXML/Request/InvoiceDetailRequest/InvoiceDetailRequestHeader/InvoicePartner/Contact[@role = 'billTo']/Name)) > 0">
                                    <xsl:value-of
                                        select="substring(cXML/Request/InvoiceDetailRequest/InvoiceDetailRequestHeader/InvoicePartner/Contact[@role = 'billTo']/Name, 1, 40)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of
                                        select="substring(cXML/Request/InvoiceDetailRequest/InvoiceDetailRequestHeader/InvoicePartner/Contact[@role = 'soldTo']/Name, 1, 40)"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </AddressName>
                    </Address>
                </Party>
<!--                IG-36976-->
<!--                <xsl:if
                    test="cXML/Request/InvoiceDetailRequest/InvoiceDetailSummary/InvoiceDetailDiscount/Money * $v_sign &gt; 0">
                    <PricingElement>
                        <SupplierConditionType>
                            <xsl:attribute name="listID">
                                <xsl:value-of select="'Cash Discount'"/>
                            </xsl:attribute>
                            <xsl:value-of select="'HDVA'"/>
                        </SupplierConditionType>
                        <ConditionAmount>
                            <xsl:attribute name="currencyCode">
                                <xsl:value-of
                                    select="substring(cXML/Request/InvoiceDetailRequest/InvoiceDetailSummary/InvoiceDetailDiscount/Money/@currency, 1, 5)"/>
                            </xsl:attribute>
                            <xsl:value-of
                                select="format-number(number(cXML/Request/InvoiceDetailRequest/InvoiceDetailSummary/InvoiceDetailDiscount/Money * $v_sign),'#.######')"/>
                        </ConditionAmount>
                    </PricingElement>
                </xsl:if>-->
<!--                IG-36976-->
                <xsl:if
                    test="cXML/Request/InvoiceDetailRequest/InvoiceDetailSummary/ShippingAmount/Money * $v_sign &gt; 0">
                    <PricingElement>
                        <SupplierConditionType>
                            <xsl:attribute name="listID">
                                <xsl:value-of select="'Shipping Cost'"/>
                            </xsl:attribute>
                            <xsl:value-of select="'HFVA'"/>
                        </SupplierConditionType>
                        <ConditionAmount>
                            <xsl:attribute name="currencyCode">
                                <xsl:value-of
                                    select="substring(cXML/Request/InvoiceDetailRequest/InvoiceDetailSummary/ShippingAmount/Money/@currency, 1, 5)"/>
                            </xsl:attribute>
                            <xsl:value-of
                                select="format-number(number(cXML/Request/InvoiceDetailRequest/InvoiceDetailSummary/ShippingAmount/Money * $v_sign),'0.######')"/>
                        </ConditionAmount>
                    </PricingElement>
                </xsl:if>
                <xsl:if
                    test="cXML/Request/InvoiceDetailRequest/InvoiceDetailSummary/SpecialHandlingAmount/Money * $v_sign &gt; 0">
                    <PricingElement>
                        <SupplierConditionType>
                            <xsl:attribute name="listID">
                                <xsl:value-of select="'Special Handling Charge'"/>
                            </xsl:attribute>
                            <xsl:value-of select="'HSVA'"/>
                        </SupplierConditionType>
                        <ConditionAmount>
                            <xsl:attribute name="currencyCode">
                                <xsl:value-of
                                    select="substring(cXML/Request/InvoiceDetailRequest/InvoiceDetailSummary/SpecialHandlingAmount/Money/@currency, 1, 5)"/>
                            </xsl:attribute>
                            <xsl:value-of
                                select="format-number(number(cXML/Request/InvoiceDetailRequest/InvoiceDetailSummary/SpecialHandlingAmount/Money * $v_sign),'0.######')"/>
                        </ConditionAmount>
                    </PricingElement>
                </xsl:if>
                <xsl:for-each
                    select="cXML/Request/InvoiceDetailRequest/InvoiceDetailSummary/Tax/TaxDetail">
                    <HeaderTax>
                        <SupplierTaxTypeCode>
                            <xsl:call-template name="TaxType">
                                <xsl:with-param name="p_category" select="@category"/>
                            </xsl:call-template>
                        </SupplierTaxTypeCode>
                        <Amount>
                            <xsl:attribute name="currencyCode">
                                <xsl:value-of select="substring(TaxAmount/Money/@currency, 1, 5)"/>
                            </xsl:attribute>
                            <xsl:value-of select="format-number(number(TaxAmount/Money * $v_sign),'0.######')"/>
                        </Amount>
                        <TaxPercentage>
                            <xsl:value-of select="@percentageRate"/>
                        </TaxPercentage>
                    </HeaderTax>
                </xsl:for-each>
                <!-- CI-2383 Text element -->
                <DocumentHeaderText>
                    <xsl:attribute name="Type">
                        <xsl:value-of select="'Text'"/>
                    </xsl:attribute>
                    <TextElementText>
                        <xsl:value-of select="'ARIBA_INVOICE'"/>
                    </TextElementText>
                </DocumentHeaderText>
                <xsl:if test="string-length(normalize-space(cXML/Request/InvoiceDetailRequest/InvoiceDetailRequestHeader/Comments)) > 0">
                    <DocumentHeaderText>
                        <xsl:attribute name="Type">
                            <xsl:value-of select="'Note'"/>
                        </xsl:attribute>
                        <xsl:if test="string-length(normalize-space(cXML/Request/InvoiceDetailRequest/InvoiceDetailRequestHeader/Comments/@xml:lang)) > 0 or string-length(normalize-space($v_lang)) > 0">
                            <TextElementLanguage>
                                <xsl:choose>
                                    <xsl:when test="string-length(normalize-space(cXML/Request/InvoiceDetailRequest/InvoiceDetailRequestHeader/Comments/@xml:lang)) > 0">
                                        <xsl:value-of select="substring(cXML/Request/InvoiceDetailRequest/InvoiceDetailRequestHeader/Comments/@xml:lang,1,9)"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="substring($v_lang,1,9)"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </TextElementLanguage>
                        </xsl:if>
                        <!-- IG-36832 When a segment has a child segment + Content, then directly mapping the segment name will not fetch the content. Need to use /text() -->
                        <TextElementText>
                            <xsl:value-of select="cXML/Request/InvoiceDetailRequest/InvoiceDetailRequestHeader/Comments/text()"/>
                        </TextElementText>
                        <!-- IG-36832 -->
                    </DocumentHeaderText>
                </xsl:if>
                <!-- CI-2395 Invoice Cancellation -->
                <xsl:if test="cXML/Request/InvoiceDetailRequest/InvoiceDetailRequestHeader/@operation = 'delete' ">
                <Extrinsic>
                    <Name>
                        <xsl:value-of select="'operation'"/>
                    </Name>
                    <Value>
                        <xsl:value-of
                            select="cXML/Request/InvoiceDetailRequest/InvoiceDetailRequestHeader/@operation"
                        />
                    </Value>
                </Extrinsic>
                </xsl:if>
                <!-- CI-2395 Invoice Cancellation -->
                <!-- CI-2383 -->
                <xsl:for-each
                    select="cXML/Request/InvoiceDetailRequest/InvoiceDetailOrder/InvoiceDetailItem">
                    <Item>
                        <SupplierInvoiceItemID>
                            <xsl:value-of select="substring(@invoiceLineNumber, 1, 10)"/>
                        </SupplierInvoiceItemID>
                        <SupplierInvoiceItemTypeCode>
                            <xsl:choose>
                                <xsl:when test="$v_inv_typ = 'standard'">
                                    <xsl:value-of select="'002'"/>
                                </xsl:when>
                                <xsl:when test="$v_inv_typ = 'lineLevelCreditMemo'">
                                    <xsl:value-of select="'003'"/>
                                </xsl:when>
                            </xsl:choose>
                        </SupplierInvoiceItemTypeCode>
                        <xsl:if test="(exists(SubtotalAmount/Money))">
                        <NetAmount>
                            <xsl:attribute name="currencyCode">
                                <xsl:value-of select="substring(SubtotalAmount/Money/@currency, 1, 5)"/>
                            </xsl:attribute>
<!--                            IG-36976-->
<!--                            <xsl:value-of select="format-number(number(SubtotalAmount/Money * $v_sign),'#.######')"/>-->
                            <xsl:variable name="v_amt" select="SubtotalAmount/Money"/>
                            <xsl:choose>
                                <xsl:when test="string-length(InvoiceDetailDiscount/Money)>0">
                                    <xsl:variable name="v_disc" select="InvoiceDetailDiscount/Money"/>
                                    <xsl:value-of select="format-number(number(($v_amt - $v_disc) * $v_sign),'0.######')"/>                                    
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="format-number(number($v_amt * $v_sign),'0.######')"/> 
                                </xsl:otherwise>
                            </xsl:choose>
<!--                            IG-36976-->
                        </NetAmount>
                        </xsl:if>
                        <InvoicedQuantity>
                            <xsl:attribute name="unitCode">
                                <xsl:value-of select="substring(UnitOfMeasure, 1, 3)"/>
                            </xsl:attribute>
                            <!-- IG-49468 : Fix to avoid exponential values in Invoiced Quantity -->
                                <xsl:value-of select="format-number(number(@quantity * $v_sign), '0.##############')"/>
                            <!-- IG-49468 -->
                        </InvoicedQuantity>
                        <!-- IG-16318 Duplicate PO number 27.02.2020 -->
                        <xsl:if test="string-length(normalize-space(../InvoiceDetailOrderInfo/OrderReference/@orderID)) > 0">
                        <PurchaseOrderID>
                            <xsl:value-of select="substring(../InvoiceDetailOrderInfo/OrderReference/@orderID, 1, 35)"/>
                        </PurchaseOrderID>
                        <!-- CI-1640 : Non-PO Invoice -->
                        <PurchaseOrderItemID>
                            <xsl:value-of
                                select="format-number(number(substring(InvoiceDetailItemReference/@lineNumber, 1, 10)), '000000')"/>
                        </PurchaseOrderItemID>
                        </xsl:if>
                        <!-- CI-1640 -->
                        <!-- CI-1491 reference to Delivery Note -->
                        <xsl:if test="string-length(normalize-space(../InvoiceDetailShipNoticeInfo/ShipNoticeReference/@shipNoticeID)) > 0">
                        <DeliveryNote>
                            <xsl:value-of select="substring(../InvoiceDetailShipNoticeInfo/ShipNoticeReference/@shipNoticeID, 1, 35)"/>
                        </DeliveryNote>
                        </xsl:if>
                        <!-- CI-1491 -->
                        <xsl:choose>
                            <xsl:when test="exists(Tax/TaxDetail)">
                                <xsl:for-each select="Tax/TaxDetail">
                                    <ItemTax>
                                        <SupplierTaxTypeCode>
                                            <xsl:call-template name="TaxType">
                                                <xsl:with-param name="p_category" select="@category"/>
                                            </xsl:call-template>
                                        </SupplierTaxTypeCode>
                                        <TaxPercentage>
                                            <xsl:value-of select="@percentageRate"/>
                                        </TaxPercentage>
                                        <TaxDeterminationDate>
                                            <xsl:value-of select="substring($v_erpdate, 1, 10)"/>
                                        </TaxDeterminationDate>
                                    </ItemTax>
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:for-each select="../../InvoiceDetailSummary/Tax/TaxDetail">
                                    <ItemTax>
                                        <SupplierTaxTypeCode>
                                            <xsl:call-template name="TaxType">
                                                <xsl:with-param name="p_category" select="@category"/>
                                            </xsl:call-template>
                                        </SupplierTaxTypeCode>
                                        <TaxPercentage>
                                            <xsl:value-of select="@percentageRate"/>
                                        </TaxPercentage>
                                        <TaxDeterminationDate>
                                            <xsl:value-of select="substring($v_erpdate, 1, 10)"/>
                                        </TaxDeterminationDate>
                                    </ItemTax>
                                </xsl:for-each>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="string-length(normalize-space(Comments)) > 0">
                            <DocumentItemText>
                                <!-- CI-2383 Text element -->
                                <xsl:attribute name="Type">
                                    <xsl:value-of select="'Note'"/>
                                </xsl:attribute>
                                <!-- CI-2383 -->
                                <xsl:if test="string-length(normalize-space(Comments/@xml:lang)) > 0 or string-length(normalize-space($v_lang)) > 0">
                                <TextElementLanguage>
                                    <xsl:choose>
                                        <xsl:when
                                            test="string-length(normalize-space(Comments/@xml:lang)) > 0">
                                            <xsl:value-of select="substring(Comments/@xml:lang, 1, 9)"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="substring($v_lang, 1, 9)"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </TextElementLanguage>
                                </xsl:if>
                                <TextElementText>
                                    <xsl:value-of select="Comments"/>
                                </TextElementText>
                            </DocumentItemText>
                        </xsl:if>
                        <HigherLevelItem>
                            <xsl:value-of select="'000000'"/>
                        </HigherLevelItem>
                    </Item>
                </xsl:for-each>
                <xsl:for-each
                    select="cXML/Request/InvoiceDetailRequest/InvoiceDetailOrder/InvoiceDetailServiceItem">
                    <Item>
                        <SupplierInvoiceItemID>
                            <xsl:value-of select="substring(@invoiceLineNumber, 1, 10)"/>
                        </SupplierInvoiceItemID>
                        <SupplierInvoiceItemTypeCode>
                            <xsl:choose>
                                <xsl:when test="$v_inv_typ = 'standard'">
                                    <xsl:value-of select="'002'"/>
                                </xsl:when>
                                <xsl:when test="$v_inv_typ = 'lineLevelCreditMemo'">
                                    <xsl:value-of select="'003'"/>
                                </xsl:when>
                            </xsl:choose>
                        </SupplierInvoiceItemTypeCode>
                        <NetAmount>
                            <xsl:attribute name="currencyCode">
                                <xsl:value-of select="substring(SubtotalAmount/Money/@currency, 1, 5)"/>
                            </xsl:attribute>
<!--                            IG-36976-->
<!--                            <xsl:value-of select="format-number(number(SubtotalAmount/Money * $v_sign),'#.######')"/>-->
                            <xsl:variable name="v_amt" select="SubtotalAmount/Money"/>
                            <xsl:choose>
                                <xsl:when test="string-length(InvoiceDetailDiscount/Money)>0">
                                    <xsl:variable name="v_disc" select="InvoiceDetailDiscount/Money"/>
                                    <xsl:value-of select="format-number(number(($v_amt - $v_disc) * $v_sign),'0.######')"/>                                    
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="format-number(number($v_amt * $v_sign),'0.######')"/> 
                                </xsl:otherwise>
                            </xsl:choose>
<!--                            IG-36976-->
                        </NetAmount>
                        <InvoicedQuantity>
                            <xsl:attribute name="unitCode">
                                <xsl:value-of select="substring(UnitOfMeasure, 1, 3)"/>
                            </xsl:attribute>
                            <!-- IG-49468 : Fix to avoid exponential values in Invoiced Quantity -->
                                <xsl:value-of select="format-number(number(@quantity * $v_sign), '0.##############')"/>
                            <!-- IG-49468 -->
                        </InvoicedQuantity>
                        <!-- IG-16318 Duplicate PO number 27.02.2020 -->
                        <xsl:if test="string-length(normalize-space(../InvoiceDetailOrderInfo/OrderReference/@orderID)) > 0">
                        <PurchaseOrderID>
                            <xsl:value-of select="substring(../InvoiceDetailOrderInfo/OrderReference/@orderID, 1 ,35)"/>
                        </PurchaseOrderID>
                        <!-- CI-1640 : Non-PO Invoice -->
                        <xsl:if test="string-length(normalize-space(InvoiceDetailServiceItemReference/@lineNumber)) > 0">
                        <PurchaseOrderItemID>
                            <xsl:value-of
                                select="format-number(number(substring(InvoiceDetailServiceItemReference/@lineNumber, 1, 10)), '000000')"/>
                        </PurchaseOrderItemID>
                        </xsl:if>
                        </xsl:if>
                        <!-- CI-1640 -->
                        <!-- New field introduced in 2002 S4H release -->
                        <xsl:if test="string-length(normalize-space(ServiceEntryItemReference/@serviceEntryID)) > 0">
                        <ServiceEntrySheetIDBySupplier>
                            <xsl:value-of select="substring(ServiceEntryItemReference/@serviceEntryID, 1, 35)"/>
                        </ServiceEntrySheetIDBySupplier>
                        </xsl:if>
                        <xsl:choose>
                            <xsl:when test="exists(Tax/TaxDetail)">
                                <xsl:for-each select="Tax/TaxDetail">
                                    <ItemTax>
                                        <SupplierTaxTypeCode>
                                            <xsl:call-template name="TaxType">
                                                <xsl:with-param name="p_category" select="@category"/>
                                            </xsl:call-template>
                                        </SupplierTaxTypeCode>
                                        <TaxPercentage>
                                            <xsl:value-of select="@percentageRate"/>
                                        </TaxPercentage>
                                        <TaxDeterminationDate>
                                            <xsl:value-of select="substring($v_erpdate, 1, 10)"/>
                                        </TaxDeterminationDate>
                                    </ItemTax>
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:for-each select="../../InvoiceDetailSummary/Tax/TaxDetail">
                                    <ItemTax>
                                        <SupplierTaxTypeCode>
                                            <xsl:call-template name="TaxType">
                                                <xsl:with-param name="p_category" select="@category"/>
                                            </xsl:call-template>
                                        </SupplierTaxTypeCode>
                                        <TaxPercentage>
                                            <xsl:value-of select="@percentageRate"/>
                                        </TaxPercentage>
                                        <TaxDeterminationDate>
                                            <xsl:value-of select="substring($v_erpdate, 1, 10)"/>
                                        </TaxDeterminationDate>
                                    </ItemTax>
                                </xsl:for-each>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="string-length(normalize-space(Comments)) > 0">
                            <DocumentItemText>
                                <!-- CI-2383 Text element -->
                                <xsl:attribute name="Type">
                                    <xsl:value-of select="'Note'"/>
                                </xsl:attribute>
                                <!-- CI-2383 -->
                                <xsl:if test="string-length(normalize-space(Comments/@xml:lang)) > 0 or string-length(normalize-space($v_lang)) > 0">
                                <TextElementLanguage>
                                    <xsl:choose>
                                        <xsl:when test="string-length(normalize-space(Comments/@xml:lang)) > 0">
                                            <xsl:value-of select="substring(Comments/@xml:lang, 1, 9)"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="substring($v_lang, 1, 9)"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </TextElementLanguage>
                                </xsl:if>
                                <TextElementText>
                                    <xsl:value-of select="Comments"/>
                                </TextElementText>
                            </DocumentItemText>
                        </xsl:if>
                        <HigherLevelItem>
                            <xsl:value-of select="'000000'"/>
                        </HigherLevelItem>
                    </Item>
                </xsl:for-each>
                <!-- Attachments Processing for 2005 release. Only Header Level Attachments -->
                <xsl:if test="string-length($cXMLAttachments) > 0">
                    <xsl:variable name="v_HeaderAttachmentList" select="$cXMLAttachments"/>
                    <xsl:variable name="v_HeaderAttachmentList">
                        <xsl:call-template name="InboundS4Attachment">
                            <xsl:with-param name="AttachmentList">
                                <xsl:value-of select="$v_HeaderAttachmentList"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:copy-of select="$v_HeaderAttachmentList"/>
                </xsl:if>
                <!-- IG-45461: Mexico Localization - Start-->
                <xsl:if test="exists(//cXML/Request/InvoiceDetailRequest/InvoiceDetailRequestHeader/Extrinsic[@name = 'taxInvoiceNumber'])">
                    <CountrySpecificFields>
                        <ElectronicInvoiceUUID>
                            <xsl:value-of select="//cXML/Request/InvoiceDetailRequest/InvoiceDetailRequestHeader/Extrinsic[@name = 'taxInvoiceNumber']"/>
                        </ElectronicInvoiceUUID>
                    </CountrySpecificFields>
                </xsl:if>
                <!-- IG-45461: Mexico Localization - End-->
            </Invoice>
        </n0:InvoiceRequest>
    </xsl:template>
    <xsl:template match="//Combined/AttachmentList"></xsl:template>
</xsl:stylesheet>
