#!/bin/bash
# This file handles the logic behind all the Database-level commands

<<COMMENT
    This function handles the logic behind deleting data from table.
    It takes in the a table name, column name, and filtering value and do all the work!
COMMENT
deleteRows(){
    awk -v col="$2" -v val="$3" 'BEGIN{ 
	FS=","
	field=0
	}		
	{
	if(NR==1){
	print $0
		i=1
	while(i<=NF){
	if($i == col){
	field=i
	}
		i++	
	}
	}
	else if (NR > 4 && field != 0) {
        if($field != val){
		print $0
    }
	}
	else{
		print $0
	}
	}
	END{
	}' "$1.csv" > "output.csv"
    mv "output.csv" "$1.csv"
}

<<COMMENT
    This function handles the logic behind parsing the delete from table command.
    It takes in the a user command and do all the work!
COMMENT
parseDeleteRow(){
    # First Extract the command attributes, it would go something like this
    # Table name where column name = (value)
    attributes=$(echo "$1" | sed 's/^[ ]*delete[ ]*from[ ]*//I') 
    # We need to extract 3 attributes: Table name, column name, and value
    # We want first to get table name then rest
    # Spliting the (Table name where column name = (value)) over the word
    # Where is a smart idea, unless the user puts a where word in the table name!
    # Extract whatever before the where statement and this is the table name

    # We need to make sure the where is lower case for the splitting to work as expected
    lowered_attr=$(echo "$attributes" | tr '[:upper:]' '[:lower:]')
    bfore_last_where=$(echo "$lowered_attr" | awk -F'where' -v OFS='where' '{$NF=""; print $0}')
    
    # Trim any left/right spaces from the table name
    table_name=$(echo "$bfore_last_where" | sed 's/^[[:space:]]*//;s/[[:space:]]*where[[:space:]]*$//I')
    # Capitalize the table name
    table_name=$(echo "$table_name" | tr '[:lower:]' '[:upper:]')

    # Then parse the text after the where statement
    # It will be something like this "Column name = (Value)""
    after_last_where=$(echo "$1" | sed 's/.*where[[:space:]]*//I')
    # Extract the column name and the filtering value from it
    column_name=$(echo "$after_last_where" | sed 's/[[:space:]]*=.*//')
    column_name=$(echo "$column_name" | tr '[:lower:]' '[:upper:]')
    value=$(echo "$after_last_where" | grep -oP '\(.*?\)')
    value=$(echo "$value" | sed 's/^[[:space:]]*([[:space:]]*//; s/[[:space:]]*)[[:space:]]*$//')

    # Check that the user is connected to a database
    if [ "$database" == "" ]
    then
        echo "You are not Connected to a Database!!"
    elif [ ! -f "$table_name.csv" ]
    # Check that the database have such table
    then
        echo "There is no table named $table_name  in $database !!"     
    else
        # First Make sure the table has such column
        header=$(head -n 1 "$table_name.csv")
        exists=$(echo "$header" | sed -n -E "/^($column_name,)|(,$column_name,)|(,$column_name)$|^($column_name)$/p")
        if [ "$exists" == "" ]
        then
            echo "There is no column named $column_name in $table_name"
        else    
            # Update the table
            echo "Deleting Data from $table_name Where $column_name equals $value ..."
            deleteRows "$table_name" "$column_name" "$value"
            echo "Data updated successfully"
        fi        
    fi
}

if grep -i -E -q '^[ ]*delete[ ]+from[ ]+.+[ ]+where[ ]+(.+)=[ ]*\((.+)\)[ ]*$' <<< "$1"
then
    parseDeleteRow "$1"
else
    echo "Unsupported Command!!
Check The docs or use the command >Commands to show all supported commands" 
fi

