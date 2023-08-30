#!/bin/bash
cat > "/var/lib/heavyai/odbc/odbcinst.ini" <<odbcinstiniEnd
[ODBC Drivers]
Snowflake=Installed
Snowflake=Installed


[Snowflake]
APILevel=1
ConnectFunctions=YYY
Description=Snowflake DSII
Driver=/usr/lib/snowflake/odbc/lib/libSnowflake.so
odbcinstiniEnd

cat > "/var/lib/heavyai/odbc/odbc.ini" <<odbciniEnd
[ODBC Drivers]
Snowflake=Installed
Snowflake=Installed


[Snowflake]
APILevel=1
ConnectFunctions=YYY
Description=Snowflake DSII
Driver=/usr/lib/snowflake/odbc/lib/libSnowflake.so

[snowflake]
Description=SnowflakeDB
Driver=Snowflake
Locale=en-US
SERVER=lqa26912.snowflakecomputing.com
PORT=443
SSL=on
ACCOUNT=lqa26912
odbciniEnd
