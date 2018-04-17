# Case tracker data model

DEPRECATED: see data-model.numbers instead, to be replaced with a RelaxNG schema...

## Data mapping

The main entities are a Person, an Enterprise, a Case, an Activity.

| Entity                 | Collection                    | Resource               |
|:-----------------------|:------------------------------|:-----------------------|
| Person                 | /db/sites/{app}/persons       | persons.xml            |
| Enterprise             | /db/sites/{app}/enterprises   | enterprises.xml        |
| Case                   | /db/sites/{app}/cases/YYYY/MM | case.xml               |
| Activity               | inside Case                   | inside Case            |

## Person entity

Here is a sample Person record. Empty tags are shown to reveal the full data model but the convention is to not store them in database.

```xml
<Person>
  <Id>3</Id>
  <Sex>M</Sex>
  <Civility>Dr</Civility>
  <Name>
    <LastName>Ducharme</LastName>
    <FirstName>Bob</FirstName>
    <SortString/>
  </Name>
  <Country>FR</Country>
  <EnterpriseRef>1</EnterpriseRef>
  <Function>Manager</Function>
  <Contacts>
    <Phone>+33 (0) 2 29 97 41 65</Phone>
    <Mobile>+33 (0) 6 62 94 21 50</Mobile>
    <Email>bob@ducharme.com</Email>
  </Contacts>
  <Photo/>
  <UserProfile/>
</Person>
```

The `Photo` is a path to an image uploaded into the `/db/sites/{app}/persons/images` collection.

The `UserProfile` contains information about the user if the Person entity represents a user with access to the case tracker.

## Enterprise entity

Here is a sample Enterprise record. Empty tags are shown to reveal the full data model but the convention is to not store them in database.

```xml
<?xml version="1.0"?>
<Enterprise>
  <Id>1</Id>
  <Name>Acme Software Ltd</Name>
  <ShortName>Acme</ShortName>
  <CreationYear>2014</CreationYear>
  <SizeRef>2</SizeRef>
  <DomainActivityRef>J62</DomainActivityRef>
  <MainActivities>web application development</MainActivities>
  <TargetedMarkets>
    <TargetedMarketRef>572010</TargetedMarketRef>
    <TargetedMarketRef>581010</TargetedMarketRef>
  </TargetedMarkets>
  <Address>
    <StreetNameAndNo>1 impasse des Papillons</StreetNameAndNo>
    <PO-Box/>
    <Co/>
    <PostalCode>85000</PostalCode>
    <Town>La Roche Sur Yon</Town>
    <Country>FR</Country>
  </Address>
</Enterprise>
```

The `DomainActivityRef` belongs to the NACE code classification.

The `TargetedMarketRef` belongs to the Thomson Reuters classification.

## Live / Dead copy rules

The ClientEnterprise in Case/Information is a live copy until a new case is created with the same company. Then it is archived directly inside the Case/Information.

The ClientEnterprise in an Activity/FundingRequest is a live copy until the workflow is advanced to a new status. 

Live copy model :

ClientEnterprise
  EnterpriseRef
  
Dead copy model :

ClientEnterprise
  EnterpriseRef
  Enterprise Date="YYYY-MM-DD"
  
The live copy mechanism is directly implemented in the data templates.

The ContactPerson in NeedsAnalysis is a live copy until a new case is created with the same company. The it is archived directly inside the Case/NeedsAnalysis

The ContactPerson in Activity/FundingRequest is a live copy until the workflow is advanced to a new status. 

Live copy model :

ContactPerson
  ContactPersonRef
  
Dead copy model :

ContactPerson
  PersonRef
  Person Date="YYYY-MM-DD"
  
If the workflow is returned back or the Activity/FundingRequest is edited when the Enterprise or the ContactPerson has been already been archived, then it is displayed with the archived values. In that situation you can click on "Update data" to open the enterprise or contact person modal window and click on [Import] to copy the new values. This mechanism is implemented in the 'update' data template : when there is an archive it tests both versions with a deep-equal and updates the archive if they differ.

