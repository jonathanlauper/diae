xquery version "1.0";
(: --------------------------------------
   Platinn Coaching application

   Creation: Stéphane Sire <s.sire@oppidoc.fr>

   Serves binary files from the database. Sets a Cache-Control header.

   LIMITATION : 
   - limited to annexes of Case because of the way the Case base collection is computed

   TODO:
   - improve Cache-Control (HTTP 1.1) with Expires / Date (HTTP 1.0)
   - (no need for must-revalidate / Last-Modified since uploaded documents never change)
   - use ETag headers

   August 2013 - (c) Copyright 2013 Oppidoc SARL. All Rights Reserved.
   -------------------------------------- :)

import module namespace request = "http://exist-db.org/xquery/request";
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace access = "http://oppidoc.com/ns/xcm/access" at "../../../xcm/lib/access.xqm";
import module namespace custom = "http://oppidoc.com/ns/application/custom" at "../../app/custom.xqm";
import module namespace mime = "http://platinn.ch/coaching/mime" at "mime.xqm";
import module namespace annex = "http://oppidoc.com/ns/xcm/annex" at "annex.xqm";

declare option exist:serialize "method=text media-type=text/plain indent=no";

let $cmd := request:get-attribute('oppidum.command')
let $case-no := tokenize($cmd/@trail, '/')[2]
let $case := fn:collection($globals:cases-uri)/Case[No eq $case-no]
let $activity-no := tokenize($cmd/@trail, '/')[4]
let $activity := $case/Activities/Activity[No = $activity-no]
(: TODO: stronger access control :)
let $errors := custom:pre-check-activity($case, $activity, 'GET', (), ())
return
  if (empty($errors)) then
    let $dur := request:get-attribute('xquery.cache')
    let $cache := if ($dur) then
                    if ($dur = 'no-cache') then
                      $dur
                    else
                      concat('public, max-age=', $dur)
                  else
                    'public, max-age=900000'
    let $pragma := if ($cache = 'no-cache') then $cache else 'x'
    let $col-uri := annex:get-coaching-base-collection-uri($cmd)
    let $file-uri := concat($col-uri, '/', $cmd/resource/@resource, '/', $cmd/resource/@name, '.', $cmd/@format)
    return
     if (util:binary-doc-available($file-uri)) then
       let $file := util:binary-doc($file-uri)
       return (
         response:set-header('Pragma', $pragma),
         response:set-header('Cache-Control', $cache),
         if ($cmd/@format != 'pdf') then (
           (: with this Content-Disposition the browser detects the file name :)
           response:set-header('Content-Disposition', concat("attachment; filename=", concat($cmd/resource/@name, '.', $cmd/@format))),
           response:stream-binary($file, mime:get-mime-for-extension($cmd/@format))
           )
         else
          (: adds "inline; " in front of Content-Disposition and Firefox does not take filename into account (!) :)
          response:stream-binary($file, mime:get-mime-for-extension($cmd/@format), 
            concat("attachment; filename=", concat($cmd/resource/@name, '.', $cmd/@format)))
       )
     else
       ( concat("Erreur 404 : ", $file-uri), response:set-status-code(404) )
  else
    $errors
