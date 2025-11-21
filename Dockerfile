# Use stable Debian base
FROM debian:stable

ENV DEBIAN_FRONTEND=noninteractive
ENV REGION=ap

# Install required packages + docker client and compose plugin
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    openssh-server wget unzip vim curl python3 python3-pip \
    ca-certificates apt-transport-https gnupg lsb-release \
    docker.io docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Make sure docker group exists
RUN groupadd -f docker

# Download and setup ngrok
RUN wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip -O /ngrok.zip \
    && unzip /ngrok.zip -d / \
    && rm /ngrok.zip \
    && chmod +x /ngrok

# Create SSH directory
RUN mkdir -p /run/sshd

# Setup startup script
RUN echo '#!/bin/bash' > /openssh.sh \
    && echo '/ngrok tcp --authtoken "$NGROK_TOKEN" --region "$REGION" 22 &' >> /openssh.sh \
    && echo 'sleep 5' >> /openssh.sh \
    && echo 'curl -s http://localhost:4040/api/tunnels | python3 -c "import sys, json; data=json.load(sys.stdin); print(\"ssh info:\\nssh root@\" + data[\"tunnels\"][0][\"public_url\"][6:].replace(\":\", \" -p \") + \"\\nROOT Password:craxid\")" || echo "Error: NGROK_TOKEN missing"' >> /openssh.sh \
    && echo '/usr/sbin/sshd -D' >> /openssh.sh \
    && chmod +x /openssh.sh

# Configure SSH root login
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config \
    && echo "root:craxid" | chpasswd

# Add root to docker group (container runs as root anyway)
RUN usermod -aG docker root || true

# Expose ports
EXPOSE 22 4040 80 443

CMD ["/bin/bash", "/openssh.sh"]
