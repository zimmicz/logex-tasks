FROM mcr.microsoft.com/mssql/server:latest
RUN mkdir -p /opt/mssql/data
RUN mkdir -p /opt/mssql/bin
COPY data/*.sql /opt/mssql/data/
COPY bin/import-data.sh /opt/mssql/bin
COPY bin/entrypoint.sh /opt/mssql/bin

WORKDIR /opt/mssql-tools/bin
CMD /bin/bash /opt/mssql/bin/entrypoint.sh

