<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site" xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="yes"/>

  <xsl:param name="base-url">/</xsl:param>

  <!-- FIXME: do not forget fix-xsl-import in install.xql ! -->

  <xsl:template match="Display">
    <site:view>
      <site:content>
        <xsl:apply-templates select="Topic"/>
      </site:content>
    </site:view>
  </xsl:template>

  <xsl:template match="Topic[@Editor='true']">
    <div id="results">
      <div id="editor" class="c-autofill-border" data-template="{Template}">
        <xsl:apply-templates select="Resource"/>
        <noscript loc="app.message.js">Activez Javascript</noscript>
        <p>Chargement du formulaire en cours</p>
      </div>
      <div class="row-fluid">
        <div class="span4 offset8">
          <div class="edit-menu-actions">
            <button class="btn btn-primary" data-command="save" data-target="editor"
              data-replace-target="results">Save</button>
            <xsl:apply-templates select="Cancel"/>
          </div>
        </div>
      </div>
    </div>
  </xsl:template>
  
  <xsl:template match="Resource">
    <xsl:attribute name="data-src">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="Cancel">
    <a class="btn" href="{.}">Cancel</a>
  </xsl:template>
  
</xsl:stylesheet>
