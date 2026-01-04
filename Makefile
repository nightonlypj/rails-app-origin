define IS_IN_DOCKER
	test -f /.dockerenv
endef

define CHECK_OUTSIDE_DOCKER
	@if $(IS_IN_DOCKER); then \
		echo "[ERROR] Cannot be executed inside Docker."; \
		exit 1; \
	fi
endef

define IS_APP_RUNNING
	docker compose ps --status running app --services 2>/dev/null | grep -q '^app$$'
endef

define CHECK_APP_RUNNING
	@if $(IS_APP_RUNNING); then \
		echo "[ERROR] Docker app is running."; \
		exit 1; \
	fi
endef

define RUN_CMD
	echo $(1); \
	$(1)
endef

.PHONY: up up-all
up:
	$(call CHECK_OUTSIDE_DOCKER)
	docker compose up --build
up-all: up

.PHONY: up-d up-all-d
up-d:
	$(call CHECK_OUTSIDE_DOCKER)
	docker compose up -d --build
up-all-d: up-d

.PHONY: up-base
up-base:
	$(call CHECK_OUTSIDE_DOCKER)
	docker compose up mysql mariadb pg schemaspy --build

.PHONY: up-base-d
up-base-d:
	$(call CHECK_OUTSIDE_DOCKER)
	docker compose up mysql mariadb pg schemaspy -d --build

.PHONY: down
down:
	$(call CHECK_OUTSIDE_DOCKER)
	docker compose down

.PHONY: bash
bash:
	$(call CHECK_OUTSIDE_DOCKER)
	docker compose exec app bash

.PHONY: bash-new
bash-new:
	$(call CHECK_OUTSIDE_DOCKER)
	docker compose run --rm app bash

.PHONY: bundle install
bundle:
	@CMD="bundle install -j4 --retry=3"; \
	if $(IS_IN_DOCKER) || ! $(IS_APP_RUNNING); then $(call RUN_CMD,$$CMD); else $(call RUN_CMD,docker compose exec app $$CMD); fi
install: bundle

.PHONY: db
db:
	@echo "==== db_local"
	@$(MAKE) db_local
	@echo "==== db_test"
	@$(MAKE) db_test
	@echo "==== db_seed"
	@$(MAKE) db_seed

.PHONY: db_local
db_local:
	@CMD="bundle exec rails db:create db:migrate"; \
	if $(IS_IN_DOCKER) || ! $(IS_APP_RUNNING); then $(call RUN_CMD,$$CMD); else $(call RUN_CMD,docker compose exec app $$CMD); fi

.PHONY: db_test
db_test:
	@CMD="bundle exec rails db:create db:migrate RAILS_ENV=test"; \
	if $(IS_IN_DOCKER) || ! $(IS_APP_RUNNING); then $(call RUN_CMD,$$CMD); else $(call RUN_CMD,docker compose exec app $$CMD); fi

.PHONY: db_seed
db_seed:
	@CMD="bundle exec rails db:seed"; \
	if $(IS_IN_DOCKER) || ! $(IS_APP_RUNNING); then $(call RUN_CMD,$$CMD); else $(call RUN_CMD,docker compose exec app $$CMD); fi

.PHONY: reset
reset:
	@echo "==== reset_local"
	@$(MAKE) reset_local
	@echo "==== reset_test"
	@$(MAKE) reset_test
	@echo "==== db_seed"
	@$(MAKE) db_seed

.PHONY: reset_local
reset_local:
	@CMD="bundle exec rails db:migrate:reset"; \
	if $(IS_IN_DOCKER) || ! $(IS_APP_RUNNING); then $(call RUN_CMD,$$CMD); else $(call RUN_CMD,docker compose exec app $$CMD); fi

.PHONY: reset_test
reset_test:
	@CMD="bundle exec rails db:migrate:reset RAILS_ENV=test"; \
	if $(IS_IN_DOCKER) || ! $(IS_APP_RUNNING); then $(call RUN_CMD,$$CMD); else $(call RUN_CMD,docker compose exec app $$CMD); fi

.PHONY: c
c:
	@CMD="bundle exec rails c"; \
	if $(IS_IN_DOCKER) || ! $(IS_APP_RUNNING); then $(call RUN_CMD,$$CMD); else $(call RUN_CMD,docker compose exec app $$CMD); fi

.PHONY: cs
cs:
	@CMD="bundle exec rails c -s"; \
	if $(IS_IN_DOCKER) || ! $(IS_APP_RUNNING); then $(call RUN_CMD,$$CMD); else $(call RUN_CMD,docker compose exec app $$CMD); fi

.PHONY: s
s:
	$(call CHECK_OUTSIDE_DOCKER)
	$(call CHECK_APP_RUNNING)
	bundle exec rails s

.PHONY: jobs j
jobs:
	$(call CHECK_OUTSIDE_DOCKER)
	$(call CHECK_APP_RUNNING)
	rails jobs:work
