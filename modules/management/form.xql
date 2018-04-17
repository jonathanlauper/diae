xquery version "1.0";
(: --------------------------------------
   Case tracker pilote

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Form fields generation for user management module

   March 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)
declare default element namespace "http://www.w3.org/1999/xhtml";

import module namespace form = "http://oppidoc.com/ns/xcm/form" at "../../../xcm/lib/form.xqm";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace enterprise = "http://oppidoc.com/ns/xcm/enterprise" at "../../../xcm/modules/enterprises/enterprise.xqm";
import module namespace person = "http://oppidoc.com/ns/xcm/person" at "../../../xcm/modules/persons/person.xqm";

declare namespace xt = "http://ns.inria.org/xtiger";
declare namespace site = "http://oppidoc.com/oppidum/site";

declare option exist:serialize "method=xml media-type=text/xml";

let $cmd := request:get-attribute('oppidum.command')
let $lang := string($cmd/@lang)
let $target := oppidum:get-resource(oppidum:get-command())/@name
let $goal := request:get-parameter('goal', 'read')
return
  if ($target = ('profile')) then
    <site:view>
      <site:field Key="function">
        { form:gen-selector-for('Functions', $lang, ";multiple=no;typeahead=no") }
      </site:field>
      <site:field Key="services">
        { form:gen-selector-for('Services', $lang, " optional;multiple=yes;typeahead=no;xvalue=ServiceRef") }
      </site:field>
      <site:field Key="cantonal-antenna">
        { form:gen-selector-for('CantonalAntennas', $lang, " optional;multiple=no;typeahead=no") }
      </site:field>
      <site:field Key="coladmin-entity">
        { form:gen-selector-for('CollaborativeEntities', $lang, ";multiple=no;typeahead=no") }
      </site:field>
    </site:view>
    else   if ($target = ('contractors')) then
    <site:view>
      <site:field Key="contractor">
        { enterprise:gen-enterprise-selector($lang, ";typeahead=yes") }
      </site:field>
      <site:field Key="contact">
        { person:gen-person-selector($lang, ";multiple=yes;typeahead=yes;xvalue=PersonKey") }
      </site:field>
      
 <!--    <site:field Key="contractor">
      { enterprise:gen-enterprise-choice-selector($lang, "filter=event optional;class=span12 a-control") }
        </site:field>
      <site:field Key="contact">
<xt:use types="choice"  
        param="filter=event optional;class=span12 a-control"
        ></xt:use>
                    </site:field>-->
    </site:view>
    
  else (: only constant fields  :)
    <site:view/>
