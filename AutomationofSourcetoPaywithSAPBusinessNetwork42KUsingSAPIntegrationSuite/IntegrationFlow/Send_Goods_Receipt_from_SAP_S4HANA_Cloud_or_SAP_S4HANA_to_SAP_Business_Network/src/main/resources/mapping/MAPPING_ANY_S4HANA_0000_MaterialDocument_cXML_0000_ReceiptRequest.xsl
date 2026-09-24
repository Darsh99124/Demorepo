<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:n0="http://sap.com/xi/APPL/Global2"
    exclude-result-prefixes="#all" version="2.0">
    <xsl:output method="xml" indent="no" omit-xml-declaration="yes"/>   
    <xsl:param name="anProviderANID"/>
    <xsl:param name="anPayloadID"/>
    <xsl:param name="anSenderID"/>
    <xsl:param name="anERPSystemID"/>
    <xsl:param name="anIsMultiERP"/>
    <xsl:param name="anEnvName"/>
    <xsl:param name="anERPTimeZone"/>
    <xsl:include href="FORMAT_S4HANA_0000_cXML_0000.xsl" use-when="doc-available('FORMAT_S4HANA_0000_cXML_0000.xsl')"/> <!-- Added changes in pd entries file for BPI-147 feature applied use-when logic-->
