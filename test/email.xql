xquery version "1.0";
(: --------------------------------------
   Case Tracker Pilote

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   Use this file to write unit tests at the application level

   TODO: identify and apply a unit test framework for XQuery

   May 2017 - (c) Copyright 2017 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

declare namespace site = "http://oppidoc.com/oppidum/site";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../lib/globals.xqm";
import module namespace database = "http://oppidoc.com/ns/xcm/database" at "../../xcm/lib/database.xqm";
import module namespace access = "http://oppidoc.com/ns/xcm/access" at "../../xcm/lib/access.xqm";
import module namespace template = "http://oppidoc.com/ns/ctracker/template" at "../lib/template.xqm";
import module namespace workflow = "http://oppidoc.com/ns/xcm/workflow" at "../../xcm/modules/workflow/workflow.xqm";

declare option exist:serialize "method=text media-type=text/plain";

declare variable $crlf := codepoints-to-string((13, 10));

let $title := "Case Tracker e-mail messages"
return (
  $title, $crlf,
  string-join(for $i in 1 to string-length($title) return "=", ""), $crlf,
  $crlf,
  for $template in fn:collection($globals:global-info-uri)//Emails/*[@Lang eq 'en']
  return 
    (
    concat("Key: ", $template/@Name, " (do not translate !)"), $crlf,
    "Subject: ", string($template/Subject), $crlf,
    "Object: ", $crlf,
    for $text-or-block in $template/Message/*
    return
      if (local-name($text-or-block) eq 'Text') then
        concat(string($text-or-block), $crlf, $crlf)
      else (
        for $line in $text-or-block
        return
          concat(string($line), $crlf),
        $crlf
        ),
    $crlf
    )
  )
