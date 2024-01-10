#!/bin/bash

# Print a Start Up Text to the user
echo "Application Has Started 
Enter your command in the command bar:
PS: type -commands- for a list of all available commands"

# Set initial value for the username
export username=""
# Set initial value for the connected database
export database=""
# The state of the aplication wheather it is active or not
active=true

<<COMMENT
    This function handles the Register logic.
    It takes in the username and password and do all the heavy work!
COMMENT
register(){
    # If the user has already logged in
    if [ "$username" != "" ]
    then
        echo "You are already logged in!!"
    #Validate the Username & Password using a ReGex
    elif ! grep -E -q '^[a-zA-Z][a-zA-Z0-9]{2,}$' <<< "$1"
    then
        echo "Invalid Username!!"
    elif ! grep -E -q '^[a-zA-Z0-9][^,]{2,}$' <<< "$2"
    then
        echo "Invalid Password!!"
    else
    # All is good so it is (almost) time to register a new user  
        if [ ! -f "users.csv" ]
        then
        # IF the file does not exist, create it and add the new user
            echo "$1,$2" > users.csv
        else
            password=$(sed -n "/^$1,/p" users.csv | cut -d',' -f2)
            
            # If the username already exists
            if [ "$password" != "" ]
            then
                echo "The username ($1) is taken!!"
            else    
                echo "Regsitering $1 ..."
                echo "$1,$2" >> users.csv
                username=$1
                echo "user: $1 Has been registered and logged into the system"
            fi    
        fi
    fi    
}

<<COMMENT
    This function handles the login logic.
    It takes in the username and password and do all the heavy work!
COMMENT
login(){
    # If the user has already logged in
    if [ "$username" != "" ]
    then
        echo "You are already logged in!!"
    elif [ ! -f "users.csv" ]
    then
    # IF the file does not exist, It means there are no users in the system
        echo "The username $1 does not exist!!"
    else
    # All is good so it is (almost) time to Log in the user  
        password=$(sed -n "/^$1,/p" users.csv | cut -d',' -f2)
            
        # If the username does not exist
        if [ "$password" = "" ]
        then
            echo "The username $1 does not exist!!"
        elif [ "$password" != "$2" ]
        then 
            echo "Wrong Password!!"
        else    
            echo "Logging $1 into the system..."
            username=$1
        fi
    fi    
}

<<COMMENT
    This function handles the logic behind deleting a user.
    It takes in the username and do all the work!
COMMENT
deleteUser(){
    # Can't delete a my account without being logged in
    if [ "$username" = "" ]
    then
        echo "You are not logged in!!"
    # can't find the users data file: How on earth did he log into the system
    # This is a fatal error that requires the use to let the db admin know!
    # Because someone has deleted the users.csv file, which leads to a data curruption
    elif [ ! -f "users.csv" ]
    then
        echo "A Fatal Error happened trying to access a sensitive file
You need to let the database admin know!!"
    else
    # Eveything is good and we are ready to delete the user
        echo "This action can't be reverted are you sure you wanna proceed?!"
        select option in Yes No
        do
            case $option in
            "Yes")
                echo "Deleting User: $username ..."
                # Delete the user's row from the users file
                sed -i "/^$username,/d" users.csv
                username=""
                echo "User is deleted, You are logged out!"
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
    This function handles the database connection logic.
    It takes in the database name and do all the work!
COMMENT
connect(){
    # Can't connect to a database without logging in
    if [ "$username" = "" ]
    then
        echo "You are not logged in!!"
    # If the user is connected to a database, he can't connect to another one!!
    elif [ "$database" != "" ]
    then
        echo "You are connected to $database!!
        Please Disconnect and try again."
    elif [ ! -d "./$1" ]
    # can't find a database with this name 
    then
        echo "There is no database named $1!!"
    else
    # Eveything is good and we are ready to connect to the database
        echo "connecting to $1 ..."
        # moving to the Database folder
        cd "$1"
        # Update the value of the currently connected database
        database=$1
    fi        
}

<<COMMENT
    This function handles the database creation logic.
    It takes in the a database name and do all the work!
