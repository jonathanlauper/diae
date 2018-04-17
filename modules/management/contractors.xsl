<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site"  xmlns:xt="http://ns.inria.org/xtiger"
  xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" media-type="application/xhtml+xml" omit-xml-declaration="yes" indent="yes"/>

  <xsl:param name="xslt.base-url">/</xsl:param>
  <xsl:template match="/ExternalServicesContractors[@Goal = 'read']">
    <div id="results1" class="row-fluid">
      <h2>External service providers</h2>
      <form>
        <div class="row-fluid">
          <xsl:apply-templates select="Contractors" mode="read"/>
        </div>
      </form>
    <!--  <p style="margin-top: 20px">
        <button class="btn btn-primary" onclick="javascript:$(event.target).trigger('coaching-update-contractors')">Modifier</button>
      </p>-->

      <a><span class="rn" data-contractors="management/externalservice/contractors">Edit</span></a>
    </div>
  </xsl:template>
 
  <!-- Returns a static view of the application parameters -->
  <xsl:template match="Contractors" mode="read">
    
    <xsl:apply-templates select="Contractor"/>
    
  </xsl:template>
  <xsl:template match="Contractor" mode="read">
    
    <xsl:apply-templates select="*"/>
    
  </xsl:template>
  
  <!-- Returns a READONLY field  -->
  <xsl:template match="Field">
    <div class="span12" style="margin-left:0">
        <div class="control-group">
            <label class="control-label"><xsl:value-of select="@Label"/></label>
            <div class="controls">
              <span class="uneditable-input span a-control" label="{@Tag}"><xsl:value-of select="."/></span>
            </div>
        </div>
    </div>
  </xsl:template>
  <xsl:template match="Seperator">
    
    <div class="span12" style="margin-left:0">
    <hr/>
    </div>
  </xsl:template>

</xsl:stylesheet>