## Case skeleton

    Case
      No
      CreationDate
      StatusHistory<+>
      Information
        Title
        ClientEnterprise<+>
          [PILOTE] EnterpriseRef (live copy from enterprises.xml)
        [NOT USED] ContactPerson<+>
        [NOT USED] ManagingEntity
          RegionalEntityRef
          AssignedByRef
          Date
      Alerts<+>
      Management
        AccountManagerRef
        [NOT USED] AssignedByRef
        [NOT USED] Date
        Conformity<+>
      NeedsAnalysis
        [NOT USED]Contact
          Date
          Agent
        ContactPerson<+>
        Analysis
          Date
          [PILOTE] Agent
          [PILOTE] FundingSource
        Tools
        Stats
        Context<+>
        Impact<+>
        Comments
      Activities
        Acitvity<+>
      [NEW] Cache
        KAMReport
          Recognition
          Tools
      [NOT USED] Proxies
        KAMReportNAProxy
          Recognition
          Tools

## Activity skeleton

### Reference version

    Activity
      No
      CreationDate
      StatusHistory<+>
      NeedsAnalysis [DEAD COPY]
      AccountManagerFeedback ([x] duplicated from Evaluation / Order for KAM)
        Recognition
        Tools
        Profiles
        [x] Profiles
        [x] Dialogue
        [x] PastRegionalInvolvement
        [x] RegionalInvolvement
        [x] FutureRegionalInvolvement
        [x] FutureSupport
      Assignment 
        Weights
        Description
        ServiceRef
        PhaseRef
        ResponsibleCoachRef
        AssignedByRef
        Date
      Alerts<+>
      FundingRequest<+>
        [NEW] Title (automatic synthesis)
        [OLD] PhaseRef [=> Assignment]
        [OLD, REPLACE] ServiceName [=> Assignment, replace with ServiceRef ?]
        [OLD] ResponsibleCoach [=> Assignment]
                CoachRef
                CoachName [=> remove it or Archive/Name ?]
        [OLD] SubmissionOrigin
        [OLD] ContactSourceRef
        [OLD] ClientEnterprise [=> Enterprise transclusion]
                EnterpriseRef
                Archive<+>
        [MOVE]ContactPerson [=> Person transclusion]
                PersonRef
                Archive<+>
        [NEW] Conformity<+>
        [OLD] Partners
                Partner* [=> Enterprise transclusion]
                  EnterpriseRef
                  Archive<+>
        Objectives
          [NEW] Text*
          [OLD] Parag*
        [NEW] SME-Agreement ???
        ResponsibleCoachComments (#text)
      Opinions
        [NEW] Region @LastModification
          [OLD, DELETE] (CantonalAntenna)Date
          [OLD] (CantonalAntenna)AuthorRef
          [OLD] (CantonalAntenna)PositionRef
          [OLD] (CantonalAntenna)Comment (#text)
        [NEW] Service @LastModification
          [OLD, DELETE] (ServiceResponsible)Date
          [OLD] (ServiceResponsible)AuthorRef
          [OLD] (ServiceResponsible)PositionRef
          [OLD] (ServiceResponsible)Comment (#text)
        [OLD] Others
                OtherOpinion* @LastModification
                  AuthorRef
                  Comment (#text)
      FundingDecision<+>
        [OLD] DecisionMakingAuthorityRef
        Comments
      CoachingReport [ex. FinalReport]
        KAMPreparation
        ManagementTeam
        Comment
        PlannedContinuation (Text*)
        Dissemination
          RatingScaleRef
          CommunicationAdviceRef
          Comment (Text*)
        EvaluationCriteria
          Business
          Capacity
        ObjectivesAchievements
          RatingScaleRef
          PositiveComment (Text*)
          NegativeComment (Text*)
        [OLD, NEW] Partners<+>
        TimesheetFile [only when reading]
        [OLD] ObjectivesAchievements
        [OLD] SpecificProblems
        [OLD] Comments
        [OLD] PlannedContinuation
        [OLD] Dissemination
                ToAppearInNews
                Motivation
        Partners<+>
      ReportApproval [ex. FinalReportApproval]
        [OLD] Completeness
                OpinionRef [=> PositionRef]
                Comment (#text)
                Date
                Author [=> AuthorRef]
        [OLD] ResultsQuality
                OpinionRef [=> PositionRef]
                Comment (#text)
                Date
                Author [=> AuthorRef]
        [OLD] FinancialStatementComment
                OpinionRef [=> PositionRef]
                Comment
                Date
                Author
        DecisionMakingAuthorityRef
      Budget
        Costs
          Tasks
            Task
              Description
              NbOfHours
            TotalTasks
          OtherExpenses
            OtherExpense
              ...
            TotalOtherExpenses
          CoachingCosts*
            CoachActivity
              CoachRef
              EffectiveNbOfHours
              EffectiveHoursAmount
              EffectiveOtherExpensesAmount
              ActivityAmount
        Revenues
          FundingSources
            FundingSource
              FundingSourceRef
              Comment
              RequestedAmount
              ApprovedAmount
              EffectiveAmount
        Variables
          CoachingHourlyRate
          TotalRequested
          TotalApproved
          ApprovedBalance
          TotalSpend
          SpentBalance
          EffectiveBalance
          Difference
      Feedbacks ???
        Sent ?
      Evaluation (connection with poll module)
       Order (for SME)
       Order (for KAM, transcoded into FinalReportApproval [b])

### EASME version

### Platinn version

    Activity
      No
      [NEW] CreationDate
      StatusHistory<+>
      [DEAD COPY] NeedsAnalysis
      [OLD] CoachingHourlyRate [ => settings.xml ]
        Amount
        Currency
      [OLD] NbOfHoursPerDay
      [OLD] Title
      [OLD] ServiceRef
      [NEW] Assignment
        Weights
        Description
        ServiceRef
        [ADD] PhaseRef
        ResponsibleCoachRef
        AssignedByRef
        Date
      Alerts<+>
      FundingRequest<+>
        [NEW] Title (automatic synthesis)
        [OLD] PhaseRef [=> Assignment]
        [OLD, REPLACE] ServiceName [=> Assignment, replace with ServiceRef ?]
        [OLD] ResponsibleCoach [=> Assignment]
                CoachRef
                CoachName [=> remove it or Archive/Name ?]
        [OLD] SubmissionOrigin
        [OLD] ContactSourceRef
        [OLD] ClientEnterprise [=> Enterprise transclusion]
                EnterpriseRef
                Archive<+>
        [MOVE]ContactPerson [=> Person transclusion]
                PersonRef
                Archive<+>
        [NEW] Conformity<+>
        [OLD] Partners
                Partner* [=> Enterprise transclusion]
                  EnterpriseRef
                  Archive<+>
        Objectives
          [NEW] Text*
          [OLD] Parag*
        [NEW] SME-Agreement
        Budget<+>
          Tasks
            Task
              Description
              NbOfHours
            TotalTasks
          OtherExpenses
            OtherExpense
              ...
            TotalOtherExpenses
          TotalBudget
          FundingSources
            FundingSource
              [REPLACE] Id [rename FundingSourceRef]
              Comment
              Amount
            TotalFundingSources [Move to TotalRequested]
          CoachingHourlyRate
          TotalRequested
          BudgetBalance
        ResponsibleCoachComments (#text)
      Opinions
        [OLD] ResponsibleCoachComments [ from FundingRequest ]
        [NEW] Region @LastModification
          [OLD, DELETE] (CantonalAntenna)Date
          [OLD] (CantonalAntenna)AuthorRef
          [OLD] (CantonalAntenna)PositionRef
          [OLD] (CantonalAntenna)Comment (#text)
        [NEW] Service @LastModification
          [OLD, DELETE] (ServiceResponsible)Date
          [OLD] (ServiceResponsible)AuthorRef
          [OLD] (ServiceResponsible)PositionRef
          [OLD] (ServiceResponsible)Comment (#text)
        [OLD] Others
                OtherOpinion* @LastModification
                  AuthorRef
                  Comment (#text)
        KAM-Opinion<+>
        ServiceHeadOpinion<+>
      FundingDecision<+>
        [OLD] DecisionMakingAuthorityRef
        [OLD] FundingSources
                FundingSource
                  FundingSourceRef
                  RequestedAmount
                  ApprovedAmount
                  FundingSourceBalance
        [OLD] TotalFundingSources
                TotalRequested
                TotalApproved
                TotalBalance
      FinalReport (Coaching Report)
        KAMPreparation
        ManagementTeam
        Comment
        PlannedContinuation (Text*)
        Dissemination
          RatingScaleRef
          CommunicationAdviceRef
          Comment (Text*)
        EvaluationCriteria
          Business
          Capacity
        ObjectivesAchievements
          RatingScaleRef
          PositiveComment (Text*)
          NegativeComment (Text*)
        [OLD, NEW] Partners<+>
        TimesheetFile [only when reading]
        [OLD] ObjectivesAchievements
        [OLD] SpecificProblems
        [OLD] Comments
        [OLD] PlannedContinuation
        [OLD] Dissemination
                ToAppearInNews
                Motivation
        [OLD] Costs<+>
          CoachingHourlyRate (readonly, stored in activity)
          CoachingCosts*
            CoachActivity
              CoachRef
              EffectiveNbOfHours
              EffectiveHoursAmount
              EffectiveOtherExpensesAmount
              ActivityAmount
          TotalEffectiveCosts
             TotalEffectiveHoursNb
             TotalEffectiveHoursAmount
             TotalEffectiveOtherExpensesAmount
             TotalActivityAmount
          TotalApproved
          TotalBalance
        [OLD] ClientEnterprise<+>
        Partners<+>
      FinalReportApproval ([a] from KAMReportNAProxy and [b] form poll module)
        [a] Recognition
        [a] Tools
        [b] Profiles
        [b] Dialogue
        [b] PastRegionalInvolvement
        [b] RegionalInvolvement
        [b] FutureRegionalInvolvement
        [b] FutureSupport
        [OLD] Completeness
                OpinionRef [=> PositionRef]
                Comment (#text)
                Date
                Author [=> AuthorRef]
        [OLD] ResultsQuality
                OpinionRef [=> PositionRef]
                Comment (#text)
                Date
                Author [=> AuthorRef]
        [OLD] FinancialStatement<+>
                FundingSource*
                  FundingSourceRef
                  ApprovedAmount
                  EffectiveAmount
                  Balance
                TotalApprovedAmount
                TotalEffectiveAmount
                ApprovedBalance
                Difference
                EffectiveBalance
        [OLD] FinancialStatementComment
                OpinionRef [=> PositionRef]
                Comment
                Date
                Author
        DecisionMakingAuthorityRef
        [NEW] CoachingManagerVisa (abandonned ?)
      Evaluation (connection with poll module)
       Order (for SME)
       Order (for KAM, transcoded into FinalReportApproval [b])

### The `Partner` data type

Platinn version

```xml
<Partner>
  <Partner>
    <PartnerRef>302</PartnerRef>
    <Name>Haute Ecole Arc Ingénierie, He-arc ingénierie</Name>
    <Address>
      <PostalCode>2000</PostalCode>
      <Town>Neuchâtel</Town>
      <State>NE</State>
      <Country>CH</Country>
    </Address>
  </Partner>
  <PartnerTypeRef>2</PartnerTypeRef>
  <PartnerRoleRef>8</PartnerRoleRef>
</Partner>
```

CaseTracker version 

```xml
<Partner>
  <Partner>
    <EnterpriseRef>302</EnterpriseRef>
    <Archive Date="">
      <Name>Haute Ecole Arc Ingénierie, He-arc ingénierie</Name>
      <Address>
        <PostalCode>2000</PostalCode>
        <Town>Neuchâtel</Town>
        <State>NE</State>
        <Country>CH</Country>
      </Address>
    </Archive>
    <PartnerTypeRef>2</PartnerTypeRef>
    <PartnerRoleRef>8</PartnerRoleRef>
</Partner>
```

In-formular version :

```xml
<Partner>
  <Partner>
    <EnterpriseRef>302</EnterpriseRef> <!-- *** not used when goal=read *** -->
    <Name>Haute Ecole Arc Ingénierie, He-arc ingénierie</Name>
    <Address>
      <PostalCode>2000</PostalCode>
      <Town>Neuchâtel</Town>
      <State>NE</State>
      <Country>CH</Country>
    </Address>
    <PartnerTypeRef>2</PartnerTypeRef>
    <PartnerRoleRef>8</PartnerRoleRef>
</Partner>
```

### The `Conformity` data type

```xml
<Conformity>
  <Evaluation>
    <YesNoScaleRef>2</YesNoScaleRef>
  </Evaluation>
  <Personal>
    <YesNoScaleRef>2</YesNoScaleRef>
  </Personal>
  <Financial>
    <YesNoScaleRef>2</YesNoScaleRef>
  </Financial>
  <Professional>
    <YesNoScaleRef>2</YesNoScaleRef>
  </Professional>
</Conformity>
```

### The `Budget` data type

EASME version

```xml
<Budget>
  <Tasks>
    <Task>
      <Description>Three half day workshop "...</Description>
      <NbOfHours>12</NbOfHours>
    </Task>
    <Task>
      <Description>Three half day workshops...</Description>
      <NbOfHours>12</NbOfHours>
    </Task>
    <TotalNbOfHours>24</TotalNbOfHours>
    <TotalTasks>1350</TotalTasks>
  </Tasks>
</Budget>
```

Platinn version

```xml
<Budget>
  <Tasks>
    <Task>
      <Description>- Soutien dans la préparation....</Description>
      <NbOfHours>4</NbOfHours>
    </Task>
    <Task>
      <Description>- Interprétation et formalisation...</Description>
      <NbOfHours>12</NbOfHours>
    </Task>
    <TotalTasks>2400</TotalTasks>
  </Tasks>
  <OtherExpenses>
    <OtherExpense>
    </OtherExpense>
    <TotalOtherExpenses>0</TotalOtherExpenses>
  </OtherExpenses>
  <TotalBudget>2400</TotalBudget>
  <FundingSources>
    <FundingSource>
      <Id>1</Id>
      <Amount>2400</Amount>
    </FundingSource>
    <TotalFundingSources>2400</TotalFundingSources>
  </FundingSources>
  <CoachingHourlyRate>150</CoachingHourlyRate>
  <BudgetBalance>0</BudgetBalance>
</Budget>
````

## The `StatusHistory` data type

The `StatusHistory` encodes the current workflow status and a trace of the last date in each status already reached by the workflow (shallow history). The encoding uses status selectors values declared in global information.

```xml
<StatusHistory>
  <CurrentStatusRef>3</CurrentStatusRef>
  <PreviousStatusRef>2</PreviousStatusRef>
  <Status>
    <Date>2015-02-13</Date>
    <ValueRef>1</ValueRef>
  </Status>
  <Status>
    <Date>2015-03-18T14:22:07.713+01:00</Date>
    <ValueRef>2</ValueRef>
  </Status>
  <Status>
    <Date>2015-04-23T11:28:51.186+02:00</Date>
    <ValueRef>3</ValueRef>
  </Status>
</StatusHistory>
```

## The `UserProfile` data type

It contains information about the user if the Person entity represents a user with access to the case tracker.

## Functional dependencies

Tasks (FundingRequest)
  Task
    Description
    NbOfHours
  TotalTasks

OtherExpenses (FundingRequest)
  OtherExpense
    Descrpition
    Amount
  TotalOtherExpenses

FundingSources
  FundingSource
    FundingSourceRef
    Comment
    Amount (FundingRequest) => RequestedAmount (FundingDecision)
    ApprovedAmount (FundingDecision) => ApprovedAmount (FinalReportApproval)
    EffectiveAmount (FinalReportApproval)
    Balance (ApprovedAmount - Amount, FundingDecision)
    Balance (ApprovedAmount - EffectiveAmount, FinalReportApproval)
  TotalFundingSources (sum(Amount) - FundingRequest)

BudgetBalance (FundingRequest)
  
TotalFundingSources (FundingDecision)
  TotalApproved (sum(ApprovedAmount) - FundingDecision)
  TotalBalance (sum(Balance) - FundingDecision)
  

CoachingCosts (FinalReport)
  CoachActivity
    CoachRef
    EffectiveNbOfHours
    EffectiveHoursAmount
    EffectiveOtherExpensesAmount
    ActivityAmount

TotalEffectiveCosts (FinalReport)
  TotalEffectiveHoursNb
  TotalEffectiveHoursAmount 
  TotalEffectiveOtherExpensesAmount
  TotalActivityAmount

Functional dependencies 
---

Difference = SpentBalance - EffectiveBalance = Effective - Spent (invariant)
SpentBalance = TotalApproved - TotalSpent
ApprovedBalance = TotalRequested - TotalApproved
EffectiveBalance = TotalApproved - TotalEffective
TotalRequested = SUM(RequestedAmount) => Funding request
TotalApproved = SUM(ApprovedAmount) => Funding decision
TotalSpend = SUM(ActivityAmount) => Final report
TotalEffective = SUM(EffectiveAmount) => Final report approval

3 situations :

a) coaching plan : on change FundingSource (amount) => 'dependency'
b) coach contracing : on change FundingSource (approved amount) => 'dependency'

PBS: 
- on retire une source (?) => la laisser, on peut éditeur l'autre document pour la supprimer
- on duplique une source (?) => appliquer un group by algorithm (?)

=====> on peut faire tous les calculs dans 'update' ? pas besoin de dependency (factoriser les variables ?)
=====> implémenter le group by pour Coaching Plan ?


Coaching plan

FundingSources
  FundingSource
    FundingSourceRef
    Comment=== > concat()
    Amount ==> sum()
  TotalFundingSources (sum(Amount) - FundingRequest)
