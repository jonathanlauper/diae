<?xml version="1.0" encoding="UTF-8"?>
<!-- OppiStore module : webpage view

     Version 1.0

     Author: Stéphane Sire <s.sire@opppidoc.fr>

     Web page content model rendering to HTML
     
     Pre-conditions
     - to use Illustration type, you MUST include this file from another stylesheet
       with an xslt.key parameter to generate image links as {$xsl.key}/images/* 
       or {$xsl.key}/vignettes/* in case $xslt.key is not the empty string

    April 2012 - (c) Copyright 2012 Oppidoc SARL. All Rights Reserved.
  -->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site"
  xmlns="http://www.w3.org/1999/xhtml">
  
  <xsl:template match="WebPage">
    <xsl:apply-templates select="PageTitle"/>
    <xsl:apply-templates select="PageContent"/>
    <xsl:apply-templates select="BlocContent[position() mod 2 = 1]"/>
  </xsl:template>

  <xsl:template match="BlocContent">
    <div class="row">
      <div class="col-md-6">
        <div class="bloc-titre mosaic">
          <h2>
            <xsl:apply-templates select="Index[. != '']"/>
            <span><xsl:value-of select="BlocTitle"/></span>
          </h2>
          <xsl:if test="@status = 'archive'">
            <div class="archive">ARCHIVE</div>
          </xsl:if>
        </div>
        <xsl:apply-templates select="*[(local-name(.) != 'Index') and (local-name(.) != 'BlocTitle')]"/>
      </div>
      <xsl:apply-templates select="./following-sibling::BlocContent[1]" mode="sibling"/>
    </div>
  </xsl:template>

  <xsl:template match="BlocContent" mode="sibling">
    <div class="col-md-6">
      <div class="bloc-titre mosaic">
        <h2>
          <xsl:apply-templates select="Index[. != '']"/>
          <span><xsl:value-of select="BlocTitle"/></span>
        </h2>
        <xsl:if test="@status = 'archive'">
          <div class="archive">ARCHIVE</div>
        </xsl:if>
      </div>
      <xsl:apply-templates select="*[(local-name(.) != 'Index') and (local-name(.) != 'BlocTitle')]"/>
    </div>
  </xsl:template>

  <xsl:template match="Index">
    <div class="in-bloc">
      <img class="pthumbimg" src="{$xslt.key}/images/{substring-after(., 'images/')}"/>
    </div>
  </xsl:template>

  <xsl:template match="Box">
    <div>
      <xsl:apply-templates select="BoxTitle"/>
      <xsl:apply-templates select="BoxContent"/>
    </div>
  </xsl:template>
  
  <xsl:template match="PageTitle">
    <h1><xsl:value-of select="."/></h1>
  </xsl:template>

  <xsl:template match="BoxTitle">
    <h2><xsl:value-of select="."/></h2>
  </xsl:template>

  <!-- by default: Parag | List | TitleLevel1 | TitleLevel2 | LinesBlock | Illustration -->
  <xsl:template match="BoxContent | PageContent">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="Parag">
    <p><xsl:apply-templates select="Frag | Link | Fragment"/></p>
  </xsl:template>   

  <xsl:template match="Fragment[@FragmentKind = 'important']">
    <b><xsl:value-of select="."/></b>
  </xsl:template>   

  <xsl:template match="Fragment[@FragmentKind = 'emphasize']">
    <em><xsl:value-of select="."/></em>
  </xsl:template>   

  <xsl:template match="Fragment[@FragmentKind = 'verbatim']">
    <tt><xsl:value-of select="."/></tt>
  </xsl:template>   

  <xsl:template match="Frag|Fragment">
    <xsl:value-of select="."/>
  </xsl:template>

  <!-- Rewrites internal absolute links that do not start with '/static/' 
       All links open in a new window -->
  <xsl:template match="Link">
    <xsl:choose>
      <xsl:when test="starts-with(LinkRef, '/') and not(starts-with(LinkRef, '/static/'))">
        <a href="{concat($xslt.base-url, substring-after(LinkRef, '/'))}" target="_blank"><xsl:value-of select="LinkText"/></a>
      </xsl:when>
      <xsl:when test="starts-with(LinkRef, 'http:') or starts-with(LinkRef, 'https:') or contains(LinkRef,'static/alliance/docs/')">
        <a href="{LinkRef}" target="_blank"><xsl:value-of select="LinkText"/></a>
      </xsl:when>
      <xsl:otherwise>
        <a href="{LinkRef}" target="_blank"><xsl:value-of select="LinkText"/></a>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="List">
    <xsl:apply-templates select="ListHeader"/>
    <ul><xsl:apply-templates select="Item"/></ul>
  </xsl:template>

  <xsl:template match="ListHeader">
    <p><xsl:apply-templates select="Frag | Link | Fragment"/> :</p>
  </xsl:template>
  
  <xsl:template match="Item">
    <li><xsl:apply-templates select="Frag | Link | Fragment | Parag"/></li>
  </xsl:template>   

  <xsl:template match="TitleLevel1">
    <h2><xsl:value-of select="."/></h2>
  </xsl:template>   
  
  <xsl:template match="TitleLevel2">
    <h3><xsl:value-of select="."/></h3>
  </xsl:template>
  
  <xsl:template match="LinesBlock">
    <p class="x-LinesBlock">
      <xsl:apply-templates select="Line"/>
    </p>
  </xsl:template>
  
  <xsl:template match="Line[position() = last()]">
    <xsl:apply-templates select="Frag | Link | Fragment"/>
  </xsl:template>
  
  <xsl:template match="Line">
    <xsl:apply-templates select="Frag | Link | Fragment"/><br/>
  </xsl:template>
  
  <!-- Illustration no photo -->
  <xsl:template match="Illustration[count(Stack/Element/Photo[. != ''])=0]">
  </xsl:template>  

  <!-- Illustration one or more photos -->
  <xsl:template match="Illustration">
    <div class="{normalize-space(concat('x-Illustration ', @Position))}">
      <xsl:apply-templates select="@Width"/>
      <xsl:choose>
        <xsl:when test="count(Stack/Element/Photo[. != ''])=1"><div class="x-Element"><xsl:apply-templates select="Stack/Element"/></div></xsl:when>
        <xsl:otherwise>
          <table class="x-Stack"><tr><xsl:apply-templates select="Stack/Element" mode="multi"/></tr></table>
        </xsl:otherwise>
      </xsl:choose>
      <p class="x-Legend">
        <xsl:if test="@LegendWidth | @LegendAlign">
          <xsl:attribute name="style">
            <xsl:for-each select="@LegendWidth | @LegendAlign">
              <xsl:apply-templates select="."/>
            </xsl:for-each>
          </xsl:attribute>
        </xsl:if>
        <xsl:value-of select="Legend"/>
      </p>
    </div>
  </xsl:template>

  <xsl:template match="@Width">
    <xsl:attribute name="style"><xsl:value-of select="concat(concat('width:', .), 'px')"/></xsl:attribute>
  </xsl:template>

  <xsl:template match="@LegendWidth"><xsl:value-of select="concat(concat(concat('width:', .), 'px'), ';')"/>
  </xsl:template>

  <xsl:template match="@LegendAlign"><xsl:value-of select="concat(concat('text-align:', .), ';')"/>
  </xsl:template>

  <xsl:template match="Element" mode="multi">
    <td class="v-not-last">
      <xsl:apply-templates select="."/>
    </td>
  </xsl:template>
  
  <xsl:template match="Element[position()=last()]" mode="multi">
    <td>
      <xsl:apply-templates select="."/>
    </td>
  </xsl:template>
    
  <!-- Photo with a LinkRef, link it to an external web site -->
  <xsl:template match="Element[LinkRef]">
    <xsl:variable name="prefix"><xsl:if test="$xslt.key != ''"><xsl:value-of select="concat($xslt.key, '/')"/></xsl:if></xsl:variable>
    <a target="_blank">
      <xsl:attribute name="href">
        <xsl:choose>
          <xsl:when test="starts-with(LinkRef, 'http://') or starts-with(LinkRef, 'https://')"><xsl:value-of select="LinkRef"/></xsl:when>
          <xsl:otherwise><xsl:value-of select="concat('http://', LinkRef)"/></xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <img class="x-Photo" src="{$prefix}vignettes/{substring-after(Photo, 'images/')}" alt="Photo"/>
    </a>
  </xsl:template>

  <!-- Pure Photo with no LinkRef, link it to the larger version -->
  <xsl:template match="Element">
    <xsl:variable name="prefix"><xsl:if test="$xslt.key != ''"><xsl:value-of select="concat($xslt.key, '/')"/></xsl:if></xsl:variable>
    <a href="{$prefix}images/{substring-after(Photo, 'images/')}"><img class="x-Photo" src="{$prefix}vignettes/{substring-after(Photo, 'images/')}" alt="Photo"/></a>
  </xsl:template>
</xsl:stylesheet>