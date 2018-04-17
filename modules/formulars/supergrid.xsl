<?xml version="1.0" encoding="UTF-8" ?>
<!--
     XQuery Content Management Library

     Author: Stéphane Sire <s.sire@opppidoc.fr>

     Supergrid transformation entry point

     Copy this file into your project to extend supergrid with your own vocabulary/modules

     April 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
  -->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xt="http://ns.inria.org/xtiger"
  xmlns:site="http://oppidoc.com/oppidum/site"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  >

  <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="yes" />

  <!-- Inherited from Oppidum pipeline -->
  <xsl:param name="xslt.base-url"></xsl:param>

  <!-- Query "goal" parameter transmitted by Oppidum pipeline -->
  <xsl:param name="xslt.goal">test</xsl:param>

  <!-- Will be transmitted by formulars/install.xqm-->
  <xsl:param name="xslt.base-root"></xsl:param> <!-- for Include -->

  <!-- Will be transmitted by formulars/install.xqm-->
  <xsl:param name="xslt.app-name">ctracker</xsl:param>
  <xsl:param name="xslt.base-formulars">webapp/platinn/ctracker/formulars/</xsl:param> <!-- for Include -->
  
  <!-- ***** Poll Configuration *****  -->
  <xsl:param name="xslt.read-only">on</xsl:param> <!-- when 'on' generates read-only form version -->
  <xsl:param name="xslt.context">ctracker</xsl:param> <!-- application context name for filtering with site:conditional -->
  <xsl:param name="xslt.default-variable">off</xsl:param> <!-- when 'on' generates Prefill/@DefaultVariable to pre-fill field default value -->
  <xsl:param name="xslt.likert-class">;class=c-inline-choice</xsl:param> <!-- use ";class=something" syntax to add class to likert fields -->
  <xsl:param name="xslt.question-likert-class"> a-gap3</xsl:param> <!-- use " something" syntax to add class to likert fields labels -->

  <!-- CONFIGURE these paths if you change XCM folder name ! -->
  <xsl:include href="poll.xsl"/>
  <xsl:include href="../../../xcm/modules/formulars/search-mask.xsl"/>
  <xsl:include href="../../../xcm/modules/formulars/supergrid-core.xsl"/>
</xsl:stylesheet>  