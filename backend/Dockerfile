# Start from the base image
FROM ghcr.io/gleam-lang/gleam:v1.11.1-erlang-alpine

# Install the C compiler and other essential build tools
RUN apk add --no-cache build-base

# Add project code
WORKDIR /app/
COPY . ./

# Compile the Gleam application
RUN gleam build

# Run the application (as the default root user)
CMD ["gleam", "run"]
