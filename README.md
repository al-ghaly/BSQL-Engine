# B-SQL
      Welcome to Bash-SQL, a simple Database Management System implemented in Bash.


## Overview
<span style="font-size:larger;">This project provides a basic DBMS functionality, supporting various commands varying from DCL and DDL to DML. It's designed to be a lightweight solution for simple database operations within a Bash environment.</span>

<br>

# Supported Commands
##  DCL - System Commands (Data Control Language)
<span style="font-size:larger;">This is a subset of SQL responsible for defining and managing access and permissions to SYSTEM objects like (users, schemas, databases, tables, ... ).<br></span>

### 1. Register User
>To Create a new user 
- Format: `REGISTER USER username password`
- Example: `REGISTER USER Ghaly 12345`
- Complexity: *O(U)*
   - **U**: is the number of users in the system


### 2. Delete User
>To delete your account from the system<br> You have to be logged in and not connected to a database
- Format: `DELETE USER`
- Complexity: *O(U)*

### 3. Login User
>To log into the system
- Format: `LOGIN USER username password`
- Example: `LOGIN USER Ghaly 12345`
- Complexity: *O(U)*

### 4. Logout
>To log out from the system
- Format: `LOGOUT`
- Complexity: *O(1)*

### 5. Create Database

- Format: `CREATE DATABASE database`
- Example: `CREATE DATABASE COLLEGE`
- Complexity: *O(1)*

### 6. Drop Database

- Format: `DROP DATABASE database`
- Example: `DROP DATABASE COLLEGE`
- Complexity: *O(1)*

### 7. Connect to a Database

- Format: `CONNECT DATABASE database`
- Example: `CONNECT DATABASE COLLEGE`
- Complexity: *O(1)*

### 8. Disconnect
>To disconnect from a database
- Format: `DISCONNECT`
- Complexity: *O(1)*

### 9. List Databases
>To list all the databases in the system
- Format: `LIST DATABASES`
- Complexity: *O(1)*

##  DDL - Database Commands (Data Definition Language)
<span style="font-size:larger;">This is a subset of SQL used for defining and managing the structure of a database, including creating, modifying, and deleting database objects like tables.<br>You need to be connected to a database to run these commands</span>

### 1. Create Table

- Format: `CREATE TABLE table (column/data type/constraint, ... )`
- Example: `CREATE TABLE STUDENTS (ID/INT/PK, NAME/STRING/REQUIRED, CITY/STRING, AGE/INT, EMAIL/STRING/UINIQUE)`
- Complexity: *O(C)*
   - **C**: is the number of columns in the table
- Constraints
   - Primary Key (PK)
   - Foreign Key (FK) Still Yet to be Integrated
   - Unique
   - Required

### 2. Drop Table

- Format: `DROP TABLE table`
- Example: `DROP TABLE STUDENTS`
- Complexity: *O(1)*

### 3. Truncate Table

- Format: `TRUNCATE TABLE table`
- Example: `TRUNCATE TABLE STUDENTS`
- Complexity: *O(1)*

### 4. Add Column

- Still Yet To be Implemented

### 5. Drop Column

- Format: `DROP COLUMN table, column`
- Example: `DROP COLUMN STUDENTS, AGE`
- Complexity: *O(N)*
   - N: is the number of rows in the table

### 6. List Tables
>To list all the tables in the database
- Format: `LIST TABLES`
- Complexity: *O(1)*

##  DML - Table Commands (Data Manipulation Language)
<span style="font-size:larger;">This is a subset of SQL used for interacting with and manipulating data stored in a database.<br>
You need to be connected to a database to run these commands</span>

### 1. Insert Command

- Format: `INSET INTO table VALUES [COLUMN1=value, ...]`
- Example: `INSERT INTO STUDENTS VALUES  [ID=1, NAME=Ali, CITY= Cairo, AGE=24]`
- Complexity: *O(N.C)*

### 2. Delete Command

- Format: `DELETE FROM table WHERE COLUMN1=(value)`
- Example: `DELETE FROM STUDENTS WHERE NAME=(Aly)`
- Complexity: *O(N)*

### 3. Update Command

- Format: `UPDATE table SET [COLUMN1=value, ...] WHERE COLUMN=(value)`
- Example: `UPDATE STUDENTS SET [AGE=25, NAME=Samy, CITY= ] WHERE NAME = (Bassam)`
   `UPDATE STUDENTS SET [CITY=Cairo]`
- Complexity: *O(N.C)*

### 4. Select Command

- Format: `SELECT COLUMN1, COLUMN2, ... FROM table WHERE COLUMN=(value)`
- Example: `SELECT NAME, AGE, ID FROM STUDENTS WHERE NAME = (Aly)` 
`SELECT * FROM STUDENTS`
- Complexity: *O(N)*

<br><br>
# Usage
<span style="font-size:larger;">To use Bash DBMS, follow these steps:</span>


## Clone the repository:
   ```bash
   git clone https://github.com/al-ghaly/BSQL-Engine.git
   cd BSQL-Engine
   ```

## Run the file and start interacting with the command line App:
   ```bash
   ./BSQL.bash
   ```

## Alternatively you can write your B-SQL commands in a file and then run it as a script:
   ```bash
   ./BSQL.bash >filename
   ```
Example
   ```
   ./BSQL.bash script
   ```
In the script file write your BSQL Commands each command in a single line 
and you can use "#" For comments.
