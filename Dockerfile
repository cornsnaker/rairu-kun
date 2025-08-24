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
    && echo 'set -e' >> /openssh.sh \
    && echo 'if [ -z "$NGROK_TOKEN" ]; then echo "Error: NGROK_TOKEN missing"; exit 1; fi' >> /openssh.sh \
    && echo '/ngrok tcp 22 --authtoken "$NGROK_TOKEN" --region "$REGION" > /ngrok.log 2>&1 &' >> /openssh.sh \
    && echo 'sleep 5' >> /openssh.sh \
    && echo 'curl -s http://localhost:4040/api/tunnels | python3 -c "import sys, json; \
try: \
    data=json.load(sys.stdin); \
    if \\"tunnels\\" in data and data[\\"tunnels\\"]: \
        print(\\"ssh info:\\nssh root@\\" + data[\\"tunnels\\"][0][\\"public_url\\"][6:].replace(\\":\\", \\" -p \\") + \\"\\nROOT Password:craxid\\"); \
    else: \
        print(\\"Error: No tunnels found\\") \
except Exception as e: \
    print(\\"Error: NGROK not running or bad NGROK_TOKEN\\")"' >> /openssh.sh \
    && echo '/usr/sbin/sshd -D' >> /openssh.sh \
    && chmod +x /openssh.sh

# Configure SSH root login
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config \
    && echo "root:craxid" | chpasswd

# Expose ports
EXPOSE 22 4040 80 443

# Run the startup script
CMD ["/bin/bash", "/openssh.sh"]
