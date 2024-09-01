:: This is a Windows script to build and run a Docker container with the server
:: Make sure that you have Docker/Docker Desktop installed and running
:: This script will stop any existing containers named `oldonyx` and will remove any images named `oldonyx-server`

:: This script must be started from the root folder of the build
:: This script will automatically mount your config/ and data/ folders into the container.
:: Please adjust the `docker run` command if you want to change this behavior.

@echo off

echo Removing old container and image

docker rm -f oldonyx 2>nul
docker image rm oldonyx-server 2>nul

echo Building docker image!

docker build -t oldonyx-server .
if errorlevel 1 (
	echo Failed to build the image
	pause
	exit
)


echo.
echo Image built, starting...

docker run -d -p 14076:14076 -v %cd%\config:/ss13config -v %cd%\data:/ss13data --name oldonyx oldonyx-server
if errorlevel 1 (
	echo Failed to start the container
	pause
	exit
)

echo.
echo Container successfully started!

pause