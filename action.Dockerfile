FROM vapor/toolbox:18
WORKDIR /app
COPY entrypoint.sh .
ENTRYPOINT ["/app/entrypoint.sh"]
