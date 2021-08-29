run:
	mix phx.server

tests:
	mix test

stop-prod:
	docker-compose stop

clean-prod:
	docker-compose rm -f

build-prod:
	$(MAKE) stop-prod
	$(MAKE) clean-prod
	docker-compose build app

run-prod:
	docker-compose up -d

migrate-prod:
	docker-compose run app bin/league eval "League.Release.migrate"

seed-prod:
	docker-compose run app bin/league eval "League.Release.seed"
