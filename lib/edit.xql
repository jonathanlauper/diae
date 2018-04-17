xquery version "1.0";
(: --------------------------------------
   DocEng 2105

   Author(s): Christine Vanoirbeek

   CRUD controller to manage welcome page content inside the database.
   
   August 2013 - (c) Copyright 2013 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "globals.xqm";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

let $cmd := oppidum:get-command()

return
  <Display>
    <Topic Editor="true">
      <Cancel>{concat($cmd/@base-url,$cmd/@trail)}</Cancel>
      <Template>../templates/topic?goal=create</Template>
      <Resource>content.xml</Resource>
    </Topic>
  </Display>