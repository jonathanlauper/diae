xquery version "1.0";
(:~ 
 : Case tracker pilote application
 :
 : This module provides the helper functions that depend on the application
 : specific data model, such as :
 : <ul>
 : <li> label generation for different data types (display)</li>
 : <li> drop down list generation to include in formulars (form)</li>
 : <li> miscellanous utilities (misc)</li>
 : </ul>
 : 
 : You most probably need to update that module to reflect your data model.
 : 
 : NOTE: actually eXist-DB does not support importing several modules
 : under the same prefix. Once this is supported this module could be 
 : splitted into corresponding modules (display, form, access, misc)
 : to be merged through import with their generic module counterpart.
 :
 : January 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
 :
 : @author Stéphane Sire
 :)
module namespace custom = "http://oppidoc.com/ns/application/custom";
declare namespace site = "http://oppidoc.com/oppidum/site";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../lib/globals.xqm";
import module namespace display = "http://oppidoc.com/ns/xcm/display" at "../../xcm/lib/display.xqm";
import module namespace cache = "http://oppidoc.com/ns/xcm/cache" at "../../xcm/lib/cache.xqm";
import module namespace form = "http://oppidoc.com/ns/xcm/form" at "../../xcm/lib/form.xqm";
import module namespace user = "http://oppidoc.com/ns/xcm/user" at "../../xcm/lib/user.xqm";
import module namespace access = "http://oppidoc.com/ns/xcm/access" at "../../xcm/lib/access.xqm";
import module namespace misc = "http://oppidoc.com/ns/xcm/misc" at "../../xcm/lib/util.xqm";
import module namespace enterprise = "http://oppidoc.com/ns/xcm/enterprise" at "../../xcm/modules/enterprises/enterprise.xqm";

declare namespace xt = "http://ns.inria.org/xtiger";

declare function custom:number( $text as xs:string? ) as xs:double {
  if (exists($text) and ($text ne '') and ($text castable as xs:double)) then
    number($text)
  else
    0
};

(: ======================================================================
   Returns a localized string
   ====================================================================== 
:)
declare function custom:get-local-string( $key as xs:string, $lang as xs:string ) as xs:string {
  let $res := globals:collection('dico-uri')//site:Translations[@lang = $lang]/site:Translation[@key = $key]/text()
  return
    if ($res) then
      $res
    else
      concat('missing [', $key, ', lang="', $lang, '"]')
};

(: ======================================================================
  Same as form:gen-person-selector but with person's enterprise as a satellite
  It doubles request execution times
   ======================================================================
:)
declare function custom:gen-person-enterprise-selector ( $lang as xs:string, $params as xs:string ) as element() {
  let $pairs :=
      for $p in globals:collection('persons-uri')//Person 
      let $fn := $p/Information/Name/FirstName
      let $ln := $p/Information/Name/LastName
      let $pe := $p/Information/EnterpriseKey
      order by $ln ascending
      return
        let $en := if ($pe) then globals:doc('enterprises-uri')//Enterprise[Id = $pe]/Information/Name else ()
        return
          <Name id="{$p/Id/text()}">{concat(replace($ln,' ','\\ '), '\ ', replace($fn,' ','\\ '))}{if ($en) then concat('::', replace($en,' ','\\ ')) else ()}</Name>
  return
    let $ids := string-join(for $n in $pairs return string($n/@id), ' ') (: FLWOR to defeat document ordering :)
    let $names := string-join(for $n in $pairs return $n/text(), ' ') (: idem :)
    return
      <xt:use types="choice" values="{$ids}" i18n="{$names}" param="select2_complement=town;{form:setup-select2($params)}"/>
};

