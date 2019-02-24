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
    <div id="log2">Log</div>

    
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
    <xsl:variable name="nextImg">
      <xsl:value-of select="Next"/>
    </xsl:variable>
    <xsl:variable name="prevImg">
      <xsl:value-of select="Prev"/>
    </xsl:variable>
    <xsl:variable name="nextCol">
      <xsl:value-of select="NextCol"/>
    </xsl:variable>
    <xsl:variable name="prevCol">
      <xsl:value-of select="PrevCol"/>
    </xsl:variable>
    
    <p>Image to recognize</p>
    
    <img id="orig_image" src="{$xslt.base-url}{$imglink}" hidden="none" > </img> 
    <div id="buttons">
      <input type="button" onclick="location.href='{$xslt.base-url}{$prevImg}';" value="Previous Image" />
      <input type="button" onclick="location.href='{$xslt.base-url}{$nextImg}';" value="Next Image" />
      <input type="button" onclick="location.href='{$xslt.base-url}{$nextCol}';" value="Next Collection" />
      <input type="button" onclick="location.href='{$xslt.base-url}{$prevCol}';" value="Previous Collection" />
    </div>
    
  </xsl:template>
  
  
  <xsl:template match="Collection">
    <script id="script" base='{$xslt.base-url}'>var currentCollection; var currentImage; var allImageDropdowns = [];
      function changeCollection(menu){
        currentCollection = menu.value; 
        allImageDropdowns.forEach( function(all){
                                        if(all.id == currentCollection) 
                                        all.style.display = "block"; 
                                        else all.style.display = "none";})
      }
      function changeImageTo(menu){
      currentImage = menu.value;
      document.getElementById("log2").innerHTML = "/"+"images-"+currentCollection+"-"+currentImage.replace("\.","_");
      location.href= "images-"+currentCollection+"-"+currentImage.replace("\.","_");
      }
    </script> 

    <select id="collection" onchange="changeCollection(this)">
      <option value="default">Select a collection</option>
      <xsl:for-each select="Name">

        <option value="{.}"> <xsl:value-of select="current()"/></option>
      </xsl:for-each>
    </select>
  </xsl:template>
  
  <xsl:template match="Images">
    
    <xsl:for-each select="Collection">
        <xsl:variable name="id">
          <xsl:value-of select="Name"/>
        </xsl:variable>
          <select id="{$id}" onchange="changeImageTo(this)" display='none'>
            <option value="default">Select an image</option>
            <xsl:for-each select="Ref">

              
              <option value="{.}"><xsl:value-of select="current()"/></option>
              
            </xsl:for-each>
          </select>
      <script>allImageDropdowns.push(document.getElementById("<xsl:value-of select="Name"/>"))</script> 
    </xsl:for-each>
  </xsl:template>
  



</xsl:stylesheet>
