SCHEMASPY_JAR=schemaspy-6.2.4.jar

define RUN_CMD
	echo $(1); \
	$(1)
endef

define OPEN_CMD
	open analysis/index.html
endef

.PHONY: sqlite
sqlite:
	java -jar $(SCHEMASPY_JAR) -t sqlite.properties -s dumy -db ../db/development.sqlite3 -u dumy -cat dumy
	$(call OPEN_CMD)

.PHONY: docker-sqlite
docker-sqlite:
	docker compose run --rm schemaspy java -jar $(SCHEMASPY_JAR) -t sqlite.properties -s dumy -db ../db/development.sqlite3 -u dumy -cat dumy
	$(call OPEN_CMD)

.PHONY: mariadb
mariadb:
	@bash -c '\
		set -e; \
		set -a; source ../.env; set +a; \
		CMD="java -jar $(SCHEMASPY_JAR) -t mariadb -host 127.0.0.1 -port $$MYSQL_PORT -s $$DB_NAME_DEVELOPMENT -db $$DB_NAME_DEVELOPMENT -u $$MYSQL_USER -p $$MYSQL_PASSWORD"; \
		$(call RUN_CMD,$$CMD) \
	'
	$(call OPEN_CMD)

.PHONY: mysql
mysql:
	@bash -c '\
		set -e; \
		set -a; source ../.env; set +a; \
		CMD="java -jar $(SCHEMASPY_JAR) -t mysql -host 127.0.0.1 -port $$MYSQL_PORT -s $$DB_NAME_DEVELOPMENT -db $$DB_NAME_DEVELOPMENT -u $$MYSQL_USER -p $$MYSQL_PASSWORD"; \
		$(call RUN_CMD,$$CMD) \
	'
	$(call OPEN_CMD)

.PHONY: docker-mysql
docker-mysql:
	@bash -c '\
		set -e; \
		set -a; source ../.env; set +a; \
		CMD="docker compose run --rm schemaspy java -jar $(SCHEMASPY_JAR) -t mysql -host mysql -port 3306 -s $$DB_NAME_DEVELOPMENT -db $$DB_NAME_DEVELOPMENT -u $$MYSQL_USER -p $$MYSQL_PASSWORD"; \
		$(call RUN_CMD,$$CMD) \
	'
	$(call OPEN_CMD)

.PHONY: pg
pg:
	@bash -c '\
		set -e; \
		set -a; source ../.env; set +a; \
		CMD="java -jar $(SCHEMASPY_JAR) -t pgsql -host 127.0.0.1 -port $$POSTGRES_PORT -s public -db $$DB_NAME_DEVELOPMENT -u $$POSTGRES_USER -p $$POSTGRES_PASSWORD"; \
		$(call RUN_CMD,$$CMD) \
	'
	$(call OPEN_CMD)

.PHONY: docker-pg
docker-pg:
	@bash -c '\
		set -e; \
		set -a; source ../.env; set +a; \
		CMD="docker compose run --rm schemaspy java -jar $(SCHEMASPY_JAR) -t pgsql -host pg -port 5432 -s public -db $$DB_NAME_DEVELOPMENT -u $$POSTGRES_USER -p $$POSTGRES_PASSWORD"; \
		$(call RUN_CMD,$$CMD) \
	'
	$(call OPEN_CMD)