(: ======================================================================
   Generates XTiger XML 'choice' element for selecting a coach (for /stage)
   Optimized version showing only coach with an activity
   ======================================================================
:)
declare function custom:gen-coach-selector ( $lang as xs:string, $params as xs:string ) as element() {
  let $pairs :=
      for $ref in distinct-values(fn:collection($globals:cases-uri)//ResponsibleCoachKey)
      let $p := fn:collection($globals:persons-uri)//Person[Id eq $ref]
      let $name := $p/Information/Name
      let $fn := if ($name) then $name/FirstName else "reference"
      let $ln := if ($name) then $name/LastName else "Unknown"
      order by $ln ascending
      return
         <Name id="{$ref}">{concat(replace($ln,' ','\\ '), '\ ', replace($fn,' ','\\ '))}</Name>
  return
    let $ids := string-join(for $n in $pairs return string($n/@id), ' ') (: FLWOR to defeat document ordering :)
    let $names := string-join(for $n in $pairs return $n/text(), ' ') (: idem :)
    return
      <xt:use types="choice" values="{$ids}" i18n="{$names}" param="{form:setup-select2($params)}"/>
};

(: ======================================================================
   Generates selector with list of all given persons by tag
   ======================================================================
:)
declare function custom:gen-person-tag-selector ( $tag as xs:string, $lang as xs:string, $params as xs:string ) as element() {
  let $pairs :=
      for $ref in distinct-values(fn:collection($globals:cases-uri)/Case/Management/*[local-name() eq $tag])
      let $p := fn:collection($globals:persons-uri)//Person[Id eq $ref]
      let $name := $p/Information/Name
      let $fn := if ($name) then $name/FirstName else "reference"
      let $ln := if ($name) then $name/LastName else "Unknown"
      order by $ln ascending
      return
        <Name id="{$p/Id/text()}">{concat(replace($ln,' ','\\ '), '\ ', replace($fn,' ','\\ '))}</Name>
  return
    if (count($pairs) > 0) then
      let $ids := string-join(for $n in $pairs return string($n/@id), ' ') (: FLWOR to defeat document ordering :)
      let $names := string-join(for $n in $pairs return $n/text(), ' ') (: idem :)
      return
        <xt:use types="choice" values="{$ids}" i18n="{$names}" param="{form:setup-select2($params)}"/>
    else
      <xt:use types="constant" param="noxml=true;class=uneditable-input span2">None assigned yet</xt:use>
};

(: ======================================================================
   Generates selector with list of all KAMs (for /Stage request)
   Optimized version showing only account managers with a case
   ======================================================================
:)
declare function custom:gen-kam-selector ( $lang as xs:string, $params as xs:string ) as element() {
  let $pairs :=
      for $ref in distinct-values(fn:collection($globals:cases-uri)//AccountManagerKey)
      let $p := fn:collection($globals:persons-uri)//Person[Id eq $ref]
      let $name := $p/Information/Name
      let $fn := if ($name) then $name/FirstName else "reference"
      let $ln := if ($name) then $name/LastName else "Unknown"
      order by $ln ascending
      return
        <Name id="{$p/Id/text()}">{concat(replace($ln,' ','\\ '), '\ ', replace($fn,' ','\\ '))}</Name>
  return
    if (count($pairs) > 0) then
      let $ids := string-join(for $n in $pairs return string($n/@id), ' ') (: FLWOR to defeat document ordering :)
      let $names := string-join(for $n in $pairs return $n/text(), ' ') (: idem :)
      return
        <xt:use types="choice" values="{$ids}" i18n="{$names}" param="{form:setup-select2($params)}"/>
    else
      <xt:use types="constant" param="noxml=true;class=uneditable-input span2">None assigned yet</xt:use>
};

(: ======================================================================
   Generates selector with list of all legacy KAMs (which may no more be KAM)
   and current KAM
   ======================================================================
:)
declare function custom:gen-legacy-kam-selector ( $lang as xs:string, $params as xs:string ) as element() {
  let $pairs :=
      for $ref in distinct-values(
                    (
                    fn:collection($globals:cases-uri)//AccountManagerKey,
                    fn:collection($globals:persons-uri)//Person[UserProfile//Role[FunctionRef = '5']]/Id
                    )
                    )
      let $p := fn:collection($globals:persons-uri)//Person[Id eq $ref]
      let $name := $p/Information/Name
      let $fn := if ($name) then $name/FirstName else "reference"
      let $ln := if ($name) then $name/LastName else "Unknown"
      order by $ln ascending
      return
        <Name id="{$p/Id/text()}">{concat(replace($ln,' ','\\ '), '\ ', replace($fn,' ','\\ '))}</Name>
  return
    if (count($pairs) > 0) then
      let $ids := string-join(for $n in $pairs return string($n/@id), ' ') (: FLWOR to defeat document ordering :)
      let $names := string-join(for $n in $pairs return $n/text(), ' ') (: idem :)
      return
        <xt:use types="choice" values="{$ids}" i18n="{$names}" param="{form:setup-select2($params)}"/>
    else
      <xt:use types="constant" param="noxml=true;class=uneditable-input span2">None assigned yet</xt:use>
};

(: ======================================================================
   Generates selector with list of all person actually registered as KAM
   ======================================================================
:)
declare function custom:gen-active-kam-selector ( $lang as xs:string, $params as xs:string ) as element() {
  let $pairs :=
      for $ref in fn:collection($globals:persons-uri)//Person[UserProfile//Role[FunctionRef = '5']]/Id
      let $p := fn:collection($globals:persons-uri)//Person[Id eq $ref]
      let $name := $p/Information/Name
      let $fn := if ($name) then $name/FirstName else "reference"
      let $ln := if ($name) then $name/LastName else "Unknown"
      order by $ln ascending
      return
        <Name id="{$p/Id/text()}">{concat(replace($ln,' ','\\ '), '\ ', replace($fn,' ','\\ '))}</Name>
  return
    if (count($pairs) > 0) then
      let $ids := string-join(for $n in $pairs return string($n/@id), ' ') (: FLWOR to defeat document ordering :)
      let $names := string-join(for $n in $pairs return $n/text(), ' ') (: idem :)
      return
        <xt:use types="choice" values="{$ids}" i18n="{$names}" param="{form:setup-select2($params)}"/>
    else
      <xt:use types="constant" param="noxml=true;class=uneditable-input span2">None assigned yet</xt:use>
};

(: ======================================================================
   Generates selector for creation years
   NOTE: for stats
   ======================================================================
:)
declare function custom:gen-creation-year-selector ( ) as element() {
  let $years := 
    for $y in distinct-values(globals:doc('enterprises-uri')//CreationYear)
    where matches($y, "^\d{4}$")
    order by $y descending
    return $y
  return
    <xt:use types="choice" values="{ string-join($years, ' ') }" param="select2_dropdownAutoWidth=on;select2_width=off;class=year a-control;filter=optional select2;multiple=no"/>
};

(: ======================================================================
   Generates XTiger XML 'choice' element for selecting a  Case Impact (Vecteur d'innovation)
   NOTE: for stats
   TODO: 
   - caching
   - use Selector / Group generic structure with a gen-selector-for( $name, $group, $lang, $params) generic function
   ======================================================================
:)
declare function custom:gen-challenges-selector-for  ( $root as xs:string, $lang as xs:string, $params as xs:string ) as element() {
  let $ampersand := '&amp;'
  let $pairs :=
      for $p in fn:collection($globals:global-info-uri)//Description[@Lang = $lang]/Selector[@Name eq 'CaseImpacts']/Group[Root eq $root]/Selector/Option
      let $n := $p/Name
      return
         <Name id="{string($p/Value)}">{replace(replace($n,' ','\\ '), $ampersand, '&amp;amp;')}</Name>
  return
    let $ids := string-join(for $n in $pairs return string($n/@id), ' ') (: FLWOR to defeat document ordering :)
    let $names := string-join(for $n in $pairs return $n/text(), ' ') (: idem :)
    return
      <xt:use types="choice" values="{$ids}" i18n="{$names}" param="{form:setup-select2($params)}"/>
};

(: ======================================================================
   Assumes InitialContexts SAME AS TargetedContexts

   ====================================================================== 
:)
declare function local:gen-context-title( $ctx as element()?, $lang as xs:string ) as xs:string {
  (: TODO: l14n substring before ! :)
  if ($ctx) then
    let $res := display:gen-name-for("InitialContexts", $ctx, $lang)
    return (: FIXME: use a shortname to avoid english translation pitfall ? :)
      if (ends-with($res, " stage")) then
        substring-before($res, " stage")
      else
        $res
  else
    '…'
};

declare function custom:gen-short-case-title( $case as element(), $lang as xs:string ) as xs:string {
  concat(
    substring($case/CreationDate, 1, 4), 
    ' - ', 
    local:gen-context-title($case/NeedsAnalysis/Context/InitialContextRef, $lang),
    ' &#8594; ',
    local:gen-context-title($case/NeedsAnalysis/Context/TargetedContextRef, $lang)
  )
};

declare function custom:gen-case-title( $case as element(), $lang as xs:string ) as xs:string {
  concat(
    enterprise:gen-enterprise-name($case/Information/ClientEnterprise/EnterpriseKey, $lang),
    ' - ',
    custom:gen-short-case-title($case, $lang)
    )
};

declare function custom:gen-short-activity-title( $case as element(), $activity as element(), $lang as xs:string ) as xs:string {
  let $service := $activity/Assignment/ServiceRef
  let $phase := $activity/Assignment/PhaseRef
  let $coach := $activity/Assignment/ResponsibleCoachKey
  return
    concat(
      if ($service) then 
        display:gen-name-for("Services", $service, $lang) 
      else 
        '…',
      ' ',
      if ($phase) then 
        display:gen-name-for("Phases", $phase, $lang) 
      else if ($service) then
        '…'
      else
        (),
      ' - ',
      if ($coach) then 
        display:gen-person-name($coach, $lang)
      else 
        '…'
      )
};

declare function custom:gen-activity-title( $case as element(), $activity as element(), $lang as xs:string ) as xs:string {
  concat(
    custom:gen-case-title($case, $lang),
    ' - ',
    custom:gen-short-activity-title($case, $activity, $lang)
    )
};

(: ======================================================================
   "All in one" utility function
   Checks case exists and checks user has rights to execute the goal action 
   with the given method on the given root document or has access to 
   the whole case if the root is undefined
   Either throws an error (and returns it) or returns the empty sequence
   ======================================================================
:)
declare function custom:pre-check-case(
  $case as element()?,
  $method as xs:string,
  $goal as xs:string?,
  $root as xs:string?, 
  $lang as xs:string ) as element()*
{
  if (empty($case)) then
    oppidum:throw-error('CASE-NOT-FOUND', ())
  else if (not(access:check-entity-permissions('open', 'Case', $case))) then
    oppidum:throw-error("CASE-FORBIDDEN", custom:gen-case-title($case, $lang))
  else if ($root) then 
    let $action := if ($method eq 'GET') then 'read' else 'update'
    return
      (: access to a specific case document :)
      (: FIXME: use access:check-workflow-permissions to take into account workflow status - see below ?:)
      if (access:check-document-permissions($action, $root, $case, ())) then
        ()
      else
        oppidum:throw-error('FORBIDDEN', ())
  else if ($method eq 'GET') then
    (: access to case workflow view :)
    ()
  else
    oppidum:throw-error("URI-NOT-FOUND", ())
};

(: ======================================================================
   "All in one" utility function
   Same as custom:pre-check-case but at the activity level
   FIXME: replace check-omnipotent-user with declarative parameters
   ======================================================================
:)
declare function custom:pre-check-activity(
  $case as element()?,
  $activity as element()?,
  $method as xs:string,
  $goal as xs:string?,
  $root as xs:string? ) as element()*
{
  if (empty($case)) then
    oppidum:throw-error('CASE-NOT-FOUND', ())
  else if (empty($activity)) then 
    oppidum:throw-error('ACTIVITY-NOT-FOUND', ())
  else if (not(access:check-entity-permissions('open', 'Case', $case))) then
    oppidum:throw-error("CASE-FORBIDDEN", $case/Title/text())
  else if ($root) then 
    (: access to specific activity document :)
    (: FIXME: use access:check-workflow-permissions to take into account workflow status - see below ?:)
    let $action := if ($method eq 'GET') then 'read' else if ($goal eq 'delete') then $goal else 'update'
    let $control := globals:doc('application-uri')/Application/Security/Documents/Document[@Root = $root]
    return
      if (access:assert-user-role-for($action, $control, $case, $activity)) then
        if (access:check-omnipotent-user() or access:assert-workflow-state($action, 'Activity', $control, string($activity/StatusHistory/CurrentStatusRef))) then
          ()
        else
          oppidum:throw-error('STATUS-DONT-ALLOW', ())
      else
        oppidum:throw-error('FORBIDDEN', ())

  else if ($method eq 'GET') then (: access to activity workflow view :)
    ()
  else
    oppidum:throw-error("URI-NOT-FOUND", ())
};

(: ======================================================================
   Custom version of misc:unreference called by template module

   Calls custom:gen-name-for-entity to unreference entities. This way 
   you can easily customize your application data model.

   Generates _Display attributes to unreference encoded values

   TODO:
   - add $lang parameter
   ======================================================================
:)
declare function custom:unreference( $nodes as item()*, $lang as xs:string ) as item()* {
  for $node in $nodes
  return
    typeswitch($node)
      case text()
        return $node
      case attribute()
        return $node
      case element()
        return
          let $tag := local-name($node)
          return
            if (exists($node/@_Unref)) then
              element { $tag }
                {
                misc:unref_display_attribute($node, $lang),
                $node/(*|text())
                }
            else if (ends-with($tag, 'Ref') or ($tag eq 'Country')) then (: selector data type :)
              element { $tag }
                {
                if (exists($node/@_Display)) then
                  $node/@_Display
                else
                  misc:gen_display_attribute($node, $lang),
                $node/text()
                }
            else if (ends-with($tag, 'Key')) then (: entity name :)
              element { $tag }
                {
                if (exists($node/@_Display)) then
                  $node/@_Display
                else if ($tag = ('EnterpriseKey')) then (: Enterprise :)
                  attribute { '_Display' } { enterprise:gen-enterprise-name($node/text(), $lang) }
                else (: assumes Person - e.g. ResponsibleCoachKey, etc. :)
                  attribute { '_Display' } { display:gen-person-name($node/text(), $lang) },
                $node/text()
                }
            else if (ends-with($tag, 's') and (count($node/*) > 0) and (: selector data type list :)
                (every $c in $node/* satisfies (ends-with(local-name($c), 'Ref') and not(ends-with(local-name($c), 'ScaleRef'))))) then
              element { $tag }
                {
                if (exists($node/@_Display)) then
                  $node/@_Display
                else
                  misc:gen_display_attribute($node/*, $lang),
                $node/*
                }
                (: TODO: also check for list of entities ? :)
            else if (ends-with($tag, 'Date')) then
              if (exists($node/@_Display)) then
                <Date>
                  {
                  $node/@_Display,
                  $node/text()
                  }
                </Date>
              else
                misc:unreference-date($node, $lang)
            else
              element { $tag }
                { custom:unreference($node/(attribute()|node()), $lang) }
      default
        return $node
};

(: ======================================================================
   Return address e-mail of the current user
   Note: this is data implementation dependant
   ======================================================================
:)
declare function custom:get-current-user-email( ) as xs:string? {
  let $uid := user:get-current-person-id()
  let $user := globals:collection('persons-uri')//Person[Id = $uid]
  let $res := $user/Information/Contacts/Email/text()
  return
    if ($res) then (: TODO: check syntax ? :)
      normalize-space($res)
    else (: not found, send-email will use default sender :)
      ()
};


declare function custom:pre-check-externalservice(
  $case as element()?,
  $contractor as element()?,
  $method as xs:string,
  $goal as xs:string?,
  $root as xs:string? ) as element()*
{
  if (empty($case)) then
    oppidum:throw-error('CASE-NOT-FOUND', ())
  else if (empty($contractor)) then 
    oppidum:throw-error('CONTRACTOR-NOT-FOUND', ())
  else if (not(access:check-entity-permissions('open', 'Case', $case))) then
    oppidum:throw-error("CASE-FORBIDDEN", $case/Title/text())
  else if ($root) then 
    (: access to specific activity document :)
    (: FIXME: use access:check-workflow-permissions to take into account workflow status - see below ?:)
    let $action := if ($method eq 'GET') then 'read' else if ($goal eq 'delete') then $goal else 'update'
    let $control := globals:doc('application-uri')/Application/Security/Documents/Document[@Root = $root]
    return
      if (access:assert-user-role-for($action, $control, $case, $contractor)) then
        if (access:check-omnipotent-user() or access:assert-workflow-state($action, 'Contractor', $control, string($contractor/StatusHistory/CurrentStatusRef))) then
          ()
        else
          oppidum:throw-error('STATUS-DONT-ALLOW', ())
      else
        oppidum:throw-error('FORBIDDEN', ())

  else if ($method eq 'GET') then (: access to activity workflow view :)
    ()
  else
    oppidum:throw-error("URI-NOT-FOUND", ())
};


declare function custom:gen-person-username() as element() {
 let $currentuser := oppidum:get-current-user()
let $person := globals:collection('persons-uri')//Person[UserProfile/Username =$currentuser]
return
$person
};

declare function custom:gen-person($ref as xs:string?) as element()? {
  if (exists($ref)) then
    let $person := globals:collection('persons-uri')//Person[Id =$ref]
    return $person
  else
    ()
};

declare function custom:gen-entreprise-username() as element()? {
 let $currentuser := oppidum:get-current-user()
let $person := globals:collection('persons-uri')//Person[UserProfile/Username =$currentuser]
let $entreprise := globals:doc('enterprises-uri')//Enterprise[Id = $person/Information/EnterpriseKey/text()]
return
     $entreprise
};

declare function custom:gen-entreprise($ref as xs:string) as element() {
let $entreprise := globals:doc('enterprises-uri')//Enterprise[Id = $ref]
return
     $entreprise
};
declare function custom:gen-enterprise-contractor-choice-selector ( $lang as xs:string, $params as xs:string ) as element() {
 
      let $pairs :=
          for $p in globals:doc('enterprises-uri')//Enterprise[IsContractor='1']
          let $n := $p/Information/Name
          let $town := $p//Town
          order by $n ascending
          return
             <Name id="{ $p/Id }">{replace($n,' ','\\ ')}{if ($town) then concat('::', replace($town,' ','\\ ')) else ()}</Name>
      return
        let $ids := string-join(for $n in $pairs return string($n/@id), ' ') (: FLWOR to defeat document ordering :)
        let $names := string-join(for $n in $pairs return $n/text(), ' ') (: idem :)
        return (
      <xt:use types="choice" values="{$ids}" i18n="{$names}" param="{$params}"></xt:use>
          )
};
