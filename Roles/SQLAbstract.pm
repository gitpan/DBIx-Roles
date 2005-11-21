# $Id: SQLAbstract.pm,v 1.1.1.1 2005/11/20 18:01:06 dk Exp $

package DBIx::Roles::SQLAbstract;
use strict;
use vars qw(%defaults $VERSION);
use SQL::Abstract;

$VERSION = '1.00';

# SQL::Abstract parameters to new()
%defaults = (
	case		=> 'textbook',
	cmp		=> '=',
	logic		=> 'or',
	convert		=> 0,
	bindtype	=> 'normal',
	quote_char	=> '',
	name_sep 	=> undef,
);

sub initialize
{
	return [], \%defaults, qw(insert select update delete);
}

sub insert 
{ 
	my ( $self, $sql) = @_;
	my ( $query, @bindval) = abstract('insert', @_);
	$self-> do( $query, {}, @bindval);
}

sub select 
{ 
	my ( $self, $sql) = @_;
	my ( $query, @bindval) = abstract('select', @_);
	return $self-> selectall_arrayref( $query, {}, @bindval);
}

sub update 
{ 
	my ( $self, $sql) = @_;
	my ( $query, @bindval) = abstract('update', @_);
	$self-> do( $query, {}, @bindval);
}

sub delete 
{ 
	my ( $self, $sql) = @_;
	my ( $query, @bindval) = abstract('delete', @_);
	$self-> do( $query, {}, @bindval);
}

sub abstract
{
	my ( $method, $self, $sql, @params) = @_;

	# auto-instantiate, if any
	$sql->[0] = SQL::Abstract-> new( 
		map { $_ => $self->{attr}->{$_} } keys %defaults)
			unless $sql->[0];
 	$sql = $sql->[0];

	return $sql-> $method( @params);
}

sub STORE
{
	my ( $self, $sql, $key, $val) = @_;

	# delete the SQL::Abstract object if settings have changed
	undef $sql->[0] if exists $defaults{$key};

	return $self-> next( $key, $val);
}

1;

__DATA__

=head1 NAME

DBIx::Roles::SQLAbstract - Exports SQL commands C<insert>, C<select> etc as methods.

=head1 DESCRIPTION

The role exports SQL commands C<insert>, C<select>, C<update>, C<delete> after 
L<SQL::Abstract> fashion. See L<SQL::Abstract> for syntax of these methods.

=head1 SYNOPSIS

     use DBIx::Roles qw(SQLAbstract);

     my $dbh = DBI-> connect(
           "dbi:Pg:dbname=template1",
	   "postgres",
	   "password",
     );

     $dbh-> select( $table, \@fields, \%where, \@order);
     $dbh-> insert( $table, \%fieldvals || \@values);
     $dbh-> update( $table, \%fieldvals, \%where);
     $dbh-> delete( $table, \%where);

=head1 SEE ALSO

L<DBIx::Roles>, L<SQL::Abstract>.

=head1 COPYRIGHT

Copyright (c) 2005 catpipe Systems ApS. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Dmitry Karasik <dk@catpipe.net>

=cut
