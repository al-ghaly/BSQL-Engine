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

<<COMMENT
    This function handles the logic behind selecting data from table.
    It takes in the a table name, columns name, filter column name, and a filtering value and do all the work!
COMMENT
selectRows(){
    header=$(head -n 1 "$table_name.csv")
    # First we will start by extracting and validating the selecting columns
    # We have columns in the format column one, column two, ....
    # So extracting them is a real piece of cake
    if grep -i -E -q '\*' <<< "$2"
    then    
        IFS="," read -a columns <<< "$header"
    else
        # This variable will hold the count of selecting columns that don't exist
        violations=0
        # This variable will hold the column names after we trim the spaces from it
        columnNames=""
        # This variable holds the column names given from the user
        IFS="," read -a names <<< "$2"
        for i in "${names[@]}"
        do
            columnName=$(echo "$i" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            # Check of we already have a column with the same name
            exists=$(echo "$header" | sed -n -E "/^($columnName,)|(,$columnName,)|(,$columnName)$/p")
            if [ "$exists" == "" ]
            # If this column does not exist in the table
            then  
                echo "$1 Does not have a column named $columnName"  
                ((violations++))
            fi    
            columnNames="$columnNames$columnName,"
        done

        if ((violations>0))
        then
            # Abort the operation due to column does not exist ERROR
            return
        else 
        # In case all the columns can be found in the table
            IFS="," read -a columns <<< "${columnNames:0:-1}"
        fi    
    fi    

    # Now all looks pretty perfect! Time to show some data !
    # The return statement made it sure we won't get here unless all is good
    echo "Table: $1."
    echo "${columns[@]}"
    echo "Filter: $3."
    echo "Filter Va: $4."
}

<<COMMENT
    This function handles the logic behind parsing the select from table command.
    It takes in the a user command and do all the really heavy work!
COMMENT
parseSelect(){
    # The command goes something like this
    # SELECT (COLUMNS) FROM (TABLE) WHERE (FILTERING_COL) = (VALUE)
    # So lets extract the 4 groups: Table name, columns, filtering column, value
    # Let's firs capitalize the command for 2 reasons:
        # For the match to be case Insensetive
        # For the table name, column name, filtering column to be capitalized
    capCommand=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    if [[ $capCommand =~ ^[[:space:]]*SELECT(.*)FROM(.*)WHERE(.*)=[[:space:]]*\((.*)\) ]]; then
        table_name="${BASH_REMATCH[2]}"
        columns="${BASH_REMATCH[1]}"
        filteringCol="${BASH_REMATCH[3]}"
        filteringValue=$(echo "$1" | grep -oP '\(.*?\)')
        filteringValue=$(echo "$filteringValue" | sed 's/^[[:space:]]*([[:space:]]*//; s/[[:space:]]*)[[:space:]]*$//')

    elif [[ $capCommand =~ ^[[:space:]]*SELECT(.*)FROM(.*) ]]; then
        table_name="${BASH_REMATCH[2]}"
        columns="${BASH_REMATCH[1]}"
        filteringCol=""
        filteringValue=""
    else
        echo "Error happened trying to parse the SELECT command !!
Check the Command format and try again."
    # There is no expected scenario for the function to enter this block
    # But in case anything unexpected happens abort the select operation
        return      
    fi
    # Trim any left/right spaces from the table name/column name
    table_name=$(echo "$table_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    filteringCol=$(echo "$filteringCol" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [ "$database" == "" ]
    # Check that the user is connected to a database
    then
        echo "You are not Connected to a Database!!"
    elif [ ! -f "$table_name.csv" ]
    # Check that the database have such table
    then
        echo "There is no table named $table_name  in $database !!" 
    # Everything is almost good, now let's check the validity of the filtering column
    elif [ "$filteringCol" == "" ]
    # If there is no filtering column so we are ready to go
    then
        #PS: We still need to validate that the table has all the selected columns
        # But this will be done in the selectRows function
        selectRows "$table_name" "$columns" "$filteringCol" "$filteringValue" 
    else
        header=$(head -n 1 "$table_name.csv")
        exists=$(echo "$header" | sed -n -E "/^($filteringCol,)|(,$filteringCol,)|(,$filteringCol)$|^($filteringCol)$/p")
        if [ "$exists" == "" ]
        # If the table has the filtering column go select, otherwise NOT
        then
            echo "There is no column named $filteringCol in $table_name"
        else    
            #PS: We still need to validate that the table has all the selected columns
            # But this will be done in the selectRows function
            selectRows "$table_name" "$columns" "$filteringCol" "$filteringValue" 
        fi        
    fi
}

if grep -i -E -q '^[ ]*delete[ ]+from[ ]+.+[ ]+where[ ]+(.+)=[ ]*\((.+)\)[ ]*$' <<< "$1"
then
    parseDeleteRow "$1"
elif grep -i -E -q '^[ ]*select[ ]+((\*)|(([a-zA-Z][a-zA-Z0-9@#$%_ -]*)|(([a-zA-Z][a-zA-Z0-9@#$%_ -]*,[ ]*)+[a-zA-Z][a-zA-Z0-9@#$%_ -]*)))[ ]+from[ ]+[a-zA-Z][a-zA-Z0-9@#$%_ -]*[ ]*( where[ ]+[a-zA-Z][a-zA-Z0-9@#$%_ -]*[ ]*=[ ]*\([ ]*.*[ ]*\))?[ ]*$' <<< "$1"
then
    parseSelect "$1"
else
    echo "Unsupported Command!!
Check The docs or use the command >Commands to show all supported commands" 
fi

