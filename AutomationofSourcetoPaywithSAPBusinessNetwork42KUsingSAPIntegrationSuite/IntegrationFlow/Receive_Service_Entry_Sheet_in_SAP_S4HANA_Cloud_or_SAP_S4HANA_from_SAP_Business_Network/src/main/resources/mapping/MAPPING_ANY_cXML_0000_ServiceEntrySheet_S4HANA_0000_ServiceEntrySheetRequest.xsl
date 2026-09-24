<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:n0="http://sap.com/xi/SAPGlobal20/Global"   xmlns:hci="http://sap.com/it/" xmlns:xop="http://www.w3.org/2004/08/xop/include" 
    exclude-result-prefixes="xs xop" version="2.0">
    <xsl:output method="xml" indent="no" omit-xml-declaration="yes"/>
    <!--Indent No is made on purpose, else attachments will fail in S4 Cloud    -->
    <!--BPI-147 start -->
    <xsl:include href="FORMAT_S4HANA_0000_cXML_0000.xsl" use-when="doc-available('FORMAT_S4HANA_0000_cXML_0000.xsl')"/> <!-- Added changes in pd entries file for BPI-147 feature applied use-when logic-->
<!--    <xsl:include href="../../../common/FORMAT_S4HANA_0000_cXML_0000.xsl"/>    -->
    <xsl:param name="anReceiverID"/>
    <xsl:param name="anSourceDocumentType"/>
    <xsl:param name="anERPSystemID"/>
    <xsl:param name="anERPTimeZone"/>
    <xsl:param name="UOMinput"/>
    <xsl:param name="cXMLAttachments"/>
    <xsl:param name="anCorrelationID"/>
    <xsl:param name="exchange"/>
    <xsl:template match="Combined">
        <!--   <Get the System Id -->
        <xsl:variable name="v_sysid">
            <xsl:call-template name="MultiErpSysIdIN">
                <xsl:with-param name="p_ansysid"
                    select="Payload/cXML/Header/To/Credential[@domain = 'SystemID']/Identity"/>
                <xsl:with-param name="p_erpsysid" select="$anERPSystemID"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="v_timeZoneCode">
            <xsl:value-of select="$anERPTimeZone"/>
        </xsl:variable>
        <!--Prepare the CrossRef path-->
        <xsl:variable name="v_pd">
            <xsl:call-template name="PrepareCrossref">
                <xsl:with-param name="p_doctype" select="$anSourceDocumentType"/>
                <xsl:with-param name="p_erpsysid" select="$v_sysid"/>
                <xsl:with-param name="p_ansupplierid" select="$anReceiverID"/>
            </xsl:call-template>
        </xsl:variable>
        <!--Get the Language code-->
        <xsl:variable name="v_lang">
            <xsl:call-template name="FillDefaultLang">
                <xsl:with-param name="p_doctype" select="$anSourceDocumentType"/>
                <xsl:with-param name="p_pd" select="$v_pd"/>
            </xsl:call-template>
        </xsl:variable>
        <!-- IG-44694: Start - ServiceEntryDate (BN to S4 API) -->
        <xsl:variable name="v_creationDateTime">
            <xsl:call-template name="ERPDateTime">
                <xsl:with-param name="p_date" select="Payload/cXML/Request/ServiceEntryRequest/ServiceEntryRequestHeader/@serviceEntryDate"/>
                <xsl:with-param name="p_timezone" select="$anERPTimeZone"/>
            </xsl:call-template>
        </xsl:variable>
        <!--    Begin of BPI_256 Final Service Sheet Indicator (BN to S4 API)    --> 
        <xsl:variable name="v_final">
            <xsl:value-of select="Payload/cXML/Request/ServiceEntryRequest/ServiceEntryRequestHeader/@isFinal"/>
        </xsl:variable>
        <!--    End of BPI_256   -->
        <!-- IG-44694: End -->
        <!--   As S4HANA  CE doesn't support deleting approved SES in single API call, So for this CIG will call 2 API's one for Revoke and other for Delete so we need this condition to distinguish 'new' actioncode from 'delete'     -->
        <xsl:if test="/Combined/Payload/cXML/Request/ServiceEntryRequest/ServiceEntryRequestHeader/@operation = 'delete'">
            <xsl:variable name="v_revoke">
                &lt;n0:ServiceEntrySheetS4RevokeRequest xmlns:n0="http://sap.com/xi/APPL/Global2"&gt;
                &lt;MessageHeader&gt;
                &lt;ID&gt;<xsl:value-of select="substring(Payload/cXML/@payloadID,1,35)"/>&lt;/ID&gt;
                &lt;ReferenceID&gt;<xsl:value-of select="Payload/cXML/Request/ServiceEntryRequest/ServiceEntryRequestHeader/@serviceEntryID"/>&lt;/ReferenceID&gt;
                <!-- IG-44694: Start - ServiceEntryDate (BN to S4 API) -->
                &lt;CreationDateTime&gt;<xsl:value-of select="$v_creationDateTime"/>&lt;/CreationDateTime&gt;
                <!-- IG-44694: End -->
                &lt;SenderBusinessSystemID&gt;<xsl:value-of select="Payload/cXML/Header/To/Credential[translate(@domain, 'NETWORKID', 'networkid') = 'networkid']/Identity"/>&lt;/SenderBusinessSystemID&gt;
                &lt;/MessageHeader&gt;
                &lt;ServiceEntrySheet&gt;
                &lt;ID/&gt;
                &lt;Supplier&gt;<xsl:value-of select="Payload/cXML/Header/From/Credential[@domain='VendorID']/Identity"/>&lt;/Supplier&gt;  <!-- IG-43055: map VendorID to newly added Supplier field in proxy -->                
                &lt;/ServiceEntrySheet&gt;
                &lt;/n0:ServiceEntrySheetS4RevokeRequest&gt;
            </xsl:variable>
            <!--        <xsl:copy-of select="concat($exchange,'ansesrevoke', $v_revoke)"/>-->
            <xsl:if test="$v_revoke">
                <!-- DO NOT REMOVE - This is to make XSPEC assume that $ancXMLAttachments has some value -->
            </xsl:if>
            <xsl:value-of select="hci:setHeader($exchange, 'ansesrevoke', $v_revoke)"/>
        </xsl:if>
        <n0:ServiceEntrySheetRequestMsg>
            <MessageHeader>
                <ID>
                    <xsl:value-of select="substring(Payload/cXML/@payloadID, 1, 35)"/>
                </ID>
                <ReferenceID>
                    <!-- IG-28541 - ses cancellation _1 logic removal -->                    
                            <xsl:value-of select="Payload/cXML/Request/ServiceEntryRequest/ServiceEntryRequestHeader/@serviceEntryID"/>
                    <!-- IG-28541 -->
                </ReferenceID>
                <SenderBusinessSystemID>
                    <xsl:value-of
                        select="Payload/cXML/Header/To/Credential[translate(@domain, 'NETWORKID', 'networkid') = 'networkid']/Identity"/>
                </SenderBusinessSystemID>
                <RecipientBusinessSystemID>
                    <xsl:value-of select="$v_sysid"/>
                </RecipientBusinessSystemID>
                <CreationDateTime>
                    <!-- IG-44694: Start - ServiceEntryDate (BN to S4 API) -->
                    <xsl:value-of select="$v_creationDateTime"/>
                    <!-- IG-44694: End -->
                </CreationDateTime>
                <SenderParty>
                    <InternalID>
                        <xsl:value-of
                            select="Payload/cXML/Header/From/Credential[translate(@domain, 'NETWORKID', 'networkid') = 'networkid']/Identity"
                        />
                    </InternalID>
                </SenderParty>
                <RecipientParty>
                    <InternalID>
                        <xsl:value-of
                            select="Payload/cXML/Header/To/Credential[translate(@domain, 'NETWORKID', 'networkid') = 'networkid']/Identity"
                        />
                    </InternalID>
                </RecipientParty>
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
            <ServiceEntrySheetEntity>
                <!-- {CI-1802 Delete SES if it is InApproval  -->                
                <xsl:if
                    test="Payload/cXML/Request/ServiceEntryRequest/ServiceEntryRequestHeader/@operation = 'delete'">    
                    <DeleteInApproval>
                    <xsl:value-of select="'true'"/>     
                    </DeleteInApproval>
                </xsl:if>      
                <!-- CI-1802}} Delete SES if it is InApproval  -->                  
                <ActionCode>
                    <xsl:choose>
                        <xsl:when
                            test="Payload/cXML/Request/ServiceEntryRequest/ServiceEntryRequestHeader/@operation = 'new'">
                            <xsl:value-of select="'01'"/>
                        </xsl:when>
                        <xsl:when
                            test="Payload/cXML/Request/ServiceEntryRequest/ServiceEntryRequestHeader/@operation = 'delete'">
                            <xsl:value-of select="'03'"/>
                        </xsl:when>
                    </xsl:choose>
                </ActionCode>
                <ApprovalStatus>20</ApprovalStatus>
                <ServiceEntrySheet>
                    <!--<xsl:value-of                        select="Payload/cXML/Request/ServiceEntryRequest/ServiceEntryRequestHeader/@serviceEntryID"                    />-->
                    <!--<xsl:value-of
                        select="Payload/cXML/Request/ServiceEntryRequest/ServiceEntryOrder/ServiceEntryOrderInfo/OrderReference/@orderID"
                    />-->
                </ServiceEntrySheet>
                <ServiceEntrySheetName>
