FROM ghcr.io/prefix-dev/pixi:0.70.1 AS build

WORKDIR /app

COPY pixi.toml pixi.lock* /app/

RUN pixi install --locked || pixi install

RUN pixi shell-hook -e default -s bash > /shell-hook \
    && echo "#!/bin/bash" > /app/entrypoint.sh \
    && cat /shell-hook >> /app/entrypoint.sh \
    && echo 'exec "$@"' >> /app/entrypoint.sh

FROM ubuntu:24.04 AS production

WORKDIR /app

COPY --from=build /app/.pixi/env/default /app/.pixi/envs/default
COPY --from=build --chmod=0755 /app/entrypoint.sh /app/entrypoint.sh

COPY . /app

EXPOSE 8888

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--no-browser", "--allow-root", "--IdentityProvider.token="]
