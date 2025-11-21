FROM debian:stable

ENV DEBIAN_FRONTEND=noninteractive
ENV REGION=ap

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    openssh-server wget unzip vim curl python3 python3-pip \
    ca-certificates apt-transport-https gnupg lsb-release \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

# optionally install docker-compose (v1) via pip (uncomment if you want)
# RUN pip3 install docker-compose

RUN groupadd -f docker

RUN wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip -O /ngrok.zip \
    && unzip /ngrok.zip -d / \
    && rm /ngrok.zip \
    && chmod +x /ngrok

RUN mkdir -p /run/sshd

RUN echo '#!/bin/bash' > /openssh.sh \
    && echo '/ngrok tcp --authtoken "$NGROK_TOKEN" --region "$REGION" 22 &' >> /openssh.sh \
    && echo 'sleep 5' >> /openssh.sh \
    && echo 'curl -s http://localhost:4040/api/tunnels | python3 -c "import sys, json; data=json.load(sys.stdin); print(\"ssh info:\\nssh root@\" + data[\"tunnels\"][0][\"public_url\"][6:].replace(\":\", \" -p \") + \"\\nROOT Password:craxid\")" || echo "Error: NGROK_TOKEN missing"' >> /openssh.sh \
    && echo '/usr/sbin/sshd -D' >> /openssh.sh \
    && chmod +x /openssh.sh

RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config \
    && echo "root:craxid" | chpasswd

RUN usermod -aG docker root || true

EXPOSE 22 4040 80 443

CMD ["/bin/bash", "/openssh.sh"]
