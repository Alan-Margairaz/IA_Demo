run:
	love src/

love:
	mkdir -p dist
	cd src && zip -r ../dist/Exemple-FSM.love .

js: love
	love.js -c --title="Exemple FSM" ./dist/Exemple-FSM.love ./dist/js
