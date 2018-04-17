# Synopsis  : ./bootstrap.sh {admin-password}
# Parameter : database admin password
# ---
# Preconditions
# - eXist instance running
# - edit ../../../../client.properties to point to the running instance (port number, etc.)
# ---
# Creates initial /db/www/diae/config and /db/www/diae/mesh collections
# You should then use curl {home}/admin/deploy?t=[targets] to terminate the installation
# and then restore some application data / users from an application backup using {exist}/bin/backup.sh
#
APPCOL='diae' # edit and put the same value as $globals:app-collection in globals.xqm
../../../../bin/client.sh -u admin -P $1 -m "/db/www/$APPCOL/mesh" --parse ../mesh
../../../../bin/client.sh -u admin -P $1 -m "/db/www/$APPCOL/config" --parse ../config
echo "''" | ../../../../bin/client.sh -u admin -P $1 -m "/db/sites/$APPCOL" -x -s
CURPWD=`pwd`
CURDIR=`dirname $CURPWD`
CURMOD=`basename $CURDIR`
echo "update value fn:doc('/db/www/$APPCOL/config/mapping.xml')/site/@key with '$CURMOD'" | ../../../../bin/client.sh -u admin -P $1 -x -s
echo "update value fn:doc('/db/www/$APPCOL/config/mapping.xml')/site/@db with '/db/sites/$APPCOL'" | ../../../../bin/client.sh -u admin -P $1 -x -s
echo "update value fn:doc('/db/www/$APPCOL/config/mapping.xml')/site/@confbase with '/db/www/$APPCOL'" | ../../../../bin/client.sh -u admin -P $1 -x -s
echo "update value fn:doc('/db/www/$APPCOL/config/skin.xml')/*/@key with '$CURMOD'" | ../../../../bin/client.sh -u admin -P $1 -x -s

