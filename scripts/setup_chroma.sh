#!/bin/bash

# Create Chroma directory
sudo mkdir -p /home/chroma
sudo chown azureuser:azureuser /home/chroma

# Create docker-compose.yml
sudo tee /home/chroma/docker-compose.yml << 'EOF'
networks:
  chroma-net:
    driver: bridge

services:
  server:
    image: ghcr.io/chroma-core/chroma:0.4.15
    volumes:
      - index_data:/chroma/chroma
    ports:
      - 8000:8000
    networks:
      - chroma-net
    restart: unless-stopped
    environment:
      - ALLOW_RESET=TRUE
      - CHROMA_SERVER_HOST=0.0.0.0
      - CHROMA_SERVER_PORT=8000

volumes:
  index_data:
    driver: local
EOF

# Start Chroma
cd /home/chroma
sudo docker compose pull
sudo docker compose up -d 