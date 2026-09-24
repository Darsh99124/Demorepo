<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xop="http://www.w3.org/2004/08/xop/include"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:n0="http://sap.com/xi/EDI"
    exclude-result-prefixes="#all" version="2.0">
    <xsl:output method="xml" indent="no" omit-xml-declaration="yes"/>
    <!-- Indent No is made on purpose, else attachments will fail in S4 Cloud -->
    <xsl:param name="cXMLAttachments"/>
    <xsl:param name="anERPSystemID"/>
<!--BPI-147 Start     -->    
    <xsl:include href="FORMAT_S4HANA_0000_cXML_0000.xsl" use-when="doc-available('FORMAT_S4HANA_0000_cXML_0000.xsl')"/>
<!--BPI-147 End     -->
<!--<xsl:include href="FORMAT_S4HANA_0000_cXML_0000.xsl"/>-->
    <xsl:variable name="v_sysid">
        <xsl:call-template name="MultiErpSysIdIN">
            <xsl:with-param name="p_ansysid"
                select="Combined/Payload/cXML/Header/To/Credential[@domain = 'SystemID']/Identity"/>
            <xsl:with-param name="p_erpsysid" select="$anERPSystemID"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:template match="Combined">
        <n0:OrderConfRequest>
            <MessageHeader>
                <ID>
                    <xsl:value-of select="substring(substring-before(Payload/cXML/@payloadID, '@'), 1,35)"/>
                </ID>
                <ReferenceID>
                    <xsl:value-of select="substring(Payload/cXML/Request/ConfirmationRequest/ConfirmationHeader/@confirmID, 1,35)"/>
                </ReferenceID>
                <CreationDateTime>
                    <xsl:value-of select="Payload/cXML/Request/ConfirmationRequest/ConfirmationHeader/@noticeDate"/>
                </CreationDateTime>
                <SenderBusinessSystemID>
                    <xsl:value-of select="'ARIBA_NETWORK'"/>
                </SenderBusinessSystemID>
                <SenderParty>
                    <InternalID>
                        <xsl:value-of select="substring(Payload/cXML/Header/From/Credential[@domain = 'VendorID']/Identity, 1,32)"/>
                    </InternalID>
                </SenderParty>
                <RecipientBusinessSystemID>
                    <xsl:value-of select="$v_sysid"/>
                </RecipientBusinessSystemID>
<!--                *To determine LP for Status Updates, this is mapped.-->
                <RecipientParty>
                    <InternalID>
                        <xsl:value-of select="(Payload/cXML/Header/To/Credential[@domain = 'NetworkID']/Identity)"/>
                    </InternalID>
                </RecipientParty>
                
