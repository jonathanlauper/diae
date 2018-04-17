xquery version "1.0";
(: --------------------------------------
   DIAE application

   Creation: Fouad Slimane <fouad.slimane@unifr.ch>

  OCR test

   Mars 2018 - (c) Copyright 2014 Dpcetis SARL + UNIFR. All Rights Reserved.
   ----------------------------------------------- :)

module namespace globals = "http://oppidoc.com/ns/xcm/globals";

(: Application name (rest), project folder name and application collection name :)
declare variable $globals:app-name := 'diae';
declare variable $globals:app-folder := 'projects';
declare variable $globals:app-collection := 'diae';

(: Database paths :)
declare variable $globals:dico-uri := '/db/www/diae/dictionaries';
declare variable $globals:cache-uri := '/db/caches/diae/cache.xml';
declare variable $globals:global-info-uri := '/db/sites/diae/global-information';
declare variable $globals:settings-uri := '/db/www/diae/config/settings.xml';
declare variable $globals:log-file-uri := '/db/debug/login.xml';
declare variable $globals:application-uri := '/db/www/diae/config/application.xml';
declare variable $globals:templates-uri := '/db/www/diae/templates';
declare variable $globals:variables-uri := '/db/www/diae/config/variables.xml';
declare variable $globals:services-uri := '/db/www/diae/config/services.xml';
declare variable $globals:stats-formulars-uri := '/db/www/diae/formulars';
declare variable $globals:database-file-uri := '/db/www/diae/config/database.xml';

(: Application entities paths :)
declare variable $globals:persons-doc := '/db/sites/diae/persons/persons.xml';
declare variable $globals:persons-uri := '/db/sites/diae/persons';
declare variable $globals:enterprises-uri := '/db/sites/diae/enterprises/enterprises.xml';
declare variable $globals:cases-uri := '/db/sites/diae/cases';
declare variable $globals:accounts-uri := '/db/sites/diae/accounts/accounts.xml';
(:OCR Test :)
declare variable $globals:ocr-uri := '/db/sites/diae/pages';


(: MUST be aligned with xcm/lib/globals.xqm :)
declare variable $globals:xcm-name := 'xcm';
declare variable $globals:globals-uri := '/db/www/xcm/config/globals.xml';

declare function globals:app-name() as xs:string {
  $globals:app-name
};

declare function globals:app-folder() as xs:string {
  $globals:app-folder
};

declare function globals:app-collection() as xs:string {
  $globals:app-collection
};

(:~
 : Returns the selector from global information that serves as a reference for
 : a given selector enriched with meta-data.
 : @return The normative Selector element or the empty sequence
 :)
declare function globals:get-normative-selector-for( $name ) as element()? {
  fn:collection($globals:global-info-uri)//Description[@Role = 'normative']/Selector[@Name eq $name]
};

(: ******************************************************* :)
(:                                                         :)
(: Below this point paste content from xcm/lib/globals.xqm :)
(:                                                         :)
(: ******************************************************* :)

declare function globals:doc-available( $name ) {
  fn:doc-available(fn:doc($globals:globals-uri)//Global[Key eq $name]/Value)
};

declare function globals:collection( $name ) {
  fn:collection(fn:doc($globals:globals-uri)//Global[Key eq $name]/Value)
};

declare function globals:doc( $name ) {
  fn:doc(fn:doc($globals:globals-uri)//Global[Key eq $name]/Value)
};

