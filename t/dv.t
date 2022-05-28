# test DV plugin
use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('SampleMojoApp');

subtest 'app startup' => sub {
    $t->get_ok('/')->status_is(200)->content_like(qr/Sample Mojolicious App/i);
};

subtest 'validators simple' => sub {
    $t->get_ok('/dv/dv1')
        ->status_is(400)
        ->content_like(qr/missing param/);

    $t->get_ok('/dv/dv1' => form => {ball => 'whaever'})
        ->status_is(400)
        ->content_like(qr/invalid param/);

    $t->get_ok('/dv/dv1' => form => {foo => 'ball'})
        ->status_is(400)
        ->content_like(qr/invalid param/);

    $t->get_ok('/dv/dv1' => form => {foo => 'bar'})
        ->status_is(200)
        ->content_like(qr/OK.+=bar/);

    $t->get_ok('/dv/dv1' => form => {foo => 'baz'})
        ->status_is(200)
        ->content_like(qr/OK.+=baz/);

    $t->get_ok('/dv/dv1' => form => {foo => 'token'})
        ->status_is(200)
        ->content_like(qr/OK.+=token/);
};

subtest 'validators mapped' => sub {
    $t->get_ok('/dv/dv2')
        ->status_is(400)
        ->content_like(qr/missing param/);

    $t->get_ok('/dv/dv2' => form => {ball => 'whaever'})
        ->status_is(400)
        ->content_like(qr/invalid param/);
        diag $t->tx->res->body;

    $t->get_ok('/dv/dv2' => form => {username => 'foo', password => 'topsecret'})
        ->status_is(400)
        ->content_like(qr/invalid param/);
        diag $t->tx->res->body;

    $t->get_ok('/dv/dv2' => form => {username => 'admin', password => 'topsecret'})
        ->status_is(200)
        ->content_like(qr/OK/);
};

subtest 'validation map from a helper' => sub {
    $t->get_ok('/dv/dv3')
        ->status_is(400)
        ->content_like(qr/missing param/);

    $t->get_ok('/dv/dv3' => form => {ball => 'whaever'})
        ->status_is(400)
        ->content_like(qr/invalid param/);
        diag $t->tx->res->body;

    $t->get_ok('/dv/dv3' => form => {username => 'foo', password => 'topsecret'})
        ->status_is(400)
        ->content_like(qr/invalid param/);
        diag $t->tx->res->body;

    $t->get_ok('/dv/dv3' => form => {username => 'admin', password => 'topsecret'})
        ->status_is(200)
        ->content_like(qr/OK/);

    $t->get_ok('/dv/dv3' => form => {username => 'mike', password => 'topsecret', email => 'mike@3open.org'})
        ->status_is(200)
        ->content_like(qr/OK/, 'with email param');

    $t->get_ok('/dv/dv3' => form => {username => 'mike', password => 'topsecret', email => 'mike@3open@org'})
        ->status_is(400)
        ->content_like(qr/invalid param/, 'with bad email');
        diag $t->tx->res->body;
};

subtest 'validation on json' => sub {
    $t->post_ok('/dv/dv.json')
        ->status_is(400)
        ->content_like(qr/invalid json/, 'no json at all');

    $t->post_ok('/dv/dv.json' => json => {ball => 'whaever'})
        ->status_is(400)
        ->content_like(qr/invalid json/, 'no param obj');
        diag $t->tx->res->body;

    $t->post_ok('/dv/dv.json' => json => {param => {foo => 999}})
        ->status_is(400)
        ->content_like(qr/invalid param/);
        diag $t->tx->res->body;

    $t->post_ok('/dv/dv.json' => json => {param => {username => 'foo', password => 'topsecret'}})
        ->status_is(400)
        ->content_like(qr/invalid param/);
        diag $t->tx->res->body;

    $t->post_ok('/dv/dv.json' => json => {param => {username => ' admin', password => 'topsecret'}})
        ->status_is(200)
        ->content_like(qr/OK/);
        diag $t->tx->res->body;

    $t->post_ok('/dv/dv.json' => json => {param => {username => 'mike', password => 'topsecret ', email => 'mike@3open.org'}})
        ->status_is(200)
        ->content_like(qr/OK/, 'with email param');
        diag $t->tx->res->body;

    $t->post_ok('/dv/dv.json' => json => {param => {username => 'mike', password => 'topsecret', email => 'mike@3open@org'}})
        ->status_is(400)
        ->content_like(qr/invalid param/, 'with bad email');
        diag $t->tx->res->body;
};

done_testing();
