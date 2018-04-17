xquery version "1.0";
(: --------------------------------------
   Case tracker pilote application

   Creator: Stéphane Sire <s.sire@oppidoc.fr>

   This module can be used to declare functions using XPath expressions 
   with no namespace to be called from epilogue.xql, since that later one 
   is in the default XHTML namespace.

   November 2016 - (c) Copyright 2016 Oppidoc SARL. All Rights Reserved.
   ----------------------------------------------- :)

module namespace partial = "http://oppidoc.com/ns/xcm/partial";

declare function partial:scaffold () {
  <Scaffold/>
};

