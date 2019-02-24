xquery version "1.0";
(: --------------------------------------
   Case tracker pilote

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Generates extension points for Enterprise search and Enterprise formulars

   December 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

declare default element namespace "http://www.w3.org/1999/xhtml";


import module namespace request="http://exist-db.org/xquery/request";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace display = "http://oppidoc.com/ns/xcm/display" at "../../../xcm/lib/display.xqm";
import module namespace form = "http://oppidoc.com/ns/xcm/form" at "../../../xcm/lib/form.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace person = "http://oppidoc.com/ns/xcm/person" at "../../../xcm/modules/persons/person.xqm";

import module namespace user = "http://oppidoc.com/ns/xcm/user" at "../../../xcm/lib/user.xqm";

import module namespace httpclient = "http://exist-db.org/xquery/httpclient";

declare namespace xt = "http://ns.inria.org/xtiger";
declare namespace site = "http://oppidoc.com/oppidum/site";

declare option exist:serialize "method=xml media-type=text/xml";

(: flags for hierarchical  2 levels selectors:)
declare variable $local:json-selectors := true();

(: ======================================================================
   Generate selector for two level fields like domains of activity or markets
   TODO: move to form.xqm
   ====================================================================== 
:)
declare function local:gen-hierarchical-selector ($tag as xs:string, $xvalue as xs:string?, $optional as xs:boolean, $left as xs:boolean, $lang as xs:string ) {
  let $filter := if ($optional) then ' optional' else ()
  let $params := if ($xvalue) then
                  concat(';multiple=yes;xvalue=', $xvalue, ';typeahead=yes')
                 else
                  ';multiple=no'
  return
    if ($local:json-selectors) then
      form:gen-json-selector-for($tag, $lang,
        concat($filter, 
               $params, 
               ";choice2_width1=300px;choice2_width2=300px;choice2_closeOnSelect=true",
               if ($left) then ";choice2_position=left" else ()
               )
        ) 
    else
      form:gen-selector-for($tag, $lang, concat($filter, $params))
};


declare function local:gen-collection-selector ( $lang as xs:string, $params as xs:string ) as element() {
    let $pairs :=
      for $c in fn:collection('/db/sites/diae/pages/images')//Collection
          let $name := $c/Name/text()
      return
         <Name id="{$c/Id/text()}">{$name}</Name> 
  return
   let $ids := string-join(for $n in $pairs return string($n/@id), ' ')    (:  FLWOR to defeat document ordering :)
    let $names := string-join(for $n in $pairs return $n/text(), ' ') (: idem :)
    return
          <xt:use types="choice" values="{$names}" i18n="{fn:collection('/db/sites/diae/pages/images')//Collection}" param="{form:setup-select2($params)}"/>
};



declare function local:gen-collection-selector2 ( $lang as xs:string, $params as xs:string ) as element() {(:For when I add id to collection:)
    let $pairs :=
      for $p in globals:collection('persons-uri')//Person
      let $info := $p/Information
      let $fn := $info/Name/FirstName
      let $ln := $info/Name/LastName
      where ($info/Name/LastName ne '')
      order by $ln ascending
      return
         <Name id="{$p/Id/text()}">{concat(replace($ln,' ','\\ '), '\ ', replace($fn,' ','\\ '))}</Name>
  return
    let $ids := string-join(for $n in $pairs return string($n/@id), ' ') (: FLWOR to defeat document ordering :)
    let $names := string-join(for $n in $pairs return $n/text(), ' ') (: idem :)
    return
      <xt:use types="choice" values="{$ids}" i18n="{$names}" param="{form:setup-select2($params)}"/>
};




declare function local:requestAlgorithms() {
    let $url := 'http://divaservices.unifr.ch/api/v2/'
    return
       httpclient:get($url, false(), ()) (:TODO convert JSON to XML:)
};
declare function local:generate-algorithm-selector() as element() {
    let $all := local:requestAlgorithms()
    return
        let $pair := 
            for $p in $all
            let $n := $p/name
            let $url := $p/url
            return <Name id="{$url}">{(replace($n,' ','_'))}</Name>
        return
            let $ids := string-join(for $n in $names return string($n/@id), ' ') (: FLWOR to defeat document ordering :)
            let $names := string-join(for $n in $names return $n/text(), ' ') (: idem :)
            return
            <xt:use types="choice" values="{$ids}" i18n="{$names}" param="{form:setup-select2(";multiple=no;xvalue=Algorithm;typeahead=yes")}"/>
};


let $cmd := request:get-attribute('oppidum.command')
let $lang := string($cmd/@lang)
let $target := oppidum:get-resource(oppidum:get-command())/@name
let $goal := request:get-parameter('goal', 'read')

return
    if($goal = 'update') then
      <site:view>
        <site:field Key="algorithms">
          {form:gen-selector-for('Algorithms', $lang, ";multiple=no;xvalue=Algorithm;typeahead=yes") (:local:generate-algorithm-selector():) }
        </site:field>
      </site:view>
    
    
    else ()
     
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
