xquery version "1.0";
(: --------------------------------------
   XQuery Content Management Library

   CRUD controller to manage Enterprise entities inside the database.

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   TODO:
   - create data template
   - validate data template (remove dependency on enterprises.xqm )

   July 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

import module namespace request="http://exist-db.org/xquery/request";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace template = "http://oppidoc.com/ns/ctracker/template" at "../../lib/template.xqm";
import module namespace display = "http://oppidoc.com/ns/xcm/display" at "../../../xcm/lib/display.xqm";
import module namespace access = "http://oppidoc.com/ns/xcm/access" at "../../../xcm/lib/access.xqm";
import module namespace cache = "http://oppidoc.com/ns/xcm/cache" at "../../../xcm/lib/cache.xqm";
import module namespace ajax = "http://oppidoc.com/ns/xcm/ajax" at "../../../xcm/lib/ajax.xqm";
import module namespace enterprise = "http://oppidoc.com/ns/xcm/enterprise" at "../../../xcm/modules/enterprises/enterprise.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Adds a new enterprise record into the database
   TODO: use a data template for validation
   ======================================================================
:)
declare function local:create-enterprise( $cmd as element(), $submitted as element(), $lang as xs:string ) as element() {
  let $next := request:get-parameter('next', ())
  let $validated := enterprise:validate-enterprise-submission($submitted, ())
  return
    if (empty($validated)) then
      let $created := template:do-create-resource('enterprise', (), (), $submitted, ())
      return
        if (local-name($created) eq 'success') then (
          cache:invalidate('enterprise'),
          cache:invalidate('town'),
          if ($next eq 'redirect') then
            ajax:report-success-redirect('ACTION-CREATE-SUCCESS', (), concat($cmd/@base-url, $cmd/@trail, '?preview=', string($created/@key)))
          else (: short ajax protocol with 'augment' or 'autofill' plugin (no table row update) :)
            let $result := 
              <Response Status="success">
                <Payload>
                  <Name>{ $submitted/Name/text() }</Name>
                  <Value>{ string($created/@key) }</Value>
                </Payload>
              </Response>
            return
              ajax:report-success('ACTION-CREATE-SUCCESS', (), $result)
          )
        else
          $created
    else
      ajax:report-validation-errors($validated)
};

(: ======================================================================
   Updates an enterprise record into database
   Returns Ajax table protocol payload
   ======================================================================
:)
declare function local:update-enterprise( $enterprise as element(), $submitted as element(), $lang as xs:string ) as element() {
  let $validated := enterprise:validate-enterprise-submission($submitted, $enterprise/Id)
  let $name := string($enterprise/Information/Name)
  let $town := string($enterprise/Information/Address/Town)
  return
    if (empty($validated)) then
      let $id := string($enterprise/Id)
      let $updated := template:do-update-resource('enterprise', $id, $enterprise, (), $submitted, $lang)
      return
        if (local-name($updated) eq 'success') then (
          if ($name ne $submitted/Name) then
            cache:invalidate('enterprise')
          else
            (),
          if ($town ne $submitted/Address/Town) then
            cache:invalidate('town')
          else
            (),
          (: TODO: implement 'ACTION-UPDATE-SAME-SUCCESS' in case there is no change :)
          ajax:report-success('ACTION-UPDATE-SUCCESS', (), 
            <Response Status="success">
              <Payload Table="Enterprise">
                <Name>{ $submitted/Name/text() }</Name>
                <Value>{ $id }</Value>
                { $submitted/Address/(Town | RegionRef) }
                <Size>{ display:gen-name-for('Sizes', $submitted/SizeRef, $lang) }</Size>
                <DomainActivity>{ display:gen-name-for('DomainActivities', $submitted/DomainActivityRef, $lang) }</DomainActivity>
                <TargetedMarkets>{ display:gen-name-for('TargetedMarkets', $submitted/TargetedMarkets/TargetedMarketRef, $lang) }</TargetedMarkets>
              </Payload>
            </Response>
            )
          )
        else
          $updated
    else
      ajax:report-validation-errors($validated)
  };
  
(: ======================================================================
   Returns the Enterprise with No $ref with a representation depending on $goal
   ======================================================================
:)
declare function local:gen-enterprise( $ref as xs:string, $lang as xs:string, $goal as xs:string ) as element()* {
  let $enterprise := fn:doc(oppidum:path-to-ref())/Enterprises/Enterprise[Id = $ref]
  return
    if (empty($enterprise)) then
      <Enterprise/>
    else if ($goal = 'autofill') then (: transclusion content generation :)
      let $payload := 
        if (request:get-parameter('context', ()) eq 'Partner') then 
          template:gen-citation('partner', $enterprise/Id, $enterprise/Information, $lang)
        else
          template:gen-citation('enterprise', $enterprise/Id, $enterprise/Information, $lang)
      let $envelope := request:get-parameter('envelope', '')
      return
        <data>
          {
          if ($envelope) then
            element { $envelope } { $payload/* }
          else
            $payload/*
          }
        </data>
    else (: assumes 'read' or 'update' :)
      template:gen-read-model('enterprise', $enterprise, $lang)
};

(: *** MAIN ENTRY POINT *** :)
let $m := request:get-method()
let $cmd := oppidum:get-command()
let $name := string($cmd/resource/@name)
let $lang := string($cmd/@lang)
return
  if ($m = 'POST') then
    let $submitted := oppidum:get-data()
    return
      if ($cmd/@action = 'add') then
        if (access:check-entity-permissions('create', 'Enterprise')) then
          local:create-enterprise($cmd, $submitted, $lang)
        else
          oppidum:throw-error('FORBIDDEN', ())
      else
        let $enterprise := globals:doc('enterprises-uri')/Enterprises/Enterprise[Id = $name]
        let $access := access:get-entity-permissions('update', 'Enterprise', $enterprise)
        return
          if (local-name($access) eq 'allow') then
            local:update-enterprise($enterprise, $submitted, $lang)
          else
            $access
  else (: assumes GET - TODO: access control ? :)
    let $goal := request:get-parameter('goal', 'read')
    return
      local:gen-enterprise($name, $lang, $goal)
