FROM registry.redhat.io/rhel9/python-312

USER 0
WORKDIR /app

COPY --chown=1001:0 requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY --chown=1001:0 app.py .

RUN openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost" && \
    chmod 644 cert.pem && \
    chmod 600 key.pem && \
    chown 1001:0 *.pem

USER 1001
EXPOSE 8443

CMD ["python", "-m", "flask", "run", "--cert=cert.pem", "--key=key.pem", "--host=0.0.0.0", "--port=8443"]
