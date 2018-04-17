<?xml version="1.0" encoding="UTF-8"?>
<!--
     Case Tracker Reference

     Creator: Stéphane Sire <s.sire@opppidoc.fr>

     With saxon use -strip:all to remove whitespaces, ex :

     saxon -strip:all -s:persons/persons.xml -xsl:/usr/local/platinn/ctracker22/lib/webapp/platinn/ctracker/migrations/persons.xsl -o:persons.xml

     Migration of legacy coaching Platinn persons.xml resource file
  -->
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  >

  <xsl:output method="xml" media-type="text/xml" omit-xml-declaration="yes" indent="yes"/>

  <xsl:template match="/Persons">
    <Persons>
      <xsl:apply-templates select="Person"/>
    </Persons>
  </xsl:template>

  <xsl:template match="Person">
    <Person>
      <xsl:apply-templates select="Id"/>
      <Information>
        <xsl:apply-templates select="*[local-name() != 'Id' and local-name() != 'UserProfile']"/>
      </Information>
      <xsl:apply-templates select="UserProfile"/>
    </Person>
  </xsl:template>

  <xsl:template match="UserProfile">
    <UserProfile>
      <xsl:copy-of select="Username"/>
      <xsl:copy-of select="Roles"/>
      <xsl:apply-templates select="AdministrativeEntity"/>
      <xsl:apply-templates select="CollaborativeEntity"/>
    </UserProfile>
  </xsl:template>

  <!-- TODO: convert CollaborativeEntity to CollaborativeEntityRef -->
  <xsl:template match="AdministrativeEntity[. != '']">
    <AdministrativeEntityRef>
      <xsl:call-template name="entities"/>
    </AdministrativeEntityRef>
  </xsl:template>

  <xsl:template match="AdministrativeEntity[. = '']">
  </xsl:template>

  <!-- TODO: convert CollaborativeEntity to CollaborativeEntityRef -->
  <xsl:template match="CollaborativeEntity[. != '']">
    <CollaborativeEntityRef>
      <xsl:call-template name="entities"/>
    </CollaborativeEntityRef>
  </xsl:template>

  <xsl:template match="CollaborativeEntity[. = '']">
  </xsl:template>

  <xsl:template match="EnterpriseRef">
    <EnterpriseKey><xsl:value-of select="."/></EnterpriseKey>
  </xsl:template>
  
  <!-- Also used in case.xsl migration -->
  <xsl:template name="entities">
    <xsl:variable name="apos">A</xsl:variable>
    <xsl:choose>
      <xsl:when test="upper-case(.) = 'ASSOCIATION PLATINN'">1</xsl:when>
      <xsl:when test="upper-case(.) = 'ADMINISTRATION PLATINN'">1</xsl:when>
      <xsl:when test="upper-case(.) = 'BE-ADVANCED'">2</xsl:when>
      <xsl:when test="upper-case(.) = 'FRI UP'">3</xsl:when>
      <xsl:when test="upper-case(.) = 'OPI'">4</xsl:when>
      <xsl:when test="ends-with(upper-case(.), 'ÉCONOMIE DE NEUCHÂTEL')">5</xsl:when>
      <xsl:when test="ends-with(upper-case(.), 'ECONOMIE DE NEUCHÂTEL')">5</xsl:when>
      <xsl:when test="upper-case(.) = 'PROMOTION ÉCONOMIQUE PROMFR'">5</xsl:when>
      <xsl:when test="upper-case(.) = 'PROMOTION ECONOMIQUE PROMFR'">5</xsl:when>
      <xsl:when test="upper-case(.) = 'INNOVAUD'">6</xsl:when>
      <xsl:when test="upper-case(.) = 'CIMARK'">7</xsl:when>
      <xsl:when test="upper-case(.) = 'CREAPOLE'">8</xsl:when>
      <xsl:when test="upper-case(.) = 'CRÉAPOLE'">8</xsl:when>
      <xsl:when test="upper-case(.) = 'CREAPÔLE'">8</xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="*[. = '']"></xsl:template>

  <xsl:template match="*|@*|text()">
    <xsl:copy>
      <xsl:apply-templates select="*|@*|text()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
