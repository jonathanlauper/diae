<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site"
  xmlns="http://www.w3.org/1999/xhtml">
  
  <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="yes"/>
  
  
  <xsl:include href="../../../xcm/lib/commons.xsl"/>
  <xsl:include href="../../../xcm/lib/widgets.xsl"/>
  <xsl:include href="../../../xcm/modules/workflow/workflow.xsl"/>
  
  <xsl:include href="../annexes/annex.xsl"/>
  
  <!-- Calls Display when rendering a workflow view page
       Calls success or error to return an Ajax response when creating an Alert (see alert.xql)
       Note: Ajax error should have cut the pipeline because of status code and not reach that code
       -->
  
  <xsl:template match="/">
    <xsl:apply-templates select="*"/>
  </xsl:template>
  
  <xsl:template match="Display">
    <xsl:apply-templates select="Image"/>
  </xsl:template>
  
  <xsl:template match="Images">
    <xsl:apply-templates select="Image"/>
  </xsl:template>
  
  <!-- pre-check error rendering -->
  <xsl:template match="error" priority="1">
    <site:view skin="workflow">
      <site:win-title>
        <title>Case Tracker Error</title>
      </site:win-title>
      <site:content>
        <h2>Oops !</h2>
        
      </site:content>
    </site:view>
  </xsl:template>
  
</xsl:stylesheet>
