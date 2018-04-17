xquery version "1.0";
(: --------------------------------------
   Case Tracker platinn coaching application

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Generates extension points for Annex formular

   January 2018 - (c) Copyright 2018 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

declare default element namespace "http://www.w3.org/1999/xhtml";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";

declare namespace xt = "http://ns.inria.org/xtiger";
declare namespace site = "http://oppidoc.com/oppidum/site";

declare option exist:serialize "method=xml media-type=text/xml";

let $cmd := oppidum:get-command()
let $file_upload := concat($cmd/@base-url, replace($cmd/@trail, "/templates.*", "/docs"))
let $file_base := $file_upload
return
  (: use comma separated file_type list if upgrading AXEL ! :)
  <site:view>
    <site:field Key="file" filter="no">
    <xt:use types="file" label="LinkRef"
      param="filter=event;file_URL={$file_upload};file_base={$file_base};file_gen_name=manual;file_type=application/pdf application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet application/vnd.ms-powerpoint application/vnd.openxmlformats-officedocument.presentationml.presentation;file_reset=empty;file_type_message=Vous devez sélectionner un document PDF ou un document Microsoft Office (Word, Excel, Power Point)"/>
    </site:field>
  </site:view>
