<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:marc="http://www.loc.gov/MARC21/slim"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	
	<xsl:param name="bibid" select="//marc:controlfield[@tag='001']"/>

	<xsl:output method="xml" omit-xml-declaration="no" indent="yes" encoding="utf-8"
		media-type="text/xml"/>

<!--If there are two 856s, then remove the second 856 and write out the existing file-->
<!--Write out a second file, removing the first 856, and renaming the file with an "a" at the end of the filename and in the 001$a-->
<!--If there is a 246 that reads, "marc:subfield code="i" "Title on poster verso:</marc:subfield>", then use that for the 245 in the second file. AND
 Use the 245 as the 246 with "marc:subfield code="i" "Title on poster recto:" in the second file and remove 246.-->

	<xsl:template match="/">
		<xsl:if test="//marc:datafield[@tag='856'][2]">
			<xsl:result-document href="{$bibid}.xml" method="xml">
				<xsl:apply-templates mode="recto"/>
			</xsl:result-document>
			<xsl:result-document href="{$bibid}a.xml" method="xml">
				<xsl:apply-templates mode="verso"/>
			</xsl:result-document>
		</xsl:if>
	</xsl:template>		

	<xsl:template match="@*|node()" priority="-1" mode="recto">
		<xsl:if test="//marc:datafield[@tag='856'][2]">
			<xsl:copy>
			  <xsl:apply-templates select="@*|node()" mode="recto"/>
			</xsl:copy>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="@*|node()" priority="-1" mode="verso">
		<xsl:if test="//marc:datafield[@tag='856'][2]">
			<xsl:copy>
			  <xsl:apply-templates select="@*|node()" mode="verso"/>
			</xsl:copy>
		</xsl:if>
	</xsl:template>
  
	<xsl:template match="marc:datafield[@tag='856'][2]" mode="recto"/>
	<xsl:template match="marc:datafield[@tag='856'][1]" mode="verso"/>
	
	<xsl:template match="marc:datafield[@tag='245']" mode="verso">
		<xsl:choose>
			<!--If the 246 contains the verso title, swap the 245 & the 246-->
			<xsl:when test="//marc:datafield[@tag='246']/marc:subfield[@code='i']='Title on poster verso:'">
				<xsl:element name="marc:datafield">
					<xsl:attribute name="tag">245</xsl:attribute>
					<xsl:attribute name="ind1"><xsl:value-of select="@ind1"/></xsl:attribute>
					<xsl:attribute name="ind2">0</xsl:attribute>
					<xsl:element name="marc:subfield">
						 <xsl:attribute name="code">a</xsl:attribute>
							<xsl:value-of select="../marc:datafield[@tag='246']/marc:subfield[@code='a']"/>
					</xsl:element>
				</xsl:element>	
				<xsl:element name="marc:datafield">
					<xsl:attribute name="tag">246</xsl:attribute>
					<xsl:attribute name="ind1">1</xsl:attribute>
					<xsl:attribute name="ind2">2</xsl:attribute>
					<xsl:element name="marc:subfield">
						 <xsl:attribute name="code">i</xsl:attribute>
							<xsl:text>Title on poster recto:</xsl:text>	
					</xsl:element>
					<xsl:element name="marc:subfield">
						 <xsl:attribute name="code">a</xsl:attribute>
							<xsl:value-of select="marc:subfield[@code='a']"/>	
					</xsl:element>
					<xsl:if test="marc:subfield[@code='b']">
						<xsl:element name="marc:subfield">
							 <xsl:attribute name="code">b</xsl:attribute>
								<xsl:value-of select="marc:subfield[@code='b']"/>	
						</xsl:element>
					</xsl:if>
				</xsl:element>				
			</xsl:when>
			<!--Otherwise, just stick a $p with text "Verso." after the title.-->
			<xsl:otherwise>
				<xsl:element name="marc:datafield">
						<xsl:attribute name="tag">245</xsl:attribute>
						<xsl:attribute name="ind1"><xsl:value-of select="@ind1"/></xsl:attribute>
						<xsl:attribute name="ind2"><xsl:value-of select="@ind2"/></xsl:attribute>
						<xsl:element name="marc:subfield">
							 <xsl:attribute name="code">a</xsl:attribute>
								<xsl:value-of select="marc:subfield[@code='a']"/>	
						</xsl:element>
						<xsl:if test="marc:subfield[@code='b']">
							<xsl:element name="marc:subfield">
								 <xsl:attribute name="code">b</xsl:attribute>
									<xsl:value-of select="marc:subfield[@code='b']"/>	
							</xsl:element>
						</xsl:if>
						<xsl:element name="marc:subfield">
							<xsl:attribute name="code">p</xsl:attribute>
							<xsl:text>Verso.</xsl:text>
						</xsl:element>	
						<xsl:if test="marc:subfield[@code='c']">
							<xsl:element name="marc:subfield">
								 <xsl:attribute name="code">c</xsl:attribute>
									<xsl:value-of select="marc:subfield[@code='c']"/>	
							</xsl:element>
						</xsl:if>
					</xsl:element>
				</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

		<!--Note that this should only get called for the "B-Side" record, in the first choose condition for title processing-->
	<xsl:template match="marc:datafield[marc:subfield[.='Title on poster verso:']]" mode="verso"/>
	
	<xsl:template match="marc:controlfield[@tag='001']" mode="verso">
		<xsl:element name="marc:controlfield">
			<xsl:attribute name="tag">001</xsl:attribute>
			<xsl:value-of select="."/><xsl:text>a</xsl:text>
		</xsl:element>
	</xsl:template>
	
		
</xsl:stylesheet>