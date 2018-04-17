<?xml version="1.0" encoding="UTF-8"?>
<!--
     Case Tracker Reference

     Creator: Stéphane Sire <s.sire@opppidoc.fr>

     With saxon use -strip:all to remove whitespaces:

     saxon -strip:all -s:enterprises/enterprises.xml -xsl:/usr/local/platinn/ctracker22/lib/webapp/platinn/ctracker/migrations/enterprises.xsl -o:enterprises.xml

     Migration of legacy coaching Platinn enterprises.xml resource file
  -->
<xsl:stylesheet version="2.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  >

  <xsl:output method="xml" media-type="text/xml" omit-xml-declaration="yes" indent="yes"/>

  <xsl:template match="/Enterprises">
    <Enterprises>
      <xsl:apply-templates select="Enterprise"/>
    </Enterprises>
  </xsl:template>

  <!-- TODO: sort
        $form/Name,
        $form/ShortName,
        $form/WebSite,
        $form/CreationYear,
        $form/SizeRef,
        $form/DomainActivityRef,
        $form/MainActivities,
        $form/TargetedMarkets,
        $form/Address -->
  <xsl:template match="Enterprise">
    <Enterprise>
      <xsl:apply-templates select="Id"/>
      <Information>
        <xsl:apply-templates select="*[local-name() != 'Id']"/>
      </Information>
    </Enterprise>
  </xsl:template>

  <xsl:template match="State">
    <RegionRef><xsl:value-of select="."/></RegionRef>
  </xsl:template>

  <xsl:template match="NOGA-Code">
    <DomainActivityRef><xsl:value-of select="."/></DomainActivityRef>
  </xsl:template>

  <!-- Also used in case.xsl migration -->
  <xsl:template match="TargetedMarkets">
    <TargetedMarkets>
      <xsl:apply-templates select="TargetedMarketRef"/>
    </TargetedMarkets>
  </xsl:template>

  <!-- Also used in case.xsl migration -->
  <xsl:template match="TargetedMarketRef">
    <xsl:choose>
      <xsl:when test=". = '010'">
        <TargetedMarketRef>521010</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '020'">
        <TargetedMarketRef>532030</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '030'">
        <TargetedMarketRef>541010</TargetedMarketRef>
        <TargetedMarketRef>541020</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '050'">
        <TargetedMarketRef>532040</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '055'">
        <TargetedMarketRef>553010</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '070'">
        <TargetedMarketRef>521020</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '075'">
        <TargetedMarketRef>531010</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '080'">
        <TargetedMarketRef>571050</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '100'">
        <TargetedMarketRef>571020</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '110'">
        <TargetedMarketRef>513020</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '120'">
        <TargetedMarketRef>522010</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '125'">
        <TargetedMarketRef>551010</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '140'">
        <TargetedMarketRef>501010</TargetedMarketRef>
        <TargetedMarketRef>501020</TargetedMarketRef>
        <TargetedMarketRef>501030</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '160'">
        <TargetedMarketRef>521020</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '165'">
        <TargetedMarketRef>551010</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '170'">
        <TargetedMarketRef>521020</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '180'">
        <TargetedMarketRef>532020</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '190'">
        <TargetedMarketRef>571040</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '200'">
        <TargetedMarketRef>572010</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '210'">
        <TargetedMarketRef>572010</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '215'">
        <TargetedMarketRef>522010</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '230'">
        <TargetedMarketRef>533010</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '240'">
        <TargetedMarketRef>554020</TargetedMarketRef>
        <TargetedMarketRef>554030</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '255'">
        <TargetedMarketRef>571040</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '260'">
        <TargetedMarketRef>562010</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '265'">
        <TargetedMarketRef>562010</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '280'">
        <TargetedMarketRef>561020</TargetedMarketRef>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="*[. = '']"></xsl:template>

  <xsl:template match="*|@*|text()">
    <xsl:copy>
      <xsl:apply-templates select="*|@*|text()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