j: jobs

.PHONY: routes r
routes:
	@CMD="bundle exec rails routes $(wordlist 2, $(words $(MAKECMDGOALS)), $(MAKECMDGOALS))"; \
	if $(IS_IN_DOCKER) || ! $(IS_APP_RUNNING); then $(call RUN_CMD,$$CMD); else $(call RUN_CMD,docker compose exec app $$CMD); fi
r: routes

.PHONY: rubocop lint l
rubocop:
	@CMD="bundle exec rubocop -a"; \
	if $(IS_IN_DOCKER) || ! $(IS_APP_RUNNING); then $(call RUN_CMD,$$CMD); else $(call RUN_CMD,docker compose exec app $$CMD); fi
lint: rubocop
l: rubocop

.PHONY: rspec
rspec:
	@CMD="bundle exec rspec $(wordlist 2, $(words $(MAKECMDGOALS)), $(MAKECMDGOALS))"; \
	if $(IS_IN_DOCKER) || ! $(IS_APP_RUNNING); then $(call RUN_CMD,$$CMD); else $(call RUN_CMD,docker compose exec app $$CMD); fi
	@if [ $(words $(MAKECMDGOALS)) -eq 1 ]; then $(call RUN_CMD,open coverage/index.html); fi

.PHONY: rspec-fail
rspec-fail:
	@CMD="bundle exec rspec --only-failures"; \
	if $(IS_IN_DOCKER) || ! $(IS_APP_RUNNING); then $(call RUN_CMD,$$CMD); else $(call RUN_CMD,docker compose exec app $$CMD); fi

.PHONY: brakeman b
brakeman:
	@CMD="bundle exec brakeman -Aqzw1 --no-pager"; \
	if $(IS_IN_DOCKER) || ! $(IS_APP_RUNNING); then $(call RUN_CMD,$$CMD); else $(call RUN_CMD,docker compose exec app $$CMD); fi
b: brakeman

.PHONY: brakeman-ignore b-ignore
brakeman-ignore:
	@CMD="bundle exec brakeman -I"; \
	if $(IS_IN_DOCKER) || ! $(IS_APP_RUNNING); then $(call RUN_CMD,$$CMD); else $(call RUN_CMD,docker compose exec app $$CMD); fi
b-ignore: brakeman-ignore

.PHONY: yard
yard:
	@CMD="bundle exec yard doc"; \
	if $(IS_IN_DOCKER) || ! $(IS_APP_RUNNING); then $(call RUN_CMD,$$CMD); else $(call RUN_CMD,docker compose exec app $$CMD); fi
	open doc/index.html

.PHONY: erd
erd:
	@CMD="bundle exec erd"; \
	if $(IS_IN_DOCKER) || ! $(IS_APP_RUNNING); then $(call RUN_CMD,$$CMD); else $(call RUN_CMD,docker compose exec app $$CMD); fi
	open db/erd.pdf

.PHONY: schemaspy-sqlite ss-sqlite
schemaspy-sqlite:
	$(call CHECK_OUTSIDE_DOCKER)
	$(MAKE) -C schemaspy sqlite
ss-sqlite: schemaspy-sqlite

.PHONY: schemaspy-docker-sqlite ssd-sqlite
schemaspy-docker-sqlite:
	$(call CHECK_OUTSIDE_DOCKER)
	$(MAKE) -C schemaspy docker-sqlite
ssd-sqlite: schemaspy-docker-sqlite

.PHONY: schemaspy-mysql ss-mysql
schemaspy-mysql:
	$(call CHECK_OUTSIDE_DOCKER)
	$(MAKE) -C schemaspy mysql
ss-mysql: schemaspy-mysql

.PHONY: schemaspy-docker-mysql ssd-mysql
schemaspy-docker-mysql:
	$(call CHECK_OUTSIDE_DOCKER)
	$(MAKE) -C schemaspy docker-mysql
ssd-mysql: schemaspy-docker-mysql

.PHONY: schemaspy-mariadb ss-mariadb
schemaspy-mariadb:
	$(call CHECK_OUTSIDE_DOCKER)
	$(MAKE) -C schemaspy mariadb
ss-mariadb: schemaspy-mariadb

.PHONY: schemaspy-docker-mariadb ssd-mariadb
schemaspy-docker-mariadb:
	$(call CHECK_OUTSIDE_DOCKER)
	$(MAKE) -C schemaspy docker-mariadb
ssd-mariadb: schemaspy-docker-mariadb

.PHONY: schemaspy-pg ss-pg
schemaspy-pg:
	$(call CHECK_OUTSIDE_DOCKER)
	$(MAKE) -C schemaspy pg
ss-pg: schemaspy-pg

.PHONY: schemaspy-docker-pg ssd-pg
schemaspy-docker-pg:
	$(call CHECK_OUTSIDE_DOCKER)
	$(MAKE) -C schemaspy docker-pg
ssd-pg: schemaspy-docker-pg
