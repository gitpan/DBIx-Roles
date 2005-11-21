# $Id: Hook.pm,v 1.1.1.1 2005/11/20 18:01:06 dk Exp $

package DBIx::Roles::Hook;

use strict;
use vars qw(%defaults $VERSION);

$VERSION = '1.00';

%defaults = (
	Hooks  => {}
);

sub initialize { undef, \%defaults }

sub connect
{
	my ( $self, $storage, @param) = @_;
	return $self-> next( @param) unless exists $self-> {attr}-> {Hooks}-> {connect};
	$self-> {attr}-> {Hooks}-> {connect}->( @param);
}

sub disconnect
{
	my ( $self, $storage, @param) = @_;
	return $self-> next( @param) unless exists $self-> {attr}-> {Hooks}-> {disconnect};
	$self-> {attr}-> {Hooks}-> {disconnect}->( @param);
}

sub any
{
	my ( $self, $storage, $method, @param) = @_;
	return $self-> next( $method, @param) unless exists $self-> {attr}-> {Hooks}-> {$method};
	$self-> {attr}-> {Hooks}-> {$method}->( $self, $storage, @param);
}

sub rewrite
{
	my ( $self, $storage, $method, @param) = @_;
	return $self-> next( $method, @param) unless exists $self-> {attr}-> {Hooks}-> {"rewrite_$method"};
	$self-> {attr}-> {Hooks}-> {"rewrite_$method"}->( $self, $storage, @param);
}

sub dbi_method
{
	my ( $self, $storage, $method, @param) = @_;
	return $self-> next( $method, @param) unless exists $self-> {attr}-> {Hooks}-> {$method};
	$self-> {attr}-> {Hooks}-> {$method}->( $self, $storage, @param);
}

sub STORE
{
	my ( $self, $storage, $key, $val) = @_;
	return $self-> next( $key, $val) if
		$key eq 'Hooks' or 
		not exists $self-> {attr}-> {Hooks}-> {STORE};
	$self-> {attr}-> {Hooks}-> {STORE}->( @_);
}

1;

__DATA__

=head1 NAME

DBIx::Roles::Hook - Exports callbacks to override DBI calls.

=head1 DESCRIPTION

Exports the single attribute C<Hooks> that is a hash, where keys can be one of
C<connect>, C<disconnect>, C<any>, C<rewrite>, C<dbi_method>, C<STORE>, and
values are code references, that are called when the corresponding call occurs.

=head1 SYNOPSIS

     use DBIx::Roles qw(Hook);

     my $dbh = DBI-> connect(
           "dbi:Pg:dbname=template1",
	   "postgres",
	   "password",
	   {
               Hooks => {
	           do => sub {
		       my ( $self, undef, @param) = @_;
		       return 42; # no do
		   },
               }
	   }
     );

     print $dbh-> do("SELECT meaning FROM life");


=head1 SEE ALSO

L<DBIx::Roles>.

=head1 COPYRIGHT

Copyright (c) 2005 catpipe Systems ApS. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Dmitry Karasik <dk@catpipe.net>

=cut

