xquery version "3.0";
(:~ 
 : Case Tracker version 1.0
 :
 : Maintenance script to close cases and to keep active only the one with most recent activity
 :
 : You MUST add ?m=run for running with side effects
 :
 : October 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
 :
 : @author Stéphane Sire <s.sire@oppidoc.fr>
 :)

declare namespace request = "http://exist-db.org/xquery/request";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../lib/globals.xqm";
import module namespace case = "http://oppidoc.com/ns/application/case" at "../modules/cases/case.xqm";
import module namespace custom = "http://oppidoc.com/ns/application/custom" at "../../app/custom.xqm";
import module namespace display = "http://oppidoc.com/ns/xcm/display" at "../../../xcm/lib/display.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

let $mode := request:get-parameter('m', 'dry')
return
  <Closing>
      {
      for $case in fn:collection($globals:cases-uri)/Case[StatusHistory/CurrentStatusRef eq '1']
      let $key := $case/Information/ClientEnterprise/EnterpriseKey
      group by $key
      return
          if (count($case) > 1) then
              <Enterprise>
              {
              head($case/Information/ClientEnterprise/EnterpriseKey),
              let $most-recent := string(max(for $date in $case//Activity/CreationDate return xs:date($date)))
              return (
                  for $c in $case[not(.//Activity[CreationDate eq $most-recent])]
                  return
                      <OldCase No="{ $c/No }">
                        {
                        if ($mode eq 'run') then
                          case:close-case($c, 'en')
                        else (
                          case:pick-client-enterprise($c),
                          case:pick-contact-person($c)
                          )
                        }
                      </OldCase>,
                  for $c in $case[.//Activity[CreationDate eq $most-recent]]
                  return
                      <MostRecentCase No="{ $c/No }"/>
                  )
              }
              </Enterprise>
          else
              ()
      }
  </Closing>
