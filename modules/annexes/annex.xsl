<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml">

  <!--*********************************-->
  <!--*****  Annexes tab content  *****-->
  <!--*********************************-->

  <xsl:template match="Annexes">
    <xsl:if test="not(Annex)">
      <p id="c-no-annex" loc="app.noAnnex">Pas d'annexe</p>
    </xsl:if>
    <table>
      <xsl:apply-templates select="." mode="class"/>
      <thead>
        <tr bgcolor="#9EC0D9"> <!-- CV-FIXME -->
          <th loc="term.date">Date</th>
          <th loc="term.activityStatus">Statut de l'activité</th>
          <th loc="term.filename">Nom du fichier</th>
          <th loc="term.sender">Expéditeur</th>
          <th loc="term.action">Action</th>
        </tr>
      </thead>
      <tbody id="c-annex-list" data-command="c-delannexe" data-confirm-loc="confirm.annex.delete" >
        <xsl:apply-templates select="Annex">
           <xsl:sort select="Date/@SortKey" order="descending"/>
        </xsl:apply-templates>
      </tbody>
    </table>
  </xsl:template>

  <!-- empty list -->
  <xsl:template match="Annexes" mode="class">
    <xsl:attribute name="class">table table-bordered c-empty</xsl:attribute>
  </xsl:template>

  <!-- not empty list -->
  <xsl:template match="Annexes[Annex]" mode="class">
    <xsl:attribute name="class">table table-bordered</xsl:attribute>
  </xsl:template>

  <!-- TODO: factorize format-text with XCM libs -->
  <xsl:template match="Annex">
    <tr>
      <td>
        <xsl:call-template name="ann-format-text"><xsl:with-param name="text"><xsl:value-of select="Date"/></xsl:with-param></xsl:call-template>
      </td>
      <td>
        <xsl:call-template name="ann-format-text"><xsl:with-param name="text"><xsl:value-of select="ActivityStatus"/></xsl:with-param></xsl:call-template>
      </td>
      <td>
        <xsl:apply-templates select="File"/> 
      </td>
      <td>
        <xsl:call-template name="ann-format-text"><xsl:with-param name="text"><xsl:value-of select="Sender"/></xsl:with-param></xsl:call-template>
      </td>
      <td>
        <xsl:apply-templates select="File" mode="delete"/>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="File">
      <a class="c-annex-link" target="_blank" href="{@href}">
        <xsl:value-of select="."/>
      </a>
  </xsl:template>

  <!-- no upload (hence no delete) right -->
  <xsl:template match="File" mode="delete">
    <xsl:text>-</xsl:text>
  </xsl:template>

  <!-- upload (hence delete) right -->
  <xsl:template match="File[@Del = '1']" mode="delete">
    <i data-file="{.}" class="icon-trash"></i>
  </xsl:template>

  <!-- Prints text param or a dash - if empty -->
  <xsl:template name="ann-format-text">
    <xsl:param name="text"/>
    <xsl:choose>
      <xsl:when test="$text != ''"><xsl:value-of select="$text"/></xsl:when>
      <xsl:otherwise>-</xsl:otherwise>
    </xsl:choose>
    <xsl:value-of select="text"/>
  </xsl:template>

</xsl:stylesheet>
