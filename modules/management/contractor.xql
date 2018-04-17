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
   Validates submitted contractors
   ======================================================================
:)declare function local:validate-contractors-submission( $data as element() ) as element()* {
  (
    )
};

(: ======================================================================
   Updates external services contractors
   ======================================================================
:)
declare function local:update-contractors( $data as element() ) as element()* {
let $enterprises := fn:doc($globals:enterprises-uri)/Enterprises/Enterprise[IsContractor]
let $persons := fn:doc($globals:persons-doc)/Persons/Person[ContractorKey]

  return (
    for $i in $enterprises
    return
    update value $i/IsContractor with 0,
    
for $i in $persons
    return
    update value $i/ContractorKey with 0,

  for $i in $data//Contractors/Contractor
    return
    (
    if($enterprises[Id=$i/ContractorKey/text()]) then
        update value $enterprises[Id=$i/ContractorKey/text()]/IsContractor with 1
    else
        update insert <IsContractor>1</IsContractor> into fn:doc($globals:enterprises-uri)/Enterprises/Enterprise[Id=$i/ContractorKey/text()],

    for $j in $i/Contact/PersonKey
    return
     if($persons[Id=$j/text()]) then
        update value $persons[Id=$j/text()]/ContractorKey with $i/ContractorKey/text()
    else
        update insert <ContractorKey>{$i/ContractorKey/text()}</ContractorKey> into fn:doc($globals:persons-doc)/Persons/Person[Id=$j/text()]
),
  
    ajax:report-success('ACTION-UPDATE-SUCCESS', ())
    )[last()]
};

(: ======================================================================
   Returns the list of contractors dor external services
   ======================================================================
:)
declare function local:gen-contractors-model( $goal as xs:string) as element()* {

  <ExternalServicesContractors>
    {
    let $contractors := fn:doc($globals:enterprises-uri)/Enterprises/Enterprise[IsContractor='1']
    let $contacts := fn:doc($globals:persons-doc)/Persons/Person[exists(ContractorKey) and not(ContractorKey='0')]
    return
      if (exists($contractors)) then
        <Contractors>
        {
        for $i in $contractors
        return
          <Contractor>
            <ContractorKey>
              { $i/Id/text() }
            </ContractorKey>
            <Contact>
              {
              for $j in $contacts[ContractorKey=$i/Id/text()]
              return
                <PersonKey>
                  { $j/Id/text() }
                </PersonKey>
              }
            </Contact>
          </Contractor>
        }
        </Contractors>
      else
        ()
    }
  </ExternalServicesContractors>
};

let $m := request:get-method()
let $cmd := oppidum:get-command()
let $name := string($cmd/resource/@name)
let $lang := string($cmd/@lang)
return
  if ($m = 'POST') then
    let $data := oppidum:get-data()
    let $errors := local:validate-contractors-submission($data)
    return
      if (empty($errors)) then
        local:update-contractors($data)
      else
        ajax:report-validation-errors($errors)
  else (: assumes GET :)
    let $goal := request:get-parameter('goal', 'read')
    return
    
      local:gen-contractors-model($goal)
    
