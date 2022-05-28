# demo data validation
package SampleMojoApp::Controller::DataV;
use Mojo::Base 'Mojolicious::Controller', -signatures, -async_await;
use Mojo::Promise;
use SampleMojoApp::Util;
use Feature::Compat::Try;


# ad-hoc param validation
sub demo_validator1 ($c) {
  my $v = $c->validation;
  return $c->render( status => 400, text => 'missing parameters' )
    unless $v->has_data;

  return $c->render( status => 400, text => 'invalid parameter' )
    unless $v->required('foo')->in(qw(bar baz token))->is_valid;
  my $tx = $c->render_later->tx;

  $c->render( text => 'OK. Got param value=' . $v->param('foo') );

}

# test build a validation table
sub demo_validator2 ($c) {
  my $v     = $c->validation;
  my %v_map = (
    username => sub ($v) {
      $v->required('username')->in(qw/mike admin root/);
    },
    password => sub ($v) {
      $v->required('password')->like(qr/[[:alnum:]]/)->size( 8, 50 );
    }
  );

  for (qw/username password/) {
    $v_map{$_}->($v);
  }

  return $c->render( status => 400, text => 'missing parameters' )
    unless $v->has_data;

  return $c->render(
    status => 400,
    text   => 'invalid parameters: ' . Dumper $v->failed
  ) if $v->has_error;

  $c->render( text => 'OK' );
}

# demo use of helper validation table
sub demo_validator3 ($c) {
  my $v = $c->validation;
  for (qw/username password/) {
    $c->dv_map->{$_}->($v);
  }
  for (qw/email/) {
    $c->dv_map->{$_}->($v, 0);
  }
  return $c->render( status => 400, text => 'missing parameters' )
    unless $v->has_data;

  return $c->render(
    status => 400,
    text   => 'invalid parameters: ' . Dumper $v->failed
  ) if $v->has_error;

  $c->render( text => 'OK' );
}

# demo validate param in json
# expect {"param":{ ... }}
sub demo_validate_json ($c) {
  my $v = $c->validation;
  my $req_json;

  # inject posted json params to validation
  return $c->render( status => 400, text => 'invalid json parameter' )
    unless ( $c->req->json('/param') );
  $v->input( $c->req->json->{param} );

  for (qw/username password/) {
    $c->dv_map->{$_}->($v);
  }
  for (qw/email/) {
    $c->dv_map->{$_}->($v, 0);
  }

  return $c->render(
    status => 400,
    text   => 'invalid parameters: ' . Dumper $v->failed
  ) if $v->has_error;

  my $params = $v->output;

  $c->render( text => sprintf('OK. Hello %s with email %s', $params->{username}, $v->param('email')));
}

1;
