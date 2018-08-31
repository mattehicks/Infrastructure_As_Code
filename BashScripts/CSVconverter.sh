#!/bin/bash



#CSVconverter.sh
#      Point toward a directory of raw CSV files, using -i (input) or -o (output).
#      it will endeavor to unify the delimiters, parse the field names, and trim long column names
#      Will create a mysql database "DataLook" and load all processed records.
#      Run CSVconverter.sh -c once to enter mysql credentials config.
#	   Requires the python package CSVSQL

#SQL converted directory
sqldir="/home/ec2-user/sqldata"
database_name="DataLook"
outputdir="/home/ec2-user/cleanedCSV"
csvdir="/home/ec2-user/sampledata"

for i in "$@"
do
case $i in
        -i | --inpath)
            shift
        csvdir=$1
            ;;
        -o | --outpath )
            shift
        $outpath=$1
            ;;
        -h | --help)
        shift
        echodirs
            ;;
        -c | --config )
            shift
        RUN_CONF="true"   
            ;;
    esac
    shift
done

echodirs(){
          echo "SQL directory: ${sqldir}"
        echo "DB name: ${database_name} " 
        echo "Raw CSV directory (input): ${csvdir}"
        echo "Cleaned files (output): ${outputdir}" 
}

#edit : needs to check for sqldir "sqldata"
#edit : needs to create an output dir
if [ ! -d ${outputdir} ]; then
  mkdir -p ${outputdir};
fi
if [ ! -d ${sqldir} ]; then
  mkdir -p ${sqldir};
fi
if [ ! -d ${outputdir} ]; then
  mkdir -p ${outputdir};
fi

echodirs

#clean all files
# get a list of CSV files in directory
_csv_files=`ls -1 "${csvdir}"`

# loop through csv files
for _csv_file in ${_csv_files[@]}
do
if [[ $_csv_file == *.csv ]]; then

echo "found: $_csv_file"
echo "cleaning : ${csvdir}/${_csv_file}"

#Remove commas between quotes, and quotes, set comma as delimiter
head -n 1 ${csvdir}/${_csv_file} | awk -F'"' -v OFS='' '{ for (i=2; i<=NF; i+=2) gsub(",", "", $i) } 1' | dd of="temp.csv" bs=1 conv=notrunc

#remove ALL spaces in column names
var1= head -n 1 "temp.csv" | sed -e 's/ /_/g'

#replace CSV line with fixed header
sed "1s/.*/${var1}/" ${csvdir}/${_csv_file} > ${outputdir}/${_csv_file} 
rm temp.csv

#head -n 1 $rawfile | awk -F, '/,/{gsub(/ /, "", $0); print} ' OFS=, | dd of="${outputdir}/${newfile}.csv" bs=1 conv=notrunc
echo "Outputted: ${outputdir}/${_csv_file}"
fi

done 


#SQL PASSWORD prompt:
if [ "$RUN_CONF" == "true" ]; then
mysql_config_editor set --login-path=local --host=localhost --user=root --password
fi

#mysql -uroot --password=Stone22! -e "drop database $database_name"
mysql --login-path=local -e "drop database $database_name"

echo "Creating database ${database_name}"
mysql --login-path=local -e "create database $database_name"

for filename in "$outputdir/"*.csv
do

tablename=$(basename "$filename" .csv)
echo "Creating SQL file ${tablename}"
#convert file
csvsql --dialect mysql --snifflimit 100000 $filename > "${sqldir}/${tablename}.sql"
#make database

echo "Creating table structure"
#load file into database    
mysql --login-path=local ${database_name} < "${sqldir}/${tablename}.sql"

#load data infile filename into table ${tablename} fields terminated by ',';

mysql --login-path=local -e  "LOAD DATA LOCAL INFILE '$filename'
INTO TABLE ${database_name}.${tablename}
FIELDS TERMINATED BY ',' 
ENCLOSED BY '\"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;"


#echo "var2 is : ${var2}"

echo "table data loaded"

done

