# Configuration for multiple languages support

Settings :

1. dictionary files stored in a dictionaries folder at the root of the code depot

2. each languages translations stored in a dictionary-{lang}.xml file inside dictionaries folder (e.g. dictionary-fr.xml)

3. deploy script deploys dictionaries folder into /db/www/{$globals:app-collection}/dictionaries collection in database (can be embedded inside config target or inside specific dico target)

4.  lib/globals.xqm to declare $globals:dico-uri to point to the dictionaries collection

5. config/globals.xml to declare 'dico-uri' global key

Code snippet for 1: 

    $ ls -1 dictionaries/
    dictionary-de.xml
    dictionary-en.xml
    dictionary-fr.xml

Code snippet for 3: 

    <group name="config">
      ...
      <collection name="/db/www/{$globals:app-collection}/dictionaries">
        <files pattern="dictionaries/dictionary*.xml"/>
      </collection>
    </group>

Code snippet for 4: 

    declare variable $globals:dico-uri := '/db/www/ctracker/dictionaries';

Code snippet for 5: 

    <Global>
        <Key>dico-uri</Key>
    </Global>

and content of /db/www/xcm/config/globals.xml after target globals deployment for 5 (*ctracker* application collection):
    
    <Global>
      <Key>dico-uri</Key>
      <Value>/db/www/ctracker/dictionaries</Value>
    </Global>
