# try Perl 7 features
package SampleMojoApp::Controller::P7;
use Mojo::Base 'Mojolicious::Controller', -signatures, -async_await;
use Mojo::Promise;
use SampleMojoApp::Util;
use Feature::Compat::Try;

async sub title ($c) {
  my $tx = $c->render_later->tx;

  my $url = $c->param('url') || 'https://httpbin.org/';
  my $title = do {
    try {
      await $c->get_title_p($url);
    }
    catch ($e) {
      $c->log->error(
        sprintf 'act=P7::get_title msg="error fetching title" error="%s"', $e );
      return $c->render( text => "error fetching title for $url" );
    }
  };

  $c->log->debug("continue process title ...");

  $c->render( text => "processed result for $title is ..." );
}


1;
