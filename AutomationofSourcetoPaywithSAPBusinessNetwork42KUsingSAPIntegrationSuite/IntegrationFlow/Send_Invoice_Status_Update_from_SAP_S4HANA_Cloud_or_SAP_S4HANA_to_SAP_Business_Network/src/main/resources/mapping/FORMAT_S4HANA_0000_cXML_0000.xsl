<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:hci="http://sap.com/it/"
	xmlns:xop="http://www.w3.org/2004/08/xop/include" xmlns:xs="http://www.w3.org/2001/XMLSchema" 
	exclude-result-prefixes="#all" version="2.0">
<!--	<xsl:variable name="crossrefparamLookup" select="document('ParameterCrossreference.xml')"/>
   <xsl:variable name="UOMLookup" select="document('UOMTemplate.xml')"/>-->
	<xsl:param name="anCrossRefFlag"/>
	<xsl:param name="anLookUpFlag"/>
	<xsl:param name="anUOMFlag"/>
	<xsl:param name="anLocalTesting"/>
	<xsl:param name="commentlevel_header" select="'HEADER'"/>
	<xsl:param name="commentlevel_line" select="'LINE'"/>
	<xsl:param name="commentlevel_service_line" select="'SERVICE'"/>
	<!--IG-46494 Begin-->
	<!--Use values maintained in CPI-->
	<xsl:param name="intPackageCrossRef"/>
	<xsl:param name="intPackageLookup"/>
	<!--IG-46494 End-->
	<!-- Outbound MultiERP template -->
	<xsl:template name="MultiERPTemplateOut">
		<xsl:param name="p_anIsMultiERP"/>
		<xsl:param name="p_anERPSystemID"/>
		<xsl:if test="upper-case($p_anIsMultiERP) = 'TRUE'">
			<Credential>
				<xsl:attribute name="domain">SystemID</xsl:attribute>
				<Identity>
					<xsl:value-of select="$p_anERPSystemID"/>
				</Identity>
			</Credential>
		</xsl:if>
	</xsl:template>
	<!--Template for lookup table -->
	<xsl:template name="LookupTemplate">
		<xsl:param name="p_anERPSystemID"/>
		<xsl:param name="p_anSupplierANID"/>
		<xsl:param name="p_producttype"/>
		<xsl:param name="p_doctype"/>
		<xsl:param name="p_lookupname"/>
		<xsl:param name="p_input"/>
		<xsl:choose>
		<xsl:when test="string-length($intPackageLookup) > 0">
			<xsl:variable name="Lookup_cpi" select="parse-xml($intPackageLookup)"/>
			<xsl:choose>
				<xsl:when test="$p_lookupname = 'QuoteRequestMatchingType'">
					<xsl:if test="string-length($Lookup_cpi/LOOKUPTABLE/Parameter[DocumentType = $p_doctype and Name = $p_lookupname and ProductType = $p_producttype]/ListOfItems/Item[Value = $p_input]/Name) &gt; 0">
						<xsl:value-of select="$Lookup_cpi/LOOKUPTABLE/Parameter[DocumentType = $p_doctype and Name = $p_lookupname and ProductType = $p_producttype]/ListOfItems/Item[Value = $p_input]/Name"/>
					</xsl:if>
				</xsl:when>
				<xsl:otherwise>
					<xsl:if test="string-length($Lookup_cpi/LOOKUPTABLE/Parameter[DocumentType = $p_doctype and Name = $p_lookupname and ProductType = $p_producttype]/ListOfItems/Item[Name = $p_input]/Value) &gt; 0">
						<xsl:value-of select="$Lookup_cpi/LOOKUPTABLE/Parameter[DocumentType = $p_doctype and Name = $p_lookupname and ProductType = $p_producttype]/ListOfItems/Item[Name = $p_input]/Value"/>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:when>
		<xsl:when test="$p_input != '' and $anLookUpFlag = 'YES'">
			<xsl:variable name="v_sysId">
				<xsl:value-of select="concat('LOOKUPTABLE', '_', $p_anERPSystemID)"/>
			</xsl:variable>
			<xsl:variable name="v_pd">
				<xsl:choose>
					<xsl:when test="$anLocalTesting ='YES'">
						<xsl:value-of
							select="'../../../common/LOOKUPTABLE.xml'"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of
							select="concat('pd', ':', $p_anSupplierANID, ':', $v_sysId, ':', 'Binary')"/>
					</xsl:otherwise>
				</xsl:choose>
				
			</xsl:variable>
			<!--calling the binary PD to get the lookup -->
			<xsl:variable name="Lookup" select="document($v_pd)"/>
			<xsl:choose>
				<xsl:when test="$p_lookupname = 'QuoteRequestMatchingType'">
					<xsl:if test="string-length($Lookup/LOOKUPTABLE/Parameter[DocumentType = $p_doctype and Name = $p_lookupname and ProductType = $p_producttype]/ListOfItems/Item[Value = $p_input]/Name) &gt; 0">
						<xsl:value-of select="$Lookup/LOOKUPTABLE/Parameter[DocumentType = $p_doctype and Name = $p_lookupname and ProductType = $p_producttype]/ListOfItems/Item[Value = $p_input]/Name"/>
					</xsl:if>
				</xsl:when>
				<xsl:otherwise>
					<xsl:if test="string-length($Lookup/LOOKUPTABLE/Parameter[DocumentType = $p_doctype and Name = $p_lookupname and ProductType = $p_producttype]/ListOfItems/Item[Name = $p_input]/Value) &gt; 0">
						<xsl:value-of select="$Lookup/LOOKUPTABLE/Parameter[DocumentType = $p_doctype and Name = $p_lookupname and ProductType = $p_producttype]/ListOfItems/Item[Name = $p_input]/Value"/>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:when>
			
			
		</xsl:choose>
	</xsl:template>
