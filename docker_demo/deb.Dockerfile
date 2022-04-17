FROM debian:stable

RUN apt-get update && apt-get install -y python3 python3-pip
RUN pip3 install flask
COPY server.py app.py

CMD python3 app.py