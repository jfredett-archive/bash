#!/bin/bash 


files=`cat .gitignore`


for file in $files ; do
    if [[ "$file" = "##~" ]] ; then
        shouldcount="true"
    fi
    if [[ -n $file && $shouldcount ]] ; then 
        count=$[$count + 1]
    fi 
done

manifest=`tail -n $count .gitignore`

for file in $manifest ; do 
    echo $file
done
