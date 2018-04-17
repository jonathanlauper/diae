xquery version "1.0";
(: --------------------------------------
   Case Tracker platinn coaching application

   Creation: Stéphane Sire <s.sire@oppidoc.fr>

   Controller to delete an Annexe

   LIMITATION : 
   - limited to annexes of Case/Activity because of the way the Case base collection is computed

   January 2018 - (c) Copyright 2018 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)
import module namespace xdb = "http://exist-db.org/xquery/xmldb";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace access = "http://oppidoc.com/ns/xcm/access" at "../../../xcm/lib/access.xqm";
import module namespace ajax = "http://oppidoc.com/ns/xcm/ajax" at "../../../xcm/lib/ajax.xqm";
import module namespace custom = "http://oppidoc.com/ns/application/custom" at "../../app/custom.xqm";
import module namespace annex = "http://oppidoc.com/ns/xcm/annex" at "annex.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Deletes requested Annex
   Note: no rollback, delete resource record in Activity then delete binary file
   ======================================================================
:)
declare function local:delete-annex( $cmd as element(), $activity as element() ) {
  let $col-uri := annex:get-coaching-base-collection-uri($cmd)
  let $filename := concat($cmd/resource/@name, '.', $cmd/@format)
  let $resource := $activity/Resources/Resource[File eq $filename]
  let $file-uri := concat($col-uri, '/', $cmd/resource/@resource, '/', $filename)
  return
    if (access:check-entity-permissions('delete', 'Annex', $activity, $resource)) then (
      if ($resource) then
        update delete $resource
      else
        (),
      if (util:binary-doc-available($file-uri)) then
        xdb:remove(concat($col-uri, '/', $cmd/resource/@resource), $filename)
      else
        (),
      oppidum:throw-message('DELETE-ANNEXE-SUCCESS', $filename)
      )[last()]
    else
      oppidum:throw-error("FORBIDDEN", ())
};

let $m := request:get-method()
let $cmd := oppidum:get-command()
let $case-no := tokenize($cmd/@trail, '/')[2]
let $case := fn:collection($globals:cases-uri)/Case[No eq $case-no]
let $activity-no := tokenize($cmd/@trail, '/')[4]
let $activity := $case/Activities/Activity[No = $activity-no]
let $errors := custom:pre-check-activity($case, $activity, 'GET', (), ())
return
  if (empty($errors) and ($m = 'POST') and (request:get-parameter('_delete', ()) eq "1")) then (:($m = 'DELETE'):)
    local:delete-annex($cmd, $activity)
  else
    ajax:throw-error('URI-NOT-SUPPORTED', ())
