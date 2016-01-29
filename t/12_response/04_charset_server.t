use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer::ModuleLoader;
use Dancer;
use Encode;

# Ensure a recent version of HTTP::Headers
my $min_hh = 5.827;

plan skip_all => "HTTP::Headers $min_hh required (use of content_type_charset)"
    unless Dancer::ModuleLoader->load( 'HTTP::Headers', $min_hh );
plan skip_all => "HTTP::Request::Common is needed for this test"
    unless Dancer::ModuleLoader->load('HTTP::Request::Common');

use Plack::Test;

plan tests => 10;

test_psgi(
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request::Common::POST("http://127.0.0.1/name", [ name => 'vasya' ]);
        my $res = $cb->($req);

        is $res->content_type, 'text/html';
        ok $res->content_type_charset; # we always have charset if the setting is set
        is $res->content, 'Your name: vasya';

        $req = HTTP::Request::Common::GET("http://127.0.0.1/unicode");
        $res = $cb->($req);

        is $res->content_type, 'text/html';
        is $res->content_type_charset, 'UTF-8';
        is $res->content, Encode::encode('utf-8', "cyrillic shcha \x{0429}");
    },
    app => do {
        my $cb = shift;

        use lib "t/lib";
        use TestApp;
        Dancer::Config->load;

        set( charset      => 'utf-8',
             environment  => 'production',
             apphandler   => 'PSGI',
             startup_info => 0 );
        Dancer->dance();
    },
);

test_psgi(
    client => sub {
        my $cb = shift;

        my $req = HTTP::Request::Common::GET(
            "http://127.0.0.1/unicode-content-length");
        my $res = $cb->($req);

        is $res->content_type, 'text/html';
        # UTF-8 seems to be Dancer's default encoding
        my $v = "\x{100}0123456789";
        utf8::encode($v);
        is $res->content, $v;
    },
    app => do {

        use lib "t/lib";
        use TestAppUnicode;
        Dancer::Config->load;

        set(
            # no charset
            environment  => 'production',
            apphandler   => 'PSGI',
            startup_info => 0,
        );
        Dancer->dance;
    },
);

SKIP: {
    skip "JSON module required for test", 2 
        unless Dancer::ModuleLoader->load('JSON');

    test_psgi(
        client => sub {
            my $cb = shift;

            my $req = HTTP::Request::Common::GET(
                "http://127.0.0.1/unicode-content-length-json");
            my $res = $cb->($req);

            is $res->content_type, 'application/json';
            is_deeply(from_json($res->content), { test => "\x{100}" });
        },
        app => do {

            use lib "t/lib";
            use TestAppUnicode;
            Dancer::Config->load;

            set(
                # no charset
                environment  => 'production',
                apphandler   => 'PSGI',
                startup_info => 0,
                serializer   => 'JSON',
            );
            Dancer->dance;
        },
    );

}
