use strict;
use warnings;
use Test::More import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;
use Plack::Test;

plan tests => 43;

ok(Dancer::App->current->registry->is_empty,
    "registry is empty");
ok(Dancer::Plugin::Ajax::ajax( '/', sub { "ajax" } ), "ajax helper called");
ok(!Dancer::App->current->registry->is_empty,
    "registry is not empty");

test_psgi(
    client => sub {
        my $cb = shift;

        my @queries = (
            { path => 'req', ajax => 1, success => 1, content => 1 },
            { path => 'req', ajax => 0, success => 0 },
            { path => 'foo', ajax => 1, success => 1, content => 'ajax' },
            { path => 'foo', ajax => 0, success => 1, content => 'not ajax' },
            { path => 'bar', ajax => 1, success => 1, content => 'ajax' },
            { path => 'bar', ajax => 0, success => 1, content => 'not ajax' },
            { path => 'layout', ajax => 0, success => 1, content => 'wibble' },
            { path => 'die', ajax => 1, success => 0 },
            { path => 'layout', ajax => 0, success => 1, content => 'wibble' },
        );

        foreach my $query (@queries) {
            ok my $request =
              HTTP::Request->new(
                GET => "http://127.0.0.1/" . $query->{path} );

            $request->header( 'X-Requested-With' => 'XMLHttpRequest' )
              if ( $query->{ajax} == 1);

            ok my $res = $cb->($request);

            if ( $query->{success} == 1) {
                ok $res->is_success;
                is $res->content, $query->{content};
                like $res->header('Content-Type'), qr/text\/xml/ if $query->{ajax} == 1;
            }
            else {
                ok !$res->is_success;
            }
        }

        # test ajax with content_type to json
        ok my $request =
          HTTP::Request->new( GET => "http://127.0.0.1/ajax.json" );
        $request->header( 'X-Requested-With' => 'XMLHttpRequest' );
        ok my $res = $cb->($request);
        like $res->header('Content-Type'), qr/json/;
    },
    app => do {

        use Dancer;
        use Dancer::Plugin::Ajax;

        set apphandler => 'PSGI', startup_info => 0, layout => 'wibble';

        ajax '/req' => sub {
            return 1;
        };
        get '/foo' => sub {
            return 'not ajax';
        };
        ajax '/foo' => sub {
            return 'ajax';
        };
        get '/bar' => sub {
            return 'not ajax';
        };
        get '/bar', {ajax => 1} => sub {
            return 'ajax';
        };
        get '/ajax.json' => sub {
            content_type('application/json');
            return '{"foo":"bar"}';
        };
        ajax '/die' => sub {
            die;
        };
        get '/layout' => sub {
            return setting 'layout';
        };
        start();
    },
);
