<?xml version="1.0" encoding="UTF-8"?>

<!-- POLL - Oppidoc Poll Application

     Author: Stéphane Sire <s.sire@opppidoc.fr>

     Transformation of Poll questionnaire mini-language into a dual XTiger XML form
     and an Oppidum mesh.The Variable elements are rendered as site:field element
     for late substitution during epilogue rendering.

     This file is originally from POLL application modules/poll/poll.xsl

     For proper rendering of the formular you may need to copy POLL
     CSS rules specific to questionnaires

     June 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
  -->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xt="http://ns.inria.org/xtiger"
  xmlns:site="http://oppidoc.com/oppidum/site"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  >
  
  <!-- ************************* -->
  <!--           Embed           -->
  <!-- ************************* -->
  <xsl:template match="Embed" mode="component">
    <xsl:apply-templates select="document(concat($xslt.base-root, concat($xslt.base-formulars, @src)))/Poll" mode="head"/>
  </xsl:template>

  <xsl:template match="/Poll">
    <html xmlns="http://www.w3.org/1999/xhtml" xmlns:xt="http://ns.inria.org/xtiger" xmlns:site="http://oppidoc.com/oppidum/site">
    <head><xsl:text>
    </xsl:text><xsl:comment>XTiger XML template generated with "poll.xsl" from Oppidoc POLL application</xsl:comment><xsl:text>
    </xsl:text><meta http-equiv="content-type" content="text/html; charset=UTF-8" />
      <xt:head version="1.1" templateVersion="1.0" label="Answers">
        <xsl:apply-templates select="Questions/* | Questions/CommentatedQuestion/*" mode="component"/>
      </xt:head>
      <site:skin force="true"/>
    </head>
    <body data-template="#">
      <xsl:apply-templates select="Questions/*"/>
    </body>
    </html>
  </xsl:template>

  <!-- generates XTiger components for the head section  -->
  <xsl:template match="/Poll" mode="head">
    <xsl:apply-templates select="Questions/* | Questions/CommentatedQuestion/*" mode="component"/>
  </xsl:template>

  <xsl:template match="/Poll" mode="body">
    <xsl:apply-templates select="Questions/*"/>
  </xsl:template>

  <!-- ************************ -->
  <!--     site:conditional     -->
  <!-- ************************ -->

  <!-- site:conditional overlay with @context (see also supergrid.xsl rule) -->
  <xsl:template match="site:conditional[@context][@context = @context]" mode="component">
    <xsl:apply-templates select="*" mode="component"/>
  </xsl:template>

  <!-- site:conditional overlay with @context (see also supergrid.xsl rule) -->
  <xsl:template match="site:conditional[@context][@context != @context]" mode="component"></xsl:template>

  <!-- site:conditional overlay with @context (see also supergrid.xsl rule) -->
  <xsl:template match="site:conditional[@context][$xslt.context = @context]" priority="20">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <!-- site:conditional overlay with @context (see also supergrid.xsl rule) -->
  <xsl:template match="site:conditional[@context][$xslt.context != @context]" priority="20">
  </xsl:template>

  <!-- **************** -->
  <!--     Prefill      -->
  <!-- **************** -->

  <xsl:template match="Prefill" mode="component">
    <xsl:variable name="key"><xsl:value-of select="@Key"></xsl:value-of></xsl:variable>
    <xt:component name="t_{$key}">
      <div class="control-group">
        <label class="control-label">
          <xsl:apply-templates select="text()|*"/>
        </label>
        <div class="controls">
          <xt:use param="class=span12 a-control" types="input"><xsl:apply-templates select="@DefaultVariable"/></xt:use>
        </div>
      </div>
    </xt:component>
  </xsl:template>

  <xsl:template match="Prefill">
    <div class="row-fluid">
      <div class="span12">
        <xt:use types="t_{@Key}" label="{@Tag}"/>
      </div>
    </div>
  </xsl:template>

  <xsl:template match="@DefaultVariable"></xsl:template>

  <xsl:template match="@DefaultVariable[$xslt.default-variable = 'on']">
    <site:field Key="{.}" force="true" type="var"><xsl:value-of select='.'/></site:field>
  </xsl:template>

  <!-- **************** -->
  <!--     Question     -->
  <!-- **************** -->
  <xsl:template match="CommentatedQuestion" mode="component">
    <xsl:variable name="Label"><xsl:value-of select="@Label"></xsl:value-of></xsl:variable>
    <xsl:variable name="CommentLabel"><xsl:value-of select="@CommentLabel"></xsl:value-of></xsl:variable>
    <xt:component name="t_{$Label}">
      <div class="span12 c-v-spacer" style="margin-left:0">
        <xsl:apply-templates select="Question"/>
      	<div class="span12" style="margin-left:0">
          <div class="control-group">
            <label class="control-label a-gap0"><xsl:value-of select="$CommentLabel"/></label>
            <div class="controls">
              <!--<site:field force="true" filter="copy">-->
              <xt:use types="input" label="Comment_{Question/@Key}" param="type=textarea;multilines=normal;class=sg-multitext;filter=optional"/>
              <!--<xt:use types="text" label="Comment_{Question/@Key}" handle="p" param="type=textarea;placeholder=empty;shape=parent;class=sg-textarea;filter=optional"/>-->
              <!--</site:field>-->
            </div>
          </div>
        </div>
      </div>
    </xt:component>
  </xsl:template>


  <xsl:template match="CommentatedQuestion[$xslt.read-only = 'on']" mode="component">
    <xsl:variable name="Label"><xsl:value-of select="@Label"></xsl:value-of></xsl:variable>
    <xsl:variable name="CommentLabel"><xsl:value-of select="@CommentLabel"></xsl:value-of></xsl:variable>
    <xt:component name="t_{$Label}">
      <div class="row-fluid" style="margin-left:0">
        <xsl:apply-templates select="Question"/>
      	<div class="span12" style="margin-left:0">
          <div class="control-group">
            <label class="control-label a-gap0"><xsl:value-of select="$CommentLabel"/></label>
            <!--<site:field force="true" filter="copy">-->
            <xt:use types="html" label="Comment_{Question/@Key}" param="class=span a-control af-question-comment"/>
            <!--<xt:use types="constant" label="Comment_{Question/@Key}" param="class=sg-multiline uneditable-input span a-control" />-->
              <!--</site:field>-->
          </div>
        </div>
      </div>
    </xt:component>
  </xsl:template>

  <xsl:template match="CommentatedQuestion">
    <xsl:variable name="Label"><xsl:value-of select="@Label"></xsl:value-of></xsl:variable>
    <xt:use types="t_{@Label}"/>
  </xsl:template>

  <xsl:template match="Question" mode="component">
    <xsl:variable name="key"><xsl:value-of select="@Key"></xsl:value-of></xsl:variable>
    <xt:component name="t_{$key}">
      <div class="control-group">
        <label class="control-label question-likert{$xslt.question-likert-class}">
          <xsl:apply-templates select="text()|*"/>
        </label>
        <div class="controls">
          <xsl:apply-templates select="/Poll/Plugins/*[contains(@Keys, $key)]"/>
        </div>
      </div>
    </xt:component>
  </xsl:template>

  <xsl:template match="Question">
    <xsl:variable name="key"><xsl:value-of select="@Key"></xsl:value-of></xsl:variable>
    <xsl:variable name="prefix"><xsl:value-of select="/Poll/Plugins/*[contains(@Keys, $key)]/@Prefix"/></xsl:variable>
    <div class="row-fluid">
      <div class="span12">
        <xt:use types="t_{@Key}" label="{$prefix}{@Key}"/>
      </div>
    </div>
    <hr class="a-separator"/>
  </xsl:template>

  <xsl:template match="Question[last()]">
    <xsl:variable name="key"><xsl:value-of select="@Key"></xsl:value-of></xsl:variable>
    <xsl:variable name="prefix"><xsl:value-of select="/Poll/Plugins/*[contains(@Keys, $key)]/@Prefix"/></xsl:variable>
    <div class="row-fluid">
      <div class="span12">
        <xt:use types="t_{@Key}" label="{$prefix}{@Key}"/>
      </div>
    </div>
  </xsl:template>

  <!-- **************** -->
  <!--     Variable     -->
  <!-- **************** -->
  <xsl:template match="Variable">
      <site:field Key="{@Name}" force="true" type="var">
          <xsl:value-of select="."/>
      </site:field>
  </xsl:template>

  <!-- ********************* -->
  <!--     Likert Plugin     -->
  <!-- ********************* -->
  <xsl:template match="Likert">
    <xsl:variable name="read-only">
      <xsl:if test="$xslt.read-only = 'on'">;noedit=true</xsl:if>
    </xsl:variable>
    <xt:use types="choice" param="appearance=full;multiple=no{$xslt.likert-class}{$read-only}">
      <xsl:attribute name="values"><xsl:apply-templates select="Option" mode="Likert-id"/></xsl:attribute>
      <xsl:attribute name="i18n"><xsl:apply-templates select="Option" mode="Likert-name"/></xsl:attribute>
    </xt:use>
  </xsl:template>

  <xsl:template match="Option" mode="Likert-id"><xsl:value-of select="Id|Value"/><xsl:text> </xsl:text></xsl:template>

  <xsl:template match="Option[position() = last()]" mode="Likert-id"><xsl:value-of select="Id|Value"/></xsl:template>

  <xsl:template match="Option" mode="Likert-name"><xsl:value-of select="Name"/><xsl:text> </xsl:text></xsl:template>

  <xsl:template match="Name[position() = last()]" mode="Likert-name"><xsl:value-of select="Name"/></xsl:template>

  <!-- ************************ -->
  <!--     Comments Plugin     -->
  <!-- ************************ -->
  <xsl:template match="Comments">
    <xt:use types="input" param="type=textarea;multilines=normal;class=sg-multitext;filter=optional"/>
  </xsl:template>

  <xsl:template match="Comments[$xslt.read-only = 'on']">
    <xt:use types="html" param="class=span a-control"/>
  </xsl:template>

</xsl:stylesheet>

