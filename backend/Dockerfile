# Start from the base image
FROM ghcr.io/gleam-lang/gleam:v1.11.1-erlang-alpine

# Install the C compiler and other essential build tools
RUN apk add --no-cache build-base

# Create a group and user to run as
RUN addgroup -S echogroup && adduser -S echouser -G echogroup

# Add project code
WORKDIR /app/
COPY . ./

# Compile the Gleam application
RUN gleam build

# The CMD will be run as root by default. We change ownership,
# then switch to the non-root user to execute the final command.
# This is a secure and common pattern.
CMD ["sh", "-c", "chown -R echouser:echogroup /data && su-exec echouser gleam run"]
