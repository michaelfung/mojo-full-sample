# Used by Github workflow to build an image for deployment
# Adapted to support multi-arch building

# Use the development image to compile dependencies
FROM ghcr.io/michaelfung/perl-devel:5.32.1 AS builder

RUN mkdir /staging
COPY cpanfile cpanfile.snapshot /staging/

WORKDIR /staging
RUN carton install --deployment && \
    rm -rf local/cache

# Pack compiled dependencies and App code with runtime image
FROM ghcr.io/michaelfung/perl-rt:5.32.1

RUN mkdir -p /app && \
    chown -R nobody /app

COPY --from=builder --chown=nobody:nogroup /staging/local /app/local
COPY --chown=nobody:nogroup sample_mojo_app.yml /app/
COPY --chown=nobody:nogroup public /app/public/
COPY --chown=nobody:nogroup script /app/script/
COPY --chown=nobody:nogroup templates /app/templates/
## folder changes the most placed at last
COPY --chown=nobody:nogroup lib /app/lib/
COPY --chown=nobody:nogroup t /app/t/
COPY --chown=nobody:nogroup *.sh /app/

# execution
USER nobody
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["/app/start.sh"]
