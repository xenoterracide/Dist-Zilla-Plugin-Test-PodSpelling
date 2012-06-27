#!/usr/bin/perl
use strict;
use warnings;
use Test::More 0.88;
use Test::DZil;

# test the file content generated when various attributes are set

my $fname  = 'Fo';
my $mi     = 'G';
my $lname1 = 'oer';
my $lname2 = 'bar';
my $author = "$fname $mi $lname1 - $lname2";

sub get_content {
  my ($args) = @_;

  my $name = 'Test::PodSpelling';
  my $zilla = Builder->from_config(
    { dist_root => 'corpus/foo' },
    {
      add_files => {
        'source/dist.ini' => dist_ini(
          {
            name => 'Spell-Checked',
            version => 1,
            abstract => 'spelled wrong',
            license => 'Perl_5',
            author => $author,
            copyright_holder => $author,
          },
          [$name => $args],
        )
      }
    }
  );

  my $plugin = $zilla->plugin_named($name);
  $plugin->gather_files;
  return $zilla->files->[0]->content;
}

my $content = get_content({});

like   $content, qr/$fname /xms, 'includes first name';
like   $content, qr/$lname1/xms, 'includes last name 1';
like   $content, qr/$lname2/xms, 'includes last name 2';
unlike $content, qr/$mi    /xms, 'does not include the midddle initial';

SKIP: {
	use English '-no_match_Vars';
	skip 'qr//m does not work properly in 5.8.8', 4,
		unless $PERL_VERSION gt v5.10
		;

	like   $content, qr/^$fname $/xms, q[includes first name];
	like   $content, qr/^$lname1$/xms, q[includes last name 1];
	like   $content, qr/^$lname2$/xms, q[includes last name 2];
	unlike $content, qr/^$mi    $/xms, q[does not include the midddle initial];
}

done_testing;
