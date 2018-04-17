xquery version "3.0";
(:~ 
 : Case Tracker version 1.0
 :
 : Maintenance script to check/correct budget information in Activities
 :
 : You MUST add ?m=run for running with side effects
 :
 : January 2018 - (c) Copyright 2018 Oppidoc SARL. All Rights Reserved.
 :
 : @author Stéphane Sire <s.sire@oppidoc.fr>
 :)

declare namespace custom = "http://oppidoc.com/ns/application/custom";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";

declare option exist:serialize "method=xml media-type=text/xml indent=yes";

declare variable $local:coaching-hourly-rate := 150; (: TODO: replace by value in settings instead !!! :)

declare function custom:number( $text as xs:string? ) as xs:double {
  if (exists($text) and ($text ne '') and ($text castable as xs:double)) then
    number($text)
  else
    0
};

declare function local:substract( $n1 as xs:double, $n2 as xs:double ) {
  round($n1 *100 - $n2 * 100) div 100
};

declare function local:coaching-hourly-rate( $budget ) {
  let $rate := $budget/Variables/CoachingHourlyRate
  return
    if (empty($rate)) then
      $local:coaching-hourly-rate
    else
      custom:number($rate)
};

declare function local:total-spent( $budget as element() ) {
  if (exists($budget/Variables/TotalSpent) and ($budget/Variables/TotalSpent ne '[TotalEffectiveAmount]')) then 
    custom:number($budget/Variables/TotalSpent)
  else
    (: in case FinalReportApprovement was not available while importing :)
    sum($budget/Costs/CoachingCosts//EffectiveNbOfHours) * local:coaching-hourly-rate($budget) + sum($budget/Costs/CoachingCosts//EffectiveOtherExpensesAmount)
    (: we cannot use ActivityAmount since this is not stored in Activities :)
};

declare function local:fix-variable( $tag as xs:string, $value as xs:double, $budget as element(), $mode as xs:string) {
  let $legacy := $budget/Variables/*[local-name() eq $tag]
  return
    if (empty($legacy)) then
      element { $tag } {
        attribute { 'Status' } { if ($mode ne 'run') then 'insert' else 'inserted' },
        if ($mode eq 'run') then
          update insert element { $tag } { $value } into $budget/Variables 
        else
          (),
        $value 
        }
    else if ($legacy ne string($value)) then
      element { $tag } { 
        attribute { 'Status' } { if ($mode ne 'run') then 'replace' else 'replaced' }, 
        attribute { 'Legacy' } { $legacy/text() },
        if ($mode eq 'run') then
          update value $legacy with $value
        else
          (),
        $value 
        }
    else
      element { $tag } { 
        attribute { 'Status' } { 'same' }, 
        $value 
        }
};

let $cmd := oppidum:get-command()
let $mode := request:get-parameter('m', 'dry')
let $host := request:get-parameter('h', '')
let $nb := request:get-parameter('n', ())
return
  <BudgetHealthCheck Mode="{ $mode }">
    {
    for $budget in fn:collection('/db/sites/ctracker/cases')//Case[empty($nb) or No eq $nb]//Activity[StatusHistory//ValueRef = ('7')]//Budget
    let $total-effective := sum($budget/Revenues//FundingSource/EffectiveAmount)
    let $total-approved := custom:number($budget/Variables/TotalApproved)
    let $effective-balance := local:substract($total-approved, $total-effective)
    let $spent := local:total-spent($budget)
    let $balance :=  custom:number($budget/Variables/SpentBalance)
    let $spent-balance := local:substract($total-approved, $spent)
    let $overrun := custom:number($budget/Revenues/Overrun/EffectiveAmount)
    let $difference := $spent-balance - $effective-balance + $overrun
    let $legacy-difference := custom:number($budget/Variables/Difference)
    let $address := concat("cases/", $budget/ancestor::Case/No, "/activities/", $budget/ancestor::Activity/No)
    return 
      <Budget Link="{$host}{$cmd/@base-url}{$address}">
        {
        (: Fix missing CoachingHourlyRate (some were not imported in January 2018) :)
        local:fix-variable('CoachingHourlyRate', local:coaching-hourly-rate($budget), $budget, $mode),
        local:fix-variable('TotalSpent', $spent, $budget, $mode),
        local:fix-variable('TotalEffective', $total-effective, $budget, $mode),
        local:fix-variable('EffectiveBalance', $effective-balance, $budget, $mode),
        local:fix-variable('SpentBalance', $spent-balance, $budget, $mode),
        local:fix-variable('Difference', $difference, $budget, $mode),
        (: Detects pathalogical cases that could have been imported in January 2018 :)
        if (some $ref in $budget/Revenues//FundingSourceRef
            satisfies count($budget/Revenues//FundingSourceRef[. eq $ref/text()]) > 1) then
          <Multiple/>
        else
          ()
        }
      </Budget>
    }
  </BudgetHealthCheck>
