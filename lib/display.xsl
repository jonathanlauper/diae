<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site" xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="yes"/>


  <xsl:template match="/">
    <site:view>
      <site:content>
        <xsl:apply-templates select="Root"/>
      </site:content>
    </site:view>
  </xsl:template>

  <xsl:template match="Actions">
    <xsl:apply-templates select="Action"/>
  </xsl:template>

  <xsl:template match="Action[@Name='edit']">
    <a class="btn" href="{.}">Edit</a>
  </xsl:template>

  <xsl:template match="CFP">
    <p>Download the <a href="{.}">printable version of the Call for Papers</a> (PDF)</p>
    <!--    <p>Download the call for paper in <a href="http://localhost:8080/exist/projets/de2015/static/de2015/docs/doceng2015-cfp.pdf">PDF</a></p>-->
  </xsl:template>

  <xsl:template match="Title">
    <h4>
      <xsl:value-of select="."/>
    </h4>
  </xsl:template>

  <xsl:template match="Parag">
    <p>
      <xsl:apply-templates select="Fragment | Link"/>
    </p>
  </xsl:template>
  
  <xsl:template match="Fragment[@FragmentKind = 'emphasize']">
    <span class="emphasize">
      <xsl:value-of select="."/>
    </span>
  </xsl:template>

  <xsl:template match="Fragment[@FragmentKind = 'verbatim']">
    <span class="verbatim">
      <xsl:value-of select="."/>
    </span>
  </xsl:template>

  <xsl:template match="Fragment[@FragmentKind = 'important']">
    <span class="important">
      <xsl:value-of select="."/>
    </span>
  </xsl:template>
  
  <xsl:template match="Fragment[@FragmentKind = 'very-important']">
    <span class="very-important">
      <xsl:value-of select="."/>
    </span>
  </xsl:template>

  <xsl:template match="Fragment">
    <xsl:value-of select="."/>
  </xsl:template>

  <!-- External links open in a new window -->
  <xsl:template match="Link">
    <xsl:choose>
      <xsl:when test="starts-with(LinkRef, 'http:') or starts-with(LinkRef, 'https:')">
        <a href="{LinkRef}" target="_blank">
          <xsl:value-of select="LinkText"/>
        </a>
      </xsl:when>
      <xsl:otherwise>
        <a href="{LinkRef}">
          <xsl:value-of select="LinkText"/>
        </a>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="List">
    <xsl:apply-templates select="ListHeader"/>
    <ul>
      <xsl:apply-templates select="./Item | ./SubList"/>
    </ul>
  </xsl:template>

  <xsl:template match="ListHeader">
    <p>
      <xsl:value-of select="."/>
    </p>
  </xsl:template>

  <xsl:template match="Item|SubListItem">
    <li>
      <xsl:apply-templates/>
    </li>
  </xsl:template>

  <xsl:template match="SubList">
    <ul>
      <xsl:apply-templates/>
    </ul>
  </xsl:template>

  <xsl:template match="SubListItem">
    <ul>
      <xsl:apply-templates/>
    </ul>
  </xsl:template>

  <xsl:template match="SubListHeader">
    <li>
      <xsl:value-of select="."/>
    </li>
  </xsl:template>
  
  <!-- Added templates to render a table - not taken into account by Axel -->
  <xsl:template match="Table">
    <table border="1">
      <xsl:apply-templates select="Row"/>
    </table>
  </xsl:template>
  
  <xsl:template match="Row">
    <tr>
      <xsl:apply-templates select="Cell"/>
    </tr>
  </xsl:template>
  
  <xsl:template match="Cell">
    <td>
      <xsl:value-of select="."/>
    </td>
  </xsl:template>

</xsl:stylesheet>
