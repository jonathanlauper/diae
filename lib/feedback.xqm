xquery version "1.0";
(: ------------------------------------------------------------------
   Case tracker pilote application

   Creation: Stéphane Sire <s.sire@opppidoc.fr>

   Utility function COPIED from feedback 3rd part application (lib/poll.xqm)
   
   The feedback:genPollDataForEditing is used to decode Answers 
   to display them in the evaluation questionnaire

   July 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

module namespace feedback = "http://oppidoc.com/ns/feedback";

(: ======================================================================
   Reverse of local:encodePollData
   ======================================================================
:)
declare function feedback:genPollDataForEditing ( $nodes as item()* ) as item()* {
  for $node in $nodes
  return
    typeswitch($node)
      case text()
        return $node
      case attribute()
        return $node
      case element() return
        if ($node/@For) then
          let $suffix := string($node/@For)
          return
            if (local-name($node) eq 'Comment') then
              element { concat(local-name($node), '_', $suffix) } { $node/(text() | *) }
            else (: Assuming entry node is amongst (RatingScaleRef, SupportScaleRef, CommunicationAdviceRef) :)
              element { concat('Likert_', local-name($node), '_', $suffix) }
                {
                $node/text()
                }
        else
          element { local-name($node) }
            { feedback:genPollDataForEditing($node/(attribute()|node())) }
      default return $node
};
