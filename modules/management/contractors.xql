xquery version "1.0";
(: --------------------------------------
   Case tracker pilote application

   Creator: Fouad Slimane(fouad.slimane@gmail.com)
   February 2018 - (c) Copyright 2018 Docetis SARL. All Rights Reserved.
   ----------------------------------------------- :)

import module namespace request="http://exist-db.org/xquery/request";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace ajax = "http://oppidoc.com/ns/xcm/ajax" at "../../../xcm/lib/ajax.xqm";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Returns the list of contractors for the external services
   ======================================================================
:)
declare function local:gen-contractors-model( $goal as xs:string) as element()* {

  <ExternalServicesContractors Goal="{$goal}">
    {let $contractors := fn:doc($globals:enterprises-uri)/Enterprises/Enterprise[IsContractor='1']
    let $contacts := fn:doc($globals:persons-doc)/Persons/Person[exists(ContractorKey) and not(ContractorKey='0')]
    return
    <Contractors>
    {for $i in $contractors
    return
    <Contractor>
    <Field Label="External service provider" Tag="ContractorKey" loc="term.contractor">
      { $i/Information/Name/text() }
    </Field>
   <Field Label="Contact person(s)" Tag="ContactRef">
    {string-join(for $j in $contacts[ContractorKey=$i/Id/text()]
    return
    
     concat($j/Information/Name/LastName,' ',$j/Information/Name/FirstName),', ')
   
    }
     </Field>
     <Seperator/>
    </Contractor>
    }
    </Contractors>
    }
  </ExternalServicesContractors>

};

let $m := request:get-method()
let $cmd := oppidum:get-command()
let $name := string($cmd/resource/@name)
let $lang := string($cmd/@lang)
return
    let $goal := request:get-parameter('goal', 'read')
    return
      local:gen-contractors-model($goal)
