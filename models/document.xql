xquery version "1.0";
(: --------------------------------------
   SMEi cockpit

   Creation: Stéphane Sire <s.sire@oppidoc.fr>

   Generic CRUD controller to manage a document in a Case or Activity workflow

   TODO: 
   - add missing document parameter fallback ro resource name
   - execute 'dependency' data templates after update
   - call 'validate' data template for validation when available

   EXTRA:
   - create XAL redirect action to manage situation where updating a document
  changes user's rights (e.g. pure case initiator defining a KAM, then s/he 
  cannot update it and should be redirected)
 
   March 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

import module namespace request="http://exist-db.org/xquery/request";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../lib/globals.xqm";
import module namespace template = "http://oppidoc.com/ns/ctracker/template" at "../lib/template.xqm";
import module namespace access = "http://oppidoc.com/ns/xcm/access" at "../../xcm/lib/access.xqm";
import module namespace ajax = "http://oppidoc.com/ns/xcm/ajax" at "../../xcm/lib/ajax.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Validates submitted data.
   Returns a list of errors to report or the empty sequence.
   TODO: see above
   ======================================================================
:)
declare function local:validate-submission( $form as element() ) as element()* {
  let $errors := (
    )
  return $errors
};

let $m := request:get-method()
let $cmd := oppidum:get-command()
let $lang := string($cmd/@lang)
let $goal := request:get-parameter('goal', 'read')
let $document := request:get-attribute('xquery.document')
let $workflow := request:get-attribute('xquery.workflow')
let $case-no := tokenize($cmd/@trail, '/')[2]
let $activity-no := if ($workflow eq 'Activity') then tokenize($cmd/@trail, '/')[4] else ()
let $case := fn:collection($globals:cases-uri)/Case[No eq $case-no]
let $activity := if ($activity-no) then $case/Activities/Activity[No = $activity-no] else ()
return
  (: FIXME: access:check-workflow-permissions ? :)
  if  (access:check-omnipotent-user() or access:check-tab-permissions($goal, $document, $case, $activity)) then
    if ($m = 'POST') then
      let $form := oppidum:get-data()
      let $errors := local:validate-submission($form)
      return
        if (empty($errors)) then
          template:update-resource($document, $case, $activity, $form, $lang)
        else
          ajax:report-validation-errors($errors)
    else (: assumes GET :)
      template:gen-read-model($document, $case, $activity, $lang)
  else
    oppidum:throw-error('FORBIDDEN', ())
