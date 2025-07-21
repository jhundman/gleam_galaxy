# Start from the base image
FROM ghcr.io/gleam-lang/gleam:v1.11.1-erlang-alpine

# Install the C compiler and other essential build tools
# This must be done as root, before switching user
RUN apk add --no-cache build-base

# Create a group and user to run as
RUN addgroup -S echogroup && adduser -S echouser -G echogroup
USER echouser

# Add project code
WORKDIR /app/
COPY . ./

# Compile the Gleam application
RUN gleam build

# Run the application
CMD ["gleam", "run"]