COMMENT
createDB(){
    # Can't create a database without logging in
    if [ "$username" = "" ]
    then
        echo "You are not logged in!!"
    # If the user is connected to a database, he can't create a sub-database!!
    elif [ "$database" != "" ]
    then
        echo "You can't create a database while connected to another one!!
        Please Disconnect from $database and try again."
    # A database with this name already exists
    elif [ -d "./$1" ]
    then
        echo "There is already a database named $1!!"    
    #Validate the name of the database using a ReGex
    elif ! grep -E -q '^[a-zA-Z][a-zA-Z0-9]{2,}$' <<< "$1"
    then
        echo "Invalid database Name!!"
    # Eveything is good and we are ready to create the database
    else
        echo "Creating $1 database ..."
        # Make directory for the database and move to it
        mkdir "$1"
        cd "$1"
        # Update the value of the currently connected database
        database=$1
        echo "$1 database Created..."
    fi        
}

<<COMMENT
    This function handles the logic behind deleting a database.
    It takes in the database name and do all the work!
COMMENT
deleteDB(){
    # Can't delete a database without logging in
    if [ "$username" = "" ]
    then
        echo "You are not logged in!!"
    # If the user is connected to a database, he can't delete one!!
    elif [ "$database" != "" ]
    then
        echo "This is a system command that can't be executed while connected to a database.
Disconnect from $database and try again!"
    elif [ ! -d "./$1" ]
    # can't find a database with this name 
    then
        echo "There is no database named $1!!"
    else
    # Eveything is good and we are ready to delete the database
        echo "This action can't be reverted are you sure you wanna proceed?!"
        select option in Yes No
        do
            case $option in
            "Yes")
                echo "Deleting $1 ..."
                rm -r "$1"
                echo "$1 database Deleted"
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
    This function parses the user command and call the dedicated 
    method for dealing with each supported command.
