<?xml version="1.0" encoding="UTF-8"?>
<!--
     Case Tracker Reference

     Creator: Stéphane Sire <s.sire@opppidoc.fr>

     With saxon use -strip:all to remove whitespaces

     Migration of legacy coaching Platinn case.xml resource files

     See case.sh

     DEAD COPIES
     - Case > Information > ClientEnterprise (EnterpriseKey) : create Archive (when closing, or no coaching) 
     - Case > NeedsAnalysis > ContactPerson (PersonKey) : create Archive (when closing, or no coachnig)
     - in FundingRequest > ClientEnterprise (EnterpriseKey) : create Archive (when CurrentStatusRef = 10, or rejected 9)
     - in FundingRequest > ContactPerson (PersonKey) : create Archive (when CurrentStatusRef = 10, or rejected 9)
     - in FundingRequest > Partners > Partner (EnterpriseKey) : create Archive (when CurrentStatusRef = 10, or rejected 9)
     - in CoachingReport > Partners > Partner (EnterpriseKey) : create Archive (when CurrentStatusRef = 10, or rejected 9)

     FundingRequest, FundingDecision, CoachingReport @LastModification heuristic :
     - if the status after (+1) exists then takes the date of entry (i.e. leaving the editing window for the doc)
     - otherwise takes the data of entry in the editing window (status at which corresponding doc is editable)

     @legacy : 
     - no En Consultation no En décision !!!! (FIXME:)

     IMPROVEMENTS:
     - Title : ne pas transférer M ou Mme (que Dr, Prof.)

     TODO:
     - Q&A : check if discrepancies in FundingSources between FundingRequest and FundingDecision ?
     - check why some FundingRequest have a LastModification="" and why some Archive have a LastModification=""
     - Report Approval => add to StatusHistory 
         <ConcurrentStatusRef Group="feedback">80</ConcurrentStatusRef>
         <Status>
           <Date>2016-12-29</Date>
           <ValueRef>80</ValueRef>
         </Status>

     Migration of binay files (Annexes)

     The goal is to replace the distributed storage of uploaded document (annexes) 
     inside db/sites/coaching/YYYY/CaseID/docs/activities/* sub-collection of the case)
     by a centralized storage into a dedicated collection
     inside /db/binaries/ctracker/cases/YYYY/CaseId
  
     See move.sh

     Note __content__.xml in each docs folder is renamed to meta.xml to preserve binary files 
     creation date for very old cases w/o asociated Resources record (requires an adaptation 
     to annex.xqm to display correct date)

  -->
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  >

  <xsl:output method="xml" media-type="text/xml" omit-xml-declaration="yes" indent="yes"/>

  <!-- ************
       *** Case ***
       ************ -->

  <!-- Questions:
       - pertinence CreationDate ?
  -->
  <xsl:template match="/Case">
    <Case>
      <xsl:apply-templates select="No"/>
      <xsl:apply-templates select="CreationDate"/>
      <StatusHistory>
        <CurrentStatusRef>1</CurrentStatusRef>
        <Status>
          <Date><xsl:value-of select="CreationDate"/></Date>
          <ValueRef>1</ValueRef>
        </Status>
      </StatusHistory>
      <Information LastModification="{ CreationDate }">
        <xsl:apply-templates select="ClientEnterprise" mode="client-enterprise"/>
      </Information>
      <xsl:apply-templates select="ResponsibleCoachRef" mode="Management"/>
      <NeedsAnalysis LastModification="{ CreationDate }">
        <xsl:apply-templates select="Activities/Activity[1]/FundingRequest/ClientEnterprise/ContactPerson" mode="contact-person"/>
        <xsl:apply-templates select="Activities/Activity[1]/FundingRequest/ContactSourceRef"/>
        <xsl:apply-templates select="ClientEnterprise/Context"/>
        <xsl:apply-templates select="ClientEnterprise/Impact"/>
        <xsl:apply-templates select="ClientEnterprise/Comments" mode="needs-analysis"/>
      </NeedsAnalysis>
      <Evaluation/>
      <xsl:apply-templates select="Activities"/>
    </Case>
  </xsl:template>

  <xsl:template match="ClientEnterprise" mode="client-enterprise"> 
    <ClientEnterprise>
      <EnterpriseKey><xsl:value-of select="EnterpriseRef"/></EnterpriseKey>
    </ClientEnterprise>
  </xsl:template>

  <xsl:template match="ContactPerson" mode="contact-person">
    <ContactPerson>
      <PersonKey><xsl:value-of select="Id"/></PersonKey>
    </ContactPerson>
  </xsl:template>

  <xsl:template match="ContextDescription">
    <Comments><xsl:copy-of select="*"/></Comments>
  </xsl:template>
  
  <xsl:template match="InitialContext">
    <InitialContextRef><xsl:value-of select="."/></InitialContextRef>
  </xsl:template>

  <xsl:template match="TargetedContext">
    <TargetedContextRef><xsl:value-of select="."/></TargetedContextRef>
  </xsl:template>

  <xsl:template match="ContactSourceRef">
    <ContactSourceRef>
      <xsl:call-template name="contact-sources"/>
    </ContactSourceRef>
  </xsl:template>

  <xsl:template match="Impact">
    <Impact>
      <xsl:copy-of select="Vectors"/>
      <xsl:apply-templates select="Ideas"/>
      <xsl:apply-templates select="Resources"/>
      <xsl:copy-of select="Partners"/>
    </Impact>
  </xsl:template>

  <xsl:template match="Ideas">
    <Ideas>
      <xsl:apply-templates select="IdeaRef[. != '2' and . != '3' and '.' != '4' and . != '8']"/>
      <xsl:if test="IdeaRef = '2' or IdeaRef = '3' or IdeaRef = '4' or IdeaRef = '8'">
        <IdeaRef>9</IdeaRef>
      </xsl:if>
    </Ideas>
  </xsl:template>

  <xsl:template match="Resources[count(ResourceRef) > 1]">
    <Resources>
      <xsl:apply-templates select="ResourceRef"/>
    </Resources>
  </xsl:template>

  <xsl:template match="Resources[count(ResourceRef) = 1 and ResourceRef != '8']">
    <Resources>
      <xsl:apply-templates select="ResourceRef"/>
    </Resources>
  </xsl:template>

  <xsl:template match="Resources[count(ResourceRef) = 1 and ResourceRef = '8']">
  </xsl:template>

  <xsl:template match="ResourceRef[. != '8']">
    <xsl:copy-of select="."/>
  </xsl:template>

  <!-- remove Others -->
  <xsl:template match="ResourceRef[. = '8']">
  </xsl:template>

  <xsl:template match="Comments" mode="needs-analysis">
    <Challenges><xsl:copy-of select="."/></Challenges>
  </xsl:template>

  <!-- ******************
       *** Management ***
       ****************** -->

  <!-- Converts ResponsibleCoachRef to InitiatedByKey and to AccountManagerKey 
       without giving the KAM role to the corresponding person
       Conformity questions are not available in legacy case tracker -->
  <xsl:template match="ResponsibleCoachRef" mode="Management">
    <Management>
      <InitiatedByKey><xsl:value-of select="."/></InitiatedByKey>
      <AccountManagerKey><xsl:value-of select="."/></AccountManagerKey>
    </Management>
  </xsl:template>

  <!-- ******************
       *** Activities ***
       ****************** -->

  <xsl:template match="Activities[not(Activity)]">
  </xsl:template>

  <!-- Questions:
  -->
  <xsl:template match="Activities[Activity]">
    <Activities>
      <xsl:copy-of select="@LastIndex"/>
      <xsl:apply-templates select="Activity"/>
    </Activities>
  </xsl:template>
  
  <!-- ****************
       *** Activity ***
       **************** -->

  <!-- Questions:
       - pertinence CreationDate ?
       - pas de NeedsAnalysis archive ?
       FIXME: adjust StatusHistory ?
  -->
  <xsl:template match="Activity">
    <Activity>
      <xsl:copy-of select="@legacy"/>
      <xsl:apply-templates select="No"/>
      <CreationDate><xsl:value-of select="StatusHistory/Status[ValueRef eq '1']/Date/text()"/></CreationDate>
      <xsl:apply-templates select="StatusHistory"/>
      <xsl:call-template name="Budget"/>
      <xsl:call-template name="activity-Assignment"/>
      <xsl:apply-templates select="FundingRequest"/>
      <xsl:apply-templates select="Opinions"/>
      <xsl:apply-templates select="FundingDecision"/>
      <xsl:apply-templates select="Logbook"/>
      <xsl:apply-templates select="FinalReport" mode="coaching-report"/>
      <xsl:apply-templates select="FinalReportApprovement" mode="report-approval"/>
      <xsl:apply-templates select="Alerts"/>
      <xsl:apply-templates select="Appendices"/>
    </Activity>
  </xsl:template>

  <xsl:template match="StatusHistory">
    <StatusHistory>
      <xsl:apply-templates select="CurrentStatusRef"/>
      <xsl:apply-templates select="PreviousStatusRef"/>
      <xsl:apply-templates select="Status"/>
    </StatusHistory>
  </xsl:template>
  
  <xsl:template match="CurrentStatusRef">
    <CurrentStatusRef><xsl:call-template name="convert-activity-status"/></CurrentStatusRef>
  </xsl:template>

  <xsl:template match="PreviousStatusRef">
    <PreviousStatusRef><xsl:call-template name="convert-activity-status"/></PreviousStatusRef>
  </xsl:template>

  <xsl:template match="Status[ValueRef = '1']">
    <Status>
      <xsl:copy-of select="Date"/>
      <ValueRef>1</ValueRef>
    </Status>
    <Status>
      <xsl:copy-of select="Date"/>
      <ValueRef>2</ValueRef>
    </Status>
  </xsl:template>

  <xsl:template match="Status[ValueRef != '1']">
    <Status>
      <xsl:copy-of select="Date"/>
      <xsl:apply-templates select="ValueRef"/>
    </Status>
  </xsl:template>

  <xsl:template match="ValueRef">
    <ValueRef><xsl:call-template name="convert-activity-status"/></ValueRef>
  </xsl:template>

  <!-- Coach assignment didn't exist before -->
  <xsl:template name="convert-activity-status">
    <xsl:choose>
      <xsl:when test=". = 1">2</xsl:when>
      <xsl:when test=". = 2 or . = 3  or . = 4"><xsl:value-of select="number(.) + 1"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="number(.) + 2"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- **************
       *** Budget ***
       ************** -->

  <!-- new synthesis document-->
  <xsl:template name="Budget">
    <Budget>
      <Costs>
        <xsl:copy-of select="FundingRequest/Budget/Tasks"/>
        <xsl:copy-of select="FundingRequest/Budget/OtherExpenses"/>
        <xsl:apply-templates select="FinalReport/Costs/CoachingCosts"/>
      </Costs>
      <Revenues>
        <FundingSources>
          <xsl:apply-templates select="FundingRequest/Budget/FundingSources/FundingSource" mode="funding-request"/>
        </FundingSources>
      </Revenues>
      <Variables>
        <xsl:apply-templates select="CoachingHourlyRate"/>
        <xsl:apply-templates select="FundingRequest/Budget/FundingSources/TotalFundingSources" mode="funding-request"/>
        <xsl:apply-templates select="FundingDecision/TotalFundingSources/TotalApproved" mode="funding-decision"/>
        <xsl:apply-templates select="FundingDecision/TotalFundingSources/TotalBalance" mode="funding-decision"/>
        <Start/>
        <!-- ERROR: always empty, should have been FinalReport//TotalActivityAmount-->
        <xsl:apply-templates select="FinalReport/TotalActivityAmount" mode="final-report"/>
        <!-- ERROR: always empty, should have been FinalReport//TotalBalance-->
        <xsl:apply-templates select="FinalReport/TotalBalance" mode="final-report"/>
        <End/>
        <xsl:apply-templates select="FinalReportApprovement/FinancialStatement/TotalEffectiveAmount" mode="report-approval"/>
        <xsl:apply-templates select="FinalReportApprovement/FinancialStatement/EffectiveBalance" mode="report-approval"/>
        <xsl:apply-templates select="FinalReportApprovement/FinancialStatement/Difference" mode="report-approval"/>
      </Variables>
    </Budget>
  </xsl:template>

  <xsl:template match="CoachRef">
    <CoachKey><xsl:value-of select="."/></CoachKey>
  </xsl:template>

  <!-- ******************
       *** Assignment ***
       ****************** -->

  <!-- TODO: 
       - AssignedByRef -->
  <xsl:template name="activity-Assignment">
    <Assignment LastModification="{ StatusHistory/Status[ValueRef eq '1']/Date }">
      <xsl:apply-templates select="ServiceRef"/>
      <xsl:apply-templates select="FundingRequest/PhaseRef"/>
      <xsl:apply-templates select="FundingRequest/ResponsibleCoach" mode="assignment"/>
      <xsl:apply-templates select="ancestor::Case/ResponsibleCoachRef" mode="assignment"/>
      <Date><xsl:value-of select="StatusHistory/Status[ValueRef eq '1']/Date"/></Date>
    </Assignment>
  </xsl:template>

  <xsl:template match="ResponsibleCoach" mode="assignment">
    <ResponsibleCoachKey><xsl:value-of select="CoachRef"/></ResponsibleCoachKey>
  </xsl:template>

  <xsl:template match="ResponsibleCoachRef" mode="assignment">
    <AssignedByKey><xsl:value-of select="."/></AssignedByKey>
  </xsl:template>

  <!-- **************
       *** Budget ***
       ************** -->

  <!-- synthesize FundingSource in Budget from other legacy documents -->
  <xsl:template match="FundingSource" mode="funding-request">
    <xsl:variable name="source"><xsl:value-of select="Id"/></xsl:variable>
    <FundingSource>
      <FundingSourceRef><xsl:value-of select="Id"/></FundingSourceRef>
      <xsl:apply-templates select="Amount" mode="funding-request"/>
      <xsl:apply-templates select="ancestor::Activity/FundingDecision//FundingSource[Ref eq $source]/ApprovedAmount"/>
      <xsl:apply-templates select="ancestor::Activity/FinalReportApprovement//FundingSource[FundingSourceRef eq $source]/EffectiveAmount"/>
      <xsl:copy-of select="Comment"/>
    </FundingSource>
  </xsl:template>

  <xsl:template match="Amount" mode="funding-request">
    <RequestedAmount><xsl:value-of select="."/></RequestedAmount>
  </xsl:template>

  <!-- TODO:
       - use full model -->
  <xsl:template match="CoachingHourlyRate">
    <CoachingHourlyRate><xsl:value-of select="Amount"/></CoachingHourlyRate>
  </xsl:template>

  <xsl:template match="TotalFundingSources" mode="funding-request">
    <TotalRequested><xsl:value-of select="."/></TotalRequested>
  </xsl:template>

  <xsl:template match="TotalApproved" mode="funding-decision">
    <TotalApproved><xsl:value-of select="."/></TotalApproved>
  </xsl:template>

  <xsl:template match="TotalBalance" mode="funding-decision">
    <ApprovedBalance><xsl:value-of select="."/></ApprovedBalance>
  </xsl:template>
  
  <!-- ERROR: Never called ! see above -->
  <xsl:template match="TotalActivityAmount" mode="final-report">
    <TotalSpent><xsl:value-of select="."/></TotalSpent>
  </xsl:template>

  <!-- ERROR: Never called ! see above -->
  <xsl:template match="TotalBalance" mode="final-report">
    <SpentBalance><xsl:value-of select="."/></SpentBalance>
  </xsl:template>

  <!-- ERROR: should have been called TotalEffective (~ TotalAllocated) -->
  <xsl:template match="TotalEffectiveAmount" mode="report-approval">
    <TotalSpent><xsl:value-of select="."/></TotalSpent>
  </xsl:template>
  
  <!-- ERROR: should have been called EffectiveBalance (~ AllocatedBalance) -->
  <xsl:template match="EffectiveBalance" mode="report-approval">
    <SpentBalance><xsl:value-of select="."/></SpentBalance>
  </xsl:template>

  <xsl:template match="Difference" mode="report-approval">
    <Difference><xsl:value-of select="."/></Difference>
  </xsl:template>
  
  <!-- **********************
       *** FundingRequest ***
       ********************** -->

  <xsl:template match="FundingRequest">
    <FundingRequest>
      <xsl:attribute name="LastModification">
        <xsl:choose>
          <xsl:when test="../StatusHistory/Status[ValueRef eq '2']/Date/text()">
            <xsl:value-of select="../StatusHistory/Status[ValueRef eq '2']/Date/text()"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="../StatusHistory/Status[ValueRef eq '1']/Date/text()"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:apply-templates select="../Title"/>
      <xsl:apply-templates select="SubmissionOrigin"/>
      <xsl:apply-templates select="ClientEnterprise" mode="funding-request"/>
      <xsl:apply-templates select="ClientEnterprise/ContactPerson" mode="funding-request"/>
      <xsl:apply-templates select="Partners[Partner]" mode="funding-request"/>
      <xsl:copy-of select="Objectives"/>
      <xsl:apply-templates select="ResponsibleCoachComments"/>
    </FundingRequest>
  </xsl:template>

  <!-- TODO: 
       - convert free text string (e.g. Cimark) to reference 
       - create SubmissionOrigins selector in custom selectors
       -->
  <xsl:template match="SubmissionOrigin">
    <SubmissionOriginRef>
      <xsl:call-template name="entities"/>
    </SubmissionOriginRef>
  </xsl:template>

  <xsl:template match="ClientEnterprise" mode="funding-request">
    <ClientEnterprise>
      <EnterpriseKey><xsl:value-of select="Enterprise/Id"/></EnterpriseKey>
    </ClientEnterprise>
  </xsl:template>

  <xsl:template match="ClientEnterprise[ancestor::Activity/StatusHistory/CurrentStatusRef = '8']" mode="funding-request">
    <ClientEnterprise>
      <EnterpriseKey><xsl:value-of select="Enterprise/Id"/></EnterpriseKey>
      <xsl:apply-templates select="ancestor::Activity/FinalReport/ClientEnterprise/Enterprise" mode="dead-copy"/>
    </ClientEnterprise>
  </xsl:template>

  <!-- Take dead copy of Enterprise from FinalReport where it was archived when closing activity -->
  <xsl:template match="Enterprise" mode="dead-copy">
    <Archive LastModification="{ ancestor::Activity/StatusHistory/Status[ValueRef = '8']/Date }">
      <xsl:apply-templates select="Name"/>
      <xsl:apply-templates select="ShortName"/>
      <xsl:apply-templates select="CreationYear"/>
      <xsl:apply-templates select="SizeRef"/>
      <xsl:apply-templates select="NOGA-Code"/>
      <xsl:apply-templates select="WebSite"/>
      <xsl:apply-templates select="TargetedMarkets"/>
      <xsl:apply-templates select="MainActivities"/>
      <xsl:apply-templates select="Address"/>
    </Archive>
  </xsl:template>

  <xsl:template match="ContactPerson" mode="funding-request">
    <ContactPerson>
      <PersonKey><xsl:value-of select="Id"/></PersonKey>
    </ContactPerson>
  </xsl:template>

  <xsl:template match="ContactPerson[ancestor::Activity/StatusHistory/CurrentStatusRef = '8']" mode="funding-request">
    <ContactPerson>
      <PersonKey><xsl:value-of select="Id"/></PersonKey>
      <xsl:apply-templates select="." mode="dead-copy"/>
    </ContactPerson>
  </xsl:template>

  <!-- Take dead copy of Person from FundingRequest where it was first copied at the funding request creation
       and updated each time the funding request was saved (hence uses Consultation status date for TS) 
       In some @legacy Activity the status '2' have been skipped hence we cannot use it to timestamp the archive -->
  <xsl:template match="ContactPerson" mode="dead-copy">
    <Archive>
      <xsl:attribute name="LastModification">
        <xsl:choose>
          <xsl:when test="ancestor::Activity/StatusHistory/Status[ValueRef eq '2']/Date/text()">
            <xsl:value-of select="ancestor::Activity/StatusHistory/Status[ValueRef eq '2']/Date/text()"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="ancestor::Activity/StatusHistory/Status[ValueRef eq '1']/Date/text()"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:apply-templates select="Sex"/>
      <xsl:apply-templates select="Civility"/>
      <xsl:apply-templates select="Name"/>
      <xsl:apply-templates select="Country"/>
      <xsl:apply-templates select="EnterpriseKey"/>
      <xsl:apply-templates select="Function"/>
      <xsl:apply-templates select="Contacts"/>
      <xsl:apply-templates select="Photo"/>
    </Archive>
  </xsl:template>

  <!-- FIXME: generate Archive ? -->
  <xsl:template match="Partners" mode="funding-request">
    <Partners>
      <xsl:apply-templates select="Partner" mode="funding-request"/>
    </Partners>
  </xsl:template>

  <xsl:template match="Partner" mode="funding-request">
    <Partner>
      <xsl:apply-templates select="Partner/PartnerRef" mode="transclusion"/>
      <xsl:apply-templates select="PartnerTypeRef"/>
      <xsl:apply-templates select="PartnerRoleRef"/>
    </Partner>
  </xsl:template>

  <xsl:template match="Partner[ancestor::Activity/StatusHistory/CurrentStatusRef = '8']" mode="funding-request">
    <Partner>
      <xsl:apply-templates select="Partner/PartnerRef" mode="transclusion"/>
      <xsl:apply-templates select="Partner" mode="funding-request-dead-copy"/>
      <xsl:apply-templates select="PartnerTypeRef"/>
      <xsl:apply-templates select="PartnerRoleRef"/>
    </Partner>
  </xsl:template>

  <xsl:template match="Partner" mode="funding-request-dead-copy">
    <Archive LastModification="{ ancestor::Activity/StatusHistory/Status[ValueRef = '8']/Date }">
      <xsl:apply-templates select="Name"/>
      <xsl:apply-templates select="Address" mode="partner"/>
    </Archive>
  </xsl:template>

  <xsl:template match="PartnerRef" mode="transclusion">
    <EnterpriseKey><xsl:value-of select="."/></EnterpriseKey>
  </xsl:template>
  
  <xsl:template match="ResponsibleCoachComments">
    <ResponsibleCoachComment><xsl:value-of select="."/></ResponsibleCoachComment>
  </xsl:template>

  <xsl:template match="ResponsibleCoachComments[. = '']" priority="1"></xsl:template>  

  <!-- ****************
       *** Opinions ***
       **************** -->
  <xsl:template match="Opinions">
    <Opinions>
      <xsl:if test="CantonalAntennaDate or CantonalAntennaAuthor or CantonalAntennaOpinionRef or CantonalAntennaComment">
        <xsl:call-template name="Region-opinion"/>
      </xsl:if>
      <xsl:if test="ServiceResponsibleDate or ServiceResponsibleAuthor or ServiceResponsibleOpinionRef or ServiceResponsibleComment">
        <xsl:call-template name="Service-opinion"/>
      </xsl:if>
      <xsl:apply-templates select="OtherOpinions"/>
    </Opinions>
  </xsl:template>

  <xsl:template name="Region-opinion">
    <Region>
      <xsl:apply-templates select="CantonalAntennaDate"/>
      <xsl:apply-templates select="CantonalAntennaOpinionRef"/>
      <xsl:apply-templates select="CantonalAntennaComment"/>
      <xsl:apply-templates select="CantonalAntennaAuthor"/>
    </Region>
  </xsl:template>

  <xsl:template match="CantonalAntennaDate">
    <xsl:attribute name="LastModification"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="CantonalAntennaOpinionRef">
    <xsl:call-template name="convert-position"/>
  </xsl:template>

  <xsl:template match="CantonalAntennaComment">
    <Comment><xsl:value-of select="."/></Comment>
  </xsl:template>

  <xsl:template match="CantonalAntennaAuthor">
    <Author>
      <DisplayName><xsl:value-of select="."/></DisplayName>
    </Author>
  </xsl:template>

  <xsl:template name="Service-opinion">
    <Service>
      <xsl:apply-templates select="ServiceResponsibleDate"/>
      <xsl:apply-templates select="ServiceResponsibleOpinionRef"/>
      <xsl:apply-templates select="ServiceResponsibleComment"/>
      <xsl:apply-templates select="ServiceResponsibleAuthor"/>
    </Service>
  </xsl:template>

  <xsl:template match="ServiceResponsibleDate">
    <xsl:attribute name="LastModification"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="ServiceResponsibleOpinionRef">
    <xsl:call-template name="convert-position"/>
  </xsl:template>

  <xsl:template match="ServiceResponsibleComment">
    <Comment><xsl:value-of select="."/></Comment>
  </xsl:template>

  <xsl:template match="ServiceResponsibleAuthor">
    <Author>
      <DisplayName><xsl:value-of select="."/></DisplayName>
    </Author>
  </xsl:template>
  
  <xsl:template match="OtherOpinions[OtherOpinion]">
    <OtherOpinions>
      <xsl:apply-templates select="OtherOpinion"/>
    </OtherOpinions>
  </xsl:template>

  <xsl:template match="OtherOpinions[not(OtherOpinion)]">
  </xsl:template>

  <xsl:template match="OtherOpinion">
    <OtherOpinion>
      <xsl:apply-templates select="Date"/>
      <xsl:apply-templates select="Comment" mode="other-opinion"/>
      <xsl:apply-templates select="Author" mode="other-opinion"/>
    </OtherOpinion>
  </xsl:template>

  <xsl:template match="Comment" mode="other-opinion">
    <Comment><xsl:value-of select="."/></Comment>
  </xsl:template>
  
  <xsl:template match="Author" mode="other-opinion">
    <Author>
      <DisplayName><xsl:value-of select="."/></DisplayName>
    </Author>
  </xsl:template>

  <!-- ***********************
       *** FundingDecision ***
       *********************** -->

  <xsl:template match="FundingDecision">
    <FundingDecision>
      <xsl:attribute name="LastModification">
        <xsl:choose>
          <xsl:when test="../StatusHistory/Status[ValueRef eq '4']/Date/text()">
            <xsl:value-of select="../StatusHistory/Status[ValueRef eq '4']/Date/text()"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="../StatusHistory/Status[ValueRef eq '3']/Date/text()"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:apply-templates select="DecisionMakingAuthorityRef"/>
      <xsl:apply-templates select="Comment"/>
    </FundingDecision>
  </xsl:template>

  <!-- ***********************
       *** Logbook ***
       *********************** -->

  <!-- Imports Logbook Converting LogbookItem to LogbookEntry and CoachRef to CoachKey -->
  <xsl:template match="Logbook">
    <Logbook>
      <xsl:apply-templates select="@LastIndex"/>
      <xsl:apply-templates select="LogbookItem"/>
    </Logbook>
  </xsl:template>
  
  <xsl:template match="LogbookItem">
    <LogbookEntry>
      <xsl:apply-templates select="Id"/>
      <xsl:copy-of select="Date"/>
      <xsl:apply-templates select="CoachRef"/>
      <xsl:apply-templates select="NbOfHours"/>
      <xsl:apply-templates select="ExpenseAmount"/>
      <xsl:apply-templates select="Comment"/>
    </LogbookEntry>
  </xsl:template>

  <!-- **********************
       *** CoachingReport ***
       ********************** -->

  <!-- FIXME:
       - KAMPreparation not available 
       - ManagementTeam not available 
       - Comments wording not exactly equivalent -->
  <xsl:template match="FinalReport" mode="coaching-report">
    <CoachingReport>
      <xsl:attribute name="LastModification">
        <xsl:choose>
          <xsl:when test="../StatusHistory/Status[ValueRef eq '5']/Date/text()">
            <xsl:value-of select="../StatusHistory/Status[ValueRef eq '5']/Date/text()"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="../StatusHistory/Status[ValueRef eq '4']/Date/text()"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:call-template name="ObjectivesAchievements"/>
      <xsl:apply-templates select="Comments" mode="coaching-report"/>
      <xsl:apply-templates select="PlannedContinuation" mode="coaching-report"/>
      <xsl:apply-templates select="Dissemination" mode="coaching-report"/>
      <xsl:apply-templates select="Partners" mode="coaching-report"/>
    </CoachingReport>
  </xsl:template>

  <!-- FIXME:
       - RatingScaleRef not available -->
  <xsl:template name="ObjectivesAchievements">
    <xsl:if test="ObjectivesAchievements or SpecificProblems">
      <ObjectivesAchievements>
        <xsl:apply-templates select="ObjectivesAchievements" mode="objectives-achievements"/>
        <xsl:apply-templates select="SpecificProblems" mode="objectives-achievements"/>
      </ObjectivesAchievements>
    </xsl:if>
  </xsl:template>

  <!-- label : 
      - label coaching: Dans quelle mesure les tâches et objectifs fixés ont-ils été réalisés?
      - label EASME: What has been achieved, regarding the set coaching objectives and activities? What was your impact? What have they learned? How will they proceed? -->
  <xsl:template match="ObjectivesAchievements" mode="objectives-achievements">
    <PositiveComments><Text><xsl:value-of select="."/></Text></PositiveComments>
  </xsl:template>

  <!-- label : 
       - label coaching: Avez-vous été confrontés à des problèmes particuliers? 
       - label EASME : What has not been achieved? -->
  <xsl:template match="SpecificProblems" mode="objectives-achievements">
    <NegativeComments><Text><xsl:value-of select="."/></Text></NegativeComments>
  </xsl:template>

  <!-- FIXME: 
       - label coaching: Remarques et commentaires
       - label EASME: What difficulties have you faced?
       - use Difficulites instead of Comment ? -->
  <xsl:template match="Comments" mode="coaching-report">
    <Difficulty><Comments><Text><xsl:value-of select="."/></Text></Comments></Difficulty>
  </xsl:template>

  <xsl:template match="PlannedContinuation" mode="coaching-report">
    <PlannedContinuation><Comments><Text><xsl:value-of select="."/></Text></Comments></PlannedContinuation>
  </xsl:template>

  <!-- FIXME:
       - RatingScaleRef not available -->
  <xsl:template match="Dissemination" mode="coaching-report">
    <Dissemination>
      <xsl:apply-templates select="ToAppearsInNews" mode="coaching-report"/>
      <xsl:apply-templates select="Motivation" mode="coaching-report"/>
    </Dissemination>
  </xsl:template>

  <xsl:template match="ToAppearsInNews" mode="coaching-report">
    <CommunicationAdviceRef><xsl:value-of select="."/></CommunicationAdviceRef>
  </xsl:template>

  <!-- FIXME: 
       - use Comments instead of Comment ? -->
  <xsl:template match="Motivation" mode="coaching-report">
    <Comments><Text><xsl:value-of select="."/></Text></Comments>
  </xsl:template>

  <xsl:template match="Partners[not(Partner)]" mode="coaching-report">
  </xsl:template>

  <xsl:template match="Partners[Partner]" mode="coaching-report">
    <Partners>
      <xsl:apply-templates select="Partner" mode="coaching-report"/>
    </Partners>
  </xsl:template>

  <xsl:template match="Partner" mode="coaching-report">
    <Partner>
      <xsl:call-template name="guess-enterprise-key"/>
      <xsl:apply-templates select="." mode="live-copy"/>
      <xsl:apply-templates select="PartnerTypeRef"/>
      <xsl:apply-templates select="PartnerRoleRef"/>
    </Partner>
  </xsl:template>

  <!-- FIXME: temporary solutions for Activities still in Report status
              in case we cannot guess the EnterpriseKey (i.e. -1)
       TODO: check if robust
  -->
  <xsl:template match="Partner" mode="live-copy">
    <Archive LastModification="{ ancestor::Activity/StatusHistory/Status[ValueRef = '4']/Date }">
      <xsl:apply-templates select="Name"/>
      <Address>
        <xsl:copy-of select="PostalCode"/>
        <xsl:copy-of select="Town"/>
        <xsl:apply-templates select="State" mode="partner"/>
        <xsl:copy-of select="Country"/>
      </Address>
    </Archive>
  </xsl:template>

  <xsl:template match="Partner[ancestor::Activity/StatusHistory/CurrentStatusRef = '8']" mode="coaching-report">
    <Partner>
      <xsl:call-template name="guess-enterprise-key"/>
      <xsl:apply-templates select="." mode="final-report-dead-copy"/>
      <xsl:apply-templates select="PartnerTypeRef"/>
      <xsl:apply-templates select="PartnerRoleRef"/>
    </Partner>
  </xsl:template>

  <xsl:template match="Partner" mode="final-report-dead-copy">
    <Archive LastModification="{ ancestor::Activity/StatusHistory/Status[ValueRef = '8']/Date }">
      <xsl:apply-templates select="Name"/>
      <Address>
        <xsl:copy-of select="PostalCode"/>
        <xsl:copy-of select="Town"/>
        <xsl:apply-templates select="State" mode="partner"/>
        <xsl:copy-of select="Country"/>
      </Address>
    </Archive>
  </xsl:template>
  
  <xsl:template name="guess-enterprise-key">
    <xsl:variable name="name"><xsl:value-of select="Name"/></xsl:variable>
    <xsl:choose>
      <xsl:when test="ancestor::Activity/FundingRequest//Partner/Partner[Name = $name]">
        <xsl:apply-templates select="ancestor::Activity/FundingRequest//Partner/Partner[Name = $name]/PartnerRef" mode="transclusion"/>
      </xsl:when>
      <xsl:otherwise>
        <EnterpriseKey><xsl:value-of select="$name"/></EnterpriseKey>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- **********************
       *** ReportApproval ***
       ********************** -->

  <!-- FIXME: 
       - align if we introduce a @LastModification-->
  <xsl:template match="FinalReportApprovement" mode="report-approval">
    <ReportApproval>
      <xsl:apply-templates select="Completeness"/>
      <xsl:apply-templates select="ResultsQuality"/>
      <xsl:apply-templates select="FinancialStatementComment"/>
      <xsl:apply-templates select="DecisionMakingAuthorityRef" mode="report-approval"/>
    </ReportApproval>
  </xsl:template>

  <xsl:template match="Completeness">
    <Completeness><xsl:call-template name="Position"/></Completeness>
  </xsl:template>

  <xsl:template match="ResultsQuality">
    <ResultsQuality><xsl:call-template name="Position"/></ResultsQuality>
  </xsl:template>

  <xsl:template match="FinancialStatementComment">
    <FinancialStatementComment><xsl:call-template name="Position"/></FinancialStatementComment>
  </xsl:template>

  <xsl:template name="Position">
    <xsl:apply-templates select="Date"/>
    <xsl:apply-templates select="OpinionRef" mode="position"/>
    <xsl:apply-templates select="Comment"/>
    <xsl:apply-templates select="Author" mode="position"/>
  </xsl:template>

  <xsl:template match="OpinionRef" mode="position">
    <xsl:call-template name="convert-position"/>
  </xsl:template>

  <xsl:template match="Author" mode="position">
    <Author>
      <PersonKey><xsl:value-of select="."/></PersonKey>
    </Author>
  </xsl:template>

  <xsl:template match="DecisionMakingAuthorityRef" mode="report-approval"><xsl:copy-of select="."/></xsl:template>

  <xsl:template match="DecisionMakingAuthorityRef[. = '']" priority="1" mode="report-approval"></xsl:template>
  
  <!-- **************
       *** Alerts ***
       ************** -->

  <xsl:template match="Alerts">
    <Alerts>
      <xsl:copy-of select="@LastIndex"/>
      <xsl:apply-templates select="Alert"/>
    </Alerts>
  </xsl:template>

  <xsl:template match="SenderRef">
    <SenderKey><xsl:value-of select="."/></SenderKey>
  </xsl:template>

  <xsl:template match="AddresseeRef">
    <AddresseeKey><xsl:value-of select="."/></AddresseeKey>
  </xsl:template>

  <!-- TODO: check ActivityStatus conversion ? -->
  <xsl:template match="ActivityStatusRef">
    <CurrentStatusRef><xsl:call-template name="convert-activity-status"/></CurrentStatusRef>
  </xsl:template>

  <xsl:template match="AutomaticAlert">
    <Payload Generator="automatic">
      <xsl:apply-templates select="*"/>
    </Payload>
  </xsl:template>

  <xsl:template match="SpontaneousAlert">
    <Payload Generator="user">
      <xsl:apply-templates select="*"/>
    </Payload>
  </xsl:template>

  <xsl:template match="Date[parent::Alert]" priority="1">
    <xsl:copy-of select="."/>
  </xsl:template>

  <!-- **************
       *** Resources ***
       ************** -->

  <xsl:template match="Appendices">
    <Resources>
      <xsl:apply-templates select="Appendix"/>
    </Resources>
  </xsl:template>

  <!-- TODO: check ActivityStatus conversion ? -->
  <xsl:template match="Appendix">
    <Resource>
      <xsl:copy-of select="Date"/>
      <xsl:apply-templates select="SenderRef"/>
      <xsl:apply-templates select="ActivityStatusRef"/>
      <xsl:apply-templates select="File"/>
    </Resource>
  </xsl:template>

  <!-- ***********
       *** ... ***
       *********** -->
  
  <xsl:template name="convert-position">
    <xsl:choose>
      <xsl:when test=". = 1"><PositionRef>0</PositionRef></xsl:when>
      <xsl:when test=". = 2"><PositionRef>1</PositionRef></xsl:when>
      <xsl:when test=". = 3"><PositionRef>2</PositionRef></xsl:when>
      <xsl:otherwise></xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="NOGA-Code">
    <DomainActivityRef>
      <xsl:value-of select="."/>
    </DomainActivityRef>
  </xsl:template>

  <xsl:template match="Address" mode="partner">
    <Address>
      <xsl:copy-of select="PostalCode"/>
      <xsl:copy-of select="Town"/>
      <xsl:apply-templates select="State" mode="partner"/>
      <xsl:copy-of select="Country"/>
    </Address>
  </xsl:template>

  <xsl:template match="State" mode="partner">
    <RegionRef><xsl:value-of select="."/></RegionRef>
  </xsl:template>

  <xsl:template match="Date">
    <xsl:attribute name="LastModification"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>
  
  <!-- ***************
       *** Reuters ***
       *************** -->

  <!-- Also used in case.xsl migration -->
  <xsl:template match="TargetedMarkets">
    <TargetedMarkets>
      <xsl:apply-templates select="TargetedMarketRef"/>
    </TargetedMarkets>
  </xsl:template>

  <!-- Also used in case.xsl migration -->
  <xsl:template match="TargetedMarketRef">
    <xsl:choose>
      <xsl:when test=". = '010'">
        <TargetedMarketRef>521010</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '020'">
        <TargetedMarketRef>532030</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '030'">
        <TargetedMarketRef>541010</TargetedMarketRef>
        <TargetedMarketRef>541020</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '050'">
        <TargetedMarketRef>532040</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '055'">
        <TargetedMarketRef>553010</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '070'">
        <TargetedMarketRef>521020</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '075'">
        <TargetedMarketRef>531010</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '080'">
        <TargetedMarketRef>571050</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '100'">
        <TargetedMarketRef>571020</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '110'">
        <TargetedMarketRef>513020</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '120'">
        <TargetedMarketRef>522010</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '125'">
        <TargetedMarketRef>551010</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '140'">
        <TargetedMarketRef>501010</TargetedMarketRef>
        <TargetedMarketRef>501020</TargetedMarketRef>
        <TargetedMarketRef>501030</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '160'">
        <TargetedMarketRef>521020</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '165'">
        <TargetedMarketRef>551010</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '170'">
        <TargetedMarketRef>521020</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '180'">
        <TargetedMarketRef>532020</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '190'">
        <TargetedMarketRef>571040</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '200'">
        <TargetedMarketRef>572010</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '210'">
        <TargetedMarketRef>572010</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '215'">
        <TargetedMarketRef>522010</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '230'">
        <TargetedMarketRef>533010</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '240'">
        <TargetedMarketRef>554020</TargetedMarketRef>
        <TargetedMarketRef>554030</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '255'">
        <TargetedMarketRef>571040</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '260'">
        <TargetedMarketRef>562010</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '265'">
        <TargetedMarketRef>562010</TargetedMarketRef>
      </xsl:when>
      <xsl:when test=". = '280'">
        <TargetedMarketRef>561020</TargetedMarketRef>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- *********************************
       *** Admin and Collab entities ***
       ********************************* -->

  <!-- Also used in case.xsl migration -->
  <xsl:template name="entities">
    <xsl:variable name="apos">A</xsl:variable>
    <xsl:choose>
      <xsl:when test="upper-case(.) = 'ASSOCIATION PLATINN'">1</xsl:when>
      <xsl:when test="upper-case(.) = 'ADMINISTRATION PLATINN'">1</xsl:when>
      <xsl:when test="upper-case(.) = 'BE-ADVANCED'">2</xsl:when>
      <xsl:when test="upper-case(.) = 'FRI UP'">3</xsl:when>
      <xsl:when test="upper-case(.) = 'OPI'">4</xsl:when>
      <xsl:when test="ends-with(upper-case(.), 'ÉCONOMIE DE NEUCHÂTEL')">5</xsl:when>
      <xsl:when test="ends-with(upper-case(.), 'ECONOMIE DE NEUCHÂTEL')">5</xsl:when>
      <xsl:when test="upper-case(.) = 'PROMOTION ÉCONOMIQUE PROMFR'">5</xsl:when>
      <xsl:when test="upper-case(.) = 'PROMOTION ECONOMIQUE PROMFR'">5</xsl:when>
      <xsl:when test="upper-case(.) = 'INNOVAUD'">6</xsl:when>
      <xsl:when test="upper-case(.) = 'CIMARK'">7</xsl:when>
      <xsl:when test="upper-case(.) = 'CREAPOLE'">8</xsl:when>
      <xsl:when test="upper-case(.) = 'CRÉAPOLE'">8</xsl:when>
      <xsl:when test="upper-case(.) = 'CREAPÔLE'">8</xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- ***********************************
       *** ContactSourceRef conversion ***
       *********************************** -->

  <!-- Converts Evénement divers / Publications /  Réseau personnel to 17 Other source-->
  <xsl:template name="contact-sources">
    <xsl:choose>
      <xsl:when test=". = '7'">17</xsl:when>
      <xsl:when test=". = '8'">17</xsl:when>
      <xsl:when test=". = '3'">17</xsl:when>
      <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="*[. = '']"></xsl:template>

  <xsl:template match="*|@*|text()">
    <xsl:copy>
      <xsl:apply-templates select="*|@*|text()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
