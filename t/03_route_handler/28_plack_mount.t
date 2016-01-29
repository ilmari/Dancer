use strict;
use warnings;
use Test::More import => ['!pass'];

use HTTP::Request;

use Plack::Test;
use Plack::Builder; # should be loaded in BEGIN block, but it seems that it's not the case ...

plan tests => 3;

test_psgi(
    client => sub {
        my $cb = shift;
        my $url = "http://127.0.0.1/mount/test/foo";

        my $req = HTTP::Request->new(GET => $url);
        ok my $res = $cb->($req);
        ok $res->is_success;
        is $res->content, '/foo';
    },
    app => do {

        my $handler = sub {
            use Dancer;

            set apphandler   => 'PSGI', startup_info => 0;

            get '/foo' => sub {request->path_info};

            my $env     = shift;
            my $request = Dancer::Request->new(env => $env);
            Dancer->dance($request);
        };

        my $app = builder {
            mount "/mount/test" => $handler;
        };
    },
);
