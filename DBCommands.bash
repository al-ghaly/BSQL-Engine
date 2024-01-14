#!/bin/bash
# This file handles the logic behind all the Database-level commands

#Initialize the current table we are working on
table_name=""

<<COMMENT
    This function handles the table creation logic.
    It takes in the a table name and columns details and do all the heavy work!
COMMENT
createTable(){
    columnsNames=""
    types=""
    constraints=""
    # We will use this variable to count the PKs in the commands to assure a single PK is given at most
    pks=0
    # We will use this variable to count the duplications in the columns names to assure a unique name is given for each
    duplicates=0
    # for each column: in the format of col name/type/constraint
    for var in "$@"
    do
        # Extract column details: something like => [col name, type, constrains]
        IFS="/" read -a details <<< "$var"
        # Remove any left/right spaces from the columns' names, types, cons
        name=$(echo "${details[0]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        # Capitalize column names
        name=$(echo "$name" | tr '[:lower:]' '[:upper:]')
        # Check of we already have a column with the same name
        exists=$(echo "$columnsNames" | sed -n -E "/^($name,)|(,$name,)/p")
        if [ "$exists" != "" ]
        then    
            ((duplicates++))
        fi    
        columnsNames="$columnsNames$name,"
        type=$(echo "${details[1]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        types="$types$type,"
        cons=$(echo "${details[2]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if grep -i -E -q '^pk*$' <<< "$cons"
        then    
            ((pks++))
        fi    
        constraints="$constraints$cons,"
    done
    if ((pks>1))
    then
        echo "Multiple Primary Keys are not Supported !!"
    elif ((duplicates>0))
    then
        echo "Each column must have a unique name !!"
    else    
        # Convert the types and constraints into lower case
        types=$(echo "$types" | tr '[:upper:]' '[:lower:]')
        constraints=$(echo "$constraints" | tr '[:upper:]' '[:lower:]')
        printf "%s\n%s\n%s\n\n" "${columnsNames:0:-1}" "${types:0:-1}" "${constraints:0:-1}" > "$table_name.csv"
        echo "table $table_name is created in $database"
    fi    
}

<<COMMENT
    This function handles the logic behind parsing the create table command.
    It takes in the a user command and do all the work!
COMMENT
parseCreate(){
    # First Extract the command attributes, it would go something like this
    # Table name (Column 1 name/data type/cons, .......)
    attributes=$(echo "$1" | sed 's/^[ ]*create[ ]*table[ ]*//I')
    # Try to devide the attributes into 2 groups:
    # Table name: what ever before the opening ( => something like "Table name"
    # Columns: whatever inside the () 
        # something like => (Column 1 name/data type/cons, .......)
    if [[ $attributes =~ ^([^(]+)[[:space:]]*\(([^)]+)\)$ ]]; then
        table_name="${BASH_REMATCH[1]}"
        columns="${BASH_REMATCH[2]}"
        # Create a list of the columns, it would go something like this
        # [column 1 name/data type/cons, .......]
        IFS="," read -a column <<< "$columns"
        # Trim any left/right spaces from the table name
        table_name=$(echo "$table_name" | sed 's/[[:space:]]*$//')
        # Capitalize the table name
        table_name=$(echo "$table_name" | tr '[:lower:]' '[:upper:]')
        # Check that the user is connected to a database
        if [ "$database" == "" ]
        then
            echo "You are not Connected to a Database!!"
        elif [ -f "$table_name.csv" ]
        then
            echo "There is already a table named $table_name  !!"     
        else
            createTable "${column[@]}"
        fi    
    else    
        echo "Could not parse the CREATE TABLE Command
Please use the suggested format 
#CREATE TABLE >name (column name/data type/constraint1-con2)
Check docs for more details!"    
    fi
}

<<COMMENT
    This function handles the logic behind removing a column from table.
    It takes in the the table name and column name and do all the work!
COMMENT
dropColumn(){
    awk -v header="$2" 'BEGIN{ 
	FS=","
	OFS=","
	field=0
	}		
	{
	if(NR==1){
		i=1
	while(i<=NF){
	if($i == header){
	field=i
	}
		i++	
	}
	}
	if(field!=0){
        for (i=field; i<=NF; i++){
            $i = $(i+1)
        }
	print substr($0, 1, length($0)-1)
	}
	else{
		print $0		
	}
	}
	END{
	}' "$1.csv" > "$1 Temp.csv"
    mv "$1 Temp.csv" "$1.csv"
}

<<COMMENT
    This function handles the logic behind parsing the drop column command.
    It takes in the a user command and do all the work!
COMMENT
parseDropC(){
    # Lets get the attributes of the commands: it would gp something
    # Like this => table name, column name
    attributes=$(echo "$1" | sed 's/^[ ]*drop[ ]*column[ ]*//I')
    # Lets split it into [table name, column name]
    IFS="," read -a arguments <<< "$attributes"
    # Trim any left/right spaces from the table/column name
    # PS: We don't need to check that we got the formats we are expecting
    # Because the ReGex assure we do!
    table_name=$(echo "${arguments[0]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    column_name=$(echo "${arguments[1]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    # Capitalize Table Name and column name
    table_name=$(echo "$table_name" | tr '[:lower:]' '[:upper:]')
    column_name=$(echo "$column_name" | tr '[:lower:]' '[:upper:]')
    # Check that the user is connected to a database
    if [ "$database" == "" ]
    then
        echo "You are not Connected to a Database!!"
    elif [ ! -f "$table_name.csv" ]
    # Check that the database have such table
    then
        echo "There is no table named $table_name  in $database !!"      
    else
        # All is good and we are ready to #TRY# and delete the column from the table
        echo "This action can't be reverted are you sure you wanna proceed?!"
        select option in Yes No
        do
            case $option in
            "Yes")
                echo "Deleting column: $column_name from $table_name ..."
                # Delete the column IF EXISTS
                header=$(head -n 1 "$table_name.csv")
                exists=$(echo "$header" | sed -n -E "/^($column_name,)|(,$column_name,)|(,$column_name)$|^($column_name)$/p")
                if [ "$exists" == "" ]
                then
                    echo "There is no column named $column_name in $table_name"
                else    
                    dropColumn "$table_name" "$column_name"
                    echo "$column_name successfully deleted from $table_name"
                fi        
                break
                ;;
            "No")
                break
                ;;
            *)
                echo "Invalid Option, Operation terminated for data security"
                break
            esac              
        done
    fi  
}

<<COMMENT
    This function handles the logic behind adding a column to a table.
    It takes in the a user command and do all the work!
COMMENT
addColumn(){
    echo tamp
}

<<COMMENT
    This function handles the logic behind parsing the add column command.
    It takes in the a user command and do all the work!
COMMENT
parseAddC(){
    echo temp
}

            ### HERE WE WOULD COMPLETE THE COMMAND PARSING ###
# This ReGex is too complex to be illustrated in a comment, check the docs.
if grep -i -E -q '^[ ]*create[ ]+table[ ]+[a-zA-Z][a-zA-Z0-9@#$%_ -]+[ ]*\(([ ]*[a-zA-Z][a-zA-Z0-9@#$%_ -]+[ ]*\/[ ]*(int|string)[ ]*(\/[ ]*(pk|unique|required)[ ]*)?,)+\)[ ]*$' <<< "${1:0:-1},${1:${#1}-1}"
    then
        # Parse a create table command
        parseCreate "$1"
elif grep -i -E -q '^[ ]*drop[ ]+table[ ]+.*$' <<< "$1"
then
    table_name=$(echo "$1" | sed 's/^[ ]*drop[ ]*table[ ]*//I')
    # Trim any left/right spaces from the table name
    table_name=$(echo "$table_name" | sed 's/[[:space:]]*$//')
    # Capitalize Table Name
    table_name=$(echo "$table_name" | tr '[:lower:]' '[:upper:]')
    # Check that the user is connected to a database
    if [ "$database" == "" ]
    then
        echo "You are not Connected to a Database!!"
    elif [ ! -f "$table_name.csv" ]
    # Check that the database have such table
    then
        echo "There is no table named $table_name in $database !!"     
    else
        echo "This action can't be reverted are you sure you wanna proceed?!"
        select option in Yes No
        do
            case $option in
            "Yes")
                echo "Deleting table: $table_name ..."
                # Delete the table's file
                # Remove the table's file from the database
                rm "$table_name.csv"
                echo "$table_name is deleted!"
                break
                ;;
            "No")
                break
                ;;
            *)
                echo "Invalid Option, Operation terminated for data security"
                break
            esac              
        done
    fi        
