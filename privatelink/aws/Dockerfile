FROM confluentinc/cp-kafkacat:6.0.0
USER root
RUN yum clean all
RUN yum install -y bind-utils openssl unzip findutils
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && ./aws/install

USER appuser
WORKDIR /home/appuser
COPY --chown=appuser debug-connectivity.sh /usr/local/bin/
COPY --chown=appuser dns-endpoints.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/debug-connectivity.sh
RUN chmod +x /usr/local/bin/dns-endpoints.sh
CMD sh