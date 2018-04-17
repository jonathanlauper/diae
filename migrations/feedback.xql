xquery version "3.0";
(:~ 
 : Case Tracker version 1.0
 :
 : Maintenance script to set feedbacks concurrent workflow on activities in Report Approval
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
import module namespace feedback = "http://oppidoc.com/ns/ctracker/feedback" at "../app/feedback.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

let $mode := request:get-parameter('m', 'dry')
return
  <Feedback>
      {
      for $activity in fn:collection($globals:cases-uri)//Activity[StatusHistory/CurrentStatusRef eq '7']
      let $case := $activity/ancestor::Case
      return
        <Activity CaseNo="{ $case/No }" No="{ $activity/No }">
          {
          if ($activity/StatusHistory/ConcurrentStatusRef) then
            <AlreadySet>{ $activity/StatusHistory/ConcurrentStatusRef }</AlreadySet>
          else if ($mode eq 'dry') then
            <Set Mode="dry"/>
          else
            <Set>{ feedback:set-feedbacks-workflow($case, $activity) }</Set>
          }
        </Activity>
      }
  </Feedback>
