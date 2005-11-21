#!/usr/bin/perl

use strict;
use Test::More tests => 15;
$SIG{__DIE__} = sub { # need no Test::Builder hacks
	return if $^S;
	Carp::cluck(@_);
	die @_;
};

BEGIN { use_ok('DBIx::Roles'); }
require_ok('DBIx::Roles');

package DummyDBI;

sub connect { bless {}, shift }
sub disconnect {}
sub ping {0} # for AutoReconnect test

package Phase1;
use DBIx::Roles;
use strict;
import Test::More;

my $d = DBIx::Roles-> new;
ok( $d, "create object");

$d = DBIx::Roles-> new(qw(Hook));
ok( $d, "create object with roles"); 

$DBIx::Roles::DBI_connect = sub { bless {}, 'DummyDBI' };

# check if hooks work
my $had_disconnect = 0;
$d->{Hooks}->{disconnect} = sub {
	$had_disconnect++;
};
ok( $d-> connect(), "connect"); 
undef $d;

ok( $had_disconnect, "disconnect");

package Phase2;
use strict;
import Test::More;
use DBIx::Roles qw(AutoReconnect Buffered InlineArray StoredProcedures Hook SQLAbstract);
my $do = 0;

$d = DBI-> connect('','','', { Hooks => {
selectrow_array => sub {
	return 42;
},
do => sub {
	$do++;
	return @_;
},
},
Buffered => 0,
});
ok( $d, "DBI->connect() overload");

# plain request
my $g = $d-> selectrow_array( 'select dummy from yummy where 1=?', {}, 1);
ok( $g && $g == 42, "'dbi_methods'");

$d-> {Buffered} = 1;
$do = 0;
$d-> do("select buffered");
ok( $do == 0, "DBI methods");
$d-> {Buffered} = 0;
ok( $do == 1, "DBI methods");

# like a stored proc?
$g = $d-> unbelievable_procedure( 'select 1');
ok( $g && $g == 42, "'any'/StoredProcedures");

# flattened array
my @g = $d-> do( 'select ?', {}, [1,2,3]);
ok(( 5 == @g) and not( ref($g[4])), "'rewrite'/InlineArray");

# SQL::Abstract
@g = $d-> insert( 'moo', 1..4);
ok( $g[2] && $g[2] =~ /insert\s+into\s+moo/i, "SQL::Abstract");

# can restart?
my $do_retries = 2;

$DBIx::Roles::DBI_connect = sub {
	die "Won't connect\n" if $do_retries-- > 0 ;
	return bless {}, 'DummyDBI';
};

$d->{Hooks}->{do} = sub { 
	# emulate connection break
	die "aaa!!" if $do_retries > 0;
	return 42;
};
$d-> {ReconnectMaxTries} = $do_retries + 2;
$d-> {ReconnectTimeout} = 0;
$d-> {PrintError} = 0; # it warns when reconnects
$d-> do('select 0');
ok(( -1 == $do_retries and $d-> dbh and 1), "recurrency/AutoReconnect");
undef $d;

package Phase3;
use strict;
import Test::More;
use DBIx::Roles;

$DBIx::Roles::DBI_connect = sub { bless {}, 'DummyDBI' };
$d = DBI-> connect;
# tests that after DBI->connect() was overridden, it works as before in the other packages
ok( $d and ( $d =~ /Dummy/)+0, "package-selective DBI::connect");
