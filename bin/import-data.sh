#!/bin/bash
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P Zimmi1234 -d master -i /opt/mssql/data/interview_db_schema.sql
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P Zimmi1234 -d master -i /opt/mssql/data/generate_random_string.sql
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P Zimmi1234 -d master -i /opt/mssql/data/task1.sql
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P Zimmi1234 -d master -i /opt/mssql/data/task2.sql
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P Zimmi1234 -d master -i /opt/mssql/data/task3.sql
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P Zimmi1234 -d master -i /opt/mssql/data/task4.sql
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P Zimmi1234 -d master -i /opt/mssql/data/task5.sql
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P Zimmi1234 -d master -i /opt/mssql/data/task6.sql