<!--                    IG-28541  SES delete no need to trim _1-->
                        <xsl:value-of
                            select="Payload/cXML/Request/ServiceEntryRequest/ServiceEntryRequestHeader/@serviceEntryID"
                        />
<!--                    IG-28541                    -->
                </ServiceEntrySheetName>
                <PurchaseOrder>
                    <xsl:value-of
                        select="Payload/cXML/Request/ServiceEntryRequest/ServiceEntryOrder/ServiceEntryOrderInfo/OrderReference/@orderID"
                    />
                </PurchaseOrder>
                <ResponsiblePerson/>
                <!--                            For 2002 release-->
                <xsl:if test="string-length(Payload/cXML/Request/ServiceEntryRequest/ServiceEntryRequestHeader/Comments) > 0">
                <TextCollection>
                    <Text>
                        <ActionCode>
                            <xsl:value-of select="'01'"/>
                        </ActionCode>
                        <NoteTypeCode>
                            <xsl:value-of select="'SES_HEADER_TEXT'"/>
                        </NoteTypeCode>
                        <ContentText>
                            <xsl:attribute name="languageCode">
                                <xsl:value-of select="'en'"/>
                            </xsl:attribute>
                            <xsl:value-of
                                select="Payload/cXML/Request/ServiceEntryRequest/ServiceEntryRequestHeader/Comments/text()"
                            />
                        </ContentText>
                    </Text>
                </TextCollection>
                </xsl:if>
                <!--                            End of Comments-->
                <ServiceEntrySheetItemList>
                    <xsl:for-each
                        select="Payload/cXML/Request/ServiceEntryRequest/ServiceEntryOrder/ServiceEntryItem">
                        <!--                    <ServiceEntrySheetItemList>-->
                        <xsl:variable name="v_distributionCount">
                            <xsl:value-of select="count(Distribution)"/>
                        </xsl:variable>
                        <ServiceEntrySheetItemEntity>
                            <ActionCode>
                                <xsl:choose>
                                    <xsl:when test="//Request//@operation = 'new'">
                                        <xsl:value-of select="'01'"/>
                                    </xsl:when>
                                    <xsl:when test="//Request//@operation = 'delete'">
                                        <xsl:value-of select="'03'"/>
                                    </xsl:when>
                                </xsl:choose>
                            </ActionCode>
                            <xsl:if
                                test="string-length(normalize-space(Distribution[1]/Accounting/AccountingSegment[lower-case(Name) = 'accountcategory']/@id)) > 0">
                                <AccountAssignmentCategory>
                                    <xsl:value-of select="Distribution[1]/Accounting/AccountingSegment[lower-case(Name) = 'accountcategory']/@id"
                                    />
                                </AccountAssignmentCategory>
                            </xsl:if>
                            <xsl:if test="string-length(@quantity) > 0">
                                <ConfirmedQuantity>
                                    <xsl:attribute name="unitCode">
                                        <xsl:value-of select="UnitOfMeasure"/>
                                    </xsl:attribute>
                                    <xsl:value-of select="@quantity"/>
                                </ConfirmedQuantity>
                            </xsl:if>
                            <xsl:choose>
                                <xsl:when test="$v_distributionCount = 1">
                                    <MultipleAcctAssgmtDistribution/>
                                </xsl:when>
                                <xsl:when test="Distribution[1]/Accounting/AccountingSegment[lower-case(Name) = 'amount']">
                                    <MultipleAcctAssgmtDistribution>
                                        <xsl:value-of select="'3'"/>
                                    </MultipleAcctAssgmtDistribution>
                                </xsl:when>
                                <xsl:when
                                    test="Distribution[1]/Accounting/AccountingSegment[lower-case(Name) = 'percentage']">
                                    <MultipleAcctAssgmtDistribution>
                                        <xsl:value-of select="'2'"/>
                                    </MultipleAcctAssgmtDistribution>
                                </xsl:when>
                                <xsl:when test="Distribution[1]/Accounting/AccountingSegment[lower-case(Name) = 'quantity']">
                                    <MultipleAcctAssgmtDistribution>
                                        <xsl:value-of select="'1'"/>
                                    </MultipleAcctAssgmtDistribution>
                                </xsl:when>
                            </xsl:choose>
                                <xsl:if test="string-length(UnitPrice/Money) > 0">
                                    <NetPriceAmount>
                                        <xsl:attribute name="currencyCode">
                                            <xsl:value-of select="UnitPrice/Money/@currency"/>
                                        </xsl:attribute>
                                        <xsl:value-of select="UnitPrice/Money"/>
                                    </NetPriceAmount>
                                </xsl:if>
                                <xsl:if test="string-length(ItemReference/@lineNumber) > 0">
                                    <PurchaseOrderItem>
                                        <xsl:value-of select="ItemReference/@lineNumber"/>
                                    </PurchaseOrderItem>
                                </xsl:if>
                                <xsl:if test="string-length(UnitOfMeasure) > 0">
                                    <QuanitityUnit>
                                        <xsl:value-of select="UnitOfMeasure"/>
                                    </QuanitityUnit>
                                </xsl:if>
                                <Service>
                                    <xsl:if test="string-length() > 0">
                                        <xsl:value-of select="ItemReference/ItemID/BuyerPartID"/>
                                    </xsl:if>
                                </Service>
                                <xsl:if test="string-length(ItemReference/@lineNumber) > 0">
                                    <ServiceEntrySheetItem>
                                        <xsl:value-of select="ItemReference/@lineNumber"/>
                                    </ServiceEntrySheetItem>
                                </xsl:if>
                                <xsl:if test="string-length(@serviceLineNumber) > 0">
                                    <ServiceEntrySheetItemReference>
                                        <xsl:value-of select="@serviceLineNumber"/>
                                    </ServiceEntrySheetItemReference>
                                </xsl:if>
                                <ServiceEntrySheetItemDesc>
                                    <xsl:choose>
                                        <xsl:when test="(ItemReference/Description) != ''">
                                            <xsl:value-of select="ItemReference/Description"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="'Adhoc-Item'"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </ServiceEntrySheetItemDesc>
                                <xsl:if test="string-length(Period/@startDate) > 0">
                                    <ServicePerformanceDate>
                                        <xsl:value-of select="Period/@startDate"/>
                                    </ServicePerformanceDate>
                                </xsl:if>
                            <!-- IG-29871 SES Performance Period -->
                            <xsl:if test="string-length(Period/@endDate) > 0">
                                <ServicePerformanceEndDate>
                                    <xsl:value-of select="Period/@endDate"/>
                                </ServicePerformanceEndDate>
                            </xsl:if>
                            <!-- IG-29871 -->
                                <ServicePerformer/>
                                <WorkItem/>
                            <!-- Begin of BPI_256 Final Service Sheet Indicator (BN to S4 API) -->
                            <xsl:if test="string-length($v_final) > 0">
                                <SrvcEntrShtItemIsFinalEntry>
                                    <xsl:value-of select="'true'"/>
                                </SrvcEntrShtItemIsFinalEntry>
                            </xsl:if>
                            <!-- End of BPI_256 -->
                            <xsl:if test="string-length(normalize-space(Distribution[1])) > 0">
                                <ServiceEntryShtAcctAssgmtList>
                                    <xsl:for-each select="Distribution">
                                        <ServiceEntrySheetAcctAssgmtEntity>
                                            <ActionCode>01</ActionCode>
                                            <AccountAssignment>
                                                <xsl:choose>
                                                    <xsl:when test="string-length(normalize-space(Accounting/AccountingSegment[lower-case(Name)= 'sapserialnumber']/@id))>0">
                                                        <xsl:value-of
                                                            select="Accounting/AccountingSegment[lower-case(Name)= 'sapserialnumber']/@id"
                                                        />
                                                    </xsl:when>
                                                    <xsl:otherwise>
                                                        <xsl:value-of
                                                            select="position()"
                                                        />
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                            </AccountAssignment>
                                            <BusinessArea/>
                                            <CommitmentItem/>
                                            <ControllingArea/>
                                            <CostCenter>
                                                <xsl:value-of
                                                    select="Accounting/AccountingSegment[lower-case(Name)= 'costcenter']/@id"
                                                />
                                            </CostCenter>
                                            <CostObject/>
                                            <EarmarkedFundsDocument/>
                                            <FixedAsset/>
                                            <Fund/>
                                            <FundsCenter/>
                                            <GLAccount>
                                                <xsl:value-of
                                                    select="Accounting/AccountingSegment[lower-case(Name) = 'generalledger']/@id"
                                                />
                                            </GLAccount>
                                            <MasterFixedAsset/>
                                            <MultipleAcctAssgmtDistrPercent>
                                            <xsl:choose>
                                                <xsl:when test="$v_distributionCount > 1 and string-length(normalize-space(Accounting/AccountingSegment[lower-case(Name) = 'percentage']/@id)) > 0">
                                                        <xsl:value-of
                                                            select="Accounting/AccountingSegment[lower-case(Name) = 'percentage']/@id"
                                                        />
                                                </xsl:when>
                                                <xsl:otherwise>
                                                        <xsl:value-of
                                                            select="0"
                                                        />
                                                </xsl:otherwise>
                                            </xsl:choose>
                                            </MultipleAcctAssgmtDistrPercent>
                                            <NetAmount>
                                                <xsl:attribute name="currencyCode">
                                                    <xsl:value-of select="Charge/Money/@currency"/>
                                                </xsl:attribute>
                                                <xsl:choose>
                                                    <xsl:when test="string-length(normalize-space(Charge/Money))>0">
                                                        <xsl:value-of select="Charge/Money"/> 
                                                    </xsl:when>
                                                    <xsl:otherwise>
                                                        <xsl:value-of select="0"/> 
                                                    </xsl:otherwise>
                                                </xsl:choose>                                               
                                            </NetAmount>
                                            <NetworkActivity/>
                                            <NetworkActivityInternalID/>
                                            <OrderID>
                                                <xsl:value-of
                                                    select="Accounting/AccountingSegment[lower-case(Name) = 'internalorder']/@id"
                                                />
                                            </OrderID>
                                            <ProfitabilitySegment/>
                                            <ProfitCenter/>
                                            <ProjectNetwork/>
                                            <ProjectNetworkInternalID/>
                                            <Quantity>
                                                <xsl:attribute name="unitCode">
                                                    <xsl:value-of
                                                        select="../UnitOfMeasure"
                                                    />
                                                </xsl:attribute>
                                                <xsl:choose>
                                                    <xsl:when test="string-length(normalize-space(Accounting/AccountingSegment[lower-case(Name) = 'quantity']/@id))>0">
                                                        <xsl:value-of
                                                            select="Accounting/AccountingSegment[lower-case(Name) = 'quantity']/@id"
                                                        />
                                                    </xsl:when>
                                                    <xsl:otherwise>
                                                        <xsl:value-of select="0"/>
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                            </Quantity>
                                            <RealEstateObject/>
                                            <SalesOrder/>
                                            <SalesOrderItem/>
                                            <SalesOrderScheduleLine/>
                                            <WBSElementInternalID/>
                                            <xsl:if test="string-length(normalize-space(Accounting/AccountingSegment[lower-case(Name) = 'wbselement']/@id))>0">
                                                <WBSElementExternalID>
                                                    <xsl:value-of
                                                        select="Accounting/AccountingSegment[lower-case(Name) = 'wbselement']/@id"
                                                    />
                                                </WBSElementExternalID>
                                            </xsl:if>
                                        </ServiceEntrySheetAcctAssgmtEntity>
                                    </xsl:for-each>
                                </ServiceEntryShtAcctAssgmtList>
                            </xsl:if>
                            <!-- {CI-1802 Map agrement item number  -->                             
                            <xsl:if test="string-length(normalize-space(Extrinsic[@name='agreementItemNumber'])) > 0">                            
                            <PurchaseContractItem>
                                <xsl:value-of select="Extrinsic[@name='agreementItemNumber']"/>                                
                            </PurchaseContractItem>   
                            </xsl:if>  
                            <!-- CI-1802} Map agrement item number  -->                              
                            <!--                            For 2002 release-->
                            <xsl:if test="string-length(Comments) > 0">
                            <TextCollection>
                                <Text>
                                    <ActionCode>
                                        <xsl:value-of select="'01'"/>
                                    </ActionCode>
                                    <NoteTypeCode>
                                        <xsl:value-of select="'SES_ITEM_TEXT'"/>
                                    </NoteTypeCode>
                                    <ContentText>
                                        <xsl:attribute name="languageCode">
                                            <xsl:value-of select="'en'"/>
                                        </xsl:attribute>
                                        <xsl:value-of select="Comments"/>
                                    </ContentText>
                                </Text>
                            </TextCollection>
                            </xsl:if>
                            <!--                            End of Comments-->
                            <!-- {CI-1802 Comment as not to map accounting data  -->                              
<!--                            <xsl:for-each select="Distribution/Accounting">-->
                                <!--<ServiceEntryShtAcctAssgmtList>
                                    <ServiceEntrySheetAcctAssgmtEntity>
                                        <ActionCode>01</ActionCode>
                                        <xsl:if test="string-length(AccountingSegment/Name) > 0">
                                            <AccountAssignment>
                                                <xsl:choose>
                                                  <xsl:when
                                                  test="AccountingSegment/Name = 'CostCenter'">
                                                  <xsl:value-of select="'K'"/>
                                                  </xsl:when>
                                                  <xsl:when test="AccountingSegment/Name = 'Asset'">
                                                  <xsl:value-of select="'A'"/>
                                                  </xsl:when>
                                                  <xsl:when
                                                  test="AccountingSegment/Name = 'InternalOrder'">
                                                  <xsl:value-of select="'F'"/>
                                                  </xsl:when>
                                                  <xsl:when
                                                  test="AccountingSegment/Name = 'WBSElement'">
                                                  <xsl:value-of select="'P'"/>
                                                  </xsl:when>
                                                </xsl:choose>
                                            </AccountAssignment>
                                        </xsl:if>
                                        <xsl:if test="string-length(AccountingSegment/Name) > 0">
                                            <xsl:choose>
                                                <xsl:when
                                                  test="AccountingSegment/Name = 'CostCenter'">
                                                  <CostCenter>
                                                  <xsl:value-of select="AccountingSegment/@id"/>
                                                  </CostCenter>
                                                </xsl:when>
                                                <xsl:when test="AccountingSegment/Name = 'Asset'">
                                                  <FixedAsset>
                                                  <xsl:value-of select="AccountingSegment/@id"/>
                                                  </FixedAsset>
                                                </xsl:when>
                                                <xsl:when
                                                  test="AccountingSegment/Name = 'GeneralLedger'">
                                                  <GLAccount>
                                                  <xsl:value-of select="AccountingSegment/@id"/>
                                                  </GLAccount>
                                                </xsl:when>
                                                  <xsl:when test="AccountingSegment/Name = 'InternalOrder'">                                               <OrderID>                                                   <xsl:value-of select="AccountingSegment/@id"/>                                                </OrderID>                                                                                              </xsl:when>                                           <xsl:when test="AccountingSegment/Name = 'WBSElement'">                                               <WBSElementInternalID>                                                   <xsl:value-of select="AccountingSegment/@id"/>                                                </WBSElementInternalID>                                                                                              </xsl:when>
                                            </xsl:choose>
                                        </xsl:if>
                                        <xsl:if test="string-length(../../UnitPrice/Money) > 0">
                                            <NetAmount>
                                                <xsl:attribute name="currencyCode">
                                                  <xsl:value-of
                                                  select="../../UnitPrice/Money/@currencyCode"/>
                                                </xsl:attribute>
                                                <xsl:value-of select="../../UnitPrice/Money"/>
                                            </NetAmount>
                                        </xsl:if>
                                        <xsl:if test="string-length(AccountingSegment/Name) > 0">
                                            <OrderID>
                                                <xsl:if
                                                  test="AccountingSegment/Name = 'InternalOrder'">
                                                  <xsl:value-of select="AccountingSegment/@id"/>
                                                </xsl:if>
                                            </OrderID>
                                        </xsl:if>
                                        <xsl:if test="string-length(../../UnitOfMeasure) > 0">
                                            <Quantity>
                                                <xsl:attribute name="unitCode">
                                                  <xsl:value-of select="../../UnitOfMeasure"/>
                                                </xsl:attribute>
                                            </Quantity>
                                        </xsl:if>
                                        <xsl:if test="string-length(AccountingSegment/Name) > 0">
                                            <WBSElementInternalID>
                                                <xsl:if test="AccountingSegment/Name = 'WBSElement'">
                                                  <xsl:value-of select="AccountingSegment/@id"/>
                                                </xsl:if>
                                            </WBSElementInternalID>
                                        </xsl:if>
                                    </ServiceEntrySheetAcctAssgmtEntity>
                                </ServiceEntryShtAcctAssgmtList>-->
                            <!--</xsl:for-each>-->
                            <!-- CI-1802} End of  Comment as not to map accounting data  -->                              
                        </ServiceEntrySheetItemEntity>
                        <!--</ServiceEntrySheetItemList>-->
                    </xsl:for-each>
                </ServiceEntrySheetItemList>
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
            </ServiceEntrySheetEntity>
        </n0:ServiceEntrySheetRequestMsg>
    </xsl:template>
</xsl:stylesheet>
