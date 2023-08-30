FROM ubuntu:22.04

RUN apt-get update && apt-get install cowsay -y && apt-get install netcat -y

CMD while true; do echo -e "HTTP/1.1 200 OK\n\n $(/usr/games/cowsay 'It works :)')" | nc -l -p 8080 -q 1; done

EXPOSE 8080
