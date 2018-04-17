xquery version "1.0";
(: --------------------------------------
   Case tracker pilote application

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Utility to deploy the application after a code update on file system with git

   You can use it for initial deployment or for maintenance updates,
   do not forget to separately restore the application data and/or system collection (users accounts)

   PRE-CONDITIONS :
   - scripts/bootstrap.sh has been executed first (to install mapping.xml inside database)
   - must be called from the server (e.g.: using curl or wget)
   - admin password must be provided as a pwd parameter

   SYNOPSIS :
   curl -i [or wget -O-] http:127.0.0.1:[PORT]/exist/projects/pilote/admin/deploy?pwd=[PASSWORD]&t=[TARGETS]

   TARGETS (globals,users,config,data,selectors,mesh,templates,forms,stats)
   - globals : configure globals.xml for XCM integration
   - users : create user groups
   - config : load aplication configuration
   - data : 
   - selectors :
   - mesh :
   - templates :
   - forms : generate all formulars with supergrid (see $formulars in this script)
   - stats :
   - accounts : 
   - binaries :
   - debug :
   - caches :
   - questionnaires :
   - bootstrap : creates dummy enterprises and dummy persons collections (with dummy enteprises.xml and persons.xml)
                 add this target iff you want to reinitialise your enteprises and persons collection !!!
   - services :
   - policies : set database permissions

   TODO: 
   - implement inherit-policy to set collection policy different than its resources
     <collection name="/db/sites/pilote/checks" policy="open" inherit-policy="users"/> 

   November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   -------------------------------------- :)

declare namespace skin = "http://oppidoc.com/oppidum/skin";

declare namespace request = "http://exist-db.org/xquery/request";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace sm = "http://exist-db.org/xquery/securitymanager";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../lib/globals.xqm";
import module namespace install = "http://oppidoc.com/oppidum/install" at "../../oppidum/lib/install.xqm";
import module namespace sg = "http://oppidoc.com/ns/xcm/supergrid" at "../../xcm/modules/formulars/install.xqm";
import module namespace services = "http://oppidoc.com/ns/xcm/services" at "../../xcm/lib/services.xqm";
import module namespace account = "http://oppidoc.com/ns/xcm/account" at "../../xcm/modules/users/account.xqm";

declare option exist:serialize "method=xml media-type=text/html indent=yes";

