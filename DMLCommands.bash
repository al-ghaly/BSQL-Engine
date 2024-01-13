#!/bin/bash
# This file handles the logic behind all the Database-level commands

<<COMMENT
    This function takes in a table name, filtering, column, filtering value, columns to retreive
    and retreive the data from the database.
    We will need this function as a utility function in the selectRows function
    to retreive the to-be-selected data, we will also use it as a utility
    function in both the update and insert statements to check uniqueness 
    of a column.
    So it it the single most important function in the file!
COMMENT
retreiveData(){
    awk -v col="$3" -v val="$4" -v columns="$2" 'BEGIN{ 
	FS=","
	filter_index=0
	split(columns, columnsArr, ",")
	}		
	{
	line = "|"
	if(NR==1){
	i=1
	while(i<=NF){
	indexes[$i] = i
	if($i == col){
	filter_index=i
	}
		i++	
	}
	}
	else if (NR > 4 && filter_index != 0) {
        if($filter_index == val){
		for (i = 1; i <= length(columnsArr); i++) {
		line = line $indexes[columnsArr[i]] "|"
    }
		print line
	}
	}
	else if (NR > 4 && filter_index == 0 && col == ""){
		for (i = 1; i <= length(columnsArr); i++) {
		line = line $indexes[columnsArr[i]] "|"
    }
		print line
	}
	}
	END{
	}' "$1.csv" 
}

<<COMMENT
    This function handles the logic behind Updating data into a table.
    It takes in the a table name, filtering column name, update columns, new values, and filtering value and do all the work!
COMMENT
updateRows(){
    # First let's make the updates, then check if it is violates the uniqueness conditions
    awk -v col="$4" -v val="$5" -v cols="$2" -v vals="$3" 'BEGIN{ 
            FS=","
            OFS=","
            filter_index=0
            split(cols, columnsArr, ",")
            split(vals, valuesArr, ",")
        }		
        {
            if(NR==1){
                i=1
                while(i<=NF){
                    indexes[$i] = i
                    if($i == col){
                        filter_index=i
                    }
                    i++	
                }
                print $0
            }
            else if (NR > 1 && NR < 5){
                print $0
            }
            else if (NR > 4 && filter_index != 0) {
                if($filter_index == val){
                    for (i = 1; i <= length(columnsArr); i++) {
                        $indexes[columnsArr[i]] = valuesArr[i]
                    }
                }
                print $0
            }
            else if (NR > 4 && filter_index == 0 && col == ""){
                for (i = 1; i <= length(columnsArr); i++) {
                    $indexes[columnsArr[i]] = valuesArr[i]
                }
                print $0
            }
        }
        END{
	}' "$1.csv" > "$1.temp.csv"
    violated=$(validateData "$1.temp" "$2" "$3" "once") # once here cuz we have already installed a single row, so it is okay
    if [[ $violated == "" ]]
    then
        mv "$1.temp.csv" "$1.csv"
        echo "Data Updated Succesfully."
    else 
        rm -f "$1.temp.csv"
        echo "$violated"    
    fi
}

<<COMMENT
    This function validate the data type and constraints for columns values.
    It takes in the column names and values and do the work.
    This will work asa utility function for both update and insert functions