<!-- CI 2112 create S4 Date/Time to AN cXML Date/Time/Timezone Template -->
<!-- input  Date	: CCYY-MM-DD
            Time	: HH:MM:SS
            Timezone: +HH:MM
      output        : CCYY-MM-DDTHH:MM:SS+HH:MM -->
	<xsl:template name="ANDateTime_S4HANA_V1">
		<xsl:param name="p_date"/>
		<xsl:param name="p_time"/>
		<xsl:param name="p_timezone"/>
		<xsl:choose>
			<xsl:when test="string-length($p_time) &gt; 0 and string-length($p_timezone) &gt; 0">
				<xsl:variable name="v_time">
					<xsl:value-of select="$p_time"/>
				</xsl:variable>
				<xsl:value-of select="concat($p_date, 'T', $v_time, $p_timezone)"/>
			</xsl:when>
			<xsl:when test="string-length($p_time) &gt; 0 and string-length($p_timezone) = 0">
				<xsl:variable name="v_time">
					<xsl:value-of select="$p_time"/>
				</xsl:variable>
				<xsl:value-of select="concat($p_date, 'T', $v_time, '+00:00')"/>
			</xsl:when>
			<xsl:when test="string-length($p_time) = 0 and string-length($p_timezone) &gt; 0">
				<xsl:variable name="v_time">
					<xsl:value-of select="'12:00:00'"/>
				</xsl:variable>
				<xsl:value-of select="concat($p_date, 'T', $v_time, $p_timezone)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="v_time">
					<xsl:value-of select="'12:00:00'"/>
				</xsl:variable>
				<xsl:value-of select="concat($p_date, 'T', $v_time, '+00:00')"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- CI 2112 -->
	<!-- create S4 Date/Time to AN cXML Date/Time/Timezone Template -->
	<!-- input  Date	: CCYY-MM-DD
            Time	: HH:MM:SS
            Timezone: +HH:MM
      output        : CCYY-MM-DDTHH:MM:SS+HH:MM -->
	<xsl:template name="ANDateTime_S4HANA">
		<xsl:param name="p_date"/>
		<xsl:param name="p_time"/>
		<xsl:param name="p_timezone"/>
		<xsl:choose>
			<xsl:when test="string-length($p_time) &gt; 0">
				<xsl:variable name="v_time">
					<xsl:value-of select="$p_time"/>
				</xsl:variable>
				<xsl:value-of select="concat($p_date, 'T', $v_time, '+0:00')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="v_time">
					<xsl:value-of select="'12:00:00'"/>
				</xsl:variable>
				<xsl:value-of select="concat($p_date, 'T', $v_time, '+0:00')"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- AN DateTime Template -->
	<xsl:template name="ANDateTime">
		<xsl:param name="p_date"/>
		<xsl:param name="p_time"/>
		<xsl:param name="p_timezone"/>
		<xsl:if test="$p_date != ''">
			<xsl:variable name="v_yyyy">
				<xsl:value-of select="concat(substring($p_date, 1, 4), '-')"/>
			</xsl:variable>
			<xsl:variable name="v_mm">
				<xsl:value-of select="concat(substring($p_date, 5, 2), '-')"/>
			</xsl:variable>
			<xsl:variable name="v_dd">
				<xsl:value-of select="substring($p_date, 7, 2)"/>
			</xsl:variable>
			<xsl:variable name="v_date">
				<xsl:value-of select="concat($v_yyyy, $v_mm, $v_dd)"/>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="string-length($p_time) &gt; 0">
					<xsl:variable name="v_hh">
						<xsl:value-of select="concat(substring($p_time, 1, 2), ':')"/>
					</xsl:variable>
					<xsl:variable name="v_min">
						<xsl:value-of select="concat(substring($p_time, 3, 2), ':')"/>
					</xsl:variable>
					<xsl:variable name="v_ss">
						<xsl:value-of select="substring($p_time, 5, 2)"/>
					</xsl:variable>
					<xsl:variable name="v_time">
						<xsl:value-of select="concat($v_hh, $v_min, $v_ss)"/>
					</xsl:variable>
					<xsl:value-of select="concat($v_date, 'T', $v_time, $p_timezone)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:variable name="v_tim">
