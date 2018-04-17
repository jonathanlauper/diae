<?xml version="1.0" encoding="UTF-8"?>

<!-- OppiStore module : webpage view

     Version 1.0

     Author: Stéphane Sire <s.sire@opppidoc.fr>

     Web page content model rendering to HTML

     February 2012 - (c) Copyright 2012 Oppidoc SARL. All Rights Reserved.
  -->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site"
  xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="no"/>

  <xsl:param name="xslt.rights"></xsl:param>
  <xsl:param name="xslt.base-url">/</xsl:param>
  <xsl:param name="xslt.key"></xsl:param>

  <xsl:include href="webpagecontent.xsl"/>

  <xsl:template match="/">
    <site:view>
      <xsl:if test="$xslt.rights != ''">
        <site:menu> 
          <xsl:if test="contains($xslt.rights, 'modifier')">
            <button title="Modifier la page" onclick="javascript:window.location.href+='/modifier'">Modifier</button>
          </xsl:if>
        </site:menu>
      </xsl:if>
      <xsl:apply-templates select="IllustratedWebPage"/>
      <xsl:apply-templates select="WebPage" mode="top"/>
    </site:view>
  </xsl:template>

  <xsl:template match="IllustratedWebPage">
    <site:image>
      <img src="{ $xslt.base-url }photos/{ Photo }" class="column-photo"/>
    </site:image>
    <xsl:apply-templates select="WebPage" mode="top"/>
  </xsl:template>

  <xsl:template match="WebPage" mode="top">
    <site:content>
      <xsl:apply-templates select="."/>
    </site:content>
  </xsl:template>
</xsl:stylesheet>
