# test the Demo controller unit
use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('SampleMojoApp');

# --------------- /demo/title -------------------
do {
    my $params = {
        site => 'https://httpbin.org/',
    };
    $t->get_ok('/demo/title'
        => form => $params
    )
    ->status_is(200)
    ->content_like(qr/httpbin/i);

    diag "body=". $t->tx->res->body;
};

do {
    my $params = {
        site => 'https://httpbin.org/status/500',
    };
    $t->get_ok('/demo/title'
        => form => $params
    )
    ->content_like(qr/error/i);
};

do {
    my $params = {
        site => 'http://badsite.lan/',
    };
    $t->get_ok('/demo/title'
        => form => $params
    )
    ->content_like(qr/error/i);
};

do {
    ok $t->app->check_call(2);
    ok $t->app->check_call(3);
    ok $t->app->check_call('foo');
};

# app level custom attr
do {
    ok $t->app->mcache->set('f','foo');
    is $t->app->mcache->get('f'), 'foo', 'app level attr ok';

    ok $t->app->cache2->set('b','bar');
    is $t->app->cache2->get('b'), 'bar', 'app level attr ok';
};

done_testing();
