package SampleMojoApp::Util;

use Mojo::Base -strict;
use Exporter 'import';
use Scalar::Util qw/reftype looks_like_number/;
use Data::UUID::MT;
use Data::Printer ();
use feature qw/signatures/;
no warnings qw(experimental::signatures);

my $ug; # must be defined before BEGIN block that use it
#sub grep_any {};
BEGIN {
    $ug = Data::UUID::MT->new( version => 4 );
}

# these will be exported automatically,
# or by using the ':DEFAULT' tag when using the module.
our @EXPORT = qw (
    Dumper
	h2s
    h2snum
    uuid_hex
);

sub Dumper {
    my $raw = Data::Printer::np $_[0];
    $raw =~ s/^/# /smg;  # add '# ' at beginning of lines
    return $raw;
}

# hash to string for logfmt
sub h2s(%msg) {
    my $out = '';
    while ( my ($key, $val) = each %msg) {
        $out .= " $key=";

        # add quotes if contain space
        $out .= (index($val, ' ') >= 0) ? ('"'. $val .'"')  : $val;

    }
    return $out;
}

sub h2snum(%msg) {
    my $out = '';
    while ( my ($key, $val) = each %msg) {
        $out .= " $key=";

        # add quotes if not number
        $out .= looks_like_number($val) ? $val : ('"'.$val.'"');
    }
    return $out;
}

sub uuid_hex {
    #state $ug = Data::UUID::MT->new( version => 4 );
    return unpack("H*", $ug->create);
}

1;
