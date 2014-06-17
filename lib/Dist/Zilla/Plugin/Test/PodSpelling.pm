package Dist::Zilla::Plugin::Test::PodSpelling;
use 5.010;
use strict;
use warnings;

# VERSION

use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with (
	'Dist::Zilla::Role::FileMunger',
	'Dist::Zilla::Role::TextTemplate',
	'Dist::Zilla::Role::FileFinderUser' => {
		default_finders => [ ':InstallModules' ],
	},
	'Dist::Zilla::Role::PrereqSource',
);

sub mvp_multivalue_args { return ( qw( stopwords directories ) ) }

has wordlist => (
	is      => 'ro',
	isa     => 'Str',
	default => 'Pod::Wordlist',
);

has spell_cmd => (
	is      => 'ro',
	isa     => 'Str',
	default => '',                           # default to original
);

has stopwords => (
	is      => 'ro',
	isa     => 'ArrayRef[Str]',
	traits  => [ 'Array' ],
	default => sub { [] },                   # default to original
	handles => {
		push_stopwords => 'push',
		uniq_stopwords => 'uniq',
		no_stopwords   => 'is_empty',
	}
);

has directories => (
	isa     => 'ArrayRef[Str]',
	traits  => [ 'Array' ],
	is      => 'ro',
	default => sub { [] },                   # default to original
	handles => {
		no_directories => 'is_empty',
		print_directories => [ join => ' ' ],
	}
);

has _files => (
	is      => 'rw',
	isa     => 'ArrayRef[Dist::Zilla::Role::File]',
);

sub gather_files {
	my ($self) = @_;

	my $data = $self->merged_section_data;
	return unless $data and %$data;

	my @files;
	for my $name (keys %$data) {
		my $file = Dist::Zilla::File::InMemory->new({
			name    => $name,
			content => ${ $data->{$name} },
		});
		$self->add_file($file);
		push @files, $file;
	}

	$self->_files(\@files);
	return;
}

sub add_stopword {
	my ( $self, $data ) = @_;

	$self->log_debug( 'attempting stopwords extraction from: ' . $data );
	# words must be greater than 2 characters
	my ( $word ) = $data =~ /(\p{Word}{2,})/xms;

	# log won't like an undef
	return unless $word;

	$self->log_debug( 'add stopword: ' . $word );

	$self->push_stopwords( $word );
	return;
}

sub munge_files {
	my ($self) = @_;

	$self->munge_file($_) foreach @{ $self->_files };
	return;
}

sub munge_file {
	my ($self, $file) = @_;

	my ($set_spell_cmd, $add_stopwords, $stopwords);
	if ($self->spell_cmd) {
		$set_spell_cmd = sprintf "set_spell_cmd('%s');", $self->spell_cmd;
	}

	foreach my $holder ( split( /\s/xms, join( ' ',
			@{ $self->zilla->authors },
			$self->zilla->copyright_holder,
			@{ $self->zilla->distmeta->{x_contributors} || [] },
		))
	) {
		$self->add_stopword( $holder );
	}

	foreach my $file ( @{ $self->found_files } ) {
		# many of my stopwords are part of a filename
		$self->log_debug( 'splitting filenames for more words' );

		foreach my $name ( split( '/', $file->name ) ) {
			$self->add_stopword( $name );
		}
	}

	unless ( $self->no_stopwords ) {
		$add_stopwords = 'add_stopwords(<DATA>);';
		$stopwords = join "\n", '__DATA__', $self->uniq_stopwords;
	}

	$file->content(
		$self->fill_in_string(
			$file->content,
			{
				name          => __PACKAGE__,
				version       => __PACKAGE__->VERSION
					|| 'bootstrapped version',
				wordlist      => \$self->wordlist,
				set_spell_cmd => \$set_spell_cmd,
				add_stopwords => \$add_stopwords,
				stopwords     => \$stopwords,
				directories   => \$self->print_directories,
			}
		),
	);

	return;
}

sub register_prereqs {
	my $self = shift;
	$self->zilla->register_prereqs(
		{
			type  => 'requires',
			phase => 'develop',
		},
		'Test::Spelling' => '0.12',
	);
	return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

# ABSTRACT: Author tests for POD spelling

=for Pod::Coverage gather_files

=head1 SYNOPSIS

In C<dist.ini>:

	[Test::PodSpelling]

or:

	[Test::PodSpelling]
	directories = docs
	wordlist = Pod::Wordlist
	spell_cmd = aspell list
	stopwords = CPAN
	stopwords = github
	stopwords = stopwords
	stopwords = wordlist

If you're using C<[ExtraTests]> it must come after C<[Test::PodSpelling]>,
it's worth noting that this ships in the C<[@Basic]> bundle so you may have to
remove it from that first.

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing
the following file:

  xt/author/pod-spell.t - a standard Test::Spelling test

=method add_stopword

Called to add stopwords to the stopwords array. It is used to determine if
automagically detected words are valid and print out debug logging for the
process.

=attr directories

Additional directories you wish to search for POD spell checking purposes.
C<bin> and C<lib> are set by default.

=attr wordlist

The module name of a word list you wish to use that works with
L<Test::Spelling>.

Defaults to L<Pod::Wordlist>.

=attr spell_cmd

If C<spell_cmd> is set then C<set_spell_cmd( your_spell_command );> is
added to the test file to allow for custom spell check programs.

Defaults to nothing.

=attr stopwords

If stopwords is set then C<add_stopwords( E<lt>DATAE<gt> )> is added
to the test file and the words are added after the C<__DATA__>
section.

C<stopwords> can appear multiple times, one word per line.

Normally no stopwords are added by default, but author names appearing in
C<dist.ini> are automatically added as stopwords so you don't have to add them
manually just because they might appear in the C<AUTHORS> section of the
generated POD document. The same goes for contributors listed under the
'x_contributors' field on your distributions META file.

=begin Pod::Coverage

mvp_multivalue_args
munge_files
munge_file

=end Pod::Coverage

=cut
__DATA__
___[ xt/author/pod-spell.t ]___
use strict;
use warnings;
use Test::More;

# generated by {{ $name }} {{ $version }}
use Test::Spelling 0.12;
use {{ $wordlist }};

{{ $set_spell_cmd }}
{{ $add_stopwords }}
all_pod_files_spelling_ok( qw( bin lib {{ $directories }} ) );
{{ $stopwords }}