(: list of forms to generate with the 'forms' target using '+' separator :)
declare variable $formulars := 
  let $reg := fn:doc(concat('file://', system:get-exist-home(), '/webapp/', $globals:app-folder, '/', $globals:app-name, '/formulars/_register.xml'))
  return string-join(for $i in $reg//Form return substring-after($i, 'forms/'), '+');
  
declare variable $policies := <policies xmlns="http://oppidoc.com/oppidum/install">
  <user name="demo" password="test" groups="users account-manager admin-system developer"/>
  <user name="coach" password="test" groups="users"/>
  <!-- Policies -->
  <policy name="admin" owner="admin" group="users" perms="rwxr-x---"/>
  <policy name="users" owner="admin" group="users" perms="rwxrwx---"/>
  <policy name="read" owner="admin" group="users" perms="rwxrwxr-x"/>
  <policy name="read-only" owner="admin" group="users" perms="rwxr-xr-x"/>
  <policy name="open" owner="admin" group="users" perms="rwxrwxrwx"/>
  <policy name="strict" owner="admin" group="users" perms="rwxrwx---"/>
  <policy name="application" owner="admin" group="developer" perms="rwxrwxr-x"/>
</policies>;

(: use this instead of $code to target/apply policies on a single collection using the policies target 
   e.g. to repairs permissions :)
declare variable $code-tmp := <code xmlns="http://oppidoc.com/oppidum/install">
  <collection name="/db/binaries/{$globals:app-collection}" policy="users" inherit="yes"/>
  </code>;

declare variable $code := <code xmlns="http://oppidoc.com/oppidum/install">
  <!-- top level collection instructions to apply policies -->
  <collection name="/db/www/{$globals:app-collection}" policy="application" inherit="yes"/>
  <collection name="{substring-before($globals:globals-uri, '/globals.xml')}" policy="application" inherit="yes"/>
  <collection name="/db/sites/{$globals:app-collection}" policy="users" inherit="yes"/>
  <!-- policies inside group elements to refine top level collection policies -->
  <group name="binaries"> 
    <collection name="/db/binaries/{$globals:app-collection}" policy="users" inherit="yes"/>
  </group>
  <group name="caches">
    <collection name="/db/caches/{$globals:app-collection}" policy="strict" inherit="yes">
      <files pattern="data/caches/cache.xml"/>
    </collection>
  </group>
  <group name="debug">
    <collection name="/db/debug" policy="open" inherit="yes">
      <files pattern="data/debug/xal.xml"/>
      <files pattern="data/debug/debug.xml"/>
      <files pattern="data/debug/login.xml"/>
    </collection>
  </group>
  <group name="globals">
    <collection name="/db/www/xcm/config">
      <files pattern="config/globals.xml"/>
    </collection>
  </group>
  <group name="config">
    <collection name="/db/www/{$globals:app-collection}/config">
      <files pattern="config/mapping.xml"/>
      <files pattern="config/modules.xml"/>
      <files pattern="config/application.xml"/>
      <files pattern="config/database.xml"/>
      <files pattern="config/skin.xml"/>
      <files pattern="config/errors.xml"/>
      <files pattern="config/messages.xml"/>
      <files pattern="config/variables.xml"/>
      <!-- DEPRECATED: moved to platform depot
      <files pattern="config/settings.xml"/>
      <files pattern="config/services.xml"/>-->
    </collection>
    <collection name="/db/www/{$globals:app-collection}/dictionaries">
      <files pattern="dictionaries/dictionary*.xml"/>
    </collection>
  </group>
  <group name="mesh" mandatory="true">
    <collection name="/db/www/{$globals:app-collection}/mesh">
      <files pattern="mesh/*.html"/>
    </collection>
  </group>
<!--  <group name="data">
    <collection name="/db/sites/{$globals:app-collection}/cases"/>
    <collection name="/db/sites/{$globals:app-collection}/global-information" policy="read-only" inherit="yes">
      <files pattern="data/global-information/email.xml"/>
    </collection>
  </group>-->
<!--  <group name="selectors">
    <collection name="/db/sites/{$globals:app-collection}/global-information">
      <files pattern="data/global-information/global-information*.xml"/>
      <files pattern="data/global-information/custom-information*.xml"/>
      <files pattern="data/global-information/ratings*.xml"/>
      <files pattern="data/global-information/innovation-tree-en.xml"/>
      <files pattern="data/global-information/innovation-tree-fr.xml"/>
      <files pattern="data/global-information/innovation-tree-de.xml"/>
      <files pattern="selectors:data/countries-en.xml"/>
      <files pattern="selectors:data/countries-fr.xml"/>
      <files pattern="selectors:data/countries-de.xml"/>
      <files pattern="selectors:data/naces-en.xml"/>
      <files pattern="selectors:data/naces-fr.xml"/>
      <files pattern="selectors:data/naces-de.xml"/>
      <files pattern="selectors:data/reuters-en.xml"/>
      <files pattern="selectors:data/reuters-fr.xml"/>
      <files pattern="selectors:data/reuters-de.xml"/>
    </collection>
  </group>-->  
  <group name="templates">
    <collection name="/db/www/{$globals:app-collection}/templates">
      <files pattern="templates/*.xml"/>
    </collection>
  </group>
  <!--<group name="questionnaires">
    <collection name="/db/www/{$globals:app-collection}/formulars" policy="strict" inherit="yes">
      <files pattern="formulars/sme-feedback.xml"/>
      <files pattern="formulars/kam-feedback.xml"/>
      <files pattern="formulars/externalservice-feedback.xml"/>
    </collection>
  </group>-->
 <!-- <group name="stats">
    <collection name="/db/www/{$globals:app-collection}/config">
      <files pattern="modules/stats/stats.xml"/>
    </collection>
    <collection name="/db/www/{$globals:app-collection}/formulars">
      <files pattern="formulars/stats.xml"/>
      <files pattern="formulars/stats-cases.xml"/>
      <files pattern="formulars/stats-activities.xml"/>
    </collection>
  </group>-->
  <group name="bootstrap">
    <collection name="/db/sites/{$globals:app-collection}/persons" policy="read" inherit="yes">
      <files pattern="data/persons/*.xml"/>
    </collection>
    <collection name="/db/sites/{$globals:app-collection}/enterprises">
      <files pattern="data/enterprises/*.xml"/>
    </collection>
  </group>
</code>;

(: ======================================================================
   TODO:
   restore
   <Allow>
       <Category>account</Category>
       <Category>workflow</Category>
       <Category>action</Category>
   </Allow>
   into Media element in settings.xml
   ======================================================================
:)
declare function local:do-post-deploy-actions ( $dir as xs:string,  $targets as xs:string*, $base-url as xs:string, $mode as xs:string ) {
  (: terminates globals.xml installation usually once after bootstrap :)
  if ('globals' = $targets) then
    for $global in fn:doc($globals:globals-uri)//Global[not(Value)]
    let $value := if (exists($global/Eval)) then string($global/Eval) else concat('$globals:', $global/Key)
    return (
      update insert <Value>{ util:eval($value) }</Value> into $global,
      if (exists($global/Eval)) then 
        update delete $global/Eval
      else
        (),
      <p>replacing { $value } into globals</p>
      )
  else
    (),
  (: adjusts settings to environment mode (e.g. e-mail output configuration) :)
  if ('config' = $targets) then
    let $mapping := fn:doc(concat('/db/www/', $globals:app-collection, '/config/mapping.xml'))/site
    let $skin := fn:doc(concat('/db/www/', $globals:app-collection, '/config/skin.xml'))/skin:skin
    let $settings := fn:doc(concat('/db/www/', $globals:app-collection, '/config/settings.xml'))/Settings
    return
      (
      update value $mapping/@mode with $mode,
      <p>Set mode to { $mode }</p>,
      <p>Root mapping supported actions set to { string($mapping/@supported) }</p>,
      if ($mapping/@key ne $globals:app-name) then (
        update value $mapping/@key with $globals:app-name,
        <p>Set mapping key to REST application name { $globals:app-name }</p>
        )
      else
        <p>REST application name in mapping is { $globals:app-name }</p>,
      if ($skin/@key ne $globals:app-name) then (
        update value $skin/@key with $globals:app-name,
        <p>Set skin key to REST application name { $globals:app-name }</p>
        )
      else
        <p>REST application name in skin is { $globals:app-name }</p>,
      if  (not(exists($mapping/@base-url)) and $mode = ('test', 'prod')) then
        (
        update insert attribute { 'base-url' } {'/'} into $mapping,
        <p>Set attribue base-url to '/'</p>
        )
      else (
        if (exists($mapping/@base-url)) then
          update delete $mapping/@base-url
        else
          (),
        <p>Removed attribute base-url for '{ $mode }'</p>
        ),
      if (($settings/SMTPServer eq '!localhost') and $mode = 'prod') then
        (
        update value $settings/SMTPServer with 'localhost',
        <p>Changed SMTP Server to "localhost" to activate mail</p>
        )
      else if (($settings/SMTPServer eq 'localhost') and $mode = ('dev', 'test')) then
        (
        update value $settings/SMTPServer with '!localhost',
        <p>Changed SMTP Server to "!localhost" to inactivate mail for '{ $mode }'</p>
        )
      else
        <p>SMTP Server is configured to "{string($settings/SMTPServer)}"</p>
      )
  else
    ()
};

declare function local:deploy ( $dir as xs:string,  $targets as xs:string*, $base-url as xs:string, $mode as xs:string ) {
  (
  if ('accounts' = $targets) then
    <target name="users">
      {
        for $person at $i in globals:collection('persons-uri')//Person[UserProfile/Username]
        let $should := account:gen-groups-for-user($person)
        let $username := $person/UserProfile/Username
        let $password := account:gen-password($username, $person/Information/Contacts/Email)
        return
          if (sm:user-exists(string($username))) then 
            <li>({$i}) reset user { $username } with groups { account:set-user-groups($username, $should), $should } and password { system:as-user(account:get-secret-user(), account:get-secret-password(), xdb:change-user($username, $password, (), ())), $password }</li>
          else if (true()) then
            <li>({$i}) create user { sm:create-account($username, $password, 'users', $should[. ne 'users']), $username } with groups { $should } and password { $password }
            </li>
          else
            <li>({$i}) sip user { $username } with groups { $should } and password { $password }
          </li>
      }
    </target>
  else
      (),
  if ('users' = $targets) then
    <target name="users">
      { 
      (: TODO: add function compat:make-user-groups and use it in install-users :)
      (: the code below creates the groups first so it can use deprecated xdb:create/change-user :)
      let $groups := sm:list-groups()
      return 
        (: pre-condition: target config already deployed :)
        for $group in ('users', fn:doc(concat('file://', system:get-exist-home(), '/webapp/', $globals:app-folder, '/', $globals:app-name, '/data/global-information/custom-information-en.xml'))//Description[@Role eq 'normative']/Selector[@Name eq 'Functions']/Option[@Group]/string(@Group))
        return
          if ($group = $groups) then
            <li>no need to create group "{$group}" which already exists</li>
          else
            <li>Created group { sm:create-group($group), $group }</li>(:,
      install:install-users($policies):)
      }
    </target>
  else
    (),
  let $itargets := $targets[not(. = ('users', 'policies', 'forms', 'services'))]
  return
    if (count($itargets) > 0) then
      <target name="{string-join($itargets,', ')}">
        {  
        install:install-targets($dir, $itargets, $code, ())
        }
      </target>
    else
      (),
  if ('forms' = $targets) then
    <target name="forms" base-url="{$base-url}">{ sg:gen-and-save-forms($formulars, $base-url, $globals:app-name) }</target>
  else
    (),
  if (('globals', 'policies') = $targets) then
    let $refine := 
      for $group in $code/install:group[install:collection/@policy]
      return string($group/@name)
    return
      <target name="policies">{ install:install-policies($refine, $policies, $code, ())}</target>
  else
    (),
  if ('services' = $targets) then
    (
    <target name="services">{ services:deploy($dir) }</target>,
    install:install-targets($dir, ('questionnaires'), $code, ())
    )
  else
    (),
  local:do-post-deploy-actions($dir, $targets, $base-url, $mode)
  )
};

let $dir := install:webapp-home(concat($globals:app-folder, "/", $globals:app-name))
let $pwd := request:get-parameter('pwd', ())
let $fallback := fn:doc(concat('/db/www/', $globals:app-collection, '/config/mapping.xml'))/site/@mode
let $mode := request:get-parameter('m', if ($fallback) then $fallback else 'dev')
let $targets := tokenize(request:get-parameter('t', ''), ',')
let $host := request:get-header('Host')
let $cmd := request:get-attribute('oppidum.command')
return
  if (starts-with($host, 'localhost') or starts-with($host, '127.0.0.1')) then
    if ($pwd and (count($targets) > 0)) then
      <results count="{count($targets)}">
        <dir>{$dir}</dir>
        { 
        (: globals MUST be deployed first :)
        if ('globals' = $targets) then 
          system:as-user('admin', $pwd, local:deploy($dir, ('globals'), $cmd/@base-url, $mode))
        else
          (),
        system:as-user('admin', $pwd, local:deploy($dir, $targets[not(. = 'globals')], $cmd/@base-url, $mode)) 
        }
      </results>
    else
      <results>Usage : deploy?t=users,config,bootstrap,data,forms,mesh,templates,stats,policies&amp;pwd=[ADMIN PASSWORD]&amp;m=(dev | test | [prod])</results>
  else
    <results>This script can be called only from the server</results>
