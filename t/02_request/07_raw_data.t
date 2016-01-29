use Test::More import => ['!pass'];
use strict;
use warnings;
use Dancer::ModuleLoader;
use Dancer;
use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

use Plack::Test;

use constant RAW_DATA => "var: 2; foo: 42; bar: 57\nHey I'm here.\r\n\r\n";

plan tests => 2;
test_psgi(
    client => sub {
        my $cb = shift;
        my $rawdata = RAW_DATA;
        my $req = HTTP::Request->new(PUT => "http://127.0.0.1/jsondata");
        my $headers = { 'Content-Length' => length($rawdata) };
        $req->push_header($_, $headers->{$_}) foreach keys %$headers;
        $req->content($rawdata);
        my $res = $cb->($req);

        ok $res->is_success, 'req is success';
        is $res->content, $rawdata, "raw_data is OK";
    },
    app => do {
        my $port = shift;

        use TestApp;
        Dancer::Config->load;

        set( environment  => 'production',
             apphandler   => 'PSGI',
             startup_info => 0);
        Dancer->dance();
    },
);
