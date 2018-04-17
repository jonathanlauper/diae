xquery version "1.0";
(: ------------------------------------------------------------------
   Case Tracker platinn coaching application

   Creation: Stéphane Sire <s.sire@oppidoc.fr>

   Controller managing AXEL 'file' plugin upload protocol to upload an annex document 
   inside an Activity inside a Case

   TODO: 
   - extend controller to support upload inside a Case

   January 2018 - (c) Copyright 2018 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

import module namespace request = "http://exist-db.org/xquery/request";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace user = "http://oppidoc.com/ns/xcm/user" at "../../../xcm/lib/user.xqm";
import module namespace access = "http://oppidoc.com/ns/xcm/access" at "../../../xcm/lib/access.xqm";
import module namespace annex = "http://oppidoc.com/ns/xcm/annex" at "annex.xqm";

declare option exist:serialize "method=xml media-type=application/xml indent=no";

(: ======================================================================
   Saves submitted binary file and record it with the Activity resources
   Returns success message with payload (data model to support annex table 
   row generation) or error
   ======================================================================
:)
declare function local:write-annex( $cmd as element(), $activity as element() ) {
  let $lang := string($cmd/@lang)
  let $res := annex:submit-file($cmd)
  return
    if (local-name($res) eq 'success') then (:binary file saved in binary collection :)
      let $meta := (: TODO: use a XAL data template ? :)
        <Resource>
          <Date>{ current-dateTime() }</Date>
          <SenderKey>{ user:get-current-person-id () }</SenderKey>
          <CurrentStatusRef>{ $activity/StatusHistory/CurrentStatusRef/text() }</CurrentStatusRef>
          <File>{ $res/text() }</File>
        </Resource>
      return (
        if ($activity/Resources) then
          update insert $meta into $activity/Resources
        else
          update insert <Resources>{ $meta }</Resources> into $activity,
        <success>
          {
          $res/message,
          <payload>
            {
            annex:gen-annexe-for-viewing ($lang, $meta, $res, $activity/No, (), true())
            }
          </payload>
          }
         </success>,
         util:declare-option("exist:serialize", "method=xml media-type=application/xml"),
         response:set-status-code(201) (: 'file' upload protocol :)
        )
    else
      $res
};

(:::::::::::::  BODY  ::::::::::::::)

let $m := request:get-method()
let $cmd := oppidum:get-command()
let $case-no := tokenize($cmd/@trail, '/')[2]
let $ocr := fn:collection($globals:ocr-uri)/OCR

return
  if ($m = 'POST') then (: sanity check :)
    if (access:check-entity-permissions('create', 'Annex', $ocr)) then 
      if (request:get-parameter('xt-file-preflight', ())) then
        annex:submit-preflight($cmd)
      else 
        local:write-annex($cmd, $ocr)
    else
      ()
  else
    oppidum:throw-error("URI-NOT-FOUND", ())
