xquery version "1.0";
(: --------------------------------------
   DocEng 2105

   Author(s): Christine Vanoirbeek

   Returns the content of current topic to be used by the topic template
   
   August 2013 - (c) Copyright 2013 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)


import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "globals.xqm";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

let $content := fn:doc(oppidum:path-to-ref())/Topic

return
     $content
 