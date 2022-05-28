package SampleMojoApp::Backend::Worker;

use Mojo::Base -strict, -signatures, -async_await;
use Mojo::Promise;
use SampleMojoApp::Util;
use Feature::Compat::Try;
use Exporter qw(import);

our @EXPORT_OK = qw(foo bar get_title);

sub foo($c, $p) {
    $c->render(text => $p. ' is processed by foo() in Backend Worker.');
}

sub bar($c, $p) {
    $c->render(text => $p. ' is processed by bar() in Backend Worker.');
}

async sub get_title($c,$p) {

  my $title = do {
    try {
      await $c->get_title_p($p);
    }
    catch ($e) {
      $c->log->error(
        sprintf 'act=Backend::Worker::get_title msg="error fetching title" error="%s"', $e );
      return $c->render( text => "error fetching title for $p" );
    }
  };

  $c->render( text => "Backend::Worker::get_title result is: $title" );
}

1;
