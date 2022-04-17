FROM python:buster

RUN pip install flask
COPY server.py app.py

CMD python app.py