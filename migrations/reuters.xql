xquery version "3.0";
(: 
  Generates xsl:choose to migrate markets (copy-paste in XSLT) from annotated marlets-en.xml data 
  NOTE: markets code migration may create duplicated codes which must be removed post-migration
:)

declare namespace xsl = "http://www.w3.org/1999/XSL/Transform";

<xsl:choose>
    {
for $o in fn:doc('/db/sites/ctracker/global-information/markets-en.xml')//Option
return
    <xsl:when test="{ $o/Value }">
       {
       for $reuters in $o/Reuters[. ne '-1']
       return 
           <TargetedMarketRef>{ string($reuters) }</TargetedMarketRef>
       }
    </xsl:when>
    }
</xsl:choose>