COMMENT
parse(){
    # Split the command over spaces
    IFS=" " read -a arguments <<< "${1}"

    # We will use if instead of a case statement, as we need some complex 
    # pattern matching so we are in a bad need for ReGex support! 
    if grep -i -E -q '^[ ]*register[ ]+user[ ]+' <<< "$1"
    then  
        if [[ ${#arguments[@]} -eq 4 ]]
        # The user have entered 4 arguments as expected
        then   
            # Register the user
            register "${arguments[2]}" "${arguments[3]}"
        else    
            # In case the user entered too many arguments
            echo "Unsupported format for the register command,
please use the supported format as descriped in the documentation
        
#REGISTER USER >username >password
Note That the username and password can't have any spaces"
        fi        
    elif grep -i -E -q '^[ ]*exit[ ]*$' <<< "$1" 
    then
        echo "Application is Closing ..."  
        # Set the status of the application to not active  
        active=false
    elif grep -i -E -q '^[ ]*login[ ]+user[ ]+' <<< "$1" 
    then
        if [[ ${#arguments[@]} -eq 4 ]]
        # The user have entered 4 arguments as expected
        then   
            # Login the user
            login "${arguments[2]}" "${arguments[3]}"
        else    
            # In case the user entered too many arguments
            echo "Unsupported format for the LogIn command,
please use the supported format as descriped in the documentation

#LOGIN USER >username >password
Note That the username and password can't have any spaces"
        fi  
    elif grep -i -E -q '^[ ]*logout[ ]*$' <<< "$1" 
    then
        if [ "$username" = "" ]
        then
            echo "You are not logged in!!"
        elif [ "$database" = "" ]
        then
            echo "logging $username out ..."
            username=""
        else
            echo "logging $username out and disconnecting him from $database ..."
            username=""
            database=""
            cd ..
        fi        
    elif grep -i -E -q '^[ ]*connect[ ]+database[ ]+' <<< "$1" 
    then
        if [[ ${#arguments[@]} -eq 3 ]]
        # The user have entered 3 arguments as expected
        then   
            # Connect to the database 
            DBName="${arguments[2]}"
            DBName=$(echo "$DBName" | tr '[:lower:]' '[:upper:]')
            connect "$DBName"
        else    
            # In case the user entered too many arguments
            echo "Unsupported format for the connect command,
please use the supported format as descriped in the documentation

#CONNECT DATABASE >database
Note that the database name can't have any spaces"
        fi  
    elif grep -i -E -q '^[ ]*disconnect[ ]*$' <<< "$1" 
    then
        if [ "$database" = "" ]
        then
            echo "You are not connected to any databases!!"
        else
        echo "Disconnecting $username from $database ..."
            database=""
            cd ..
        fi        
    elif grep -i -E -q '^[ ]*create[ ]+database[ ]+' <<< "$1" 
    then
        if [[ ${#arguments[@]} -eq 3 ]]
        # The user have entered 3 arguments as expected
        then   
            # Create a database 
            DBName="${arguments[2]}"
            DBName=$(echo "$DBName" | tr '[:lower:]' '[:upper:]')
            createDB "$DBName"
        else    
            # In case the user entered too many arguments
            echo "Unsupported format for the create database command,
please use the supported format as descriped in the documentation

#CREATE DATABASE >database
Note That the database name can only contains letters and numbers, must start with a letter, and must have at least 3 characters"
        fi 
    elif grep -i -E -q '^[ ]*list[ ]+databases[ ]*$' <<< "$1" 
    then
        # In case the user did not log in
        if [ "$username" = "" ]
        then
            echo "Log in to access this command!!"
        elif [ "$database" != ""  ]
        # In case the user is connected to a database
        then
            echo "This is a system command that can't be executed while connected to a database.
Disconnect from $database and try again!"
        else
            echo "System Databases ..."
            ls -F | grep / | sed 's/\/$//'
        fi  
    elif grep -i -E -q '^[ ]*commands[ ]*$' <<< "$1"    
    then    
        # TODO list all supperted commands
        echo "Supported commands:
  ##SYSTEM COMMANDS:
    #REGISTER USER >username >password
    #LOGIN USER >username >password
    #LOGOUT
    #CREATE DATABASE >databaseName
    #CONNECT DATABASE >databaseName
    #DISCONNECT
    #LIST DATABASES
    #DELETE USER 
    #DELETE DATABASE >databaseName
    #COMMANDS
    #EXIT
  ##DATABASE COMMANDS:
    #CREATE TABLE >table name (column name/data type/constraint,.........)
    #DROP TABLE >table name
    #LIST TABLES
    #TRUNCATE TABLE >table name
  ##TABLE COMMANDS:
    #ADD COLUMN >table name, >column name
    #REMOVE COLUMN >table name, >column name
    #INSERT
    #UPDATE
    #DELETE FROM >table name WHERE >column name = (>value)
    #SELECT *|>column 1 name, column 2 name, .... FROM >table name WHERE >column name = (>value)"    
    elif grep -i -E -q '^[ ]*delete[ ]+database[ ]+' <<< "$1" 
    then 
        if [[ ${#arguments[@]} -eq 3 ]]
        # The user have entered 3 arguments as expected
        then   
            # try to delete the database 
            DBName="${arguments[2]}"
            DBName=$(echo "$DBName" | tr '[:lower:]' '[:upper:]')
            deleteDB "$DBName"
        else    
            # In case the user entered too many arguments
            echo "Unsupported format for the delete database command,
please use the supported format as descriped in the documentation

#DELETE DATABASE >database
Note that the database name can't have any spaces"
        fi  
    elif grep -i -E -q '^[ ]*delete[ ]+user' <<< "$1" 
    then 
        if [[ ${#arguments[@]} -eq 2 ]]
        # The user have entered 2 arguments as expected
        then   
            # try to delete the user 
            deleteUser
        else    
            # In case the user entered too many arguments
            echo "Unsupported format for the delete user command,
please use the supported format as descriped in the documentation

#DELETE USER"
        fi  
    else
    # It is more likely a Database Command or an Invalid command, lets handle those in a separate file
        if [ "$database" == "" ]
        # If the user is inside a database folder: go 2 steps back to access the script
        then
            . ../DBCommands.bash "$1"  
        else
        # Otherwise a single step back is good
            . ../../DBCommands.bash "$1"  
        fi    
    fi
}

##### APPLICATION STARTS HERE #####
# First check that the folder that holds the data exists
if [ ! -d "./data" ]
# We don't have any databases in the system
then
    # In case the user expects to connect to un existing data 
    # Let him know that this is not gonna happen!
    echo "You are starting fresh!!
Contact the database administrator in case of any missing data" 
    # Create A Folder to hold the app data
    mkdir data
fi
cd data

##TODO: REMOVE THOSE LINES AS THEY ARE TEMP FOR TEST
login "ghaly" "12345"  
connect "DB1"

# Start the application
while $active
do
<<COMMENT
    We have set IFS to null, to prevent the auto trimming for left
    and right spaces from the user-input.
    Actually this functionality would be of a great help for us, 
    but I prefer to control the behavior myself and don't depend on 
    any default behavior, because the default behavior may vary from
    a Linux version to the other, So I need to keep everything under my control.
COMMENT
    IFS= read -p "$username [$database] > " command
    # Parse the command and behave according to it
    parse "$command"
done



