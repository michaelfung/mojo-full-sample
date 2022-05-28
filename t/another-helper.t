# another way to use helper with await,
# https://gist.github.com/kiwiroy/137269c99050e90887262fbae1b1113e

use Test::More;
use Test::Mojo;
use Mojolicious::Lite -signatures, -async_await;

helper get_site_title => sub {
  my ($c, $url) = @_;

  return $c->ua->max_redirects(1)->get_p($url)->then(sub ($tx) {
    my $result = $tx->result;
    die $result->message if $result->is_error;
    die 'unknown error condition' unless $result->is_success;
    $result->dom->at('title')->text or die "no title";
  });
};

get '/title' => async sub {
  my ($c) = @_;
  $c->render_later;
  my $title ='failed to get title';

  # my way of doing it:
  #   eval { $title = await $c->get_site_title($c->param('url'))};
  #   $title .= ", error: $@" if $@;

  $title = await $c->get_site_title($c->param('url'))
    ->catch(sub ($e) { $title .= ", error: $e"; });
  return $c->render(text => "$title");
};


my $t = Test::Mojo->new;

$t->get_ok('/title' => form => { url => 'https://ddg.gg/'})
  ->content_like(qr/^DuckDuckGo/i);

$t->get_ok('/title' => form => { url => 'http://badsite.lan/'})
  ->content_like(qr/failed/i);
  diag "body=".$t->tx->res->body;

{
  eval { await Mojo::Promise->new( sub ($resolve, $reject) {  die " I am dead"; } ); };
  diag "E=".$@;
  like $@, qr/dead/, 'p die';
}

{
  async sub rej {
    my $p = Mojo::Promise->new( sub ($resolve, $reject) {  $reject->(" I am dead"); } );
  }
  eval { await rej() };
  diag "E=".$@;
  like $@, qr/dead/, 'p reject';
}

{
  eval { await $t->ua->get_p('http://badsite.lan'); };
  diag "E=".$@;
  like $@, qr/resolve/, 'eval failure';
}

done_testing();
