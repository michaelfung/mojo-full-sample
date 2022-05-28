use Mojo::Base -strict, -async_await;
use Test::More;
use Test::Mojo;

use Mojolicious::Lite;

helper get_site_title => async sub {
  my ($c, $url) = @_;
  my $result = (await $c->ua->get_p($url))->result;
  die $result->message if $result->is_error;
  die 'unknown error condition' unless $result->is_success;
  return $result->dom->at('title')->text;
};

helper get_site_title2 => async sub {
  my ($c, $url) = @_;
  my ($tx, $err);
  eval { $tx = await $c->ua->get_p($url)->catch( sub { ($err) = @_; });};
  die "$err" if $err;
  my $result = $tx->result;
  die $result->message if $result->is_error;
  die 'unknown error condition' unless $result->is_success;
  return $result->dom->at('title')->text;
};

get '/title' => async sub {
  my ($c) = @_;
  $c->render_later;
  my $title ='failed to get title';
  eval { $title = await $c->get_site_title($c->param('url'))};
  $title .= ", error: $@" if $@;
  $c->render(text => "$title");
};

get '/title2' => async sub {
  my ($c) = @_;
  $c->render_later;
  my $title ='failed to get title';
  eval { $title = await $c->get_site_title2($c->param('url')) };
  $title .= ", error: $@" if $@;
  $c->render(text => "$title");
};

my $t = Test::Mojo->new;

$t->get_ok('/title' => form => { url => 'https://mojolicious.org/'})
  ->content_like(qr/mojolicious/i);

# this gives handled promise
$t->get_ok('/title' => form => { url => 'http://badsite.lan/'})
  ->content_like(qr/failed/i);
  diag $t->tx->res->body;

$t->get_ok('/title2' => form => { url => 'http://badsite.lan/'})
  ->content_like(qr/failed/i);
  diag $t->tx->res->body;

done_testing();
