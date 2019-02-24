<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:site="http://oppidoc.com/oppidum/site"
    xmlns="http://www.w3.org/1999/xhtml">
    
    <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="yes"/>
    
    <xsl:param name="xslt.base-url">/</xsl:param>
    
    <xsl:include href="../../../xcm/lib/commons.xsl"/>
    <xsl:include href="../../../xcm/lib/widgets.xsl"/>
    
    <xsl:template match="/">
        <xsl:apply-templates select="*"/>
    </xsl:template>
    <!-- Load ocr.js -->
    <xsl:template match="*|@*|text()">
        <xsl:copy>
            <xsl:apply-templates select="*|@*|text()"/>
        </xsl:copy>
    </xsl:template>

    <p>All collections:</p>
    
    
    <xsl:template match="Collection">    
        <p><xsl:value-of select="Name"/> collection: <xsl:value-of select="Count"/> image(s)</p>
        
        <xsl:for-each select="Image">
            <xsl:variable name="imglink">
                <xsl:value-of select="Ref"/>
            </xsl:variable>
            <a href="{$xslt.base-url}{$imglink}"><xsl:value-of select="Name"/></a>
            <br/>
            
        </xsl:for-each>
        

        
        
        
    </xsl:template>
    
    <!--
    <xsl:template match="Image">
        <xsl:variable name="imglink">
            <xsl:value-of select="Ref"/>
        </xsl:variable>
        
        <p>All images:</p>
        
        <a href="{$xslt.base-url}{$imglink}"><xsl:value-of select="Name"/></a>
        
        
        
    </xsl:template>
    -->

    
</xsl:stylesheet>
