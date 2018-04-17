xquery version "1.0";
(: --------------------------------------
   DocEng 2015 Website

   Creation: Christine Vanoirbeek

   May 2013 - (c) Copyright 2013 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)


import module namespace request="http://exist-db.org/xquery/request";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";

import module namespace access="http://oppidoc.com/oppidum/access" at "access.xqm";
 
declare option exist:serialize "method=xml media-type=text/xml";

let $m := request:get-method()
let $cmd := oppidum:get-command()
let $next := request:get-parameter('next', 'frd')
let $content := fn:doc(oppidum:path-to-ref())/Topic
return
  <Root>
    <Actions>
    {
    if (access:resource-edit-allowed($cmd/@trail)) then
        <Action Name="edit">{concat($cmd/@base-url,$cmd/@trail,'/edit')}</Action>
    else ()
    }
    </Actions>
    <Topic>
    {$content/*}
     

       <Title> {request:get-url()}</Title>
    

    </Topic>
  </Root>
  
