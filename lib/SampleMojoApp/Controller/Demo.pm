package SampleMojoApp::Controller::Demo;
use Mojo::Base 'Mojolicious::Controller', -signatures, -async_await;
use Mojo::Promise;
use SampleMojoApp::Util;

# callback style
sub getip ($self) {
  $self->render_later;
  $self->ua->get( 'https://httpbin.org/ip'
      => sub ( $ua, $tx ) {
      if ( $tx->result->is_success ) {
        $self->render( text => 'ip:' . $tx->res->json('/origin') );
      }
      else {
        $self->render( text => 'failed.' );
      }
    }
  );
}

# fetch data from ext website to demo Promise style

=for comment
# sample response body:
{
  "origin": "1.2.3.4"
}
=cut

sub getip_p ($self) {
  my $url = 'https://httpbin.org/ip';
  $self->log->debug( h2s(
      act => 'getip',
      url => $url
  ) );
  $self->render_later;

  $self->ua->get_p($url)
    ->then( sub ($tx) {
      my $ip = $tx->res->json('/origin') || 'unable to parse json result';
      $self->render( text => "httpbin reports my ip=$ip" );
    } )
    ->catch( sub ($err) {
      $self->log->error( h2s(
          act => 'getip',
          msg => 'connection error',
          err => $err,
      ) );
      $self->render( text => 'failed to get ip, error=' . $err );
    } )->wait;

}

sub get_uuid ($self) {

  # use sub returned result:
  my $out = sprintf( "<p>UUID1=%s\n</p>", $self->ah->getuuid );

  # use sub returned obj:
  $out .= sprintf( "<p>UUID2=%s\n</p>", $self->ah->ug->create_string() );

  # non sub namespacecc helper also works
  $out .= sprintf( "<p>UUID3=%s\n</p>", $self->top_get_uuid );

  $self->render( text => $out );
}

# old style
sub get_title_old ($c) {
  my $url = $c->param('site') || 'https://mojolicious.org/';
  $c->get_site_title($url)
    ->then( sub ($title) {
      $c->render( text => "title of web site=" . $title );
    } )->wait;
}

# new style with async_await
async sub get_title ($c) {
  $c->render_later;
  my $url   = $c->param('site') || $c->config->{url}{mojo_home};
  my $title = 'undefined';
  eval { $title = await $c->get_site_title($url); };
  if ($@) {
    $c->log->error( h2s(
        act => 'get_title',
        msg => 'failed to get title',
    ) );
    $c->render( text => "failed to get site title, error=" . $@ );
  }
  else {    # success
    $c->log->debug( h2s(
        act   => 'get_title',
        msg   => 'titles scrap ok, now calling render',
        site  => $url,
        title => $title
    ) );
    $c->render( text => "title of web site=" . $title );
  }
}

# demo to show multi await:
async sub get_title2 ($c) {
  $c->render_later;
  my $url   = $c->param('site') || 'https://mojolicious.org/';
  my $title = 'undefined';
  $title = await $c->get_site_title($url);
  $title .= '+' . await $c->get_site_title('https://httpbin.org/');
  $c->log->debug( h2s(
      act => 'get_title',
      msg => 'got titles, now calling render'
  ) );
  $c->render( text => "title of web site=" . $title );
}

# call to cpu intensive helper, will use mojo subprocess
async sub verify_pw ($c) {
  my $tx = $c->render_later->tx;
  my $pw = $c->param('pw') // '';

  my ($is_valid) = await $c->sec->verify_pw($pw);
  if ($is_valid) {
    $c->render( text => "OK, pw correct." );
  } else {
    $c->render( status => 403, text => "Wrong pw. ACCESS DENIED." );
  }
}

# create hash for pw
async sub hash_pw ($c) {
  my $tx = $c->render_later->tx;
  my $pw = $c->param('pw') // 'password';

  my ($pw_hash) = await $c->sec->hash_pw($pw);
  $c->render( text => $pw_hash );
}

async sub read_row ($c) {
  my $tx      = $c->render_later->tx;
  my $user_id = $c->param('user_id') // 160170;

  my ($doc) = await $c->db->readrow($user_id);
  $c->render( text => Dumper $doc);
}

async sub get_devices ($c) {
  my $tx     = $c->render_later->tx;
  my $hub_id = $c->param('hub_id') // 'em-002';

  my ($devices) = await $c->db->get_devices($hub_id);
  $c->render( text => Dumper $devices);
}

sub test_stash ($c) {
  my $foo = $c->param('foo') // 'no_foo';
  $c->stash( foo => $foo );
  $c->render( text => 'foo='.$c->stash->{foo});
}

1;
