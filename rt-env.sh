# setup runtime environment

export PERL5LIB=/app/lib:/app/local/lib/perl5
export PATH=$PATH:/app/local/bin
export MOJO_REACTOR=Mojo::Reactor::UV
export MOJO_MAX_MESSAGE_SIZE=65536   # default is 10485760 (10MB)
export MOJO_MODE=production
export MOJO_LOG_LEVEL=debug