<!--						<xsl:value-of select="current-dateTime()"/>-->
						<xsl:value-of select="'12:00:00'"/>						
					</xsl:variable>
					<xsl:value-of
						select="concat($v_date, 'T', $v_tim, $p_timezone)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>
	<!-- S/4 HANA Date Template -->
	<xsl:template name="S4Date">
		<xsl:param name="p_date"/>
		<xsl:if test="$p_date != ''">
			<xsl:variable name="v_part1">
				<xsl:value-of select="substring-before($p_date,'/')"/>
			</xsl:variable>
			<xsl:variable name="v_mm">
				<xsl:value-of select="format-number($v_part1,'00')"/>
			</xsl:variable>
			<xsl:variable name="v_part2">
				<xsl:value-of select="substring-after($p_date,'/')"/>
			</xsl:variable>
			<xsl:variable name="v_part3">
				<xsl:value-of select="substring-before($v_part2, '/')"/>
			</xsl:variable>
			<xsl:variable name="v_dd">
				<xsl:value-of select="format-number($v_part3,'00')"/>
			</xsl:variable>
			<xsl:variable name="v_part4">
				<xsl:value-of select="substring-after($v_part2, '/')"/>
			</xsl:variable>
			<xsl:variable name="v_yyyy">
				<xsl:value-of select="format-number($v_part4,'00')"/>
			</xsl:variable>
			<xsl:value-of select="concat($v_yyyy, '-' ,$v_mm, '-' , $v_dd)"/>
		</xsl:if>
	</xsl:template>
	<!-- Outbound lang Template -->
	<xsl:template name="FillLangOut">
		<xsl:param name="p_spras_iso"/>
		<xsl:param name="p_spras"/>
		<xsl:param name="p_lang"/>
		<xsl:choose>
			<xsl:when test="string-length(normalize-space($p_spras_iso)) &gt; 0">
				<xsl:attribute name="xml:lang">
					<xsl:value-of select="$p_spras_iso"/>
				</xsl:attribute>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="string-length(normalize-space($p_spras)) &gt; 0">
						<xsl:attribute name="xml:lang">
							<xsl:value-of select="$p_spras"/>
						</xsl:attribute>
					</xsl:when>
					<xsl:otherwise>
						<xsl:attribute name="xml:lang">
							<xsl:value-of select="$p_lang"/>
						</xsl:attribute>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- ERP DateTime Template -->
	<xsl:template name="ERPDateTime">
		<xsl:param name="p_date"/>
		<xsl:param name="p_timezone"/>
		<xsl:if test="$p_date != ''">
			<!--Conver the AN date into SAP system zone-->
			<xsl:variable name="v_time">
				<xsl:choose>
					<!--If TimeZone contains '-' negative sign-->
					<xsl:when test="substring($p_timezone, 1, 1) = '-'">
						<xsl:value-of
							select="concat('-', 'PT', substring($p_timezone, 2, 2), 'H', substring($p_timezone, 5, 2), 'M')"
						/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of
							select="concat('PT', substring($p_timezone, 2, 2), 'H', substring($p_timezone, 5, 2), 'M')"
						/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="v_erpdatetimezone">
				<xsl:value-of
					select="adjust-dateTime-to-timezone($p_date, xs:dayTimeDuration($v_time))"/>
			</xsl:variable>
			<xsl:value-of select="$v_erpdatetimezone"/>
		</xsl:if>
	</xsl:template>
    <xsl:template name="MultiErpSysIdIN">
		<xsl:param name="p_ansysid"/>
		<xsl:param name="p_erpsysid"/>
		<xsl:choose>
			<xsl:when test="$p_ansysid != ''">
				<xsl:value-of select="$p_ansysid"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$p_erpsysid"/>
			</xsl:otherwise>
		</xsl:choose>	
	</xsl:template>
	<!--Prepare the CrossRef path-->
	<xsl:template name="PrepareCrossref">
		<xsl:param name="p_doctype"/>
		<xsl:param name="p_erpsysid"/>
		<xsl:param name="p_ansupplierid"/>
		<!--constructing the crossreference string-->
		<xsl:variable name="v_crossref">
			<!--<xsl:value-of select="concat('CROSSREFERENCE', '_', $p_erpsysid, '_', $p_doctype)"/>-->
			<!-- CROSSREFERENCE_SYSTEMID_DOCTYPE file name changed to CROSSREFERENCE_SYSTEMID for September Release-->
			<xsl:value-of select="concat('CROSSREFERENCE', '_', $p_erpsysid)"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$anLocalTesting ='YES'">
				<xsl:value-of
					select="'../../../common/ParameterCrossReference.xml'"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="concat('pd', ':', $p_ansupplierid, ':', $v_crossref, ':', 'Binary')"/>
			</xsl:otherwise>
		</xsl:choose>		
	</xsl:template>
	<!--    Get the Default Language -->
	<xsl:template name="FillDefaultLang">
		<xsl:param name="p_doctype"/>
		<xsl:param name="p_pd"/>
		<xsl:if test="$anCrossRefFlag = 'YES'">
			<xsl:choose>
				<xsl:when test="string-length($intPackageCrossRef)">
					<xsl:variable name="crossrefparamLookup_cpi" select="parse-xml($intPackageCrossRef)"/>
					<!-- Read Default Language from PD -->
					<xsl:value-of
						select="upper-case($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DefaultLang)"
					/>	
				</xsl:when>
				<xsl:otherwise>					
					<!--calling the binary PD to get the CROSS REF -->
					<xsl:variable name="crossrefparamLookup" select="document($p_pd)"/>
					<!-- Read Default Language from PD -->
					<xsl:value-of
						select="upper-case($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DefaultLang)"
					/>					
				</xsl:otherwise>
			</xsl:choose></xsl:if>
	</xsl:template>
	<xsl:template name="ReadQuote">
		<xsl:param name="p_doctype"/>
		<xsl:param name="p_pd"/>
		<xsl:param name="p_attribute"/>
		<xsl:choose>
		<xsl:when test="string-length($intPackageCrossRef) > 0">
			<xsl:variable name="crossrefparamLookup_cpi" select="parse-xml($intPackageCrossRef)"/>
				<xsl:choose>
				<xsl:when test="$p_attribute = 'AccountAssignmentCat'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/AccountAssignmentCategory))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/AccountAssignmentCategory"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'Asset'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/Asset))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/Asset"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'GrossPrice'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/GrossPrice))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/GrossPrice"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'ServiceGrossPrice'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/TotalPrice))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/TotalPrice"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'CostCenter'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/CostCenter))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/CostCenter"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'GLAccount'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/GLAccount))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/GLAccount"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'SubNumber'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/AssetSubNumber))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/AssetSubNumber"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'WBSElement'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/WBSElement))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/WBSElement"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'Order'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/Order))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/Order"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'SpotQuoteID'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/HeaderTextID))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/HeaderTextID"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'HeaderTextID'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/HeaderTextID))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/HeaderTextID"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'LineTextID'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/LineTextID))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/LineTextID"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'ItemCatService'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/ItemCatService))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/ItemCatService"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'ItemCatStandard'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/ItemCatStandard))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/ItemCatStandard"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'ItemCatMaterial'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/ItemCatStandard))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/ItemCatStandard"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'DeductionPercent'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DiscountPercentage))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DiscountPercentage"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'DeductionAmount'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DiscountAbs))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DiscountAbs"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'AdditionalPercent'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/SurchargePercentage))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/SurchargePercentage"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'AdditionalMoney'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/SurchargeAbs))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/SurchargeAbs"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'AdditionalAmount'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/SurchargeAbs))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/SurchargeAbs"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'SDeductionPercent'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DiscountPercentageItem))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DiscountPercentageItem"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'SDeductionAmount'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DiscountAbsItem))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DiscountAbsItem"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'SAdditionalPercent'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/AdditionalChargePercentageItem))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/AdditionalChargePercentageItem"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'SAdditionalMoney'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/AdditionalChargeAbsItem))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/AdditionalChargeAbsItem"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'ODeductionPercent'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DiscountPercentageHeader))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DiscountPercentageHeader"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'ODeductionAmount'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DiscountAbsHeader))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DiscountAbsHeader"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'OAdditionalPercent'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/AdditionalChargePercentageHeader))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/AdditionalChargePercentageHeader"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'OAdditionalMoney'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/AdditionalChargeAbsHeader))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/AdditionalChargeAbsHeader"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'grosspriceTypecode'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/grosspriceTypecode))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/grosspriceTypecode"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'servicegrosspriceTypecode'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/servicegrosspriceTypecode))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/servicegrosspriceTypecode"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'HeaderTextTypecode'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/HeaderTextTypecode))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/HeaderTextTypecode"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'ItemTextTypecode'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/ItemTextTypecode))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/ItemTextTypecode"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'ValueContract'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/ValueContract))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/ValueContract"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'QuantityContract'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/QuantityContract))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/QuantityContract"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'value'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/Value))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/Value"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'quantity'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/Quantity))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/Quantity"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'DefaultPlant'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/Plant))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/Plant"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'OneTimeVendor'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/Vendor))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/Vendor"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'DocType'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/SAPDocType))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/SAPDocType"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'ExternalServiceLineNote'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/ExternalServiceLineNote))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/ExternalServiceLineNote"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'InternalServiceLineNote'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/InternalServiceLineNote))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/InternalServiceLineNote"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'UserName'">
					<xsl:if
						test="(exists($crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/UserName))">
						<xsl:value-of
							select="$crossrefparamLookup_cpi/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/UserName"
						/>
					</xsl:if>
				</xsl:when>
			</xsl:choose>		
		</xsl:when>
		<xsl:when test="$p_doctype != '' and $p_pd != '' and $anCrossRefFlag = 'YES'">
			<!--calling the binary PD -->
			<xsl:variable name="crossrefparamLookup" select="document($p_pd)"/>
			<xsl:choose>
				<xsl:when test="$p_attribute = 'AccountAssignmentCat'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/AccountAssignmentCategory))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/AccountAssignmentCategory"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'Asset'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/Asset))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/Asset"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'GrossPrice'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/GrossPrice))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/GrossPrice"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'ServiceGrossPrice'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/TotalPrice))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/TotalPrice"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'CostCenter'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/CostCenter))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/CostCenter"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'GLAccount'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/GLAccount))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/GLAccount"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'SubNumber'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/AssetSubNumber))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/AssetSubNumber"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'WBSElement'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/WBSElement))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/WBSElement"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'Order'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/Order))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/Order"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'SpotQuoteID'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/HeaderTextID))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/HeaderTextID"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'HeaderTextID'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/HeaderTextID))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/HeaderTextID"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'LineTextID'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/LineTextID))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/LineTextID"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'ItemCatService'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/ItemCatService))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/ItemCatService"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'ItemCatStandard'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/ItemCatStandard))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/ItemCatStandard"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'ItemCatMaterial'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/ItemCatStandard))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/ItemCatStandard"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'DeductionPercent'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DiscountPercentage))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DiscountPercentage"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'DeductionAmount'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DiscountAbs))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DiscountAbs"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'AdditionalPercent'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/SurchargePercentage))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/SurchargePercentage"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'AdditionalMoney'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/SurchargeAbs))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/SurchargeAbs"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'AdditionalAmount'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/SurchargeAbs))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/SurchargeAbs"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'SDeductionPercent'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DiscountPercentageItem))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DiscountPercentageItem"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'SDeductionAmount'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DiscountAbsItem))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DiscountAbsItem"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'SAdditionalPercent'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/AdditionalChargePercentageItem))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/AdditionalChargePercentageItem"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'SAdditionalMoney'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/AdditionalChargeAbsItem))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/AdditionalChargeAbsItem"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'ODeductionPercent'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DiscountPercentageHeader))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DiscountPercentageHeader"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'ODeductionAmount'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DiscountAbsHeader))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/DiscountAbsHeader"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'OAdditionalPercent'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/AdditionalChargePercentageHeader))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/AdditionalChargePercentageHeader"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'OAdditionalMoney'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/AdditionalChargeAbsHeader))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/AdditionalChargeAbsHeader"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'grosspriceTypecode'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/grosspriceTypecode))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/grosspriceTypecode"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'servicegrosspriceTypecode'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/servicegrosspriceTypecode))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/servicegrosspriceTypecode"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'HeaderTextTypecode'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/HeaderTextTypecode))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/HeaderTextTypecode"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'ItemTextTypecode'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/ItemTextTypecode))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/ItemTextTypecode"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'ValueContract'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/ValueContract))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/ValueContract"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'QuantityContract'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/QuantityContract))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/QuantityContract"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'value'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/Value))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/Value"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'quantity'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/Quantity))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/Quantity"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'DefaultPlant'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/Plant))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/Plant"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'OneTimeVendor'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/Vendor))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/Vendor"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'DocType'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/SAPDocType))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/SAPDocType"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'ExternalServiceLineNote'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/ExternalServiceLineNote))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/ExternalServiceLineNote"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'InternalServiceLineNote'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/InternalServiceLineNote))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/InternalServiceLineNote"
						/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$p_attribute = 'UserName'">
					<xsl:if
						test="(exists($crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/UserName))">
						<xsl:value-of
							select="$crossrefparamLookup/ParameterCrossReference/ListOfItems/Item[DocumentType = $p_doctype]/UserName"
						/>
					</xsl:if>
				</xsl:when>
			</xsl:choose>
		</xsl:when>
	</xsl:choose>
	</xsl:template>
	<!--  Template Proxy to cXML Contact Address  -->
	<xsl:template name="FillContactAddress">
		<xsl:param name="p_path"/>
		<xsl:param name="p_lang"/>
		<xsl:variable name="v_empty" select="''"/>
		<Name>
			<xsl:attribute name="xml:lang">
				<xsl:choose>
					<xsl:when test="string-length(normalize-space($p_path/Address/CorrespondenceLanguage))">
						<xsl:value-of select="$p_path/Address/CorrespondenceLanguage"/>
					</xsl:when>
					<!-- Begin of CI-2921 XSLT Enhancement -->
					<xsl:when test="string-length(normalize-space($p_lang)) > 0">
						<xsl:value-of select="$p_lang"/>
					</xsl:when>
					<!-- End of CI-2921 XSLT Enhancement -->
					<xsl:otherwise>
						<xsl:value-of select="$v_empty"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<!-- Begin of CI-2921 XSLT Enhancement -->
			<xsl:value-of select="concat($p_path/Address/AddressName,$p_path/Address/AddressAdditionalName)"/>
			<!-- End of CI-2921 XSLT Enhancement -->
		</Name>
		<xsl:if test="$p_path/Address">
			<PostalAddress>
				<Street>
					<xsl:choose>
						<xsl:when
							test="string-length(normalize-space($p_path/Address/StreetAddressName)) > 0">
							<xsl:value-of select="$p_path/Address/StreetAddressName"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:choose>
								<xsl:when test="$p_path/Address/Country = 'DE'">
									<xsl:value-of
										select="concat($p_path/Address/StreetName, ' ', $p_path/Address/HouseNumber)"
									/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of
										select="concat($p_path/Address/HouseNumber, ' ', $p_path/Address/StreetName)"
									/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:otherwise>
					</xsl:choose>
				</Street>
				<City>
					<xsl:value-of select="$p_path/Address/CityName"/>
				</City>
					<xsl:if test="string-length(normalize-space($p_path/Address/Region)) > 0">
						<State>
							<xsl:value-of select="$p_path/Address/Region"/>
						</State>
					</xsl:if>
					<xsl:if test="string-length(normalize-space($p_path/Address/PostalCode)) > 0">
						<PostalCode>
							<xsl:value-of select="$p_path/Address/PostalCode"/>
						</PostalCode>
					</xsl:if>
				<Country>
					<xsl:attribute name="isoCountryCode">
						<xsl:value-of select="$p_path/Address/Country"/>
					</xsl:attribute>
				</Country>
			</PostalAddress>
		</xsl:if>
		<xsl:if test="$p_path/Address/EmailAddress">
			<Email>
				<xsl:value-of select="$p_path/Address/EmailAddress"/>
			</Email>
		</xsl:if>
		<xsl:if test="$p_path/Address/PhoneNumber">
			<Phone>
				<TelephoneNumber>
					<CountryCode>
						<xsl:attribute name="isoCountryCode">
							<xsl:value-of select="$p_path/Address/Country"/>
					</xsl:attribute>
					</CountryCode>
					<AreaOrCityCode/>
					<Number>
						<xsl:value-of select="$p_path/Address/PhoneNumber"/>
					</Number>
				</TelephoneNumber>
			</Phone>
		</xsl:if>
		<xsl:if test="$p_path/Address/FaxNumber">
			<Fax>
				<TelephoneNumber>
					<CountryCode>
						<xsl:attribute name="isoCountryCode">
							<xsl:value-of select="$p_path/Address/Country"/>
						</xsl:attribute>
					</CountryCode>
					<AreaOrCityCode/>
					<Number>
						<xsl:value-of select="$p_path/Address/FaxNumber"/>
					</Number>
				</TelephoneNumber>
			</Fax>
		</xsl:if>
		<!-- Begin of CI-2921 XSLT Enhancement -->
		<xsl:choose>
			<xsl:when test="string-length(normalize-space($p_path/SupplierPartyID)) > 0">
				<!-- Create IdReference for buyerID only if SupplierID is present  -->
				<xsl:if test="string-length(normalize-space($p_path/BuyerPartyID)) > 0">
					<IdReference>
						<xsl:attribute name="domain">
							<xsl:value-of select="'buyerID'"/>
						</xsl:attribute>
						<xsl:attribute name="identifier">
							<xsl:value-of select="$p_path/BuyerPartyID"/>
						</xsl:attribute>
					</IdReference>
				</xsl:if>
				<!-- Create IdReference for GlobalLocationNumber only if BuyerID or SupplierID either is present -->
				<xsl:if test="string-length(normalize-space($p_path/GlobalLocationNumber)) > 0">
					<IdReference>
						<xsl:attribute name="domain">
							<xsl:value-of select="'ILN'"/>
						</xsl:attribute>
						<xsl:attribute name="identifier">
							<xsl:value-of select="$p_path/GlobalLocationNumber"/>
						</xsl:attribute>
					</IdReference>
				</xsl:if>
			</xsl:when>
			<xsl:when test="string-length(normalize-space($p_path/BuyerPartyID)) > 0">
				<!-- Create IdReference for GlobalLocationNumber only if BuyerID or SupplierID either is present -->
				<xsl:if test="string-length(normalize-space($p_path/GlobalLocationNumber)) > 0">
					<IdReference>
						<xsl:attribute name="domain">
							<xsl:value-of select="'ILN'"/>
						</xsl:attribute>
						<xsl:attribute name="identifier">
							<xsl:value-of select="$p_path/GlobalLocationNumber"/>
						</xsl:attribute>
					</IdReference>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise/>
		</xsl:choose>
		<!-- End of CI-2921 XSLT Enhancement -->
	</xsl:template>
	<!-- Please use only for OrderRequest-->
	<!-- Template definition soap to cXML starts from here-->
	<xsl:template name="FillPartyAddress">
		<xsl:param name="p_path"/>
		<xsl:param name="p_lang"/>
		<xsl:variable name="v_empty" select="''"/>              	
		<xsl:if test="string-length(normalize-space($p_path/Address/Country)) > 0">
			<xsl:if test="($p_path/@PartyType = 'BillTo') or ($p_path/@PartyType = 'ShipTo') or ($p_path/@PartyType = 'SoldTo')">
				<xsl:attribute name="isoCountryCode">
					<xsl:value-of select="$p_path/Address/Country"/>
				</xsl:attribute>
			</xsl:if>
		</xsl:if>
			<xsl:attribute name="addressID">
				<xsl:value-of select="$p_path/BuyerPartyID"/>
			</xsl:attribute>
			<xsl:if  test="($p_path/@PartyType = 'ShipTo')">
				<xsl:attribute name="addressIDDomain">buyerLocationIDDomain</xsl:attribute>
			</xsl:if>
			<xsl:if  test="($p_path/@PartyType = 'SoldTo')">
				<xsl:attribute name="addressIDDomain">buyerAccountID</xsl:attribute>
			</xsl:if>
			<!-- Begin of changes CI - 2313 | Field parity -->
			<xsl:if test="($p_path/@PartyType = 'BillTo')">
				<xsl:attribute name="addressIDDomain">supplierID</xsl:attribute>
			</xsl:if>
			<!-- End of changes CI - 2313 | Field parity -->		
			<Name>
				<xsl:call-template name="FillLangOut">
					<xsl:with-param name="p_spras_iso" select="$v_empty"/>
					<xsl:with-param name="p_spras"
						select="$p_path/Address/CorrespondenceLanguage"/>
					<xsl:with-param name="p_lang" select="$p_lang"/>
				</xsl:call-template>
				<xsl:if test="($p_path/@PartyType = 'BillTo')">
					<xsl:value-of select="$p_path/Address/AddressAdditionalName"/>   
				</xsl:if>
				<xsl:if test="($p_path/@PartyType != 'BillTo')">
					<xsl:value-of select="$p_path/Address/AddressName"/> 
				</xsl:if>
			</Name>
			<PostalAddress>
				<Street>
					<xsl:choose>
						<xsl:when test="string-length(normalize-space($p_path/Address/StreetAddressName)) > 0">
							<xsl:value-of select="$p_path/Address/StreetAddressName"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:choose>
								<xsl:when test="$p_path/Address/Country = 'DE'">
									<xsl:value-of
										select="concat($p_path/Address/StreetName, ' ', $p_path/Address/HouseNumber)"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of
										select="concat($p_path/Address/HouseNumber, ' ', $p_path/Address/StreetName)"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:otherwise>   
					</xsl:choose>
				</Street>
				<City>
					<xsl:value-of select="$p_path/Address/CityName"/>
				</City>
				<xsl:if test="($p_path/@PartyType = 'BillTo')">
				<Municipality>
					<xsl:value-of select="$v_empty"/>
			       </Municipality>
				</xsl:if>
				<!-- Begin of changes CI - 2313 | Field parity -->				
				<xsl:if test="($p_path/@PartyType = 'ShipTo') and string-length(normalize-space($p_path/Address/CityName)) > 0">
					<Municipality>
						<xsl:value-of select="$p_path/Address/CityName"/>
					</Municipality>
				</xsl:if>	
				<xsl:if
					test="($p_path/@PartyType = 'SoldTo') and string-length(normalize-space($p_path/Address/CityName)) > 0">
					<Municipality>
						<xsl:value-of select="$p_path/Address/CityName"/>
					</Municipality>
				</xsl:if>
				<!-- End of changes CI - 2313 | Field parity -->				
				<xsl:if test="string-length(normalize-space($p_path/Address/Region)) > 0">
					<State>
						<xsl:value-of select="$p_path/Address/Region"/>
					</State>
				</xsl:if>
				<xsl:if test="string-length(normalize-space($p_path/Address/PostalCode)) > 0">
					<PostalCode>
						<xsl:value-of select="$p_path/Address/PostalCode"/>
					</PostalCode>
				</xsl:if>
				<Country>
					<xsl:attribute name="isoCountryCode">
						<xsl:value-of
							select="$p_path/Address/Country"/>
					</xsl:attribute>
					<xsl:value-of select="$p_path/Address/Country"/>
				</Country>
			</PostalAddress>
		<xsl:if test="string-length(normalize-space($p_path/Address/EmailAddress)) > 0">
			<Email>
				<xsl:attribute name="name">
					<xsl:value-of select="'default'"/>
				</xsl:attribute>
				<!-- Begin of changes CI - 2313 | Field parity -->
				<xsl:if
					test="string-length(normalize-space($p_path/Address/CorrespondenceLanguage)) > 0">
					<xsl:attribute name="preferredLang">
						<xsl:value-of select="lower-case($p_path/Address/CorrespondenceLanguage)"/>
					</xsl:attribute>
				</xsl:if>
				<!-- End of changes CI - 2313 | Field parity -->				
				<xsl:value-of select="$p_path/Address/EmailAddress"/>
			</Email>
		</xsl:if>
		<xsl:if test="string-length(normalize-space($p_path/Address/PhoneNumber)) > 0">
			<Phone>
				<TelephoneNumber>
					<CountryCode>
						<xsl:attribute name="isoCountryCode">
							<xsl:value-of select="$p_path/Address/Country"/>
						</xsl:attribute>
						</CountryCode>
						<AreaOrCityCode/>
							<Number>
								<xsl:value-of select="$p_path/Address/PhoneNumber"/>
							</Number>
					</TelephoneNumber>
				</Phone>
		</xsl:if>                                 
		<xsl:if test="string-length(normalize-space($p_path/Address/FaxNumber)) > 0 or string-length(normalize-space($p_path/Address/FaxDetails/Number)) > 0">
			<Fax>
				<TelephoneNumber>
					<CountryCode>
						<xsl:attribute name="isoCountryCode">
							<xsl:choose>
								<xsl:when test="string-length(normalize-space($p_path/Address/FaxDetails/TelephoneCountryPrefix/@CountryCode)) > 0">
									<xsl:value-of select="$p_path/Address/FaxDetails/TelephoneCountryPrefix/@CountryCode"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$p_path/Address/Country"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
						<xsl:value-of select="$p_path/Address/FaxCountryDialingCode"/>
						</CountryCode>
						<AreaOrCityCode/>
							<Number>
								<xsl:choose>
									<xsl:when test="string-length(normalize-space($p_path/Address/FaxDetails/Number)) > 0">
										<xsl:value-of select="$p_path/Address/FaxDetails/Number"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="$p_path/Address/FaxNumber"/>
									</xsl:otherwise>
								</xsl:choose>
							</Number>
					<xsl:if test="string-length(normalize-space($p_path//Address/FaxExtension)) > 0">
						<Extension>
							<xsl:value-of select="$p_path/Address/FaxExtension"/> 
						</Extension>
					</xsl:if>
					</TelephoneNumber>
				</Fax>
			</xsl:if> 	
	</xsl:template>   
	<xsl:template name="OutboundS4Attachment">
		<xsl:param name="HeaderAttachment"/>
		<xsl:for-each select="$HeaderAttachment">
			<Attachment>
				<URL>
					<xsl:value-of
						select="normalize-space(*[namespace-uri() = 'http://www.w3.org/2004/08/xop/include' and local-name() = 'Include']/@href)"
					/>
				</URL>
			</Attachment>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="InboundS4Attachment">
		<xsl:param name="AttachmentList" /> 
		<xsl:variable name="newlist" select="concat(normalize-space($AttachmentList), '')" /> 
		<xsl:variable name="first" select="substring-before($newlist, '|')" /> 
		<xsl:variable name="remaining" select="substring-after($newlist, '|')" />   
		<Attachment><xsl:variable name="tokenizedSample" select="tokenize($first,';')"/><xsl:attribute name="FileName"><xsl:value-of select="$tokenizedSample[2]"/></xsl:attribute><xsl:attribute name="MimeType"><xsl:value-of select="$tokenizedSample[3]"/></xsl:attribute><xsl:attribute name="FileSize"><xsl:value-of select="$tokenizedSample[4]"/></xsl:attribute><xop:Include><xsl:attribute name="href"><xsl:value-of select="$tokenizedSample[1]"/></xsl:attribute><xsl:value-of select="namespace-uri(xop)"/></xop:Include></Attachment>
		<xsl:if test="$remaining">
			<xsl:call-template name="InboundS4Attachment">
				<xsl:with-param name="AttachmentList" select="$remaining" /> 
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	<!-- Template Lookup Tax type category -->
	<xsl:template name="TaxType">
		<xsl:param name="p_category"/>
		<xsl:choose>
			<!--Sales Tax -->
			<xsl:when test="lower-case($p_category) = &quot;sales&quot;">
				<xsl:value-of select="'SAL'"/>
			</xsl:when>
			<!-- Usage-->
			<xsl:when test="lower-case($p_category) = &quot;usage&quot;">
				<xsl:value-of select="'USE'"/>
			</xsl:when>
			<!-- GST-->
			<xsl:when test="lower-case($p_category) = &quot;gst&quot;">
				<xsl:value-of select="'GST'"/>
			</xsl:when>
			<!--HST-->
			<xsl:when test="lower-case($p_category) = &quot;hst&quot;">
				<xsl:value-of select="'HST'"/>
			</xsl:when>
			<!--PST-->
			<xsl:when test="lower-case($p_category) = &quot;pst&quot;">
				<xsl:value-of select="'PST'"/>
			</xsl:when>
			<!-- QST-->
			<xsl:when test="lower-case($p_category) = &quot;qst&quot;">
				<xsl:value-of select="'QST'"/>
			</xsl:when>
			<!--VAT-->
			<xsl:when test="lower-case($p_category) = &quot;vat&quot;">
				<xsl:value-of select="'VAT'"/>
			</xsl:when>
			<!--Others-->
			<xsl:otherwise>
				<xsl:value-of select="upper-case($p_category)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- Please use this template only for 4A1 scenarios -->
	<!-- Template definition cXML to soap -->
	<xsl:template name="FillParty">
		<xsl:param name="p_path"/>
		<xsl:param name="p_anAlternativeSender"/>
		<!-- Begin of CI-2921 XSLT Enhancement -->
		<!-- Global Location Number -->
		<xsl:if test="exists($p_path/IdReference[@domain='ILN'])">
			<GlobalLocationNumber>                      
				<!-- Start SBNI-480 | ENGG SBNI-482 -->
				<!-- Length restriction for target's schema limitations. If not stated otherwise, this comment applies to other changes with this ID -->
				<xsl:value-of select="substring(normalize-space($p_path/IdReference[@domain='ILN']/@identifier), 1, 13)"/>
				<!-- End SBNI-480 | ENGG SBNI-482 -->
			</GlobalLocationNumber>
		</xsl:if>
		<xsl:choose>
			<xsl:when test="exists($p_path/Address/@addressID)">
				<BuyerPartyID>
					<!-- Start SBNI-480 | ENGG SBNI-482 -->
					<xsl:value-of select="substring(normalize-space($p_path/Address/@addressID), 1, 60)"/>
					<!-- End SBNI-480 | ENGG SBNI-482 -->
				</BuyerPartyID>
			</xsl:when>
			<xsl:when test="exists($p_path/@addressID)">
				<BuyerPartyID>
					<!-- Start SBNI-480 | ENGG SBNI-482 -->
					<xsl:value-of select="substring(normalize-space($p_path/@addressID), 1, 60)"/>
					<!-- End SBNI-480 | ENGG SBNI-482 -->
				</BuyerPartyID>
			</xsl:when>
			<xsl:otherwise>
				<BuyerPartyID/>
			</xsl:otherwise>
		</xsl:choose>
		<!-- End of CI-2921 XSLT Enhancement -->
		<xsl:if test="not(starts-with($p_anAlternativeSender , 'AN'))">
		<xsl:if test="($p_path/IdReference[@domain='supplierID']/@identifier) or $p_anAlternativeSender ">
			<SupplierPartyID>                        
				<!-- Begin of CI-2921 XSLT Enhancement -->
				<!-- Update supplier part ID for all roles -->
				<!-- Start SBNI-85 | ENGG SBNI-487 -->
				<!-- Begin of SBNI-85 to fix the SupplierPartyID in SoldTo -->
				<xsl:choose>
					<xsl:when test="exists($p_path/IdReference[@domain='supplierID'])">
						<!-- Start SBNI-480 | ENGG SBNI-482 -->
						<xsl:value-of select="substring(normalize-space($p_path/IdReference[@domain='supplierID']/@identifier), 1, 60)"/>
						<!-- End SBNI-480 | ENGG SBNI-482 -->
					</xsl:when>
					<xsl:otherwise>
						<!-- Start SBNI-480 | ENGG SBNI-482 -->
						<xsl:value-of select="substring(normalize-space($p_anAlternativeSender), 1, 60)"/>
						<!-- End SBNI-480 | ENGG SBNI-482 -->
					</xsl:otherwise>
				</xsl:choose>
				<!-- End of SBNI-85 to fix the SupplierPartyID in SoldTo -->
				<!-- End SBNI-85 | ENGG SBNI-487 -->
				<!-- End of CI-2921 XSLT Enhancement -->
			</SupplierPartyID>
		</xsl:if>
		</xsl:if>
		<xsl:if test="string-length($p_path/Address/PostalAddress) > 0 or string-length($p_path/Address/Phone) > 0">
			<Address>
				<xsl:if test="string-length($p_path/Address/Name) > 0">
					<!-- Begin of CI-2921 XSLT Enhancement -->
					<!-- Pass only first 40 chracters into Address Name then next 80 characters into Address Additional Name-->
					<AddressName>
						<xsl:value-of select="substring($p_path/Address/Name,1,40)"/>
					</AddressName>
					<!-- Start SBNI-480 | ENGG SBNI-482 -->
					<!-- New condition to create AddressAdditionalName -->
					<xsl:if test="string-length($p_path/Address/Name) > 40">
					<AddressAdditionalName>
						<xsl:value-of select="substring($p_path/Address/Name,41,80)"/>
					</AddressAdditionalName>
					</xsl:if>
					<!-- End SBNI-480 | ENGG SBNI-482 -->
					<!-- End of CI-2921 XSLT Enhancement --> 
				</xsl:if>  
				<!--IG-41205 Begin : When multiple Street elements exists in input, consider only the first occurance-->
				<xsl:if test="string-length($p_path/Address/PostalAddress/Street[1]) > 0">
					<!-- Begin of CI-2921 XSLT Enhancement -->
					<!-- Read all the Street tags in postal address and contacte them -->
					<xsl:variable name="p_street">
						<xsl:for-each select="$p_path/Address/PostalAddress/Street">
							<xsl:value-of select="./text()"/>
						</xsl:for-each>
					</xsl:variable>
					<StreetAddressName>
						<xsl:value-of select="substring($p_street,1,60)"/>
					</StreetAddressName>
					<!-- End of CI-2921 XSLT Enhancement -->
				</xsl:if>
				<!--IG-41205 End-->
				<xsl:if test="string-length($p_path/Address/PostalAddress/PostalCode) > 0">
					<PostalCode>
						<!-- Start SBNI-480 | ENGG SBNI-482 -->
						<xsl:value-of select="substring(normalize-space($p_path/Address/PostalAddress/PostalCode), 1, 10)"/>
						<!-- End SBNI-480 | ENGG SBNI-482 -->
					</PostalCode>
				</xsl:if>
				<CityName>
					<!-- Start SBNI-480 | ENGG SBNI-482 -->
					<xsl:value-of select="substring(normalize-space($p_path/Address/PostalAddress/City), 1, 40)"/>
					<!-- End SBNI-480 | ENGG SBNI-482 -->
				</CityName>
				<Country>
					<xsl:value-of select="$p_path/Address/PostalAddress/Country/@isoCountryCode"/>
				</Country>
				<xsl:if test="string-length($p_path/Address/PostalAddress/State) > 0">
					<Region>
						<!-- Start of IG-40107 Restrict REGION to 6 chracters as per the S4HANA field length -->
						<xsl:value-of select="substring($p_path/Address/PostalAddress/State,1,6)"/>
						<!-- End of IG-40107 -->
					</Region>                        
				</xsl:if>
				<xsl:if test="string-length($p_path/Address/Phone/TelephoneNumber/Number) > 0">
					<PhoneNumber>
						<!-- Start SBNI-480 | ENGG SBNI-482 -->
						<xsl:value-of select="substring(normalize-space($p_path/Address/Phone/TelephoneNumber/Number), 1, 30)"/>
						<!-- End SBNI-480 | ENGG SBNI-482 -->
					</PhoneNumber>
				</xsl:if>
				<xsl:if test="string-length($p_path/Address/Fax/TelephoneNumber/Number) > 0">
					<FaxNumber>
						<!-- Start SBNI-480 | ENGG SBNI-482 -->
						<xsl:value-of select="substring(normalize-space($p_path/Address/Fax/TelephoneNumber/Number), 1, 30)"/>
						<!-- End SBNI-480 | ENGG SBNI-482 -->
					</FaxNumber>
				</xsl:if>
				<xsl:if test="string-length($p_path/Address/Email) > 0">
					<EmailAddress>
						<!-- Start SBNI-480 | ENGG SBNI-482 -->
						<xsl:value-of select="substring(normalize-space($p_path/Address/Email), 1, 241)"/>
						<!-- End SBNI-480 | ENGG SBNI-482 -->
					</EmailAddress>
				</xsl:if>
				<xsl:if test="string-length($p_path/Address/Name/@xml:lang) > 0">
					<CorrespondenceLanguage>
						<xsl:value-of select="$p_path/Address/Name/@xml:lang"/>
					</CorrespondenceLanguage>
				</xsl:if>
				<!-- IG-21136 map constant flag A -->
				<ExternalAddressParserCode>A</ExternalAddressParserCode>
				<!-- IG-21136 -->
			</Address>
		</xsl:if>        
		<!-- Begin of CI-2921 XSLT Enhancement -->
		<!-- In some roles Address tag is not there to follow below code to populate address,telephone, fax and email -->
		<!-- Start SBNI-1781 -->
		<!-- Change to match 4A1 SOAP schema. Map only from the 1st occurence of PostalAddress, Phone, Fax, Email -->
		<xsl:if test="string-length($p_path/PostalAddress[1]) > 0 or string-length($p_path/Phone[1]) > 0">
			<Address>
				<xsl:if test="string-length($p_path/Name) > 0">
					<AddressName>
						<xsl:value-of select="substring($p_path/Name,1,40)"/>
					</AddressName>
					<!-- Start SBNI-480 | ENGG SBNI-482 -->
					<!-- New condition to create AddressAdditionalName -->
					<xsl:if test="string-length($p_path/Name) > 40">
						<AddressAdditionalName>
							<xsl:value-of select="substring($p_path/Name,41,80)"/>
						</AddressAdditionalName>
					</xsl:if>
					<!-- End SBNI-480 | ENGG SBNI-482 -->					
				</xsl:if>
				<xsl:if test="string-length($p_path/PostalAddress[1]/Street[1]) > 0">
					<xsl:variable name="p_street1">
						<xsl:for-each select="$p_path/PostalAddress[1]/Street">
							<xsl:value-of select="./text()"/>
						</xsl:for-each>
					</xsl:variable>
					<StreetAddressName>
						<xsl:value-of select="substring($p_street1,1,60)"/>
					</StreetAddressName>
				</xsl:if>
				<xsl:if test="string-length($p_path/PostalAddress[1]/PostalCode) > 0">
					<PostalCode>
						<!-- Start SBNI-480 | ENGG SBNI-482 -->
						<xsl:value-of select="substring(normalize-space($p_path/PostalAddress[1]/PostalCode), 1, 10)"/>
						<!-- End SBNI-480 | ENGG SBNI-482 -->
					</PostalCode>
				</xsl:if>
				<CityName>
					<!-- Start SBNI-480 | ENGG SBNI-482 -->
					<xsl:value-of select="substring(normalize-space($p_path/PostalAddress[1]/City), 1, 40)"/>
					<!-- End SBNI-480 | ENGG SBNI-482 -->
				</CityName>
				<Country>
					<xsl:value-of select="$p_path/PostalAddress[1]/Country/@isoCountryCode"/>
				</Country>
				<xsl:if test="string-length($p_path/PostalAddress[1]/State) > 0">
					<Region>
						<xsl:value-of select="substring($p_path/PostalAddress[1]/State,1,6)"/>
					</Region>                        
				</xsl:if>
				<xsl:if test="string-length($p_path/Phone[1]/TelephoneNumber/Number) > 0">
					<PhoneNumber>
						<!-- Start SBNI-480 | ENGG SBNI-482 -->
						<xsl:value-of select="substring(normalize-space($p_path/Phone[1]/TelephoneNumber/Number), 1, 30)"/>
						<!-- End SBNI-480 | ENGG SBNI-482 -->
					</PhoneNumber>
				</xsl:if>
				<xsl:if test="string-length($p_path/Fax[1]/TelephoneNumber/Number) > 0">
					<FaxNumber>
						<!-- Start SBNI-480 | ENGG SBNI-482 -->
						<xsl:value-of select="substring(normalize-space($p_path/Fax[1]/TelephoneNumber/Number), 1, 30)"/>
						<!-- End SBNI-480 | ENGG SBNI-482 -->
					</FaxNumber>
				</xsl:if>
				<xsl:if test="string-length($p_path/Email[1]) > 0">
					<EmailAddress>
						<!-- Start SBNI-480 | ENGG SBNI-482 -->
						<xsl:value-of select="substring(normalize-space($p_path/Email[1]), 1, 241)"/>
						<!-- End SBNI-480 | ENGG SBNI-482 -->						
					</EmailAddress>
				</xsl:if>
				<xsl:if test="string-length($p_path/Name/@xml:lang) > 0">
					<CorrespondenceLanguage>
						<xsl:value-of select="$p_path/Name/@xml:lang"/>
					</CorrespondenceLanguage>
				</xsl:if>
				<ExternalAddressParserCode>A</ExternalAddressParserCode>
			</Address>
		</xsl:if>
		<!-- End SBNI-1781 -->
		<!-- End of CI-2921 XSLT Enhancement -->
	</xsl:template>
	<!-- IG-31370 -->
	<!-- create S4 Date/Time to AN cXML Date/Time/Timezone Template For MRP -->	
	<xsl:template name="ANDateTime_S4HANA_MRP">
		<xsl:param name="p_date"/>
		<xsl:param name="p_time"/>
		<xsl:param name="p_timezone"/>
		<xsl:choose>
			<xsl:when test="string-length($p_time) &gt; 0">
				<xsl:variable name="v_time">
					<xsl:value-of select="$p_time"/>
				</xsl:variable>
				<xsl:value-of select="concat($p_date, 'T', $v_time, '+00:00')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="v_time">
					<xsl:value-of select="'12:00:00'"/>
				</xsl:variable>
				<xsl:value-of select="concat($p_date, 'T', $v_time, '+00:00')"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- IG-31370 -->
	<!-- IG-31370 -->
	<!-- create S4 Date/Time to AN cXML Date/Time/Timezone Template For MRP Addon-->	
<!--	IG-31598-->
	<xsl:template name="ANDateTime_S4HANA_MRP_Addon">
		<xsl:param name="p_date"/>
		<xsl:param name="p_time"/>
		<xsl:param name="p_timezone"/>
		<xsl:variable name="v_time">
			<xsl:choose>
				<xsl:when test="string-length($p_time) &gt; 0">
					<xsl:value-of select="$p_time"/>	
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="'12:00:00'"/>
				</xsl:otherwise>				
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="string-length($p_timezone) &gt; 0">
				<xsl:value-of select="concat($p_date, 'T', $v_time, $p_timezone)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="concat($p_date, 'T', $v_time, '+00:00')"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- IG-31370 -->
</xsl:stylesheet>