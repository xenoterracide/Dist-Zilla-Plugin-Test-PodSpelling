#!/usr/bin/perl
use strict;
use warnings;
use Test::Tester;
use Test::More 0.88;
use Test::Spelling;

use Dist::Zilla::Tester;
use Path::Class;
use Cwd ();

BEGIN {
	use English;

	plan skip_all => 'No working spellchecker found'
		unless has_working_spellchecker;

	plan skip_all => 'This Test has problems on BSD... patches welcome'
		if $OSNAME =~ m/bsd/i;

	no English;
}

ok( has_working_spellchecker, 'test has working spellchecker' );

# lib/ and bin/
spell_check_dist( foo   => [file(qw(bin foo)) => {ok => 0}], file(qw(lib Foo.pm)) );
# just lib/
spell_check_dist( nobin => file(qw(lib Foo.pm)) );

done_testing;

# @files should be a file (name) or an array ref of [file, hash-to-override-expected-results]
sub spell_check_dist {
  my ($dir, @files) = @_;
  my $tzil = Dist::Zilla::Tester->from_config({
    dist_root => dir('corpus', $dir),
  }, {
    tempdir_root => '.build', # avoid creating ./tmp
  });
  $tzil->build;

  my $cwd = Cwd::cwd;
  # tests typically run from the build dir
  chdir $tzil->tempdir->subdir('build') or die "chdir failed: $!";

  check_tests(
    sub {
      # all_pod_files_spelling_ok sets a plan which causes problems
      local *Test::Tester::Delegate::plan = sub {};

      # run the actual xt file
      do "${\ file(qw(xt author pod-spell.t)) }";
    },
    [
      map {
        +{
          ok => 1,
          name => 'POD spelling for ' . $_->[0],
          # depth: starts at 1; +1 for do-file; +1 for the all_ func
          depth => 3,
          %{ $_->[1] },
        },
      }
      map { ref $_ eq 'ARRAY' ? $_ : [$_ => {}] }
        @files
    ],
    "spell check pod for $dir"
  );

  # change back
  chdir $cwd or die "chdir failed: $!";
}
