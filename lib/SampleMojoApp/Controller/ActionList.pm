# demo action list inside controller
package SampleMojoApp::Controller::ActionList;
use Mojo::Base 'Mojolicious::Controller', -signatures, -async_await;
use Mojo::Promise;
use SampleMojoApp::Util;
use SampleMojoApp::Backend::Worker qw/foo bar get_title/;
use Feature::Compat::Try;

my %action_list = (
  foo => sub ( $c, $p ) {
    $c->render( text => $p . ' is processed by foo().' );
  },

  bar => sub ( $c, $p ) {
    $c->render( text => $p . ' is processed by bar().' );
  },

  delay => sub ( $c, $s ) {
    Mojo::Promise->new( sub ( $resolve, $reject ) {
        Mojo::IOLoop->timer( $s => sub {
            if   ( int rand 2 ) { $resolve->('Lucky!') }
            else                { $reject->('Unlucky!') }
        } );
    } );
  },

  # ... and many more

  default => sub ( $c, $p ) {
    $c->render( status => 400, text => 'invalid directive' );
  }
);

# for actions in other modules
my %action_list_mod = (

  #foo => \&SampleMojoApp::Backend::Worker::foo, # longform not needed after import
  foo     => \&foo,
  baz     => \&bar,
  baz     => \&bar,
  title   => \&get_title,
  default => sub ( $c, $p ) {
    $c->render( status => 400, text => 'invalid directive' );
  }
);

sub parse ($c) {
  my $m = $c->param('m') // 'default';
  my $p = $c->param('p') // 0;

  $action_list{$m}->( $c, $p );
}

sub parse_mod ($c) {
  my $m = $c->param('m') // 'default';
  my $p = $c->param('p') // 0;

  $action_list_mod{$m}( $c, $p );
}

async sub parse_async ($c) {
  my $s   = $c->param('s') // 1;
  my $res = do {
    try {
      await $action_list{delay}->( $c, $s );
    } catch ($e) {
      return $c->render( text => "@@@ Too bad! $e after delay for $s" );
    }
  };
  $c->render( text => "$res after delay for $s" );
}

# test an async sub in action list that do render itself
sub parse_await ($c) {
  my $p = 'https://httpbin.org/';
  $action_list_mod{title}->( $c, $p );
}

# try UNIVERSAL ->can method (ref: UNIVERSAL.pm )
sub parse_can ($c) {
  return $c->render( status => 400, text => 'bad action' )
    unless my $action = $c->can( sprintf '_action_%s', $c->param('m') // 'default' );
  $c->$action( $c->param('p') // 0 );
  # also works:
  # $action->($c, $c->param('p') // 0 );
}

sub _action_foo ( $c, $p ) {
  $c->render( text => 'foo action with p=' . $p );
}

sub _action_bar ( $c, $p ) {
  $c->render( text => 'bar action with p=' . $p );
}

sub _action_default ( $c, $p ) {
  warn 'default action running with ', $p;
  $c->render( text => 'default action with p=' . $p );
}

1;
