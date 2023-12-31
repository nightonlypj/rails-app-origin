.DEFAULT_GOAL := schemaspy
.PHONY: schemaspy
schemaspy:
	java -jar schemaspy-6.2.4.jar -t mariadb
	open analysis/index.html

.PHONY: docker-schemaspy
docker-schemaspy:
	docker compose run jdk java -jar schemaspy-6.2.4.jar -t mariadb -host db
	open analysis/index.html

.PHONY: schemaspy-mysql
schemaspy-mysql:
	java -jar schemaspy-6.2.4.jar
	open analysis/index.html

.PHONY: docker-schemaspy-mysql
docker-schemaspy-mysql:
	docker compose run jdk java -jar schemaspy-6.2.4.jar -host db
	open analysis/index.html

.PHONY: schemaspy-pg
schemaspy-pg:
	java -jar schemaspy-6.2.4.jar -configFile schemaspy.properties,pg
	open analysis/index.html

.PHONY: docker-schemaspy-pg
docker-schemaspy-pg:
#	docker compose run jdk java -jar schemaspy-6.2.4.jar -configFile schemaspy.properties,pg -host db
	docker compose run jdk java -jar schemaspy-6.2.4.jar -configFile schemaspy.properties,pg -host pg
	open analysis/index.html

.PHONY: schemaspy-sqlite3
schemaspy-sqlite3:
	java -jar schemaspy-6.2.4.jar -configFile schemaspy.properties,sqlite3
	open analysis/index.html

.PHONY: docker-schemaspy-sqlite3
docker-schemaspy-sqlite3:
	docker compose run jdk java -jar schemaspy-6.2.4.jar -configFile schemaspy.properties,sqlite3
	open analysis/index.html
