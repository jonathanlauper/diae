# Annexes migration shell script

# 1) unzip an archive of the cases collection and put yourself inside /db folder then execute :
#find . -path "*/activities/*/*" -name "__contents__.xml" | sed -e "p;s/__contents__.xml/meta.xml/" | xargs -n2 mv
#find . -name __contents__.xml -exec rm \{} \;
#find . -name case.xml -print -exec rm \{} \;
#find . -name activities | sed -e "p;s/\/docs//" | xargs -n2 mv
#find . -name docs -exec rmdir \{} \;

# 2) save this file to move.sh, put yoursefl inside /db folder then execute ./move.sh YEAR for each year

YEAR=$1
find sites/coaching/cases/$YEAR -name activities | sed -e "s/sites\/coaching\/cases\/$YEAR/binaries\/ctracker\/cases\/$YEAR/;s/\/activities//" | xargs -n1 mkdir -p
find sites/coaching/cases/$YEAR -name activities | sed -e "p;s/sites\/coaching\/cases\/$YEAR/binaries\/ctracker\/cases\/$YEAR/" | xargs -n2 mv

# 3) find / replace "/db/sites/coaching/cases/*" in generated meta.xml files (legacy __contents__.xml)
