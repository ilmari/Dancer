#!/usr/bin/env perl

use strict;
use warnings;

use Dancer::ModuleLoader;
use Test::More import => ['!pass'];

plan skip_all => "Dancer::Session::Cookie 0.14 required"
    unless Dancer::ModuleLoader->load( 'Dancer::Session::Cookie', '0.14' );

diag "Loaded Dancer::Session::Cookie version "
    . $Dancer::Session::Cookie::VERSION;

plan skip_all => "HTTP::Cookies required"
    unless Dancer::ModuleLoader->load('HTTP::Cookies');
HTTP::Cookies->import;

plan tests=> 7;

require LWP::UserAgent;
require LWP::UserAgent::PSGI;
require HTTP::Cookies;

my $app = do {
    use Dancer ':tests';

    set( apphandler          => 'PSGI',
         appdir              => '', # quiet warnings not having an appdir
         startup_info        => 0,  # quiet startup banner
         session_cookie_key  => "John has a long mustache",
         session             => "cookie" );

    get "/*" => sub {
        my $hits = session("hit_counter") || 0;
        my $last = session("last_hit") || '';

        session hit_counter => $hits + 1;
        session last_hit => (splat)[0];

        return "hits: $hits, last_hit: $last";
    };

    dance;
};

LWP::UserAgent::PSGI->register($app);

my $ua = LWP::UserAgent->new;

# Simulate two different browsers with two different jars
my @jars = (HTTP::Cookies->new, HTTP::Cookies->new);
for my $jar (@jars) {
    $ua->cookie_jar( $jar );

    my $res = $ua->get("http://0.0/foo");
    is $res->content, "hits: 0, last_hit: ";

    $res = $ua->get("http://0.0/bar");
    is $res->content, "hits: 1, last_hit: foo";

    $res = $ua->get("http://0.0/baz");
    is $res->content, "hits: 2, last_hit: bar";
}

$ua->cookie_jar($jars[0]);
my $res = $ua->get("http://0.0/wibble");
is $res->content, "hits: 3, last_hit: baz", "session not overwritten";
