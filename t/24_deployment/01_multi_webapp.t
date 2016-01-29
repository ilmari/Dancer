use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer;
use Plack::Test;
use Plack::Builder;

plan tests => 100;

test_psgi(
    client => sub {
        my $cb = shift;

        my @apps = (qw/app1 app2/);
        for(1..100){
            my $app = $apps[int(rand(scalar @apps - 1))];
            my $req = HTTP::Request->new(GET => "http://127.0.0.1/$app");
            my $res = $cb->($req);
            like $res->content, qr/Hello $app/;
        }
    },
    app => do {
        my $app1 = sub {
            my $env = shift;
            Dancer::App->set_running_app('APP1');
            get "/" => sub { return "Hello app1"; };
            my $request = Dancer::Request->new(env => $env);
            Dancer->dance($request);
        };

        my $app2 = sub {
            my $env = shift;
            Dancer::App->set_running_app('APP2');
            get "/" => sub { return "Hello app2"; };
            my $request = Dancer::Request->new(env => $env);
            Dancer->dance($request);
        };

        my $app = builder {
            mount "/app1" => builder {$app1};
            mount "/app2" => builder {$app2};
        };
    },
);
