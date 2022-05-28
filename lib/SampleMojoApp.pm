package SampleMojoApp;
#use EV;
use SampleMojoApp::Util;
use SampleMojoApp::Data;
use SampleMojoApp::Constants;
use Mojo::Base 'Mojolicious', -signatures;
use Scalar::Util qw/reftype blessed/;
use Data::Printer;

has mcache => sub ($self) {
  state $cache = Mojo::Cache->new;
};

# This method will run once at server start
sub startup ($app) {

  # Load configuration from config file
  $app->plugin('NotYAMLConfig');

  # setup logging
  $app->log->format(sub ($time, $level, @lines) {
      return "level=$level " . join(' ', @lines) . "\n";
  });

  # programmatic attrs
  for (qw/cache1 cache2/) {
    has $_ => sub($self) { Mojo::Cache->new; };
  }

  # Configure the application
  $app->log->debug(h2s(
    act => 'startup',
    msg => 'load app secrets',
    secrets => join(',', @{$app->config->{secrets}})
  ));


    $app->secrets($app->config->{secrets});
    $app->helper( 'apputil' => sub { state $apputil = SampleMojoApp::Util->new; } );
    $app->plugin('SampleMojoApp::Plugin::AppHelpers');
    $app->plugin('SampleMojoApp::Plugin::DV');

    # Router
    my $r = $app->routes;
    $r->get('/')->to('example#welcome');
    $r->get('/demo/mojo')->to('demo#mojo_p');
    $r->get('/demo/getip')->to('demo#getip');
    $r->get('/demo/getip2')->to('demo#getip_p');
    $r->get('/demo/uuid')->to('demo#get_uuid');
    $r->get('/demo/title')->to('demo#get_title');
    $r->get('/demo/title2')->to('demo#get_title2');
    $r->get('/demo/titleold')->to('demo#get_title_old');
    $r->get('/demo/vpw')->to('demo#verify_pw');
    $r->get('/demo/hashpw')->to('demo#hash_pw');
    $r->get('/demo/readrow')->to('demo#read_row');
    $r->get('/demo/getdev')->to('demo#get_devices');
    $r->get('/demo/stash')->to('demo#test_stash');

    $r->get('/p7/title')->to('P7#title');

    $r->get('/dv/dv1')->to('DataV#demo_validator1');
    $r->get('/dv/dv2')->to('DataV#demo_validator2');
    $r->get('/dv/dv3')->to('DataV#demo_validator3');
    $r->post('/dv/dv.json')->to('DataV#demo_validate_json');

    $r->any('/al/parse')->to('ActionList#parse');
    $r->any('/al/parsemod')->to('ActionList#parse_mod');
    $r->any('/al/delay')->to('ActionList#parse_async');
    $r->any('/al/parsewait')->to('ActionList#parse_await');
    $r->any('/al/parsecan')->to('ActionList#parse_can');

    $r->any('/ls/largeset')->to('LargeDataSet#large_set');

    $app->log->info('act=startup', 'msg="### SampleMojoApp Started ###"');
    my $reactor = Mojo::IOLoop->singleton->reactor;

    $app->log->info('act=startup', 'msg="### Reactor :', (blessed $reactor));

}

1;
