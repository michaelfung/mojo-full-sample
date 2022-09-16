use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('SampleMojoApp');

subtest 'app startup' => sub {
    $t->get_ok('/')->status_is(200)->content_like(qr/Sample Mojolicious App/i);
    $t->get_ok('/version')->status_is(200);
};

subtest 'constants' => sub {
    use SampleMojoApp::Constants;
    ok $LOOKUP{foo}, 'constant ok';
    ok !$LOOKUP{baz}, 'undef constant ok';
};

# delibrately make this test fail
#subtest 'force fail' => sub {
#    $t->get_ok('/badpathnotexists')->status_is(200);
#};

done_testing();