<!--                cXML Payload for Status Updates.-->
                <BusinessScope>
                    <TypeCode></TypeCode>
                    <InstanceID>
                        <xsl:attribute name="schemeID">
                            <xsl:value-of select="normalize-space(Payload/cXML/@payloadID)"/>
                        </xsl:attribute>
                    </InstanceID>
                </BusinessScope>
            </MessageHeader>
            <OrderConfirmation>
                <PurchaseOrderID>
                    <xsl:value-of select="substring(Payload/cXML/Request/ConfirmationRequest/OrderReference/@orderID, 1,35)"/>
                </PurchaseOrderID>
                <SalesOrderID>
                    <xsl:value-of select="substring(Payload/cXML/Request/ConfirmationRequest/ConfirmationHeader/@confirmID, 1,35)"/>
                </SalesOrderID>
                <!-- in case of hierarchy, map from "real" item, not structual item -->
                <xsl:if test="string-length(normalize-space(Payload/cXML/Request/ConfirmationRequest/ConfirmationItem[@itemType != 'composite'][1]/ConfirmationStatus[1]/ItemIn[1]/ItemDetail[1]/UnitPrice/Money/@currency)) > 0 or
                    string-length(normalize-space(Payload/cXML/Request/ConfirmationRequest/ConfirmationItem[1]/ConfirmationStatus[1]/ItemIn[1]/ItemDetail[1]/UnitPrice/Money/@currency)) > 0">
                    <TransactionCurrency>
                        <xsl:choose>
                            <xsl:when test="string-length(normalize-space(Payload/cXML/Request/ConfirmationRequest/ConfirmationItem[@itemType != 'composite'][1]/ConfirmationStatus[1]/ItemIn[1]/ItemDetail[1]/UnitPrice/Money/@currency)) > 0">
                                <xsl:value-of select="substring(Payload/cXML/Request/ConfirmationRequest/ConfirmationItem[@itemType != 'composite'][1]/ConfirmationStatus[1]/ItemIn[1]/ItemDetail[1]/UnitPrice/Money/@currency, 1, 5)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="substring(Payload/cXML/Request/ConfirmationRequest/ConfirmationItem[1]/ConfirmationStatus[1]/ItemIn[1]/ItemDetail[1]/UnitPrice/Money/@currency, 1, 5)"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </TransactionCurrency>
                </xsl:if>
                <ItemListIsCompletelyTransferred>
                    <xsl:choose>
                        <xsl:when test="Payload/cXML/Request/ConfirmationRequest/ConfirmationHeader/@type='accept' or Payload/cXML/Request/ConfirmationRequest/ConfirmationHeader/@type='allDetail'">
                            <xsl:value-of select="'true'"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="'false'"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </ItemListIsCompletelyTransferred>
                <Party>
                    <xsl:attribute name="PartyType">
                        <xsl:value-of select="'SoldTo'"/>
                    </xsl:attribute>
                    <SupplierPartyID>
                        <xsl:value-of
                            select="substring(Payload/cXML/Header/From/Credential[@domain = 'VendorID']/Identity, 1,60)"/>
                    </SupplierPartyID>
                </Party>
                <!-- CI-2526 Header Texts mapping-->
                    <xsl:for-each
                        select="Payload/cXML/Request/ConfirmationRequest/ConfirmationHeader/Comments">
                        <!-- if comment exists then only populate ESR Text table -->
                        <xsl:if test="string-length(normalize-space(.)) > 0">
                            <Text>
                                <xsl:attribute name="Type">
                                    <xsl:value-of select="'SupplierComments'"/>
                                </xsl:attribute>
                                <TextElementLanguage>
                                    <xsl:value-of select="@xml:lang"/>
                                </TextElementLanguage>
                                <TextElementText>
                                    <xsl:value-of select="text()"/>
                                </TextElementText>
                            </Text>
                        </xsl:if>
                    </xsl:for-each>
                <!-- CI-2526 -->                
                <xsl:for-each select="Payload/cXML/Request/ConfirmationRequest/ConfirmationItem">
                    <Item>
                        <PurchaseOrderItemID>
                            <xsl:value-of select="substring(@lineNumber, 1,10)"/>
                        </PurchaseOrderItemID>
                        <xsl:if test="string-length(normalize-space(ConfirmationStatus[1]/ItemIn/ItemDetail/Description[1])) > 0">
                            <OrderItemText>
                                <xsl:value-of select="substring(ConfirmationStatus[1]/ItemIn/ItemDetail/Description[1], 1, 80)"/>
                            </OrderItemText>
                        </xsl:if>
                        <xsl:if test="string-length(normalize-space(@quantity)) > 0">
                            <RequestedQuantity>
                                <xsl:if test="string-length(normalize-space(UnitOfMeasure)) > 0">
                                    <xsl:attribute name="unitCode">
                                        <xsl:value-of select="substring(UnitOfMeasure, 1, 3)"/>
                                    </xsl:attribute>
                                </xsl:if>
                                <xsl:value-of select="@quantity"/>
                            </RequestedQuantity>
                        </xsl:if>
                        <!-- set RejectionReasonText with "RE" only for a "full" item rejection (ordered qty equal confirmed qty), not for "partial" rejection -->
                        <xsl:if test="ConfirmationStatus[@type = 'reject'] and @quantity = ConfirmationStatus/@quantity">
                            <RejectionReasonText>
                                <xsl:value-of select="'RE'"/>
                            </RejectionReasonText>
                        </xsl:if>
                        <xsl:if test="string-length(normalize-space(ConfirmationStatus[1]/ItemIn/ItemDetail/UnitPrice/Money)) > 0">
                        <NetPrice>
                            <Amount>
                                <xsl:attribute name="currencyCode">
                                    <xsl:value-of select="substring(ConfirmationStatus[1]/ItemIn/ItemDetail/UnitPrice/Money/@currency, 1, 5)"/>
                                </xsl:attribute>
                                <xsl:value-of
                                    select="format-number(number(ConfirmationStatus[1]/ItemIn/ItemDetail/UnitPrice/Money),'#.######')"/>
                            </Amount>
                            <!--IG-38196 BaseQuantity were not populated for limit items, this change from 2205/Refactoring is reverted back for the case there is a limit item-->                           
                            <BaseQuantity>                      
                                <xsl:choose>          
                                        <xsl:when test="ConfirmationStatus[1]/ItemIn/ItemDetail/PriceBasisQuantity/@quantity > 0">
                                   <xsl:attribute name="unitCode">
                                       <xsl:value-of select="substring(ConfirmationStatus[1]/ItemIn/ItemDetail/PriceBasisQuantity/UnitOfMeasure, 1, 3)"/>
                                   </xsl:attribute>
                                   <xsl:value-of select="ConfirmationStatus[1]/ItemIn/ItemDetail/PriceBasisQuantity/@quantity"/>
                                        </xsl:when>
                                    <xsl:otherwise>
                                   <!-- if it is a limit item    <-->
                                <xsl:attribute name="unitCode">
                                    <xsl:value-of select="substring(ConfirmationStatus[1]/ItemIn/ItemDetail/UnitOfMeasure, 1, 3)"/>
                                </xsl:attribute>
                                <xsl:value-of select="ConfirmationStatus[1]/ItemIn/@quantity"/>
                                   </xsl:otherwise>                                 
                                </xsl:choose>
                            </BaseQuantity>
                        </NetPrice>
                        </xsl:if>
                        <xsl:for-each select="ConfirmationStatus">
                            <!-- "partial" unknown and rejection qty per same item not supported in S/4 HANA -->
                            <xsl:if test="@type != 'unknown' and @type != 'reject'">
                                <ScheduleLine>
                                    <xsl:if test="string-length(normalize-space(@deliveryDate)) > 0">
                                        <ConfirmedDeliveryDate>
                                            <xsl:value-of select="substring-before(@deliveryDate, 'T')"/>
                                        </ConfirmedDeliveryDate>
                                    </xsl:if>
                                    <!-- CI-2112 Time Zone Mapping -->
                                    <xsl:if test="string-length(normalize-space(@deliveryDate)) > 0">
                                        <ConfirmedDeliveryDateTime>
                                            <xsl:value-of select="normalize-space(@deliveryDate)"/>
                                        </ConfirmedDeliveryDateTime>
                                    </xsl:if>
                                    <!-- CI-2112 -->
                                    <xsl:if test="string-length(normalize-space(@quantity)) > 0">
                                        <ConfirmedOrderQuantityByMaterialAvailableCheck>
                                            <xsl:if test="string-length(normalize-space(UnitOfMeasure)) > 0">
                                                <xsl:attribute name="unitCode">
                                                    <xsl:value-of select="substring(UnitOfMeasure, 1, 3)"/>
                                                </xsl:attribute>
                                            </xsl:if>
                                            <xsl:value-of select="@quantity"/>
                                    </ConfirmedOrderQuantityByMaterialAvailableCheck>
                                    </xsl:if>
                                    <xsl:if test="string-length(normalize-space(ItemIn/Period/@startDate)) > 0 or 
                                        string-length(normalize-space(ItemIn/Period/@endDate)) > 0">
                                        <Service>
                                            <xsl:if test="string-length(normalize-space(ItemIn/Period/@startDate)) > 0">
                                                <PerformancePeriodStartDate>
                                                    <xsl:value-of select="substring(ItemIn/Period/@startDate, 1, 10)"/>
                                                </PerformancePeriodStartDate>
                                                <!-- CI-2112 Time Zone Mapping -->
                                                <ServicePerfPeriodStartDateTime>
                                                  <xsl:value-of select="normalize-space(ItemIn/Period/@startDate)"/>
                                                </ServicePerfPeriodStartDateTime>
                                                <!-- CI-2112 -->
                                            </xsl:if>
                                            <xsl:if test="string-length(normalize-space(ItemIn/Period/@endDate)) > 0">
                                                <PerformancePeriodEndDate>
                                                    <xsl:value-of select="substring(ItemIn/Period/@endDate, 1, 10)"/>
                                                </PerformancePeriodEndDate>
                                                <!-- CI-2112 Time Zone Mapping -->
                                                <SrvcPerformancePeriodEndDteTme>
                                                  <xsl:value-of select="normalize-space(ItemIn/Period/@endDate)"/>
                                                </SrvcPerformancePeriodEndDteTme>
                                                <!-- CI-2112 -->
                                            </xsl:if>
                                        </Service>
                                    </xsl:if>
                                    <!-- CI-1672 Enhanced Limits for Services and Materials -->
                                    <xsl:if test="string-length(normalize-space(ItemIn/ItemDetail/ExpectedLimit/Money)) > 0">
                                        <ConfirmedExpectedOverallLmtAmt>
                                            <xsl:attribute name="currencyCode">
                                                <xsl:value-of select="substring(ItemIn/ItemDetail/ExpectedLimit/Money/@currency, 1, 5) "/>
                                            </xsl:attribute>
                                            <xsl:value-of select="ItemIn/ItemDetail/ExpectedLimit/Money"/>
                                        </ConfirmedExpectedOverallLmtAmt>
                                    </xsl:if>
                                    <!-- CI-1672 -->
                                </ScheduleLine>
                            </xsl:if>
                        </xsl:for-each>
                            <!-- CI-2526 Item Texts mapping-->
                        <xsl:for-each select="ConfirmationStatus">                            
                            <xsl:if test="string-length(normalize-space(Comments/text())) > 0">
                                <Text>
                                    <xsl:attribute name="Type">
                                        <xsl:value-of select="'SupplierComments'"/>
                                    </xsl:attribute>
                                    <TextElementLanguage>
                                        <xsl:value-of select="Comments/@xml:lang"/>
                                    </TextElementLanguage>
                                    <TextElementText>
                                        <xsl:value-of select="Comments/text()"/>
                                    </TextElementText>
                                </Text>
                            </xsl:if>
                        </xsl:for-each>
                            <!-- CI-2526 -->                            
                    </Item>
                </xsl:for-each>
                <!-- Attachments Processing for 2005 release. Only Header Level Attachments -->
                <xsl:if test="string-length(normalize-space($cXMLAttachments)) > 0">
                    <xsl:variable name = "v_headerAttachmentList" select="normalize-space($cXMLAttachments)"/>
                    <xsl:call-template name="InboundS4Attachment">
                        <xsl:with-param name="AttachmentList">
                            <xsl:value-of select="$v_headerAttachmentList"/>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:if>
            </OrderConfirmation>
        </n0:OrderConfRequest>
    </xsl:template>
</xsl:stylesheet>
