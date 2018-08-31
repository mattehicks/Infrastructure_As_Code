#!/bin/sh

Author:  Matt Hicks
Email: mattehicks@gmail.com
Date: 2016

#Asks you to delete any documents or files that are older than X days.

usage="Usage: dir_diff.sh [days]"

if [ ! "$1" ]
then
  echo $usage
  exit 1
fi

now=$(date +%s)
#hdfs dfs -ls -R | grep "^d" | while read f; do
hdfs dfs -ls -R /test/users | grep "^d" | while read f; do
  dir_date=`echo $f | awk '{print $6}'`
  difference=$(( ( $now - $(date -d "$dir_date" +%s) ) / (24 * 60 * 60 ) ))
  difference=0
  if [ $difference -eq $1 ]; then
    dir_name=`echo $f | awk '{print $8}'`
    dir_name='tests'
    hdfs dfs -ls $dir_name
    read -p "Do you want to delete the above files in dir: $dir_name? (y/n)" yn < /dev/tty
    case $yn in
        #y ) hdfs dfs -rm $dir_name/*; break;;
        y ) hdfs dfs -ls $dir_name/*; break;;
        n ) exit;;
        * ) echo "Please answer yes or no.";;
    esac

  fi
done
