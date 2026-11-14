FROM ubuntu:22.04
RUN apt-get update && apt-get install -y sudo findutils procps iproute2 cron \
    && rm -rf /var/lib/apt/lists/*
RUN useradd -m lowpriv \
    && echo "lowpriv ALL=(ALL) NOPASSWD: /usr/bin/find" > /etc/sudoers.d/90-lab \
    && chmod 440 /etc/sudoers.d/90-lab
COPY . /opt/linprivhints
USER lowpriv
WORKDIR /opt/linprivhints
ENTRYPOINT ["/opt/linprivhints/linprivhints.sh"]
