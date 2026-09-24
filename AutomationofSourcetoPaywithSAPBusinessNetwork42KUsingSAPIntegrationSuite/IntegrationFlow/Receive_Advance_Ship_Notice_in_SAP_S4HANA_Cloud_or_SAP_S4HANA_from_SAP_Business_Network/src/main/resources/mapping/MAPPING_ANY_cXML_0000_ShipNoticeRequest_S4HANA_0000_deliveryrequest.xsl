<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:n0="http://sap.com/xi/EDI"
    exclude-result-prefixes="#all" version="2.0">
    <xsl:output method="xml" indent="no" omit-xml-declaration="yes"/>
<!--BPI-147 Start    -->    
    <xsl:include href="FORMAT_S4HANA_0000_cXML_0000.xsl" use-when="doc-available('FORMAT_S4HANA_0000_cXML_0000.xsl')"/>
<!--BPI-147 End    -->
<!--    <xsl:include href="FORMAT_S4HANA_0000_cXML_0000.xsl"/>-->
    <xsl:param name="anERPSystemID"/>
    <xsl:param name="anERPTimeZone"/>
    <xsl:param name="cXMLAttachments"/>
    <xsl:template match="Combined">
        <!--   <Get the System Id -->
        <xsl:variable name="v_sysid">
            <xsl:call-template name="MultiErpSysIdIN">
                <xsl:with-param name="p_ansysid"
                    select="Payload/cXML/Header/To/Credential[@domain = 'SystemID']/Identity"/>
                <xsl:with-param name="p_erpsysid" select="$anERPSystemID"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="v_currDT">
            <xsl:value-of select="current-dateTime()"/>
        </xsl:variable>
        <xsl:variable name="v_cigDT">
            <xsl:value-of
                select="concat(substring-before($v_currDT, 'T'), 'T', substring(substring-after($v_currDT, 'T'), 1, 8))" />
        </xsl:variable>
        <xsl:variable name="v_cigTS">
            <xsl:call-template name="ERPDateTime">
                <xsl:with-param name="p_date" select="$v_cigDT"/>
                <xsl:with-param name="p_timezone" select="$anERPTimeZone"/>
            </xsl:call-template>
        </xsl:variable>
        <n0:DeliveryRequest>
            <MessageHeader>
                <ID>
                    <xsl:value-of select="substring(Payload/cXML/@payloadID, 1, 35)"/>
                </ID>
                <CreationDateTime>
                    <xsl:value-of select="$v_cigTS"/>
                </CreationDateTime>
                <SenderBusinessSystemID>
                    <xsl:value-of select="'ARIBA_NETWORK'"/>
                </SenderBusinessSystemID>
                <RecipientBusinessSystemID>
                    <xsl:value-of select="$v_sysid"/>
                </RecipientBusinessSystemID>
                <RecipientParty>
                    <InternalID>
                        <xsl:value-of select="(Payload/cXML/Header/To/Credential[@domain = 'NetworkID']/Identity)"/>
                    </InternalID>
                </RecipientParty>
                <SenderParty>
                    <InternalID><xsl:value-of select="Payload/cXML/Header/From/Credential[@domain='VendorID']/Identity"/></InternalID>
                </SenderParty>
                <!--cXML Payload for Status Updates.-->
                <BusinessScope>
                    <TypeCode></TypeCode>
                    <InstanceID>
                        <xsl:attribute name="schemeID">
                            <xsl:value-of select="normalize-space(Payload/cXML/@payloadID)"/>
                        </xsl:attribute>
                    </InstanceID>
                </BusinessScope>
            </MessageHeader>
            <Delivery>
                <DeliveryDocumentBySupplier>
                    <xsl:value-of select="substring(Payload/cXML/Request/ShipNoticeRequest/ShipNoticeHeader/@shipmentID, 1, 35)"/>
                </DeliveryDocumentBySupplier>
                <xsl:for-each
                    select="/Combined/Payload/cXML/Request/ShipNoticeRequest/ShipNoticeHeader/Contact">
                    <Party>
                        <xsl:attribute name="PartyType">
                            <xsl:choose>
                                <xsl:when test="@role = 'shipTo'">
                                    <xsl:value-of select="'WE'"/>
                                </xsl:when>
                                <xsl:when test="@role = 'soldTo'">
                                    <xsl:value-of select="'AG'"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="'CP'"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                        <!-- Start of IG-45470 : Correction in reading multiple street from postal address--> 
                        <xsl:variable name="v_street">
                            <xsl:for-each select="PostalAddress/Street">
                                <xsl:value-of select="concat(., ' ')"/>
                            </xsl:for-each>
                        </xsl:variable>
                        <!-- End of IG-45470 : Correction in reading multiple street from postal address-->                         
                        <xsl:if test="string-length(normalize-space(Name)) > 0 or string-length(normalize-space(PostalAddress/Street)) > 0">
                            <Address>
                                <!-- source is a must element --> 
                                    <AddressName>
                                        <xsl:value-of select="substring(Name, 1, 40)"/>
                                    </AddressName>
                                <xsl:if test="string-length(normalize-space($v_street)) > 0">
                                    <StreetName>
                                        <xsl:value-of select="substring($v_street, 1, 60)"/>
                                    </StreetName>
                                </xsl:if>
                                <xsl:if test="string-length(normalize-space(PostalAddress/PostalCode)) > 0">
                                    <PostalCode>
                                        <xsl:value-of select="substring(PostalAddress/PostalCode, 1, 10)"/>
                                    </PostalCode>
                                </xsl:if>
                                <xsl:if test="string-length(normalize-space(PostalAddress/City)) > 0">
                                    <CityName>
                                        <xsl:value-of select="substring(PostalAddress/City, 1, 40)"/>
                                    </CityName>
                                </xsl:if>
                                <xsl:if test="string-length(normalize-space(PostalAddress/Country/@isoCountryCode)) > 0">
                                    <Country>
                                        <xsl:value-of select="substring(PostalAddress/Country/@isoCountryCode, 1, 3)" />
                                    </Country> 
                                </xsl:if>
                                <xsl:if test="string-length(normalize-space(PostalAddress/State/@isoStateCode)) > 0">
                                    <!-- Start of IG-20718 Update Region to pick from attribute @isoStateCode -->
                                    <Region>
                                        <xsl:value-of select="substring-after(PostalAddress/State/@isoStateCode, '-')"/>
                                    </Region>
                                    <!-- End of IG-20718 Update Region to pick from attribute @isoStateCode -->
                                </xsl:if>
                            </Address>
                        </xsl:if>
                    </Party>
                </xsl:for-each>
                <xsl:if test="string-length(normalize-space(Payload/cXML/Request/ShipNoticeRequest/ShipNoticeHeader/@shipmentDate)) > 0">
                    <ActualGoodsMovementDateTime>
                        <xsl:value-of select="Payload/cXML/Request/ShipNoticeRequest/ShipNoticeHeader/@shipmentDate"/>
                    </ActualGoodsMovementDateTime>
                </xsl:if>
                <xsl:if test="string-length(normalize-space(Payload/cXML/Request/ShipNoticeRequest/ShipNoticeHeader/@deliveryDate)) > 0">
                    <DeliveryDateTime>
                        <xsl:value-of select="Payload/cXML/Request/ShipNoticeRequest/ShipNoticeHeader/@deliveryDate" />
                    </DeliveryDateTime>
                </xsl:if>
                <xsl:if test="string-length(normalize-space(Payload/cXML/Request/ShipNoticeRequest/ShipNoticeHeader/@noticeDate)) > 0">
                    <DocumentDate>
                        <xsl:value-of select="substring(Payload/cXML/Request/ShipNoticeRequest/ShipNoticeHeader/@noticeDate, 1, 10)"/>
                    </DocumentDate>
                </xsl:if>
                <xsl:if test="string-length(Payload/cXML/Request/ShipNoticeRequest/ShipNoticeHeader/Packaging/Dimension[@type = 'grossWeight']/@quantity) > 0">
                    <HeaderGrossWeight>
                        <xsl:attribute name="unitCode">
                            <xsl:value-of select="substring(Payload/cXML/Request/ShipNoticeRequest/ShipNoticeHeader/Packaging/Dimension[@type = 'grossWeight']/UnitOfMeasure, 1, 3)"/>
                        </xsl:attribute>
                        <xsl:value-of select="Payload/cXML/Request/ShipNoticeRequest/ShipNoticeHeader/Packaging/Dimension[@type = 'grossWeight']/@quantity"/>
                    </HeaderGrossWeight>
                </xsl:if>
                <xsl:if
                    test="string-length(Payload/cXML/Request/ShipNoticeRequest/ShipNoticeHeader/Packaging/Dimension[@type = 'grossVolume']/@quantity) > 0">
                    <HeaderVolume>
                        <xsl:attribute name="unitCode">
                            <xsl:value-of select="substring(Payload/cXML/Request/ShipNoticeRequest/ShipNoticeHeader/Packaging/Dimension[@type = 'grossVolume']/UnitOfMeasure, 1, 3)" />
                        </xsl:attribute>
                        <xsl:value-of select="Payload/cXML/Request/ShipNoticeRequest/ShipNoticeHeader/Packaging/Dimension[@type = 'grossVolume']/@quantity" />
                    </HeaderVolume>
                </xsl:if>
                <xsl:for-each select="Payload/cXML/Request/ShipNoticeRequest/ShipNoticePortion/ShipNoticeItem">
                    <DeliveryItem>
                        <!-- CI-1890 start -->
                        <xsl:if test="string-length(normalize-space(@shipNoticeLineNumber)) > 0">
                            <DeliveryDocumentItem>
                                <xsl:value-of select="substring(@shipNoticeLineNumber, 1, 10)"/>
                            </DeliveryDocumentItem>
                        </xsl:if>
                        <!-- CI-1890 end -->                        
                        <xsl:if test="string-length(normalize-space(@shipNoticeLineNumber)) > 0">
                        <DeliveryDocumentItemBySupplier>
                            <xsl:value-of select="substring(@shipNoticeLineNumber, 1, 10)"/>
                        </DeliveryDocumentItemBySupplier>
                        </xsl:if>
                        <xsl:if test="string-length(normalize-space(ItemID/BuyerPartID)) > 0 or string-length(normalize-space(ItemID/SupplierPartID)) > 0">
                        <Material>
                            <xsl:if test="string-length(normalize-space(ItemID/BuyerPartID)) > 0">
                                <BuyerProductID>
                                    <xsl:value-of select="substring(ItemID/BuyerPartID, 1, 60)"/>
                                </BuyerProductID>
                            </xsl:if>
                            <!-- source is a must element -->
                                <SupplierProductID>
                                    <xsl:value-of select="substring(ItemID/SupplierPartID, 1, 60)"/>
                                </SupplierProductID>
                        </Material>
                        </xsl:if>
                        <xsl:if test="string-length(@quantity) > 0">
                            <ActualDeliveryQuantity>
                                <xsl:attribute name="unitCode">
                                    <xsl:value-of select="substring(UnitOfMeasure, 1, 3)"/>
                                </xsl:attribute>
                                <xsl:value-of select="@quantity"/>
                            </ActualDeliveryQuantity>
                        </xsl:if>
                        <xsl:if test="string-length(normalize-space(Batch[1]/SupplierBatchID)) > 0 or string-length(normalize-space(Batch[1]/@productionDate)) > 0 or string-length(normalize-space(Batch[1]/@expirationDate)) > 0">
                            <Batch>
                                <!--  CI-2046 BuyerBatchID mapping added & cxml supports multiple batches but inbound API does not support taking first batch-->
                                <xsl:if test="string-length(normalize-space(Batch[1]/SupplierBatchID)) > 0">
                                    <Batch>
                                        <xsl:value-of select="substring(Batch[1]/SupplierBatchID, 1, 20)"/>
                                    </Batch>
                                </xsl:if>
                                <!--   CI-2046  -->
                                <xsl:if test="string-length(normalize-space(Batch[1]/@productionDate)) > 0">
                                    <ManufactureDate>
                                        <xsl:value-of select="substring(Batch[1]/@productionDate, 1, 10)"/>
                                    </ManufactureDate>
                                </xsl:if>
                                <xsl:if test="string-length(normalize-space(Batch[1]/@expirationDate)) > 0">
                                    <ShelfLifeExpirationDate>
                                        <xsl:value-of select="substring(Batch[1]/@expirationDate, 1, 10)"/>
                                    </ShelfLifeExpirationDate>
                                </xsl:if>
                            </Batch>
                        </xsl:if>
                        <xsl:if test="string-length(normalize-space(../OrderReference/@orderID)) > 0">
                        <UnderlyingPurchaseOrder>
                            <xsl:value-of select="substring(../OrderReference/@orderID, 1, 35)"/>
                        </UnderlyingPurchaseOrder>
                        </xsl:if>
                        <xsl:if test="string-length(normalize-space(@lineNumber)) > 0">
                        <UnderlyingPurchaseOrderItem>
                            <xsl:value-of select="substring(@lineNumber, 1, 10)"/>
                        </UnderlyingPurchaseOrderItem>
                        </xsl:if>
                         <!-- CI-2351 Serial Number mapping-->
                        <xsl:for-each select="AssetInfo">
                           <xsl:variable name="v_sid">
                               <xsl:value-of select="@serialNumber"/>
                           </xsl:variable>
                           <xsl:if test="string-length(normalize-space($v_sid)) > 0">
                               <Serial>
                                   <SerialNumber>
                                       <xsl:value-of select="substring($v_sid, 1, 30)"/>
                                   </SerialNumber>
                               </Serial>
                           </xsl:if>
                       </xsl:for-each>
                       <!--CI-2351 -->
                         <!-- CI-1890 start-->
                        <xsl:if test="exists(ComponentConsumptionDetails)">
                            <xsl:for-each select="ComponentConsumptionDetails">
                                <SubcontractingComponent>
                                    <SubcontrgProductID>
                                        <xsl:value-of select="substring(Product/BuyerPartID, 1, 60)"/>
                                    </SubcontrgProductID>
                                    <xsl:if
                                        test="string-length(normalize-space(Product/SupplierPartID)) > 0">
                                        <SubcontrgSupplierProductID>
                                            <xsl:value-of select="substring(Product/SupplierPartID, 1, 60)"/>
                                        </SubcontrgSupplierProductID>
                                    </xsl:if>
                                    <xsl:if test="string-length(normalize-space(BuyerBatchID)) > 0">
                                        <SubcontrgBatch>
                                            <xsl:value-of select="substring(BuyerBatchID, 1, 20)"/>
                                        </SubcontrgBatch>
                                    </xsl:if>
                                    <xsl:if
                                        test="string-length(normalize-space(SupplierBatchID)) > 0">
                                        <SubcontrgBatchBySupplier>
                                            <xsl:value-of select="substring(SupplierBatchID, 1, 20)"/>
                                        </SubcontrgBatchBySupplier>
                                    </xsl:if>
                                    <QuantityInEntryUnit>
                                        <xsl:attribute name="unitCode">
                                            <xsl:value-of select="substring(UnitOfMeasure, 1, 3)"/>
                                        </xsl:attribute>
                                        <xsl:value-of select="substring(@quantity, 1, 31)"/>
                                    </QuantityInEntryUnit>
                                    <!--SOC for SBNI-2011 ASN with Component Serial Number-->
                                    <xsl:for-each select="AssetInfo">
                                        <xsl:variable name="v_sid_csn">
                                            <xsl:value-of select="@serialNumber"/>
                                        </xsl:variable>
                                        <xsl:if test="string-length(normalize-space($v_sid_csn)) > 0">
                                            <Serial>
                                                <SerialNumber>
                                                    <xsl:value-of select="substring($v_sid_csn, 1, 30)"/>
                                                </SerialNumber>
                                            </Serial>
                                        </xsl:if>
                                    </xsl:for-each>
                                    <!--EOC for SBNI-2011 ASN with Component Serial Number-->
                                </SubcontractingComponent>
                            </xsl:for-each>
                        </xsl:if>
                        <!-- CI-1890 end-->
                    </DeliveryItem>
                </xsl:for-each>
                <!-- CI-2049 start-->
                <xsl:variable name="v_shipmentID">
                    <xsl:value-of
                        select="Payload/cXML/Request/ShipNoticeRequest/ShipNoticeHeader/@shipmentID"
                    />
                </xsl:variable>
                <xsl:variable name="v_ShipNoticeItemPath" select="Payload/cXML/Request/ShipNoticeRequest/ShipNoticePortion/ShipNoticeItem">
                </xsl:variable>
                <xsl:for-each-group
                    select="Payload/cXML/Request/ShipNoticeRequest/ShipNoticePortion/ShipNoticeItem/Packaging"
                    group-by="ShippingContainerSerialCode">
                    <xsl:if
                        test="string-length(normalize-space(ShippingContainerSerialCode[1])) > 0 or string-length(normalize-space(PackageTypeCodeIdentifierCode[1])) > 0 
                        or (string-length(normalize-space(Dimension[1])) > 0 and string-length(normalize-space(PackagingCode[1])) > 0) and PackagingLevelCode != 'auxiliary'">
                        <HandlingUnit>
                            <ID>
                                <xsl:value-of select="substring(ShippingContainerSerialCode, 1, 40)"
                                />
                            </ID>
                                <AlternativeID>
                                    <xsl:value-of
                                        select="substring(PackageID/PackageTrackingID, 1, 20)"/>
                                </AlternativeID>
                            <ID_Type>
                                <xsl:value-of select="'H'"/>
                            </ID_Type>
                            <LoadCarrier>
                                <Product>
                                    <xsl:if
                                        test="string-length(normalize-space(PackageTypeCodeIdentifierCode)) > 0">
                                        <BuyerProductID>
                                            <xsl:value-of select="substring(PackageTypeCodeIdentifierCode,1,60)"/>
                                        </BuyerProductID>
                                    </xsl:if>
                                </Product>
                            </LoadCarrier>
                            <xsl:if test="string-length(normalize-space(Dimension[@type = 'height']/@quantity))>0">
                                <HeightMeasure>
                                    <xsl:attribute name="unitCode">
                                        <xsl:value-of
                                            select="substring(Dimension[@type = 'height']/UnitOfMeasure, 1, 3)"
                                        />
                                    </xsl:attribute>
                                    <xsl:value-of select="Dimension[@type = 'height']/@quantity"/>
                                </HeightMeasure>
                            </xsl:if>
                            <xsl:if test="string-length(normalize-space(Dimension[@type = 'length']/@quantity))>0">
                                <LengthMeasure>
                                    <xsl:attribute name="unitCode">
                                        <xsl:value-of
                                            select="substring(Dimension[@type = 'length']/UnitOfMeasure, 1, 3)"
                                        />
                                    </xsl:attribute>
                                    <xsl:value-of select="Dimension[@type = 'length']/@quantity"/>
                                </LengthMeasure>
                            </xsl:if>
                            <xsl:if test="string-length(normalize-space(Dimension[@type = 'width']/@quantity))>0">
                                <WidthMeasure>
                                    <xsl:attribute name="unitCode">
                                        <xsl:value-of
                                            select="substring(Dimension[@type = 'width']/UnitOfMeasure, 1, 3)"
                                        />
                                    </xsl:attribute>
                                    <xsl:value-of select="Dimension[@type = 'width']/@quantity"/>
                                </WidthMeasure>
                            </xsl:if>
                            <xsl:variable name="v_ShippingContainerSerialCode">
                                <xsl:value-of select="ShippingContainerSerialCode"/>
                            </xsl:variable>
                            <xsl:for-each
                                select="$v_ShipNoticeItemPath/Packaging[ShippingContainerSerialCodeReference = $v_ShippingContainerSerialCode]">
                                <xsl:choose>
                                    <xsl:when test="PackagingLevelCode = 'auxiliary'">
                                        <AdditionalPackaging>
                                            <Product>
                                                <BuyerProductID>
                                                    <xsl:value-of select="substring(PackagingCode,1,60)"/>
                                                </BuyerProductID>
                                            </Product>
                                            <Quantity>
                                                <xsl:attribute name="unitCode">
                                                    <xsl:value-of
                                                        select="substring(DispatchQuantity/UnitOfMeasure, 1, 3)"
                                                    />
                                                </xsl:attribute>
                                                <xsl:value-of
                                                    select="DispatchQuantity/@quantity"
                                                />
                                            </Quantity>
                                        </AdditionalPackaging>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <LowerLevelHandlingUnit>
                                            <ID>
                                                <xsl:value-of
                                                    select="substring(ShippingContainerSerialCode, 1, 40)"/>
                                            </ID>
                                        </LowerLevelHandlingUnit>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>
                            <xsl:for-each select="current-group()[Description/@type = 'Material' and DispatchQuantity/@quantity >0]">
                                <Load>
                                    <BusinessTransactionDocumentReference>
                                        <ID>
                                            <xsl:value-of select="substring($v_shipmentID,1,35)"/>
                                        </ID>
                                        <ItemID>
                                            <xsl:value-of
                                                select="substring(../@shipNoticeLineNumber,1,10)"
                                            />
                                        </ItemID>
                                    </BusinessTransactionDocumentReference>
                                    <Quantity>
                                        <xsl:attribute name="unitCode">
                                            <xsl:value-of
                                                select="substring(DispatchQuantity/UnitOfMeasure, 1, 3)"
                                            />
                                        </xsl:attribute>
                                        <xsl:value-of select="DispatchQuantity/@quantity"/>
                                    </Quantity>
                                    <!--SOC for SBNI-2011 ASN Serial Number at HU Level-->
                                    <xsl:for-each select="AssetInfo">
                                        <xsl:variable name="v_sid_hu">
                                            <xsl:value-of select="@serialNumber"/>
                                        </xsl:variable>
                                        <xsl:if test="string-length(normalize-space($v_sid_hu))>0">
                                            <SerialID>
                                                <SerialNumber>
                                                    <xsl:value-of select="substring($v_sid_hu, 1, 30)"/>
                                                </SerialNumber>
                                            </SerialID>
                                        </xsl:if>
                                    </xsl:for-each>
                                    <!--EOC for SBNI-2011 ASN Serial Number at HU Level-->
                                </Load>
                            </xsl:for-each>
                        </HandlingUnit>
                    </xsl:if>
                </xsl:for-each-group>
                <!-- CI-2049 end-->
                <!-- CI-2869 Attachments Processing for 2211 release. Only Header Level Attachments -->
                <xsl:if test="string-length(normalize-space($cXMLAttachments)) > 0">
                    <xsl:variable name = "v_headerAttachmentList" select="normalize-space($cXMLAttachments)"/>
                    <xsl:call-template name="InboundS4Attachment">
                        <xsl:with-param name="AttachmentList">
                            <xsl:value-of select="$v_headerAttachmentList"/>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:if>
                <!-- CI-2869 end -->
            </Delivery>
        </n0:DeliveryRequest>
    </xsl:template>
</xsl:stylesheet>
