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
  <xsl:template match="Recognition">
    <!--<a class="btn btn-primary" href="{/Display//Activities/@Current}/contract" loc="action.recognize">Imprimer</a>-->
    
    
    <div id="log">Log</div>
    
    <div class="col-md-auto">
      <canvas id="mainView" width='600' height='800' style="border: 1px solid black;"></canvas>
    </div>
    <div class="col-md-auto">
      <canvas id="view2" width='600' height='800' style="border: 1px solid black;"></canvas>
    </div>
    <div class="col-md-auto">
      <canvas id="view3" width='600' height='800' style="border: 1px solid black;"></canvas>
    </div> 
    <div class="col-md-auto">
      <canvas id="view4" width='600' height='800' style="border: 1px solid black;"></canvas>
    </div>
    
    <div class="col-md-auto">
      <div id="download"></div>
    </div>

    
<!--    <div id="segmentation" class="col-md-auto">
      <h2>Segmentation</h2>
      <img ></img>
    </div>-->
    
    
    <div class="row">
      <div class="col-md-auto">
        <h2>Recognition Result</h2>
        <div id='result'></div>
      </div>
    </div>
  </xsl:template>
  
  <xsl:template match="Image">
    <xsl:variable name="imglink">
      <xsl:value-of select="Ref"/>
    </xsl:variable>
    <p>Image to recognize</p>
    
    <img id="orig_image" src="{$xslt.base-url}{$imglink}" hidden="none" > </img> 
    
    
  </xsl:template>
  
</xsl:stylesheet>
