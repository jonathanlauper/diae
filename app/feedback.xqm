xquery version "1.0";
(: ------------------------------------------------------------------
   Case tracker pilote application

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Integration with 3rd part Feedback application for feedback questionnaire

   Pre-requisites:
   - feedback application running and correctly configured in config/services.xml
   - questionnaires deployed (/admin/deploy?target=services)

   Configuration:
   - questionnaires transactions defined in application settings.xml (incl. formular 
     and e-mail template)
   - questionnaires transactions plugged onto status changes in application.xml
     (@Launch on Transition element)
   - e-mail templates available in email.xml
   - deploy variables.xml
   - error messages defined in errors.xml (two per feedback questionnaire)

   ENTRY POINTS
   - start-feedbacks : to create new feedback questionnaires orders in 3rd part
   - assess-order : to acknowledge an order from 3rd part
   - submit-answers : to receives answers for an order from 3rd part
   - close-feedbacks : to cancel/close an order in 3rd part

   July 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

module namespace feedback = "http://oppidoc.com/ns/ctracker/feedback";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../lib/globals.xqm";
import module namespace misc = "http://oppidoc.com/ns/xcm/misc" at "../../xcm/lib/util.xqm";
import module namespace display = "http://oppidoc.com/ns/xcm/display" at "../../xcm/lib/display.xqm";
import module namespace services = "http://oppidoc.com/ns/xcm/services" at "../../xcm/lib/services.xqm";
import module namespace media = "http://oppidoc.com/ns/xcm/media" at "../../xcm/lib/media.xqm";
import module namespace email = "http://oppidoc.com/ns/xcm/mail" at "../../xcm/lib/mail.xqm";
import module namespace alert = "http://oppidoc.com/ns/xcm/alert" at "../../xcm/modules/workflow/alert.xqm";
import module namespace check = "http://oppidoc.com/ns/xcm/check" at "../../xcm/lib/check.xqm";
import module namespace workflow = "http://oppidoc.com/ns/xcm/workflow" at "../../xcm/modules/workflow/workflow.xqm";

(: ======================================================================
   Sends e-mail to the SME Contact/KAM to respond to questionnaire
   Returns success or error message
   FIXME: hardcoded status Initiate Feedback '80'
   TODO: use Email / Recipients model in application.xml to factorize
         eg: alert:send-and-archive("sme-feedback", $extras)
   ======================================================================
:)
declare function local:notify-contact( $order-id as xs:string, $case as element(), $activity as element(), $to as xs:string, $form as element() ) as element() {
  let $link := services:get-hook-address('ctracker.questionnaires', 'feedback.form.link', $order-id)
  return
    if (empty($link)) then
        oppidum:throw-error(concat($form/@ErrPrefix, 'FEEDBACK-MISSING-LINK-CONFIG'), ())
    else if (not(check:is-email($to))) then
        oppidum:throw-error(concat($form/@ErrPrefix, 'FEEDBACK-WRONG-EMAIL'), ())
    else
      let $mail := email:render-email($form/Template, $form/Template/@Lang, $case, $activity,
                    <var name="Link_To_Form">{ $link  }</var>
                    )
      let $from := media:gen-current-user-email(false())
      return
        if ($mail/Subject) then
          let $subject :=  $mail/Subject
          let $content := media:message-to-plain-text($mail/Message)
          return
            if (media:send-email('workflow', $from, $to, $subject, $content)) then
            let $archive :=
              <Email>
                <To>{ $to }</To>
                { $mail/*[local-name(.) ne 'To'] }
              </Email>
            return (
              alert:archive($activity, $archive, (), '80', string($activity/StatusHistory/CurrentStatusRef), 'en'),
              oppidum:throw-message(concat($form/@ErrPrefix, 'FEEDBACK-EMAIL-SENT'), $to)
              )[last()]
            else
              oppidum:throw-error(concat($form/@ErrPrefix,'FEEDBACK-EMAIL-ERROR'), concat('e-mail server error sending to "', $to, '"'))
         else 
           oppidum:throw-error('FEEDBACK-INCOMPLETE-EMAIL-TEMPLATE', $form/Template)
};

(: ======================================================================
   Turns a list of variable names of a given type into a list of Variable
   elements for template rendering using application's variable definitions
   ======================================================================
:)
declare function local:gen-variables( $names as xs:string*, $type as xs:string?, $subject as element(), $object as element() ) as element()* {
  let $defs := fn:doc($globals:variables-uri)/Variables
  for $var in distinct-values($names)
  return
    if ($defs/Variable[Name eq $var]) then
      let $d := $defs/Variable[Name eq $var]
      return 
        if ($d) then
          let $res := util:eval($d/Expression/text())
          return
            <Variable Key="{ $var }">
              { 
              if ($type) then attribute { 'Type' } { $type } else (),
              if ($res ne '') then
                string($res)
              else
                'undefined'
              }
            </Variable>
        else
          ()
     else
      ()
};

(: ======================================================================
   Generates an Order for a feedback questionnaire and send it to 3rd party
   feedback application, then send the questionnaire URL by e-mail and archives 
   the e-mail message in the activity. 
   Returns the empty sequence if everything is successful, or an error
   otherwise. 
   ====================================================================== 
:)
declare function local:launch-feedback ( $case as element(), $activity as element(), $target as xs:string, $form as element() ) as element()? {
  (: If former KAM report has been integrated into the KAM Feedback while migrating :)
  if (not($activity/Evaluation/Order[Questionnaire/text() eq $form/Name/text()])) then
    let $id := util:hash(concat($case/Information/Acronym, $form/Name/text(), current-dateTime(), string($case/Information/Summary)), "md5")
    let $secret := util:hash(concat($case/Information/Acronym, $form/Name/text(), current-dateTime(), string($activity/FundingRequest/Tasks)), "md5")
       (: 1. creates Order in Poll 3rd party service:)
    let $order :=
      <Order>
        <Id>{ $id }</Id>
        <Secret>{ $secret }</Secret>
        <Questionnaire lang="fr">{ $form/Name/text() }</Questionnaire>
        {
          let $vars := fn:doc(concat('/db/www/', $globals:app-collection, '/formulars/', $form/Template/text(),'.xml'))/Poll//Variable/@Name
          let $prefills := fn:doc(concat('/db/www/', $globals:app-collection, '/formulars/',$form/Template/text(),'.xml'))/Poll//Prefill/@DefaultVariable
          return
            if (exists($vars) or exists($prefills)) then
              <Variables>
              {
              local:gen-variables($vars, (), $case, $activity),
              local:gen-variables($prefills, 'entry', $case, $activity)
              }
              </Variables>
            else
              ()
        }
        <Transaction>{ $target }</Transaction>
      </Order>
    let $res := services:post-to-service('feedback', 'feedback.orders', $order, ("200", "201"))
    let $subject := $case (: for variables evaluation :)
    let $object := $activity (: for variables evaluation :)
    return
      if (local-name($res) ne 'error') then
          (: 2. notifies SME contact of feedback form URL and archives e-mail in Activity messages :)
         let $to := string(util:eval(fn:doc($globals:variables-uri)//Variable[Name eq $form/SendTo]/Expression))
         return
            let $mail := if ($to) then
                           local:notify-contact($id, $case, $activity, $to, $form)
                         else
                           oppidum:throw-error('FEEDBACK-MISSING-RECIPIENT+', ($form/SendTo))
            return
              if (local-name($mail) eq 'success') then
                (: 3. saves order in Evaluation document :)
                (: lazy creation of evaluation document if processing of the very first one amongst several orders :)
                let $evaluation :=
                  if ($activity/Evaluations) then
                    $activity/Evaluations
                  else
                    update insert element Evaluations { } into $activity
                let $data :=
                  <Order>
                    {
                    $order/*,
                    <Date>{ current-dateTime() }</Date>,
                    <Email>{ $to }</Email>
                    }
                  </Order>
                let $saved-ord := update insert $data into $activity/Evaluations (:  always success :)
                return () (: success :)
              else
                (: 4. Rolls back Order in case notification e-mail could not be sent :)
                let $rollback :=
                  <Order>
                    <Id>{ $id }</Id>
                    <Cancel/>
                    <Transaction>{ $target }</Transaction>
                  </Order>
                let $res := services:post-to-service('feedback', 'feedback.orders', $rollback, ("200", "201"))
                return $mail
      else
        $res
  else
    ()
(: else
  oppidum:throw-error('CUSTOM', 'No SME feedback form name defined in application settings, please ask a DB administrator to fix it !') :)
};

(: ======================================================================
   Validates data submitted from 3rd part feedback application
   Returns the first error found or empty sequence
   FIXME: hard coded status, hard-coded delay limit (see also alerts/checks.xml)
   TODO: move to a 'validation' data template
   ======================================================================
:)
declare function local:validate-submission ( $order as element()?, $case as element()?, $activity as element()?, $submitted as element() ) as element()* {
  if (empty($order)) then
    oppidum:throw-error('CUSTOM', concat('unkown feedback form ', $submitted/Order/Id))
  else if ($activity/StatusHistory/ConcurrentStatusRef eq '82') then
    oppidum:throw-error('CUSTOM', 'the activity workflow has been closed and cannot record feedback any more')
  else if (not($activity/StatusHistory/ConcurrentStatusRef = '81')) then
    oppidum:throw-error('CUSTOM', 'the activity workflow has moved to a new status where it cannot record feedback any more')
  else if ($order/Secret ne $submitted/Secret/text()) then
    oppidum:throw-error('CUSTOM', ('authorization to save this form refused'))
  else
    ()
  (: TODO: check root element name :)
  (: eventually checks exists($activity/Evaluation) :)
};

(: ======================================================================
   Returns the number of missing questionnaires in the same transaction 
   to apply the closing transition on the workflow
   ======================================================================
:)
declare function local:check-sibling-forms( $activity as element(), $trans-name as xs:string, $order-current as xs:string ) as xs:integer {
  let $trans-spec := fn:doc($globals:settings-uri)/Settings/Questionnaires/Transaction[Name/text() eq $trans-name]
  return
    count(
      for $form in $trans-spec/Form[not(Name/text() eq $order-current)]
      let $order := $activity/Evaluations/Order[Questionnaire/text() eq $form/Name/text()]
      where (not($form/@Collect) or ($form/@Collect ne 'facultative')) and empty($order/Answers)
      return 1
    )
};

(: ======================================================================
   Creates an Order for an SME feedback form in the Poll service
   Sends the SME Contact an e-mail with a link to the Poll
   Saves the Order into the Evaluation document
   Returns the empty sequence, otherwise returns an error message
   The SME contact notification should throw a success message into the flash
   (full pipeline condition) to notify user that an e-mail was sent
   Rolls back the Order in case of failure
   FIXME: in case of multiple forms the rollback implementation is incomplete
   since it will cancel (Order and archived Email message) only faulty forms,
   any forms which could be sent, notified and archived will not be rolled back !
  ======================================================================
:)

declare function feedback:start-feedbacks ( $case as element(), $activity as element(), $target as xs:string) as element()? {
  let $forms := fn:doc($globals:settings-uri)/Settings/Questionnaires/Transaction[Name eq $target]/Form
  return
    (for $form in $forms
    return 
      local:launch-feedback( $case, $activity, $target, $form)
    )[last()]
};

(: ======================================================================
   Implements Assess protocol to query current status of an Order from 3rd party
   FIXME: hard-coded threshold for closing questionnaire
   ======================================================================
:)
declare function feedback:assess-order( $submitted as element() ) as element() {
  let $order := fn:collection($globals:cases-uri)//Order[Id eq $submitted/Id/text()]
  let $case := $order/ancestor::Case
  let $activity := $order/ancestor::Activity
  return
    if (empty($order)) then
      oppidum:throw-error('CUSTOM', concat('unkown feedback form ', $submitted/Order/Id))
    else
      <Assess>
        <Order>
          {
          $submitted/Id,
          if ($activity/StatusHistory/ConcurrentStatusRef = '11') then (: evaluated :)
            <Closed>{ $activity/StatusHistory/Status[ValueRef eq '11']/Date/text() }</Closed>
          else if ($activity/StatusHistory/ConcurrentStatusRef = '82') then  (: closed :)
            <Closed Delay="21">{ $activity/StatusHistory/Status[ValueRef eq '10']/Date/text() }</Closed>
          else if (not($activity/StatusHistory/ConcurrentStatusRef = '81')) then  (: any other reason :)
            <Cancelled>{ $activity/StatusHistory/Status[ValueRef eq $activity/StatusHistory/CurrentStatusRef]/Date/text() }</Cancelled>
          else
            <Running/>
          }
      </Order>
    </Assess>
};

(: ======================================================================
   Handles 3rd party feedback questionnaire submission
   FIXME: hard coded status '8', '11'
   ======================================================================
:)
declare function feedback:submit-answers( $submitted as element() ) as element() {
  let $order := fn:collection($globals:cases-uri)//Order[Id eq $submitted/Id/text()]
  let $case := $order/ancestor::Case
  let $activity := $order/ancestor::Activity
  let $errors := local:validate-submission($order, $case, $activity, $submitted)
  return
    if (empty($errors)) then (
     misc:save-content($order, $order/Answers, $submitted/Answers),
     let $omitted := local:check-sibling-forms( $activity, $order/Transaction, $order/Questionnaire)
     let $workflow := fn:doc($globals:settings-uri)/Settings/Questionnaires/Transaction[Name eq $order/Transaction]/Workflow
     let $transition := globals:doc('application-uri')/Application//Workflow[@Id eq $workflow]//Transition[@TriggerBy eq $order/Transaction]
     return
       if ($omitted = 0) then
         let $result := workflow:apply-transition($transition, $case, $activity)
         return
            if (empty($result)) then
              let $success := oppidum:throw-message('INFO', 'Your answers have been recorded, thank you for your contribution')
              return workflow:apply-notification($workflow, $success, $transition, $case, $activity)
            else
              $result
       else
         oppidum:throw-message('INFO', 'Your answers have been recorded, thank you for your contribution')
      )[last()]
    else
      $errors
};

declare function feedback:submit-answers-externalservice( $submitted as element() ) as element() {
  let $order := fn:collection($globals:cases-uri)//Order[Id eq $submitted/Id/text()]
  let $case := $order/ancestor::Case
  let $activity := $order/ancestor::Activity
    let $externalservice := $order/ancestor::ExternalService
              let $feedback :=   <Feedback>
             <Impact>
                    <ServiceFollowUpScaleRef>{$submitted/Answers/ServiceFollowUpScaleRef/text()}</ServiceFollowUpScaleRef>
                </Impact>
                <Comment>
                    {$submitted/Answers/Comments/*}
                </Comment>
                <Date>{current-date()}</Date>
</Feedback>
  let $errors := if ($activity) then local:validate-submission($order, $case, $activity, $submitted) else()
  return
    if (empty($errors)) then (
     misc:save-content($order, $order/Answers, $submitted/Answers),
     update insert $feedback into $externalservice,
     
      
     let $omitted := local:check-sibling-forms( $externalservice, $order/Transaction, $order/Questionnaire)
(:     let $workflow := fn:doc($globals:settings-uri)/Settings/Questionnaires/Transaction[Name eq $order/Transaction]/Workflow
     let $transition := globals:doc('application-uri')/Application//Workflow[@Id eq $workflow]//Transition[@TriggerBy eq $order/Transaction]
    :) return
       if ($omitted = 0) then
         
              let $success := oppidum:throw-message('INFO', 'Your answers have been recorded, thank you for your contribution')
(:              return workflow:apply-notification($workflow, $success, $transition, $case, $externalservice)
:)           return $success
       else
         oppidum:throw-message('INFO', 'Your answers have been recorded, thank you for your contribution')
      )[last()]
    else
      $errors
};

(: ======================================================================
   Creates and sends an Order to close an SME feedback form in the Poll service
   Returns either a flash-ed message or the empty sequence since the outcome 
   should be non-blocking (see status.xql)
   ======================================================================
:)
declare function feedback:close-feedbacks ( $case as element(), $activity as element(), $target as xs:string) as element()? {
  let $forms := fn:doc($globals:settings-uri)/Settings/Questionnaires/Transactions[Name eq $target]/Form
  return
    for $form in $forms
    let $order := $activity/Evaluation/Order[Questionnaire/text() eq $form/text()]
    return
      if ($order) then
        let $submit :=
            <Order>
              { $order/Id }
              <Close/>
            </Order>
        let $res := services:post-to-service('feedback', 'feedback.orders', $submit, "200")
        return (
          update insert <Closed>{ current-dateTime() }</Closed> into $order,
          (: directly adds message to the flash since this method is called from the 'status' command
             which replies with an Ajax response and otherwise would immediately render the messages :)
          if (local-name($res) ne 'error') then
            oppidum:add-message('INFO', concat('The "', $order/Questionnaire/text() ,'" feedback questionnaire has been closed on the poll application'), true())
          else
            oppidum:add-message('INFO', concat('The "', $order/Questionnaire/text() ,'" feedback questionnaire could not be closed on the poll application because ', $res//message), true())
          )
      else
        ()
};

(: ======================================================================
   Configure for the first time the feedback workflow into the activity 
   Does nothing if this has already been done
   ====================================================================== 
:)
declare function feedback:set-feedbacks-workflow ( $case as element(), $activity as element() ) {
  if (empty($activity/StatusHistory/ConcurrentStatusRef[. = ('80', '81', '82', '11')])) then 
    let $cur := $activity/StatusHistory/CurrentStatusRef
    let $con-status := <ConcurrentStatusRef Group="feedback">80</ConcurrentStatusRef>
    let $con-ts := <Status>
                     <Date>{ current-dateTime() }</Date>
                     <ValueRef>80</ValueRef>
                   </Status>
   return (
      if ($cur) then
        update insert $con-status following $cur
      else
        update insert $con-status into $cur,
      update insert $con-ts into $activity/StatusHistory
      )
  else
    ()
};