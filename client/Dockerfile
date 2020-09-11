FROM python:3.8.5-alpine3.12

WORKDIR /opt
RUN apk add --no-cache \
    git
RUN git clone https://github.com/benjamingorman/kagtcprlib.git
WORKDIR /opt/kagtcprlib
RUN python3 setup.py install

WORKDIR /app
COPY requirements.txt ./
RUN pip3 install -r requirements.txt

COPY *.py /app/
COPY config.toml /app/

ENTRYPOINT ["python3", "client.py"]
CMD ["config.toml", "--api-url", "http://localhost:5000"]
