<?xml version="1.0" encoding="UTF-8"?>
<!-- Invoke XCM blender
     Placeholder to specialize XCM blender rules
 -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:xhtml="http://www.w3.org/1999/xhtml">

  <xsl:param name="xslt.base-url">/</xsl:param>

  <xsl:include href="../../xcm/views/blend.xsl"/>
  
  <xsl:template match="Title[parent::FundingRequest]">
    <xsl:copy-of select="."/>
  </xsl:template>

</xsl:stylesheet>
