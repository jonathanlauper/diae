xquery version "1.0";
(: --------------------------------------
   Case Tracker Reference application

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   CRUD controller to manage UserProfile in Person

   Implements Ajax table row update protocol

   TODO: find a way to factorize into XCM 
         (move POST actions to template via XALAction Type="eval" ?)

   July 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

import module namespace sm = "http://exist-db.org/xquery/securitymanager";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace request="http://exist-db.org/xquery/request";

import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace ajax = "http://oppidoc.com/ns/xcm/ajax" at "../../../xcm/lib/ajax.xqm";
import module namespace access = "http://oppidoc.com/ns/xcm/access" at "../../../xcm/lib/access.xqm";
import module namespace account = "http://oppidoc.com/ns/xcm/account" at "../../../xcm/modules/users/account.xqm";
import module namespace display = "http://oppidoc.com/ns/xcm/display" at "../../../xcm/lib/display.xqm";
import module namespace template = "http://oppidoc.com/ns/ctracker/template" at "../../lib/template.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Returns Ajax protocol to update roles column in user management table
   ====================================================================== 
:)
declare function local:make-ajax-response( $key as xs:string, $roles as element()?, $id as xs:string ) {
  <Response Status="success">
    <Payload Key="{$key}">
      <Name>{ display:gen-roles-for($roles, 'en') }</Name>
      <Value>{ $id }</Value>
    </Payload>
  </Response>
};

(: ======================================================================
   Guaranties that Person with $id will be the only one to have a role $func-ref
   by deleting the same Role from any other Person's UserProfile
   ======================================================================
:)
declare function local:enforce-uniqueness ( $id as xs:string, $func-ref as xs:string?, $serv-ref as xs:string?, $ca-ref as xs:string?) {
  if (exists($func-ref)) then
    for $p in globals:collection('persons-uri')//Person[UserProfile/Roles/Role/FunctionRef[. = $func-ref]][Id ne $id]
    let $role := $p/UserProfile/Roles/Role[FunctionRef = $func-ref]
    where ($serv-ref and ($role/ServiceRef = $serv-ref)) or ($ca-ref and ($role/RegionalEntityRef = $ca-ref))
    return
      update delete $role
  else
    ()
};

(: ======================================================================
   SynchronizeS A Person eXist-DB groups with his/her UserProfile groups
   Does nothing if the Person hasn't got a Username nor an eXist-DB login
   Ajax response contains a payload with a Key attribute to close modal windows (see management.js)
   NOTE: must be called as DBA (or on self account)
   ======================================================================
:)
declare function local:synch-user-groups( $person as element() ) {
  let $login := string($person//Username)
  let $uname := concat($person/Information/Name/FirstName, ' ', $person/Information/Name/LastName)
  let $results := local:make-ajax-response('profile', $person/UserProfile/Roles, $person/Id)
  return
    if ($login and sm:user-exists($login)) then
      let $has := sm:get-user-groups($login)
      let $should := account:gen-groups-for-user($person)
      return 
        (
        if ( (every $x in $has satisfies $x = $should) and (every $y in $should satisfies $y = $has) ) then
          ()
        else
          account:set-user-groups($login, $should),
        let $msg := concat($uname, " (", string-join($should, ", "), ")")
        return
          ajax:report-success('PROFILE-UPDATED', $msg, $results)
        )
    else
      ajax:report-success('PROFILE-UPDATED-WOACCESS', $uname, $results)
};

(: *** MAIN ENTRY POINT *** :)
let $m := request:get-method()
let $cmd := oppidum:get-command()
let $lang := string($cmd/@lang)
let $id := string($cmd/resource/@name)
let $person := globals:collection('persons-uri')//Person[Id = $id]
let $access := access:get-entity-permissions('update', 'UserProfile', $person) (: 'update' implies 'read' :)
return
  if (local-name($access) eq 'allow') then
    if ($m = 'POST') then
      let $submitted := oppidum:get-data()
      let $service-head := $submitted/Roles/Role[FunctionRef[. eq '2']]
      let $region-head := $submitted/Roles/Role[FunctionRef[. eq '3']]
      let $validation := template:do-validate-resource('profile', $person, $person/UserProfile, $submitted)
      return
        if (local-name($validation) eq 'valid') then 
          let $update := template:update-resource('profile', $person, $person/UserProfile, $submitted, $lang)
          return
            if (local-name($update) ne 'error') then (
              local:enforce-uniqueness($id, $service-head/FunctionRef, $service-head/ServiceRef, ()),
              local:enforce-uniqueness($id, $region-head/FunctionRef, (), $region-head/CantonalAntennaRef),
              system:as-user(account:get-secret-user(), account:get-secret-password(),
                local:synch-user-groups($person))
              )
            else
              $update
        else
          $validation
    else (: assumes GET :)
      template:gen-read-model('profile', $person, $person/UserProfile, $lang)
  else
    $access
