xquery version "3.0";
(: 
  de-duplicates TargetedMarketRef in enterprises.xml post-migration 
  TODO => de-duplicates TargetedMarketRef in FundingRequest in each activity of case.xml post-migration
:)

declare variable $local:dry := true();

<Migration>
<Assess>
    {
    for $e in fn:doc('/db/sites/ctracker/enterprises/enterprises.xml')//Enterprise
    let $markets := $e//TargetedMarketRef
    let $nb := count($markets)
    let $uniq := count(distinct-values($markets))
    return 
        if ($nb > 1) then
            if ($uniq ne $nb) then
                <Enterprise Name="{ $e/Information/Name }" ratio="{ $nb } / { $uniq }">
                { 
                let $target := $e/Information/TargetedMarkets
                let $fix := 
                      <TargetedMarkets>
                        {
                        for $val in distinct-values($markets)
                        return
                          <TargetedMarketRef>{ $val }</TargetedMarketRef>
                        }
                      </TargetedMarkets>
                return (
                  if ($local:dry) then
                    $fix
                  else
                    update replace $target with $fix,
                  "fixed"
                  )
                }
                </Enterprise>
            else
                ()
        else
            ()
    }
</Assess>
<Assess>
    {
    for $e in fn:collection('/db/sites/ctracker/cases')//FundingRequest/ClientEnterprise/Archive
    let $markets := $e//TargetedMarketRef
    let $nb := count($markets)
    let $uniq := count(distinct-values($markets))
    return 
        if ($nb > 1) then
            if ($uniq ne $nb) then
                <FundingRequest ActivityNo="{ $e/ancestor::Activity/No }" CaseNo="{ $e/ancestor::Case/No }"  Enterprise="{ $e/Information/Name }" ratio="{ $nb } / { $uniq }">
                { 
                let $target := $e//TargetedMarkets
                let $fix := 
                      <TargetedMarkets>
                        {
                        for $val in distinct-values($markets)
                        return
                          <TargetedMarketRef>{ $val }</TargetedMarketRef>
                        }
                      </TargetedMarkets>
                return (
                  if ($local:dry) then
                    $fix
                  else
                    update replace $target with $fix,
                  "fixed"
                  )
                }
                </FundingRequest>
            else
                ()
        else
            ()
    }
</Assess>
</Migration>
