# Used by Github workflow to build an image for deployment

FROM ghcr.io/michaelfung/perl-rt:5.32.1

# required perl libraries

# app code
RUN mkdir -p /app && \
    chown -R nobody /app

COPY --chown=nobody:nogroup local /app/local
COPY --chown=nobody:nogroup sample_mojo_app.yml /app/
COPY --chown=nobody:nogroup public /app/public/
COPY --chown=nobody:nogroup script /app/script/
COPY --chown=nobody:nogroup templates /app/templates/
# folder changes the most placed at last
COPY --chown=nobody:nogroup lib /app/lib/
COPY --chown=nobody:nogroup t /app/t/
COPY --chown=nobody:nogroup *.sh /app/

# execution
USER nobody
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["/app/start.sh"]
