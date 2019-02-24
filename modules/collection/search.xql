xquery version "1.0";
(: --------------------------------------
   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   May 2013 - (c) Copyright 2013 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

import module namespace request="http://exist-db.org/xquery/request";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace submission = "http://oppidoc.com/ns/xcm/submission" at "../../../xcm/modules/submission/submission.xqm";
(:import module namespace search = "http://oppidoc.com/ns/xcm/search" at "search.xqm";:)

declare option exist:serialize "method=xml media-type=text/xml";

declare variable $col-uri := '/db/sites/diae/pages/images/collections.xml';


declare function local:fetch-algorithm( $request as element() , $lang as xs:string ) as element()* {
  if ((count($request/*/*) + count($request/*[local-name(.)][normalize-space(.) != ''])) = 0) then (: empty request :)
    if (request:get-parameter('_confirmed', '0') = '0') then
      (
      <Confirm/>,
      response:set-status-code(202)
      )
    else
        ()
  else
    <Results>{ local:find-algorithm($request, $lang)}</Results>
};

declare function local:find-algorithm( $request as element(), $lang as xs:string ) as element()* {
    
    let $algorithms := globals:collection('global-info-uri')//Description[@Lang = $lang]//Selector[@Name eq 'Algorithms']
    
    let $algo-url := $request//Algorithm/text()
    
    (:TODO fetch algorithm description from algo-url and build form and store it wherever form.xql or whoever fetches the correct form xml file:)
    return
        <URL>{$algo-url}</URL>
};

let $m := request:get-method()
let $cmd := oppidum:get-command()
let $lang := string($cmd/@lang)
return
  if ($m eq 'POST') then (: executes search requests :)
    let $request := oppidum:get-data()
    return
      <Search>
        {
            local:fetch-algorithm($request, $lang)
        }
      </Search>
  else (: shows search page with default results - assumes GET :)
    <Search Initial="true" Controller="collection">
      {
        let $saved-request := submission:get-default-request('AlgorithmRequest')
        return
          if (local-name($saved-request) = local-name($submission:empty-req)) then
            <NoRequest/>
          else
            (:search:fetch-collection-results($saved-request, $lang):)()
      }
    </Search>