<!--            <xsl:include href="FORMAT_S4HANA_0000_cXML_0000.xsl"/>-->
    <!--BPI-147 end -->
    <xsl:template match="n0:MaterialDocumentCreateNotification_Async">
        <cXML>
            <xsl:attribute name="timestamp">
                <xsl:variable name="v_curDate">
                    <xsl:value-of select="current-dateTime()"/>
                </xsl:variable>
                <xsl:value-of
                    select="concat(substring($v_curDate, 1, 19), substring($v_curDate, 24, 29))"/>
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
                            <xsl:value-of
                                select="replace(MaterialDocument/MaterialDocumentItem[1]/Supplier, '^0+', '')"
                            />
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
                <ReceiptRequest>
                    <ReceiptRequestHeader>
                        <xsl:attribute name="operation">
                            <xsl:value-of select="'new'"/>
                        </xsl:attribute>
                        <xsl:attribute name="receiptDate">
                            <xsl:if
                                test="(string-length(/n0:MaterialDocumentCreateNotification_Async/MaterialDocument/DocumentDate) > 0)">
                                <xsl:call-template name="ANDateTime_S4HANA">
                                    <xsl:with-param name="p_date"
                                        select="/n0:MaterialDocumentCreateNotification_Async/MaterialDocument/DocumentDate"/>
                                    <xsl:with-param name="p_time" select="''"/>
                                    <xsl:with-param name="p_timezone" select="$anERPTimeZone"/>
                                </xsl:call-template>
                            </xsl:if>
                        </xsl:attribute>
                        <xsl:attribute name="receiptID">
                            <xsl:value-of select="MaterialDocument/MaterialDocument"/>
                        </xsl:attribute>
                        <xsl:if
                            test="string-length(normalize-space(/n0:MaterialDocumentCreateNotification_Async/MaterialDocument/ReferenceDocument)) > 0">
                            <ShipNoticeIDInfo>
                                <xsl:attribute name="shipNoticeID">
                                    <xsl:value-of select="MaterialDocument/ReferenceDocument"/>
                                </xsl:attribute>
                                <xsl:attribute name="shipNoticeDate">
                                    <xsl:if
                                        test="(string-length(/n0:MaterialDocumentCreateNotification_Async/MaterialDocument/DocumentDate) > 0)">
                                        <xsl:call-template name="ANDateTime_S4HANA">
                                            <xsl:with-param name="p_date"
                                                select="/n0:MaterialDocumentCreateNotification_Async/MaterialDocument/DocumentDate"/>
                                            <xsl:with-param name="p_time" select="''"/>
                                            <xsl:with-param name="p_timezone"
                                                select="$anERPTimeZone"/>
                                        </xsl:call-template>
                                    </xsl:if>
                                </xsl:attribute>
                            </ShipNoticeIDInfo>
                        </xsl:if>
                    </ReceiptRequestHeader>
                    <xsl:for-each-group select="MaterialDocument/MaterialDocumentItem"
                        group-by="PurchaseOrder">
                        <ReceiptOrder>
                            <ReceiptOrderInfo>
                                <OrderIDInfo>
                                    <xsl:attribute name="orderID">
                                        <xsl:value-of select="PurchaseOrder"/>
                                    </xsl:attribute>
                                </OrderIDInfo>
                            </ReceiptOrderInfo>
                            <xsl:for-each select="current-group()">
                                <!--IG-32460 GR Subcon Line Item need to supressed-->
                                <xsl:if test="not(GoodsMovementType = '543')">
                                <!-- IG-32460 -->
                                <ReceiptItem>
                                    <xsl:choose>
                                        <!--DEBIT-->
                                        <xsl:when test="DebitCreditCode = 'S'">
                                            <xsl:choose>
                                                <xsl:when test="(IsReversalMovementType = 'true') or
                                                    (IsReversalMovementType = 'false' and (GoodsMovementType = '122' or GoodsMovementType = '161'))">    <!--CI-1634 IG-51656 Return PO -->
                                                  <xsl:attribute name="quantity">
                                                  <xsl:value-of select="QuantityInEntryUnit * -1"/>
                                                  </xsl:attribute>
                                                  <xsl:attribute name="type">
                                                  <xsl:value-of select="'returned'"/>
                                                  </xsl:attribute>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                  <xsl:attribute name="quantity">
                                                  <xsl:value-of select="QuantityInEntryUnit"/>
                                                  </xsl:attribute>
                                                  <xsl:attribute name="type">
                                                  <xsl:value-of select="'received'"/>
                                                  </xsl:attribute>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:when>
                                        <!--CREDIT-->
                                        <xsl:when test="DebitCreditCode = 'H'">
                                            <xsl:choose>
                                                <xsl:when test="IsReversalMovementType = 'true'">
                                                  <xsl:attribute name="quantity">
                                                  <xsl:value-of select="QuantityInEntryUnit * -1"/>
                                                  </xsl:attribute>
                                                  <xsl:attribute name="type">
                                                  <xsl:value-of select="'received'"/>
                                                  </xsl:attribute>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                  <xsl:attribute name="quantity">
                                                  <xsl:value-of select="QuantityInEntryUnit"/>
                                                  </xsl:attribute>
                                                  <xsl:attribute name="type">
                                                  <xsl:value-of select="'returned'"/>
                                                  </xsl:attribute>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:when>
                                    </xsl:choose>
                                    <xsl:attribute name="receiptLineNumber">
                                        <xsl:value-of select="MaterialDocumentItem"/>
                                    </xsl:attribute>
                                    <xsl:if test="IsCompletelyDelivered = 'true'">
                                            <xsl:attribute name="completedIndicator">
                                                <xsl:value-of select="'yes'"/>
                                            </xsl:attribute>
                                        </xsl:if>
                                    <ReceiptItemReference>
                                        <xsl:attribute name="lineNumber">
                                            <xsl:value-of select="PurchaseOrderItem"/>
                                        </xsl:attribute>
                                        <ItemID>
                                            <SupplierPartID> </SupplierPartID>
                                            <xsl:if
                                                test="string-length(normalize-space(Material)) > 0">
                                                <BuyerPartID>
                                                  <xsl:value-of select="Material"/>
                                                </BuyerPartID>
                                            </xsl:if>
                                        </ItemID>
                                        <xsl:if
                                            test="string-length(normalize-space(/n0:MaterialDocumentCreateNotification_Async/MaterialDocument/ReferenceDocument)) > 0">
                                            <ShipNoticeIDInfo>
                                                <xsl:attribute name="shipNoticeID">
                                                  <xsl:value-of
                                                  select="/n0:MaterialDocumentCreateNotification_Async/MaterialDocument/ReferenceDocument"
                                                  />
                                                </xsl:attribute>
                                                <xsl:attribute name="shipNoticeDate">
                                                  <xsl:if
                                                  test="(string-length(/n0:MaterialDocumentCreateNotification_Async/MaterialDocument/DocumentDate) > 0)">
                                                  <xsl:call-template name="ANDateTime_S4HANA">
                                                  <xsl:with-param name="p_date"
                                                  select="/n0:MaterialDocumentCreateNotification_Async/MaterialDocument/DocumentDate"/>
                                                  <xsl:with-param name="p_time" select="''"/>
                                                  <xsl:with-param name="p_timezone"
                                                  select="$anERPTimeZone"/>
                                                  </xsl:call-template>
                                                  </xsl:if>
                                                </xsl:attribute>
                                                <xsl:if
                                                  test="string-length(normalize-space(Delivery)) > 0">
                                                  <IdReference>
                                                  <xsl:attribute name="identifier">
                                                  <xsl:value-of select="Delivery"/>
                                                  </xsl:attribute>
                                                  <xsl:attribute name="domain">
                                                      <xsl:value-of select="'deliveryNoteId'"/>
                                                  </xsl:attribute>
                                                  </IdReference>
                                                </xsl:if>
                                            </ShipNoticeIDInfo>
                                        </xsl:if>
                                    </ReceiptItemReference>
                                    <UnitRate>
                                        <Money>
                                            <xsl:attribute name="currency"/>
                                        </Money>
                                        <UnitOfMeasure>
                                            <xsl:value-of select="QuantityInEntryUnit/@n0:unitCode"/>
                                        </UnitOfMeasure>
                                    </UnitRate>
                                    <ReceivedAmount>
                                        <Money>
                                            <xsl:attribute name="currency"/>
                                        </Money>
                                    </ReceivedAmount>
                                </ReceiptItem>
                                </xsl:if>
                            </xsl:for-each>
                        </ReceiptOrder>
                    </xsl:for-each-group>
                    <Total>
                        <Money>
                            <xsl:attribute name="currency"/>
                        </Money>
                    </Total>
                </ReceiptRequest>
            </Request>
        </cXML>
    </xsl:template>
</xsl:stylesheet>
