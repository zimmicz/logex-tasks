run:
	docker run --rm --name=mssql -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=Zimmi1234' -p 1433:1433 -d mssql:latest
build:
	docker build -t mssql:latest .
stop:
	docker stop mssql