COMMENT
columnData(){
    # Get the table's meta data and store them in 3 arrays
    headerRow1=$(head -n 1 "$1.csv")  # Column names
    headerRow2=$(sed -n '2p' "$1.csv")  # Column data types
    headerRow3=$(sed -n '3p' "$1.csv")   # Column Constraints
    IFS="," read -a namesRow <<< "$headerRow1"
    IFS="," read -a dataTypes <<< "$headerRow2"
    IFS="," read -a constraints <<< "$headerRow3"
    # Loop over the meta data to retreive the data type and constrint for the column
    # Get the length of the array
    array_length=${#namesRow[@]}
    for ((i=0; i<array_length; i++)); do
        if [[ ${namesRow[i]} == "$2" ]]
        then
            dataType=${dataTypes[i]}
            constrint=${constraints[i]}
            echo "$dataType,$constrint"
            return
        fi    
    done
}

<<COMMENT
    This function validate the data type and constraints for columns values.
    This will work asa utility function for both update and insert functions.
    This function takes in the table name, column names and values and return:
        - Empty string in case of no violations
        - Non-Empty String in case of any data type/constraints violations.
    PS: The fourth parameter is:
        - skip: don't check for uniqueness.
        - once: Check the value exists exactly one time
        - unique: Check that it does not exist.
        We need this flag to be able to do the following:
            In case of an update
                - Check the uniqueness after the update effect is completed NOT BEFORE
COMMENT
validateData(){
    IFS="," read -a extractedColumns <<< "$2"
    IFS="," read -a extractedValues<<< "$3"
    array_length=${#extractedColumns[@]}
    for ((i=0; i<array_length; i++)); do
        colName="${extractedColumns[i]}"
        colValue="${extractedValues[i]}"
        metaData=$(columnData "$1" "$colName")
        IFS="," read -a tuple <<< "$metaData"
        colDataType="${tuple[0]}"
        colConstraint="${tuple[1]}"
        # Check Data Type
        if [[ "$colDataType" = "int" && "$4" != "once" ]]
        then
            if ! grep -E -q '^[0-9]*$' <<< "$colValue"
            then
                echo "Invalid value for Integer columns $colName"
            fi
        fi    
        # Check Constraint
        if [[ "$colConstraint" = "required" || "$colConstraint" == "pk" ]]
        then
            if [[ "$colValue" = "" && "$4" != "once" ]]
                then
                echo "$colName's Value can't be null as it is a $colConstraint Column"
            fi
        fi    
        # Check fro uniqueness (FOR PK & Unique)
        if [[ "$colConstraint" = "unique" || "$colConstraint" == "pk" ]]
        then
            data=$(retreiveData "$1" "$colName")
            exists=$(echo "$data" | sed -n -E "/^\|$colValue\|$/p")
            # If there is a match when we are checking for unique, return error
            if [[ "$exists" != "" && "$4" == "unique" ]]
            then
                echo "$colConstraint Constraint Violated for $colName !"
            # if a single accurance is accepted
            elif [[ "$exists" != "" && "$4" == "once" ]]
            then 
                line_count=$(echo -e "$exists" | wc -l)
                if [[ $line_count -gt 1 ]]
                then
                    echo "$colConstraint Constraint Violated for $colName !"
                fi
            fi
        fi
    done
}

<<COMMENT
    This function takes an input in this format
        table name and a string like this:
        column one = value 1, column2 = value 2, ....
    and do couple of things:
        - Validate that all the columns exists in the table name
        - Extract the columns names and values from the input string
    Then returns
        - An empty string if any of the columns does not exist in the table
        - Otherwise a String in this format:
            - Col 1,Col2,Col3,...|Value1,Value2,...
COMMENT
extractData(){
    header=$(head -n 1 "$1.csv")
    # This variable will hold the count of selecting columns that don't exist
    violations=0
    # This variable will hold the column names
    columns=""
        # This variable will hold the values
    values=""
    # This variable holds the column names & values given from the user
    IFS="," read -a names <<< "$2"
    for i in "${names[@]}"
    do
        IFS="=" read -a tuple <<< "$i"
        columnName="${tuple[0]}"
        columnName=$(echo "$columnName" | tr '[:lower:]' '[:upper:]')
        columnValue="${tuple[1]}"
        # Trim left/right spaces from both column name and column value
        columnName=$(echo "$columnName" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        columnValue=$(echo "$columnValue" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        # Check of we already have a column with the same name
        exists=$(echo "$header" | sed -n -E "/^($columnName,)|(,$columnName,)|(,$columnName)$/p")
        if [ "$exists" == "" ]
        # If this column does not exist in the table
        then  
            echo "$1 Does not have a column named $columnName"  
            ((violations++))
        else  
            duplicate=$(echo "$columns" | sed -n -E "/^($columnName,)|(,$columnName,)/p") 
            if [ "$duplicate" != "" ]
            then
                ((violations++))
                echo "The column name $columnName is specified more than once in the SET clause !!"
            fi    
        fi    
        columns="$columns$columnName,"
        values="$values$columnValue,"
    done
    if ((violations>0))
    then
        # Abort the operation and return an empty string
        echo  "Pease check the column names and try again !!"
    else 
        # In case all the columns can be found in the table
        echo "${columns:0:-1}=${values:0:-1}"
    fi    
}

<<COMMENT
    This function handles the logic behind parsing the update table command.
    It takes in the a user update command and do all the work!
COMMENT
parseUpdate(){
    # The command goes something like this
    # UPDATE (TABLE) SET (COLUMNS AND VALUES) WHERE (FILTERING_COL) = (VALUE)
    # So lets extract the 4 groups: Table name, columns & values, filtering column, value
    # Let's firs capitalize the command for 2 reasons:
        # For the match to be case Insensetive
        # For the table name, column name, filtering column to be capitalized
    capCommand=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    if [[ $capCommand =~ ^[[:space:]]*UPDATE(.*)SET[[:space:]]*\[(.*)\][[:space:]]*WHERE(.*)=[[:space:]]*\((.*)\) ]]; then
        table_name="${BASH_REMATCH[1]}"
        filteringCol="${BASH_REMATCH[3]}"
        filteringCol=$(echo "$filteringCol" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        # Trim any left/right spaces from the table name/column name and filtering value
        filteringValue=$(echo "$1" | grep -oP '\(.*\)')
        filteringValue=$(echo "$filteringValue" | sed 's/^[[:space:]]*([[:space:]]*//; s/[[:space:]]*)[[:space:]]*$//')

    elif [[ $capCommand =~ ^[[:space:]]*UPDATE(.*)SET[[:space:]]*\[(.*)\] ]]; then
        table_name="${BASH_REMATCH[1]}"
        filteringCol=""
        filteringValue=""
    else
        echo "Error happened trying to parse the UPDATE command !!
Check the Command format and try again."
    # There is no expected scenario for the function to enter this block
    # But in case anything unexpected happens abort the select operation
        return      
    fi
    # We can't depend on the matching groupt to extract the columns & values
    # because the values are capitalized in the matching group, so let's 
    # extract those here
    columns=$(echo "$1" | grep -oP '\[.*\]')
    columns=${columns:1:-1}

    # Trim any left/right spaces from the table name
    table_name=$(echo "$table_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ ! -f "$table_name.csv" ]
    # Check that the database have such table
    then
        echo "There is no table named $table_name  in $database !!" 
    # Everything is almost good, now let's check the validity of the filtering column
    else
        header=$(head -n 1 "$table_name.csv")
        exists=$(echo "$header" | sed -n -E "/^($filteringCol,)|(,$filteringCol,)|(,$filteringCol)$|^($filteringCol)$/p")
        if [[ "$filteringCol" != "" && $exists == "" ]]
        then
            echo "There is no column named $filteringCol in $table_name"
        else
            rowData=$(extractData "$table_name" "$columns")
            line_count=$(echo -e "$rowData" | wc -l)
            if [[ $line_count == 1 ]]
            then
                IFS="=" read -a tuple <<< "$rowData"
                columnNames="${tuple[0]}"
                columnValues="${tuple[1]}"
                violated=$(validateData "$table_name" "$columnNames" "$columnValues" "skip") # Skip here cuz we won't check the uniqueness now.
                if [[ $violated == "" ]]
                then
                    updateRows "$table_name" "$columnNames" "$columnValues" "$filteringCol" "$filteringValue"
                else 
                    echo "$violated"    
                fi
            else
                echo "$rowData"    
            fi
        fi
    fi        
}

<<COMMENT
    This function handles the logic behind inserting data into a table.
    It takes in table name, insert columns, insert values and do all the work!
COMMENT
insertRows(){
    IFS="," read -a insertColumns <<< "$2"
    IFS="," read -a insertValues <<< "$3"

    # Declare a dictionary holding names and values in a key: value pairs
    declare -A insertData
    # Loop over the given columns/values arrays and construct the dictionary
    array_length=${#insertColumns[@]}
    # Loop over the columns and get the corresponding value in the insert statement
    for ((i=0; i<array_length; i++)); do
        columnName=${insertColumns[i]}
        columnValue=${insertValues[i]}
        insertData["$columnName"]="$columnValue"
    done

    row="" # The row to insert in the database
    violations=0 # This variable holds the number of non-inserted required columns
    # Get the table's meta data and store them in 2 arrays
    headerRow1=$(head -n 1 "$1.csv")  # Column names
    headerRow3=$(sed -n '3p' "$1.csv")   # Column Constraints
    IFS="," read -a namesRow <<< "$headerRow1"
    IFS="," read -a constraints <<< "$headerRow3"
    # Get the length of the array
    array_length=${#namesRow[@]}
    # Loop over the columns and get the corresponding value in the insert statement
    for ((i=0; i<array_length; i++)); do
        columnName=${namesRow[i]}
        columnCon=${constraints[i]}
        data=${insertData[$columnName]}
        if [[ "$data" == "" && ($columnCon == "required" || $columnCon == "pk") ]]
        then
            echo "$columnCon Column: $columnName Is missing in the insert statement !"  
            ((violations++))
        fi
        row="$row$data,"
    done
        if ((violations==0))
    then
        echo "${row:0:-1}" >> "$1.csv"
        echo "Data Inserted succesfully into $1"
    fi    
}

<<COMMENT
    This function handles the logic behind parsing the insert command.
    It takes in the a user insert command and do all the work!
COMMENT
parseInsert(){
    # The command goes something like this
    # INSERT INTO (TABLE) VALUES (COLUMNS AND VALUES)
    # So lets extract the 2 groups: Table name, columns & values
    # Let's firs capitalize the command for 2 reasons:
        # For the match to be case Insensetive
        # For the table name, column name
    capCommand=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    if [[ $capCommand =~ ^[[:space:]]*INSERT[[:space:]]*INTO(.*)VALUES[[:space:]]*\[(.*)\][[:space:]]* ]]; then
        table_name="${BASH_REMATCH[1]}"
    else
        echo "Error happened trying to parse the INSERT command !!
Check the Command format and try again."
    # There is no expected scenario for the function to enter this block
    # But in case anything unexpected happens abort the select operation
        return      
    fi
    # We can't depend on the matching group to extract the columns & values
    # because the values are capitalized in the matching group, so let's 
    # extract those here
    columns=$(echo "$1" | grep -oP '\[.*\]')
    columns=${columns:1:-1}

    # Trim any left/right spaces from the table name
    table_name=$(echo "$table_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ ! -f "$table_name.csv" ]
    # Check that the database have such table
    then
        echo "There is no table named $table_name  in $database !!" 
    # Everything is almost good, now let's check the validity of the filtering column
    else
        rowData=$(extractData "$table_name" "$columns")
        line_count=$(echo -e "$rowData" | wc -l)
        if [[ $line_count == 1 ]]
        then
            IFS="=" read -a tuple <<< "$rowData"
            columnNames="${tuple[0]}"
            columnValues="${tuple[1]}"
            violated=$(validateData "$table_name" "$columnNames" "$columnValues" "unique") # Unique here cuz we need to check the uniqueness of the entered data.
            if [[ $violated == "" ]]
            then
                insertRows "$table_name" "$columnNames" "$columnValues"
            else 
                echo "$violated"    
            fi
        else
            echo "$rowData"    
        fi
    fi    
}

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
    value=$(echo "$after_last_where" | grep -oP '\(.*\)')
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
    header=$(head -n 1 "$1.csv")
    # First we will start by extracting and validating the selecting columns
    # We have columns in the format column one, column two, ....
    # So extracting them is a real piece of cake
    if grep -i -E -q '\*' <<< "$2"
    then    
        columns="$header"
    else
        # This variable will hold the count of selecting columns that don't exist
        violations=0
        # This variable will hold the column names after we trim the spaces from it
        columns=""
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
            columns="$columns$columnName,"
        done

        if ((violations>0))
        then
            # Abort the operation due to column does not exist ERROR
            return
        else 
        # In case all the columns can be found in the table
            columns="${columns:0:-1}"
        fi    
    fi    

    # Now all looks pretty perfect! Time to show some data !
    # The return statement made it sure we won't get here unless all is good
    echo ""
    echo ""
    echo -n "|"
    # Print The header
    for ((i=0; i<${#columns[@]}; i++)); do
        echo -n "${columns[i]}"
        echo -n "|"
    done
    echo ""
    echo ""
    # Retreive the data
    data=$(retreiveData "$1" "$columns" "$3" "$4")
    echo "$data"
    echo ""
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
        filteringValue=$(echo "$1" | grep -oP '\(.*\)')
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
elif grep -i -E -q '^[ ]*update[ ]+[a-zA-Z][a-zA-Z0-9@#$%_ -]*[ ]+set[ ]*\[[ ]*((([a-zA-Z][a-zA-Z0-9@#$%_ -]*=[^,=]*)|(([a-zA-Z][a-zA-Z0-9@#$%_ -]*=[^,=]*,[ ]*)+[a-zA-Z][a-zA-Z0-9@#$%_ -]*=[^,=]*)))\][ ]*(where[ ]+[a-zA-Z][a-zA-Z0-9@#$%_ -]*[ ]*=[ ]*\([ ]*.*[ ]*\))?[ ]*$' <<< "$1"
then
    if [ "$database" == "" ]
    # Check that the user is connected to a database
    then
        echo "You are not Connected to a Database!!"
    else 
        parseUpdate "$1"
    fi    
elif grep -i -E -q '^[ ]*insert[ ]+into[ ]+[a-zA-Z][a-zA-Z0-9@#$%_ -]*[ ]+values[ ]*\[[ ]*((([a-zA-Z][a-zA-Z0-9@#$%_ -]*=[^,=]*)|(([a-zA-Z][a-zA-Z0-9@#$%_ -]*=[^,=]*,[ ]*)+[a-zA-Z][a-zA-Z0-9@#$%_ -]*=[^,=]*)))\][ ]*$' <<< "$1"
then
    if [ "$database" == "" ]
    # Check that the user is connected to a database
    then
        echo "You are not Connected to a Database!!"
    else 
        parseInsert "$1"
    fi  
else
    echo "Unsupported Command!!
Check The docs or use the command >Commands to show all supported commands" 
fi

