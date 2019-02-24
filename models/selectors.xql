xquery version "1.0";
(: --------------------------------------
   XQuery Business Application Development Framework

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Sample service to return options to dynamically load into a 'choice' plugin
   using an 'ajax' binding

   February 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)
declare namespace json="http://www.json.org";

import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../xcm/lib/globals.xqm";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";

declare option exist:serialize "method=json media-type=application/json";

let $collections := fn:doc('/db/sites/diae/pages/images/collections.xml')

return
    if (oppidum:get-command()/resource/@name eq 'images') then
        let $id := request:get-parameter('collections', ())
        return
            <sample cache='{$id}'>
             { 
             for $image at $pos in $collections//Collection[Id eq $id]/Images/Image
                return    
                    <items>
                           { if($pos = 1) then
                                  attribute { 'json:array' } { 'true' } 
                              else ()
                            } 
                            <label>{$image/Ref/text()}</label>
                            <value>{$pos}</value>
                    </items>
              }
            </sample>
        
        else()

           

    
       
    
    (:
return  
  if (oppidum:get-command()/resource/@name eq 'contacts') then
    let $company := request:get-parameter('company', ())
    return $contacts/sample[@cache eq $company]
  else
    let $contact := request:get-parameter('contact', ())
    return (: random :)
      <sample cache="{ $contact }">
        {
        for $i in 1 to util:random(9) + 1
        return
          <items>
            <label>
              { 
              codepoints-to-string(
                for $i in 1 to util:random(7) + 3
                return 65 + util:random(25)
              )
              }
            </label>
            <value>{ $i }</value>
          </items>
        }
      </sample>
      
      
      
return
    if (oppidum:get-command()/resource/@name eq 'images') then
        let $id := request:get-parameter('collections', ())
        return $collections//Collection[Id eq $id]
        
        else()

:)