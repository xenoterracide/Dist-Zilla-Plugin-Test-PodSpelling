use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::PodSpellingTests;

# ABSTRACT: Release tests for POD spelling
use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with 'Dist::Zilla::Role::TextTemplate';
sub mvp_multivalue_args { qw( stopwords ) }
has wordlist => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Pod::Wordlist::hanekomu',    # default to original
);
has spell_cmd => (
    is      => 'ro',
    isa     => 'Str',
    default => '',                           # default to original
);
has stopwords => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },                   # default to original
);
around add_file => sub {
    my ($orig, $self, $file) = @_;
    my ($set_spell_cmd, $add_stopwords, $stopwords);
    if ($self->spell_cmd) {
        $set_spell_cmd = sprintf "set_spell_cmd('%s');", $self->spell_cmd;
    }
    if (@{ $self->stopwords } > 0) {
        $add_stopwords = 'add_stopwords(<DATA>);';
        $stopwords = join "\n", '__DATA__', @{ $self->stopwords };
    }
    $self->$orig(
        Dist::Zilla::File::InMemory->new(
            {   name    => $file->name,
                content => $self->fill_in_string(
                    $file->content,
                    {   wordlist      => \$self->wordlist,
                        set_spell_cmd => \$set_spell_cmd,
                        add_stopwords => \$add_stopwords,
                        stopwords     => \$stopwords,
                    },
                ),
            }
        ),
    );
};
__PACKAGE__->meta->make_immutable;
no Moose;
1;

=begin :prelude

=for stopwords wordlist

=for test_synopsis
1;
__END__

=end :prelude

=head1 SYNOPSIS

In C<dist.ini>:

    [PodSpellingTests]

or:

    [PodSpellingTests]
    wordlist = Pod::Wordlist
    spell_cmd = aspell list
    stopwords = CPAN
    stopwords = github
    stopwords = stopwords
    stopwords = wordlist

or, if you wanted to use my plugin bundle but just override this plugin's
configuration:

    [@Filter]
    -bundle = @MARCEL
    -remove = PodSpellingTests

    [PodSpellingTests]
    wordlist = Pod::Wordlist
    spell_cmd = aspell list
    stopwords = CPAN
    stopwords = github
    stopwords = stopwords
    stopwords = wordlist

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following file:

  xt/release/pod-spell.t - a standard Test::Spelling test

=head1 ATTRIBUTES

=method wordlist

The module name of a word list you wish to use that works with
L<Test::Spelling>.

Defaults to L<Pod::Wordlist::hanekomu>.

=method spell_cmd

If C<spell_cmd> is set then C<set_spell_cmd( your_spell_command );> is added to
the test file to allow for custom spell check programs.

Defaults to nothing.

=method stopwords

If stopwords is set then C<add_stopwords( E<lt>DATAE<gt> )> is added to the test file
and the words are added after the __DATA__ section.

C<stopwords> can appear multiple times, one word per line.

Defaults to nothing.

=begin Pod::Coverage

mvp_multivalue_args

=end Pod::Coverage

=cut

__DATA__
___[ xt/release/pod-spell.t ]___
#!perl

use Test::More;

eval "use {{ $wordlist }}";
plan skip_all => "{{ $wordlist }} required for testing POD spelling"
  if $@;

eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for testing POD spelling"
  if $@;

{{ $set_spell_cmd }}
{{ $add_stopwords }}
all_pod_files_spelling_ok('lib');
{{ $stopwords }}

