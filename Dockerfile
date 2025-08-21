# Use stable Debian base
FROM debian:stable

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV REGION=ap
# NGROK_TOKEN should be set in Railway environment variables at runtime

# Install required packages
RUN apt update && apt upgrade -y && apt install -y \
    openssh-server wget unzip vim curl python3 \
    && rm -rf /var/lib/apt/lists/*

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

# Expose ports
EXPOSE 22 4040 80 443

# Run the startup script
CMD ["/bin/bash", "/openssh.sh"]
