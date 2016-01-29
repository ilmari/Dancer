use strict;
use warnings;

# Test that vars are really reset between each request

use Test::More;
use Plack::Test;

plan tests => 10;
test_psgi(
    client => sub {
        my $cb = shift;
        for (1..10) {
            my $req = HTTP::Request->new( 
                GET => "http://127.0.0.1/getvarfoo"
            );
            my $res = $cb->($req);
            is $res->content, 1;
        }
    },
    app => do {
        use Dancer ":tests";

        # vars should be reset before the handler is called
        var foo => 42;

        set startup_info => 0, apphandler => 'PSGI';

        get "/getvarfoo" => sub {
            return ++vars->{foo};
        };

        Dancer->dance;
    },
);
