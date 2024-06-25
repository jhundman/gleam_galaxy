FROM ghcr.io/gleam-lang/gleam:v1.2.1-erlang-alpine

# Add project code
COPY . /build/

# Compile the project
RUN cd /build \
    && gleam export erlang-shipment \
    && mv build/erlang-shipment /app

# Run the server
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
