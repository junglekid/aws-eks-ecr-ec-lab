FROM python:3.11-slim-bullseye

WORKDIR /usr/src/app

COPY . .

ARG USER=color_svc
ARG GROUP=color_svc

RUN apt-get update \
    && apt-get upgrade -y \
	&& rm -rf /var/lib/apt/lists/* \
    && useradd -rm -d /home/$USER -s /bin/bash $USER \
    && chown -R $USER:$GROUP /usr/src/app \
    && chmod +x ./entrypoint.sh

EXPOSE 8080

USER color_svc

ENV PATH $PATH:/home/$USER/.local/bin

RUN pip install --no-cache-dir -r requirements.txt

CMD ["sh", "entrypoint.sh" ]
