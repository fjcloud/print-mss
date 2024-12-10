FROM registry.redhat.io/rhel9/python-312

USER 0
WORKDIR /app

RUN dnf install -y gcc python3-devel

COPY --chown=1001:0 requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY --chown=1001:0 app.py .

RUN openssl req -x509 -newkey rsa:4096 -keyout /app/key.pem -out /app/cert.pem -days 365 -nodes \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost" && \
    chmod 644 /app/cert.pem && \
    chmod 644 /app/key.pem && \
    chown -R 1001:0 /app

USER 1001
EXPOSE 8443

ENV FLASK_APP=app.py
CMD flask run --cert=/app/cert.pem --key=/app/key.pem --host=0.0.0.0 --port=8443
