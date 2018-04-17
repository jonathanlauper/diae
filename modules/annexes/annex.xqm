xquery version "1.0";
(: ------------------------------------------------------------------
   Platinn Coaching application

   Creation: Stéphane Sire <s.sire@oppidoc.fr>

   Controller for attaching documents to a collection. The host collection
   is identified by Oppidum's reference collection. The target collection
   within the host collection is identified by Oppidum's reference resource.
   So it is up to you to correctly set both references.

   This allows to maintain a hierarchy of documents attached to a host
   collection. This is useful for instance to maintain a parallel hierarchy
   when the host collection contains itself a hierarchy of XML documents.

   When addressing a file, it's name is Oppidum's command resource name
   and its extension is Oppidum's command format. You must also setup
   the mapping accordingly.
   
   The module extends the URL input space with a "docs/" subspace at the 
   importation point in the mapping. File upload is done on the  "docs/file"
   controler resource with AXEL 'file' plugin protocol with a preflight request 
   followed by the upload request.
   
   The target collection hierarchy is created lazily.

   See also mime.xqm for the definition of accepted mime types
   
   LIMITATION : 
   - limited to annexes of Case because of the way the Case base collection is computed

   TODO :
   - parameterized file permissions (currently 0744 with admin / users)

   September 2014 - (c) Copyright 2014 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

module namespace annex = "http://oppidoc.com/ns/xcm/annex";

import module namespace request = "http://exist-db.org/xquery/request";
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace util = "http://exist-db.org/xquery/util";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace database = "http://oppidoc.com/ns/xcm/database" at "../../../xcm/lib/database.xqm";
import module namespace display = "http://oppidoc.com/ns/xcm/display" at "../../../xcm/lib/display.xqm";
import module namespace mime = "http://platinn.ch/coaching/mime" at "mime.xqm";

(: ======================================================================
   Returns the base collection for a Case folder
   Needed because trail is not enough because of case collection sharding
   ======================================================================
:)
declare function local:get-case-collection-uri( $cmd as element() )
{
  let $case-no := tokenize($cmd/@trail, '/')[2]
  let $case := fn:collection($globals:cases-uri)/Case[No eq $case-no]
  return util:collection-name($case)
};

(: ======================================================================
   Returns the base collection for binary files of a Case
   Since this is a mirror hierarchy only replaces sites with binaries
   ======================================================================
:)
declare function annex:get-coaching-base-collection-uri( $cmd as element() )
{
  let $case-base-uri := local:get-case-collection-uri($cmd)
  return replace($case-base-uri, '/db/sites', '/db/binaries')
};

(: ======================================================================
   Returns and throws an error in case submission is invalid 
   Returns the empty sequence otherwise
   ======================================================================
:)
declare function local:validate-submission( $db-uri as xs:string, $path as xs:string, $filename as xs:string?, $mime as xs:string? ) as element()* {
  if (empty($mime)) then
    oppidum:throw-error("APPENDIX-MISSING-TYPE", ())
  else if (string-length($filename) = 0) then
    oppidum:throw-error("APPENDIX-MISSING-NAME", ())
  else
    let $ext := mime:get-extension-for-mime($mime)
    return
      if (empty($ext)) then
        oppidum:throw-error("APPENDIX-WRONG-TYPE", ($mime, string-join($mime:extensions, ", ")))
      else
        let $doc-uri := concat($db-uri, '/', $path, '/', $filename, '.', $ext)
        return
          if (util:binary-doc-available($doc-uri)) then
            oppidum:throw-error("APPENDIX-DUPLICATED-NAME", ($filename))
          else
            ()
};

(: ======================================================================
   Creates the $path hierarchy of collections directly below the $base-uri collection. 
   The $base-uri collection MUST be available.
   Returns the database URI to the terminal collection whatever the outcome.
   ======================================================================
:)
declare function local:create-collection-lazy ( $base-uri as xs:string, $path as xs:string, $user as xs:string, $group as xs:string ) as xs:string*
{
  let $set := tokenize($path, '/')
  return (
    for $t at $i in $set
    let $parent := concat($base-uri, '/', string-join($set[position() < $i], '/'))
    let $path := concat($base-uri, '/', string-join($set[position() < $i + 1], '/'))
    return
     if (xdb:collection-available($path)) then
       ()
     else
       if (xdb:collection-available($parent)) then
         if (xdb:create-collection($parent, $t)) then
           xdb:set-collection-permissions($path, $user, $group, util:base-to-integer(0774, 8))
         else
           ()
       else
         (),
    concat($base-uri, '/', $path)
    )[last()]
};

(: ======================================================================
   TODO: manage case without xt-file-id (i.e. no preflight)
   PRE-CONDITION: $mime mime type is supported
   ======================================================================
:)
declare function local:upload( $db-uri as xs:string, $path as xs:string, $id as xs:string, $mime as xs:string ) as element()* {
  (: get uploaded file binary stream :)
  let $data := request:get-uploaded-file-data('xt-file')
  return
    if (not($data instance of xs:base64Binary)) then
      oppidum:throw-error("APPENDIX-NO-BINARY-FILE", ())
    else
      (: FIXME : double check the binary stream MIME-TYPE but how to do it ?
         request:get-uploaded-file-name('xt-file') just gives the name of the file from the user's hard drive :)
      let $ext := mime:get-extension-for-mime($mime)
      return
        database:create-binary-entity($db-uri, 'annex-of-activity', $path, $id, $data, $ext, $mime)
};

(: ======================================================================
   Handles Ajax preflight request part of the AXEL 'file' plugin protocol
   ======================================================================
:)
declare function annex:submit-preflight( $cmd as element() ) as element()* {
  let $base := annex:get-coaching-base-collection-uri($cmd)
  let $path := string($cmd/resource/@resource)
  let $mime := request:get-parameter('xt-mime-type', ())
  let $filename := request:get-parameter('xt-file-preflight', ())
  let $error := local:validate-submission($base, $path, $filename, $mime)
  return
(:    oppidum:throw-error('CUSTOM',
      concat($base, '/', $path, '/', $filename, '.', mime:get-extension-for-mime($mime))):)
    if (empty($error)) then
      let $payload := concat($filename, '.', mime:get-extension-for-mime($mime))
      return
        oppidum:throw-message("APPENDIX-PREFLIGHT-OK", $payload)
    else
      $error
};

(: ======================================================================
   Handles Ajax real file upload request part of the AXEL 'file' plugin protocol
   Pre-condition: @resource on mapping must resolve to activities/#nb
   Returns a sucess containing stored path or an error
   ======================================================================
:)
declare function annex:submit-file( $cmd as element() ) {
  let $db-uri := concat('/db/binaries/', $globals:app-collection)
  let $case-binary-uri := annex:get-coaching-base-collection-uri($cmd)
  let $path := concat(substring-after($case-binary-uri , $db-uri), '/', $cmd/resource/@resource)
  let $mime := request:get-parameter('xt-mime-type', ())
  let $filename := request:get-parameter('xt-file-id', ())
  let $error := local:validate-submission($db-uri, $path, $filename, $mime)
  return
    if (empty($error)) then
      local:upload($db-uri, $path, $filename, $mime)
    else
      $error
};

(: ======================================================================
   Deletes an appendix (no access control)
   Returns success or error message
   ======================================================================
:)
declare function annex:delete-file( $cmd as element(), $filename as xs:string) as element()* {
  let $base := annex:get-coaching-base-collection-uri($cmd)
  let $file-uri := concat($base, '/', $cmd/resource/@resource, '/', $filename)
  return
    if (util:binary-doc-available($file-uri)) then
        (
        xdb:remove(concat($base, '/', $cmd/resource/@resource), $filename),
        oppidum:throw-message('DELETE-ANNEXE-SUCCESS', $filename)
        )
    else
      oppidum:throw-error('URI-NOT-SUPPORTED', ())
};

(: ======================================================================
   Turns an annex meta-data record into an annex model to be transformed to HTML by workflow.xsl
   To be called to build annexes tab content in workflow view, or to render a single row after Ajax upload
   For legacy reason the $item with meta-data is optional
   TODO: use a data template ?
   ======================================================================
:)
declare function annex:gen-annexe-for-viewing (
  $lang as xs:string,
  $item as element()?,
  $filename as xs:string,
  $activity-no as xs:string,
  $base as xs:string?,
  $canDelete as xs:boolean ) as element()
{
  let $url := concat($activity-no, '/docs/', $filename)
  return
    <Annex>
      {
      if ($item) then
        (
        <Date SortKey="{$item/Date/text()}">
          { display:gen-display-date($item/Date, $lang) }
        </Date>,
        <ActivityStatus>
          { display:gen-name-for('ActivityWorkflowStatus', $item/CurrentStatusRef, $lang) }
        </ActivityStatus>,
        <Sender>
          { display:gen-person-name($item/SenderKey,$lang) }
        </Sender>
        )
      else if ($base) then (: legacy appendix w/o meta-data :)
        let $date := string(xdb:created($base, $filename))
        return
          <Date SortKey="{$date}">
            { display:gen-display-date($date, $lang) }
          </Date>
      else
        ()
      }
      <File href="{$url}">
        { if ($canDelete) then attribute { 'Del' } { 1 } else () }
        { $filename }
      </File>
    </Annex>
};
