#!/bin/bash
# This file handles the logic behind all the Database-level commands

if grep -i -E -q '^[ ]*create[ ]+table[ ]+[a-zA-Z][a-zA-Z0-9@#$%_ -]+[ ]*\(([ ]*[a-zA-Z][a-zA-Z0-9@#$%_ -]+[ ]*\/[ ]*(int|string)[ ]*(\/[ ]*(pk|unique|required)[ ]*)?,)+\)[ ]*$' <<< "$1"
then  
    table_name=$(echo "$1" | grep -o -E -i '[ ]*create[ ]+table[ ]+[a-zA-Z][a-zA-Z0-9@#$%_ -]+')
    #| grep -v -o -E -i 'create table[ ]*')
    echo "$table_name"   
else
    echo "Unsupported Command!!
Check The docs or use the command >Commands to show all supported commands" 
fi

