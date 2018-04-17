xquery version "1.0";
(: --------------------------------------
   Case Tracker Pilote

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Use this file to write unit tests at the application level

   TODO: identify and apply a unit test framework for XQuery

   May 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace site = "http://oppidoc.com/oppidum/site";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../lib/globals.xqm";
import module namespace database = "http://oppidoc.com/ns/xcm/database" at "../../xcm/lib/database.xqm";
import module namespace access = "http://oppidoc.com/ns/xcm/access" at "../../xcm/lib/access.xqm";

(: ======================================================================
   NOTE: running Database test creates Case 3000 firts time, then it creates multiple Case 3000
   inside the initial one. This is not a bug but actually the database module API is unfinished 
   and the pre-requisite is that create-entity-for-key should be called only once for each key !
   ====================================================================== 
:)
declare variable $local:tests := 
  <Tests xmlns="http://oppidoc.com/oppidum/site">
    <Module>
      <Name>Others</Name>
      <Test>access:check-entity-permissions('create', 'Case')</Test>
    </Module>
    <Module>
      <Name>Database</Name>
      <Test>database:make-new-key-for('/db/XXX', 'case')</Test>
      <Test>database:make-new-key-for('/db/sites/ctracker', 'case')</Test>
      <!--<Test>database:create-collection-for-key('/db/sites/ctracker', 'case', 3000)</Test>-->
      <!--<Test><![CDATA[database:create-entity-for-key('/db/sites/ctracker', 'case', <Case xmlns=""><No>3000</No></Case>, 3000)]]></Test>-->
    </Module>
  </Tests>;

declare function local:apply-module-tests( $module as element() ) {
  <h2>{ $module/site:Name }</h2>,
  <table class="table">
    {
    for $test in $module/site:Test
    return 
      <tr>
        <td>{ $test/text() }</td>
        <td style="width:50%">
          {
          if ($test/@Format eq 'xml') then 
            <pre xmlns="">{ util:eval($test) }</pre>
          else 
            util:eval($test)
          }
          </td>
      </tr>
    }
  </table>
};

let $lang := 'en'
return
  <site:view skin="test">
    <site:content>
      <div>
        <div class="row-fluid" style="margin-bottom: 2em">
          <h1>Case Tracker Pilote unit tests (Application)</h1>
          {
            for $module in $local:tests/site:Module
            return local:apply-module-tests($module)
          }
        </div>
      </div>
    </site:content>
  </site:view>


