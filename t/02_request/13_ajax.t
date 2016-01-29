use Test::More import => ['!pass'];
use strict;
use warnings;

plan tests => 8;

use Plack::Test;
use HTTP::Request;
use HTTP::Headers;

test_psgi(
    client => sub {
        my $cb = shift;

        my $request = HTTP::Request->new(GET => "http://127.0.0.1/req");
        $request->header('X-Requested-With' => 'XMLHttpRequest');
        my $res = $cb->($request);
        ok($res->is_success, "server responded");
        is($res->content, 1, "content ok");

        $request = HTTP::Request->new(GET => "http://127.0.0.1/req");
        $res = $cb->($request);
        ok($res->is_success, "server responded");
        is($res->content, 0, "content ok");
    },
    app => do {
        use Dancer;
        set (apphandler => 'PSGI',
             startup_info => 0);

        get '/req' => sub {
            request->is_ajax ? return 1 : return 0;
        };
        Dancer->dance();
    },
);

# basic interface
$ENV{REQUEST_METHOD} = 'GET';
$ENV{PATH_INFO} = '/';

my $request = Dancer::Request->new(env => \%ENV);
is $request->method, 'GET';
ok !$request->is_ajax, 'no headers';

my $headers = HTTP::Headers->new('foo' => 'bar');
$request->headers($headers);
ok !$request->is_ajax, 'no requested_with headers';

$headers = HTTP::Headers->new('X-Requested-With' => 'XMLHttpRequest');
$request->headers($headers);
ok $request->is_ajax;
