# Annexes migration shell script

# unzip a full backup
# put yourself at /db/sites/coaching/cases
# execute this script as ./case.sh YEAR

YEAR=$1
find $YEAR -name docs -exec rm -rf \{} \;
find $YEAR -name 'case.xml' | sed -e "p;s/case/legacy/" | xargs -n2 mv

# create a script saxon.sh that runs the migration script with saxon (adjust paths !!!)
# echo -xsl:/usr/local/platinn/ctracker22/lib/webapp/platinn/ctracker/migrations/case.xsl -s:$1 -o:$(dirname $1)/case.xml | xargs -n3 java -cp /usr/local/share/SaxonHE9-6-0-7J/saxon9he.jar net.sf.saxon.Transform

# run the migration script 
find $YEAR -name "legacy.xml" -exec ./saxon.sh {} \;
# cleanup former legacy.xml files
find $YEAR -name "legacy.xml" -exec rm {} \;

# restore the collection from __content__.xml into /db/sites/coaching/cases
# use Java admin client to move the cases (since there is no month sharding before 2018 you can keep the same structure)
