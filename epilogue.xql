xquery version "1.0";
(: --------------------------------------
   Case tracker pilote application

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Copy and customize this file to finalize your application page generation

   January 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace site = "http://oppidoc.com/oppidum/site";
declare namespace xt = "http://ns.inria.org/xtiger";
declare namespace request = "http://exist-db.org/xquery/request";
declare namespace session = "http://exist-db.org/xquery/session";
declare namespace response = "http://exist-db.org/xquery/response";
declare namespace util = "http://exist-db.org/xquery/util";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../oppidum/lib/util.xqm";
import module namespace epilogue = "http://oppidoc.com/oppidum/epilogue" at "../oppidum/lib/epilogue.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "lib/globals.xqm";
import module namespace access = "http://oppidoc.com/ns/xcm/access" at "../xcm/lib/access.xqm";
import module namespace view = "http://oppidoc.com/ns/xcm/view" at "../xcm/lib/view.xqm";
(:import module namespace partial = "http://oppidoc.com/ns/xcm/partial" at "app/partial.xqm";:)

(: ======================================================================
   Trick to use request:get-uri behind a reverse proxy that injects
   /exist/projets/{$globals:app-collection} into the URL in production
   ======================================================================
:)
declare function local:my-get-uri($cmd as element()) {
    concat($cmd/@base-url, $cmd/@trail, if ($cmd/@verb eq 'custom') then
        if ($cmd/@trail eq '') then
            $cmd/@action
        else
            concat('/', $cmd/@action)
    else
        ())
};

(: ======================================================================
   Typeswitch function
   -------------------
   Plug all the <site:{module}> functions here and define them below
   ======================================================================
:)
declare function site:branch($cmd as element(), $source as element(), $view as element()*) as node()*
{
    typeswitch ($source)
        case element(site:skin)
            return
                view:skin($cmd, $view)
        case element(site:navigation)
            return
                site:navigation($cmd, $view)
        case element(site:error)
            return
                view:error($cmd, $view)
        case element(site:message)
            return
                view:message($cmd)
        case element(site:login)
            return
                site:login($cmd)
        case element(site:lang)
            return
                site:lang($cmd, $view)
        case element(site:field)
            return
                view:field($cmd, $source, $view)
        case element(site:conditional)
            return
                site:conditional($cmd, $source, $view)
        default
            return
                $view/*[local-name(.) = local-name($source)]/*
                (: default treatment to implicitly manage other modules :)
};

declare function local:gen-nav-class($name as xs:string, $target as xs:string*, $extra as xs:string?) as attribute()? {
    if ($name = $target) then
        attribute class {
            if ($extra) then
                concat($extra, ' active')
            else
                'active'
        }
    else
        if ($extra) then
            attribute class {$extra}
        else
            ()
};

(: ======================================================================
   Generates <site:navigation> menu
   TODO: create markup for menu generation !
   ======================================================================
:)
declare function site:navigation($cmd as element(), $view as element()) as element()*
{
    let $base := string($cmd/@base-url)
    let $rsc := string(oppidum:get-resource($cmd)/@name)
    let $name := if (starts-with($cmd/@trail, 'cases')) then
        (: filters out everything not cases/create as 'stage' :)
        if (starts-with($cmd/@trail, 'cases/create')) then
            'create'
        else
            'home'
    else
        $rsc
    let $user := oppidum:get-current-user()
    let $groups := oppidum:get-user-groups($user, oppidum:get-current-user-realm())
    return
        <ul
            class="nav">
            <li>{local:gen-nav-class($name, 'home', ())}<a
                    href="{$base}home"
                    loc="app.nav.home">Home</a></li>
          <!-- <li>{local:gen-nav-class($name, 'ocr', ())}<a
                    href="{$base}ocr"
                    loc="app.nav.ocr">Ocr</a></li>-->
            <li>{local:gen-nav-class($name, 'recognize', ())}<a
                    href="{$base}recognize"
                    loc="app.nav.recognize">Recognize</a></li>
            <li>
                {local:gen-nav-class($name, ('persons', 'enterprises'), 'dropdown')}
                <a
                    class="dropdown-toggle"
                    data-toggle="dropdown"
                    href="#"
                    loc="app.nav.communities">Network</a>
                <ul
                    class="dropdown-menu">
                    <li><a
                            href="{$base}persons"
                            loc="app.nav.persons">Persons</a></li>
                    <li><a
                            href="{$base}enterprises"
                            loc="app.nav.enterprises">Companies</a></li>
                </ul>
            </li>
            
            {
                
                if (($user = 'admin') or ($groups = ('developer'))) then
                    (
                    <li>
                        {local:gen-nav-class($name, ('forms'), 'dropdown')}
                        <a
                            class="dropdown-toggle"
                            data-toggle="dropdown"
                            href="#">Devel</a>
                        <ul
                            class="dropdown-menu">
                            <li><a
                                    href="{$base}forms"
                                    loc="app.nav.forms">Supergrid</a></li>
                            {
                                if ($cmd/@mode eq 'dev') then
                                    (
                                    <li><a
                                            href="{$base}/../../oppidum/test/explorer?m={$globals:app-collection}">Oppidum IDE</a></li>,
                                    <li
                                        class="divider"></li>,
                                    <li><a
                                            href="{$base}test/units/1">XCM unit tests</a></li>,
                                    <li><a
                                            href="{$base}test/units/2">Application unit tests</a></li>,
                                    <li><a
                                            href="{$base}test/selectors">Selectors unit tests</a></li>
                                    )
                                else
                                    ()
                            }
                        </ul>
                    </li>
                    )
                else
                    ()
            }
            {
                if (($user = 'admin') or $groups = ('admin-system', 'developer')) then
                    (
                    <li
                        id="c-flush-right">{local:gen-nav-class($name, 'management', ())}<a
                            href="{$base}management"
                            loc="app.nav.admin">Admin</a></li>
                    )
                else
                    ()
            }
        </ul>
};

(: ======================================================================
   Handles <site:login> LOGIN banner
   ======================================================================
:)
declare function site:login($cmd as element()) as element()*
{
    let
    $uri := local:my-get-uri($cmd),
        $user := oppidum:get-current-user()
    return
        if ($user = 'guest') then
            if (not(ends-with($uri, '/login'))) then
                <a
                    class="login"
                    href="{$cmd/@base-url}login?url={$uri}">LOGIN</a>
            else
                <span>...</span>
        else
            let $user := if (string-length($user) > 7) then
                if (substring($user, 8, 1) eq '-') then
                    substring($user, 1, 7)
                else
                    concat(substring($user, 1, 7), '...')
            else
                $user
            return
                (
                <a
                    href="{$cmd/@base-url}me"
                    style="color:#333;text-decoration:none">{$user}</a>,
                <a
                    class="login"
                    href="{$cmd/@base-url}logout?url={$cmd/@base-url}"
                    style="margin-left:10px">LOGOUT</a>
                )
};

(: ======================================================================
   Generates language menu
    - Simple logic so that default langauge (FR) is implicit (does not appear in URL)
   ======================================================================
:)
declare function site:lang($cmd as element(), $view as element()) as element()*
{
    let $lang := string($cmd/@lang)
    let $qs := request:get-query-string()
    let $uri := local:my-get-uri($cmd)
    return
        (
        if ($lang = 'fr') then
            <span
                id="c-curLg">FR</span>
        else
            (: switching from 'de' or 'en' to default language 'fr' - that is removing language prefix from URL :)
            if (contains($uri, '/de/')) then
                <a
                    href="{replace(local:my-get-uri($cmd), 'de/', '')}{
                            if ($qs) then
                                concat('?', $qs)
                            else
                                ()
                        }"
                    title="Français">FR</a>
            else (: assumes en :)
                <a
                    href="{replace(local:my-get-uri($cmd), 'en/', '')}{
                            if ($qs) then
                                concat('?', $qs)
                            else
                                ()
                        }"
                    title="Français">FR</a>,
        <span> | </span>,
        if ($lang = 'de') then
            <span
                id="c-curLg">DE</span>
        else
            if (contains($uri, '/fr/')) then
                <a
                    href="{replace($uri, '/fr/', '/de/')}"
                    title="Deutsch">DE</a>
            else
                if (contains($uri, '/en/')) then
                    <a
                        href="{replace($uri, '/en/', '/de/')}"
                        title="Deutsch">DE</a>
                else
                    (: switching from default language 'fr' to 'de' - that is adding explicit language prefix to URL :)
                    <a
                        href="{replace($uri, concat("^", $cmd/@base-url), concat($cmd/@base-url, 'de/'))}{
                                if ($qs) then
                                    concat('?', $qs)
                                else
                                    ()
                            }"
                        title="Deutsch">DE</a>,
        <span> | </span>,
        if ($lang = 'en') then
            <span
                id="c-curLg">EN</span>
        else
            if (contains($uri, '/fr/')) then
                <a
                    href="{replace($uri, '/fr/', '/en/')}"
                    title="English">EN</a>
            else
                if (contains($uri, '/de/')) then
                    <a
                        href="{replace($uri, '/de/', '/en/')}"
                        title="English">EN</a>
                else
                    (: switching from default language 'fr' to 'en' - that is adding explicit language prefix to URL :)
                    <a
                        href="{replace($uri, concat("^", $cmd/@base-url), concat($cmd/@base-url, 'en/'))}{
                                if ($qs) then
                                    concat('?', $qs)
                                else
                                    ()
                            }"
                        title="English">EN</a>
        )
};

(: ======================================================================
   Implements <site:conditional> in mesh files (e.g. rendering a Supergrid
   generated mesh XTiger template).

   Applies a simple logic to filter conditional source blocks.

   Keeps (/ Removes) the source when all these conditions hold true (logical AND):
   - @avoid does not match current goal (/ matches goal)
   - @meet matches current goal (/ does not match goal)
   - @flag is present in the request parameters  (/ is not present in parameters)
   - @noflag not present in request parameters (/ is present in parameters)

   TODO: move to view module with XQuery 3 (local:render as parameter)
   ======================================================================
:)
declare function site:conditional($cmd as element(), $source as element(), $view as element()*) as node()* {
    let $goal := request:get-parameter('goal', 'read')
    let $flags := request:get-parameter-names()
    return
        (: Filters out failing @meet AND @avoid and @noflag AND @flag :)
        if (not(
        (not($source/@meet) or ($source/@meet = $goal))
        and (not($source/@avoid) or not($source/@avoid = $goal))
        and (not($source/@flag) or ($source/@flag = $flags))
        and (not($source/@noflag) or not($source/@noflag = $flags))
        ))
        then
            ()
        else
            for $child in $source/node()
            return
                if ($child instance of element()) then
                    (: FIXME: hard-coded 'site:' prefix we should better use namespace-uri
                    - currently limited to site:field :)
                    if (starts-with(xs:string(node-name($child)), 'site:field')) then
                        view:field($cmd, $child, $view)
                    else
                        local:render-iter($cmd, $child, $view)
                else
                    $child
};

(: ======================================================================
   Recursive rendering function
   ----------------------------
   Copy this function as is inside your epilogue to render a mesh
   TODO: move to view module with XQuery 3 (site:branch as parameter)
   ======================================================================
:)
declare function local:render-iter($cmd as element(), $source as element(), $view as element()*) as element()
{
    element {node-name($source)}
    {
        $source/@*,
        for $child in $source/node()
        return
            if ($child instance of text()) then
                $child
            else
                (: FIXME: hard-coded 'site:' prefix we should better use namespace-uri :)
                if (starts-with(xs:string(node-name($child)), 'site:')) then
                    (
                    if (($child/@force) or
                    ($view/*[local-name(.) = local-name($child)])) then
                        site:branch($cmd, $child, $view)
                    else
                        ()
                    )
                else
                    if ($child/*) then
                        if ($child/@condition) then
                            let $go :=
                            if (string($child/@condition) = 'has-error') then
                                oppidum:has-error()
                            else
                                if (string($child/@condition) = 'has-message') then
                                    oppidum:has-message()
                                else
                                    if ($view/*[local-name(.) = substring-after($child/@condition, ':')]) then
                                        true()
                                    else
                                        false()
                            return
                                if ($go) then
                                    local:render-iter($cmd, $child, $view)
                                else
                                    ()
                        else
                            local:render-iter($cmd, $child, $view)
                    else
                        $child
    }
};

(: ======================================================================
   Bootstraps template rendering
   Inserts lang attribute if its an html page
   ====================================================================== 
:)
declare function local:render($cmd as element(), $source as element(), $view as element()*) as element() {
    if (local-name($source) eq 'html') then
        element {node-name($source)}
        {
            $source/@*,
            $cmd/@lang,
            for $n in $source/*
            return
                local:render-iter($cmd, $n, $view)
        }
    else
        local:render-iter($cmd, $source, $view)
};

(: ======================================================================
   Epilogue entry point
   ======================================================================
:)
let $mesh := epilogue:finalize()
let $cmd := request:get-attribute('oppidum.command')
let $sticky := false() (: TODO: support for forthcoming local:translation-agent() :)
let $lang := $cmd/@lang
let $dico := fn:collection($globals:dico-uri)//site:Translations[@lang = $lang]
let $isa_tpl := contains($cmd/@trail, "templates/") or ends-with($cmd/@trail, "/template")
let $maintenance := view:filter-for-maintenance($cmd, $isa_tpl)
return
    if ($mesh) then
        let $type := if (matches($cmd/@trail, "^test/|^calls/|activities/") or $isa_tpl) then
            "application/xhtml+xml"
        else
            "text/html"
        let $page := local:render($cmd, $mesh, oppidum:get-data())
        return
            (
            util:declare-option("exist:serialize", concat("method=html5 media-type=", $type, " encoding=utf-8 indent=yes")),
            view:localize($dico, $page, $sticky)
            )
    else
        view:localize($dico, oppidum:get-data(), $sticky)
