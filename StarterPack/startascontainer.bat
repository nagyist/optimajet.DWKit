@echo OFF

docker compose up --build dwkit_starterpack
IF ERRORLEVEL 9009 goto :NO_DOCKER

pause

exit

:NO_DOCKER
echo Docker not found. Please install Docker to run this application
echo For more information visit https://docs.docker.com/install/
