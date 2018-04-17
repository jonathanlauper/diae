xquery version "1.0";
(: --------------------------------------
   DocEng 2015 Website

   Creator: Christine Vanoirbeek

   Functions to check access rights.
   
   NOTE: Must be compatible with access rules specified in the mapping.

   July 2013 - (c) Copyright 2013 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

module namespace access = "http://oppidoc.com/oppidum/access";

declare namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "globals.xqm";

(: ======================================================================
   Get user groups
   ======================================================================
:)
declare function access:get-user-groups() as xs:string* {
  let $user := xdb:get-current-user()
  let $groups := xdb:get-user-groups($user)
  return 
    $groups
};

(: ======================================================================
   Check if the current user is allowed to edit the resource r
   ======================================================================
:)
declare function access:resource-edit-allowed($r as xs:string) as xs:boolean {
  let $user := xdb:get-current-user()
  let $groups := xdb:get-user-groups($user)
  return 
    (
      ($r = 'welcome') and ($groups='de2015-admin') or
      ($r = 'venue') and ($groups='de2015-admin') or
      ($r = 'registration') and ($groups='de2015-admin') or
      ($r = 'important-dates') and (($groups='de2015-admin') or ($groups = 'de2015-pc')) or
      ($r = 'relevant-topics') and (($groups='de2015-admin') or ($groups = 'de2015-pc')) or
      ($r = 'call-papers') and (($groups='de2015-admin') or ($groups = 'de2015-pc')) or
      ($r = 'accepted-papers') and (($groups='de2015-admin') or ($groups = 'de2015-pc')) or
      ($r = 'submission-procedure') and (($groups='de2015-admin') or ($groups = 'de2015-pc')) or
      ($r = 'call-workshop-tutorial') and (($groups='de2015-admin') or ($groups = 'de2015-wtc')) or
      ($r = 'workshop-tutorial') and (($groups='de2015-admin') or ($groups = 'de2015-wtc')) or
      ($r = 'program') and (($groups='de2015-admin') or ($groups = 'de2015-pc')) or
      ($r = 'invited-talks') and (($groups='de2015-admin') or ($groups = 'de2015-pc')) or
      ($r = 'prodoc') and (($groups='de2015-admin') or ($groups = 'de2015-prodoc')) or
      ($r = 'bof') and ($groups='de2015-admin') or
      ($r = 'student-travel-awards') and ($groups='de2015-admin') or
      ($r = 'committees') and (($groups='de2015-admin') or ($groups = 'de2015-pc')) or
      ($r = 'harassment') and ($groups='de2015-admin')
    )
};

