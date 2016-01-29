use strict;
use warnings;
use Test::More import => ['!pass'];
use Plack::Test;

plan tests => 4;

use Dancer ':syntax';
use Dancer::Test;

test();

sub test {
    test_psgi(
        client => sub {
            my $cb = shift;
            my $url  = "http://127.0.0.1/";

            for (qw/204 304/) {
                my $req = HTTP::Request->new( GET => $url . $_ );
                my $res = $cb->($req);
                ok !$res->content, 'no content for '.$_;
                ok !$res->header('Content-Length'), 'no content-length for '.$_;
            }
        },
        app => do {
            set apphandler => 'PSGI', startup_info => 0;

            get '/204' => sub {
                status 204;
                  return 'foo'
            };
            get '/304' => sub {
                status 304;
                  return 'foo'
            };

            Dancer->dance();
        },
    );
}


