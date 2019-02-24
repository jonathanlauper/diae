xquery version "1.0";
(: --------------------------------------
   DIAE application

   Creation: Fouad Slimane <fouad.slimane@unifr.ch>

  OCR test

   Mars 2018 - (c) Copyright 2014 Dpcetis SARL + UNIFR. All Rights Reserved.
   ----------------------------------------------- :)
import module namespace xdb = "http://exist-db.org/xquery/xmldb";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace compat = "http://oppidoc.com/oppidum/compatibility" at "../../../oppidum/lib/compat.xqm";
import module namespace globals = "http://oppidoc.com/ns/xcm/globals" at "../../lib/globals.xqm";
import module namespace misc = "http://oppidoc.com/ns/xcm/misc" at "../../../xcm/lib/util.xqm";
import module namespace user = "http://oppidoc.com/ns/xcm/user" at "../../../xcm/lib/user.xqm";
import module namespace access = "http://oppidoc.com/ns/xcm/access" at "../../../xcm/lib/access.xqm";
import module namespace ajax = "http://oppidoc.com/ns/xcm/ajax" at "../../../xcm/lib/ajax.xqm";
import module namespace database = "http://oppidoc.com/ns/xcm/database" at "../../../xcm/lib/database.xqm";
import module namespace enterprise = "http://oppidoc.com/ns/xcm/enterprise" at "../../../xcm/modules/enterprises/enterprise.xqm";
import module namespace template = "http://oppidoc.com/ns/diae/template" at "../../lib/template.xqm";
import module namespace annex = "http://oppidoc.com/ns/xcm/annex" at "../annexes/annex.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Generates the list of annexes which have been attached to a given
   document/facet of a given Activity of a given Case.
   ======================================================================
:)
declare function local:gen-annexes( $lang as xs:string, $case as element(), $activity as element() )
{
  let $no := $activity/No/text()
  let $col-uri := concat(replace(util:collection-name($case), "/db/sites", "/db/binaries"), '/pages/', $no)
  return
    <Annexes Collection="{$col-uri}">
      {
      if (xdb:collection-available($col-uri)) then
        for $f in xdb:get-child-resources($col-uri)
        let $item := $activity/Resources/Resource[File eq $f]
        let $canDelete := access:check-entity-permissions('delete', 'Annex', $activity, $item)
        where $f ne 'meta.xml'
        return
          annex:gen-annexe-for-viewing($lang, $item, $f, $no, $col-uri, $canDelete)
      else
        ()
      }
    </Annexes>
};

let $m := request:get-method()
let $cmd := oppidum:get-command()
let $name := string($cmd/resource/@name)
let $lang := string($cmd/@lang)
let $trail := string($cmd/@trail)

let $base := annex:get-coaching-base-collection-uri($cmd)
let $image := fn:collection($globals:ocr-uri)/OCR/Images/Image
(:let $file-uri := concat($trail,'/images', '/', $image[0]):)

let $collections := fn:collection($globals:ocr-uri)/Collections
let $images := fn:collection($globals:ocr-uri)/Collections/Images/Image

let $t := replace($trail, '-', '/')
let $actual := replace($t, '_', '.')
let $split := tokenize($actual, '/')




let $col := $collections//Collection/Name[. eq $split[3]]/parent::Collection
let $t := $col//Ref[. eq $split[4]]/parent::Image
let $nextImg := if(empty($t/following-sibling::*[1])) then
                $t/parent::Images/Image[1]
            else
                $t/following-sibling::*[1]


let $prevImg := if(empty($t/preceding-sibling::*[1])) then
                    $t/parent::Images/Image[last()]
                else
                    $t/preceding-sibling::*[1]
                    
                    
let $v := $collections//Collection/Name[. eq $split[3]]/parent::Collection    
let $nextCol := if(empty($v/following-sibling::*[1])) then
                    $v/parent::Collections//Name[1]
                else
                    $v/following-sibling::*[1]/Name
                    
                    
(:

let $f := $collections//Collection/Name[. eq $nextCol[1]]/parent::Collection
let $first := $f/Images/Image[1]






let $x := "hello"
return ($document//w[. eq $x]/following-sibling::w)[1]

            <NextCol >{concat($split[1],'/',$split[2],'-',$nextCol,'-', replace($first, '\.', '_')) }</NextCol>
            <PrevCol >{concat($split[1],'/',$split[2],'-',$split[3],'-', replace($prevImg, '\.', '_')) }</PrevCol>
                        <Next id="next_image">{concat($split[1],'/',$split[2],'-',$split[3],'-', replace($nextImg, '\.', '_')) }</Next>
            <Prev id="prev_image">{concat($split[1],'/',$split[2],'-',$split[3],'-', replace($prevImg, '\.', '_')) }</Prev>
            replace($t, '\.', '_')
:)

return
   <Page skin="formulars">
      <Content>
        <Title Level="1" loc="ocr-creation.window.title">Recognition</Title>
        
        <Image id="orig_image">
            <Ref>{$actual}</Ref>
            

            
    
        </Image>
        
 
        <Collection>
               {
        for $collection in $collections/Collection
            return 
                <Name>{$collection/Name/node()}</Name>

       }
       </Collection>
       <Images>
       {
       for $collection in $collections/Collection
            return
                <Collection>
                    <Name>{$collection/Name/node()}</Name>
                {for $image in $collection/Images/Image
                     let $t := concat($trail,'/images', '-', $collection/Name ,'-', $image )
                        return  
                            <Ref>{$image/Ref/node()}</Ref>
    
    
                }   
                </Collection>
       }
       </Images>              
      <Recognition/>
       
       
      </Content>
    </Page>
