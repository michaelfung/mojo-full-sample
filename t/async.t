use Mojo::Base -strict;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Test::More;
use Feature::Compat::Try;

BEGIN {
  plan skip_all => 'set TEST_ASYNC_AWAIT to enable this test (developer only!)'
    unless $ENV{TEST_ASYNC_AWAIT} || $ENV{TEST_ALL};
  plan skip_all => 'Future::AsyncAwait 0.52+ required for this test!' unless Mojo::Base->ASYNC;
}
use Mojo::Base -signatures, -async_await;

use Test::Future::AsyncAwait::Awaitable qw(test_awaitable);
use Test::Mojo;
use Mojo::Promise;
use Mojo::UserAgent;
use Mojolicious::Lite;

# async/await spec
test_awaitable('Mojo::Promise conforms to Awaitable API', class => "Mojo::Promise", force => sub { shift->wait },);

# Silence
app->log->level('fatal');

helper defer_resolve_p => sub {
  my ($c, $msg) = @_;
  my $promise = Mojo::Promise->new;
  Mojo::IOLoop->next_tick(sub { $promise->resolve($msg) });
  return $promise;
};

helper defer_reject_p => sub {
  my ($c, $msg) = @_;
  my $promise = Mojo::Promise->new;
  Mojo::IOLoop->next_tick(sub { $promise->reject($msg) });
  return $promise;
};

get '/one' => {text => 'works!'};

get '/two' => {text => 'also'};

get '/three' => async sub {
  my $c      = shift;
  my $first  = await $c->defer_resolve_p('this ');
  my $second = await $c->defer_resolve_p('works');
  my $third  = await $c->defer_resolve_p(' too!');
  $c->render(text => "$first$second$third");
};

get '/four' => async sub {
  my $c = shift;

  my $text = await Mojo::Promise->resolve('fail');
  eval { await $c->defer_reject_p('this went perfectly') };
  if (my $err = $@) { $c->render(text => $err, status => 500) }
  else              { $c->render(text => $text) }
};

get '/five' => async sub {
  my $c       = shift;
  my $runaway = $c->defer_reject_p('runaway too');
  await $c->defer_resolve_p('fail');
  await $runaway;
};

get '/six' => sub {
  my $c = shift;
  $c->on(
    message => async sub {
      my ($c, $msg) = @_;
      my $first  = await $c->defer_resolve_p("One: $msg");
      my $second = await $c->defer_resolve_p("Two: $msg");
      $c->send("$first $second")->finish;
    }
  );
};

my $ua = Mojo::UserAgent->new(ioloop => Mojo::IOLoop->singleton);

async sub test_one {
  await $ua->get_p('/one');
}

async sub test_two {
  my $separator = shift;

  my $text = '';
  my $two  = await $ua->get_p('/two');
  $text .= $two->res->body;
  my $one = await $ua->get_p('/one');
  $text .= $separator . $one->res->body;

  return $text;
}

async sub test_three {
  my $ok = shift;
  return Mojo::Promise->new(sub {
    my ($resolve, $reject) = @_;
    Mojo::IOLoop->next_tick(sub { ($ok ? $resolve : $reject)->('value') });
  });
}

my $t = Test::Mojo->new;

subtest 'Basic async/await' => sub {
  my $promise = test_one();
  isa_ok $promise, 'Mojo::Promise', 'right class';
  my $tx;
  $promise->then(sub { $tx = shift })->catch(sub { warn @_ });
  $promise->wait;
  is $tx->res->body, 'works!', 'right content';
};

subtest 'Multiple awaits' => sub {
  my $text;
  test_two(' ')->then(sub { $text = shift })->catch(sub { warn @_ })->wait;
  is $text, 'also works!', 'right content';
};

subtest 'Application with async/await action' => sub {
  $t->get_ok('/three')->content_is('this works too!');
};

subtest 'Exception handling and async/await' => sub {
  $t->get_ok('/four')->status_is(500)->content_like(qr/this went perfectly/);
};

subtest 'Runaway exception' => sub {
  $t->get_ok('/five')->status_is(500)->content_like(qr/runaway too/);
};

subtest 'Async function body returning a promise' => sub {
  my $text;
  test_three(1)->then(sub { $text = shift })->catch(sub { warn @_ })->wait;
  is $text, 'value', 'right content';
  $text = undef;
  test_three(0)->then(sub { warn @_ })->catch(sub { $text = shift })->wait;
  is $text, 'value', 'right content';
};

subtest 'Async WebSocket' => sub {
  $t->websocket_ok('/six')->send_ok('test')->message_ok->message_is('One: test Two: test')->finish_ok;
};

# Top-level await
is scalar await Mojo::Promise->resolve('works'), 'works', 'top-level await resolved';
is_deeply [await Mojo::Promise->resolve('just', 'works')], ['just', 'works'], 'top-level await resolved';
eval { await Mojo::Promise->reject('works too') };
like $@, qr/works too/, 'top-level await rejected';


my $res = do  { try { await Mojo::Promise->resolve('works') } catch ($e) {} };
is $res , 'works', 'try await resolved';

my $reso_p = sub {
    Mojo::Promise->resolve('works');
};
my $res2 = do  { try { await $reso_p->() } catch ($e) {} };
is $res2 , 'works', 'try await with sub resolved';

my $try_await = async sub {
  my $res3 = do { try { await $reso_p->() } catch ($e) {} };
  return $res3;
};
is await $try_await->(), 'works', 'try await with nested sub resolved';

async sub try_await2 {
  my $res3 = do { try { await $reso_p->() } catch ($e) {} };
  return $res3;
};
is await try_await2(), 'works', 'try await with nested sub resolved';
done_testing();


__DATA__





is try_await(), 'works', 'got resolve val';

# subtest 'wait for reject' => sub {
#     async sub rej {
#         await Mojo::Promise->reject('reason')->catch(sub{ die shift; });
#     }
#     my $res = do {
#         try {
#             rej();
#         } catch($e) {
#             say "exception:$e";
#             return undef;
#         }
#     };
#     ok !$res, 'res is undef';
#     diag "res=". $res;
# };