elif grep -i -E -q '^[ ]*truncate[ ]+table[ ]+.*$' <<< "$1"
then
    table_name=$(echo "$1" | sed 's/^[ ]*truncate[ ]*table[ ]*//I')
    # Trim any left/right spaces from the table name
    table_name=$(echo "$table_name" | sed 's/[[:space:]]*$//')
    # Capitalize Table Name
    table_name=$(echo "$table_name" | tr '[:lower:]' '[:upper:]')
    # Check that the user is connected to a database
    if [ "$database" == "" ]
    then
        echo "You are not Connected to a Database!!"
    elif [ ! -f "$table_name.csv" ]
    # Check that the database have such table
    then
        echo "There is no table named $table_name  in $database !!"     
    else
        echo "This action can't be reverted are you sure you wanna proceed?!"
        select option in Yes No
        do
            case $option in
            "Yes")
                echo "Truncating table: $table_name ..."
                # Delete the table's data
                sed -i '5,$d' "$table_name.csv"
                echo "$table_name is truncated!"
                break
                ;;
            "No")
                break
                ;;
            *)
                echo "Invalid Option, Operation terminated for data security"
                break
            esac              
        done
    fi         
elif grep -i -E -q '^[ ]*list[ ]+tables[ ]*$' <<< "$1" 
    then
        # In case the user is not connected to any databases
        if [ "$database" = "" ]
        then
            echo "You are not Connected to any Databases !!"
        else
            echo "$database Tables:"
            ls -p | grep -v / | sed 's/.csv$//'
        fi  
elif grep -i -E -q '^[ ]*drop[ ]+column[ ]+[^,]+,[^,]+$' <<< "$1"
then
    parseDropC "$1"   
else
# It is more likely a table Command or an Invalid command, lets handle those in a separate file
        if [ "$database" == "" ]
        # If the user is inside a database folder: go 2 steps back to access the script
        then
            . ../DMLCommands.bash "$1"  
        else
        # Otherwise a single step back is good
            . ../../DMLCommands.bash "$1"  
        fi    
fi
