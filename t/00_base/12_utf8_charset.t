use strict;
use warnings;

use utf8;
use Encode;
use Test::More import => ['!pass'];
use Plack::Test;

plan tests => 4;

test_psgi(
    client => sub {
        my $cb = shift;
        my $res;

        $res = _get_http_response(GET => '/string', $cb);
        is d($res->content), "\x{1A9}", "utf8 static response";

        $res = _get_http_response(GET => '/other/string', $cb);
        is d($res->content), "\x{1A9}", "utf8 response through forward";

        $res = _get_http_response(GET => "/param/".u("\x{1A9}"), $cb);
        is d($res->content), "\x{1A9}", "utf8 route param";

        $res = _get_http_response(GET => "/view?string1=".u("\x{E9}"), $cb);
        is d($res->content), "sigma: 'Ʃ'\npure_token: 'Ʃ'\nparam_token: '\x{E9}'\n",
            "params and tokens are valid unicode";
    },
    app => do {
        use Dancer;
        use t::lib::TestAppUnicode;

        set( charset      => 'utf8',
             apphandler   => 'PSGI',
             show_errors  => 1,
             startup_info => 0,
             log          => 'debug',
             logger       => 'console');

        Dancer->dance();
    },
);

sub u {
    encode('UTF-8', $_[0]);
}

sub d {
    decode('UTF-8', $_[0]);
}

sub _get_http_response {
    my ($method, $path, $cb) = @_;

    my $req = HTTP::Request->new($method => "http://127.0.0.1${path}");
    return $cb->($req);
}

