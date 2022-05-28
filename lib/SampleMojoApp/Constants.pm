package SampleMojoApp::Constants;

use Mojo::Base -strict;
use Exporter 'import';
use Readonly;

# these will be exported automatically,
# or by using the ':DEFAULT' tag when using the module.
our @EXPORT = qw (
    %LOG_LEVELS
    %LOG_NAMES
    %LOOKUP
);

Readonly our %LOG_LEVELS => (
        EMERGENCY => 0,
        ALERT     => 1,
        CRITICAL  => 2,
        ERROR     => 3,
        WARNING   => 4,
        NOTICE    => 5,
        INFO      => 6,
        DEBUG     => 7,
        TRACE     => 8,
    );

Readonly our %LOG_NAMES => reverse %LOG_LEVELS;

Readonly our %LOOKUP => { map { $_ => 1 } (qw/foo bar/) };

1;
