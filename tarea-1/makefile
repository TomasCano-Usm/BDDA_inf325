up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose down
	docker compose up -d

ps:
	docker compose ps

logs:
	docker compose logs -f

logs-mongo1:
	docker logs -f mongo1

logs-mongo2:
	docker logs -f mongo2

logs-mongo3:
	docker logs -f mongo3

shell1:
	docker exec -it mongo1 mongosh --port 30001

shell2:
	docker exec -it mongo2 mongosh --port 30002

shell3:
	docker exec -it mongo3 mongosh --port 30003

status:
	docker exec -it mongo1 mongosh --port 30001 --quiet --eval "rs.status()"

clean:
	docker compose down -v