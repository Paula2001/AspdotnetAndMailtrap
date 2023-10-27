## Endpoints for testing 


http://localhost:1111/mailserver

username = mailtrap
password = mailtrap
server = localhost


## Testing endpoint 

http://localhost:1111/WeatherForecast


## command to test

docker build -t mail .

docker run -p 1000:1000  -p 1111:80 -p 465:465 -p 143:143 -p 993:993 -p 1234:1234 mail
