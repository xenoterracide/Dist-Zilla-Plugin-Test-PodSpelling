package Dist::Zilla::Plugin::PodSpellingTests;
use 5.008;
use strict;
use warnings;
BEGIN {
	our $VERSION = '1.112140';
}
use Moose;
extends 'Dist::Zilla::Plugin::Test::PodSpelling';

before register_component => sub {
	warn "!!! [PodSpellingTests] is Deprecated. please use Test::Podspelling\n";
};

no Moose;
__PACKAGE__->meta->make_immutable;
1;

# ABSTRACT: (DEPRECATED) The old name of the PodSpelling plugin
=head1 MODULE VERSION

version 1.112140

I<note: this version is statically defined for this module, and does not
follow that of the dist>

=head1 SYNOPSIS

This Plugin extends L<Dist::Zilla::Test::PodSpelling> and adds nothing. It is the old
name for C<[Test::PodSpelling]> and will be removed in a few versions.

=head1 SEE ALSO

L<Dist::Zilla::Plugin::Test::PodSpelling>

=cut
