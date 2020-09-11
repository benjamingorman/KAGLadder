FROM python:3.8.5-alpine3.12

RUN apk add --no-cache \
    gcc \
    libc-dev \
    mariadb-dev

WORKDIR /app/server
COPY requirements.txt ./
RUN pip3 install -r requirements.txt

COPY static/ ./static
COPY templates/ ./templates
COPY *.py ./

WORKDIR /app
COPY default.cfg ./
COPY ip_whitelist.txt ./

ENTRYPOINT ["flask", "run", "--host=0.0.0.0"]
ENV FLASK_APP="/app/server/main.py"
ENV FLASK_ENV=development
ENV KAGLADDER_CONFIG_FILE="/app/default.cfg"
EXPOSE 5000
