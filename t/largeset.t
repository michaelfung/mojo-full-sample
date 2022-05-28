# test large data download from largeset endpoint
#
# Must have app running on port 3000 to do this test

use Mojo::Base -strict, -signatures, -async_await;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Test::More;
use Test::Mojo;
use Mojo::UserAgent;
use Mojo::Promise;
use JSON::XS;

my $ua = Mojo::UserAgent->new(max_response_size => 0);


my $chunk_count = 0;
my $total_lines = 0;
my $json_obj_count = 0;
my $total_bytes = 0;
my $errors = '';

for ( 1 .. 5 ) {
    my $p = Mojo::Promise->new;
    my $tx = $ua->build_tx(GET => 'http://localhost:3000/ls/largeset?size=50000');
    $tx->res->content->unsubscribe('read')->on(read => sub ($mojo_content_obj, $chunk) {
        diag "chunk count=". ++$chunk_count;
        my $chunk_size = length $chunk;
        diag "received chunk size=$chunk_size";
        $total_bytes += $chunk_size;
        open my $fh, '<', \$chunk;
        while (my $line = <$fh>) {
            ++$total_lines;
            eval { decode_json $line; };
            $json_obj_count++ unless $@;
            $errors .= "line=$total_lines, Err= $@ , bad json=$line\n" if $@;
        }
        $p->resolve();
    });
    # Process transaction
    $tx = $ua->start($tx);
    $p->wait;
}


diag "total JSON obj received=". $json_obj_count;
diag "total bytes received=". $total_bytes;
diag "total lines received=". $total_lines;

is $errors, '', 'all JSON decoded OK';
diag "errors=". $errors;

pass "test done";

done_testing();
