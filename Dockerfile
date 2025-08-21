FROM debian:stable

ARG NGROK_TOKEN
ARG REGION=ap
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt update && apt upgrade -y && apt install -y \
    openssh-server wget unzip vim curl python3

# Download and setup ngrok
RUN wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip -O /ngrok.zip \
    && unzip /ngrok.zip -d / \
    && chmod +x /ngrok

# Create SSH dir if it doesn't exist
RUN mkdir -p /run/sshd

# Setup startup script
RUN echo '#!/bin/bash' > /openssh.sh \
    && echo "/ngrok tcp --authtoken ${NGROK_TOKEN} --region ${REGION} 22 &" >> /openssh.sh \
    && echo "sleep 5" >> /openssh.sh \
    && echo "curl -s http://localhost:4040/api/tunnels | python3 -c 'import sys, json; print(\"ssh info:\\n\", \"ssh\", \"root@\" + json.load(sys.stdin)[\"tunnels\"][0][\"public_url\"][6:].replace(\":\", \" -p \"), \"\\nROOT Password:craxid\")' || echo '\nError: NGROK_TOKEN missing'" >> /openssh.sh \
    && echo "/usr/sbin/sshd -D" >> /openssh.sh \
    && echo "PermitRootLogin yes" >> /etc/ssh/sshd_config \
    && echo "root:craxid" | chpasswd \
    && chmod +x /openssh.sh

# Expose ports (if needed)
EXPOSE 80 443 4040 22

# Run the startup script
CMD ["/bin/bash", "/openssh.sh"]
