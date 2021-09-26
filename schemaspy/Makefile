.PHONY: schemaspy
schemaspy:
	java -jar schemaspy-6.1.0.jar
	open analysis/index.html 

.PHONY: docker-schemaspy
docker-schemaspy:
	docker-compose run jdk java -jar schemaspy-6.1.0.jar -host db
	open analysis/index.html 

.PHONY: schemaspy-pg
schemaspy-pg:
	java -jar schemaspy-6.1.0.jar -configFile schemaspy.properties,pg
	open analysis/index.html 

.PHONY: docker-schemaspy-pg
docker-schemaspy-pg:
#	docker-compose run jdk java -jar schemaspy-6.1.0.jar -configFile schemaspy.properties,pg -host db
	docker-compose run jdk java -jar schemaspy-6.1.0.jar -configFile schemaspy.properties,pg -host pg
	open analysis/index.html 

.PHONY: schemaspy-sqlite3
schemaspy-sqlite3:
	java -jar schemaspy-6.1.0.jar -configFile schemaspy.properties,sqlite3
	open analysis/index.html 

.PHONY: docker-schemaspy-sqlite3
docker-schemaspy-sqlite3:
	docker-compose run jdk java -jar schemaspy-6.1.0.jar -configFile schemaspy.properties,sqlite3
	open analysis/index.html 
