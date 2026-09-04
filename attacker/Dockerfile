FROM python:3.12-slim
WORKDIR /srv
COPY server.py /srv/server.py
COPY payloads /srv/payloads
EXPOSE 8000
CMD ["python3", "-u", "server.py"]
