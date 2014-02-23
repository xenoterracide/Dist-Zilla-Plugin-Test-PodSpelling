#!/usr/bin/perl
use strict;
use warnings;
use Test::More 0.88;
use Test::Requires 'Dist::Zilla::Plugin::Meta::Contributors';
use Test::DZil;
use Path::Tiny;

# test the file content generated gets contributor

# contributor data
my $fname  = 'Mister';
my $lname = 'Mxyzptlk';
my $email = 'mr_mxyzptlk@example.com';

sub get_content {
  my ($args) = @_;

  my $name = 'Test::PodSpelling';
  my $zilla = Builder->from_config(
    { dist_root => 'corpus/foo' },
    {
      add_files => {
        'source/lib/Spell/Checked.pm' => "package Spell::Checked;\n1;\n",
        'source/dist.ini' => dist_ini(
          {
            name => 'Spell-Checked',
            version => 1,
            abstract => 'spelled wrong',
            license => 'Perl_5',
            author => 'John Doe <jdoe@example.com>',
            copyright_holder => 'John Doe <jdoe@example.com>'
          },
          [GatherDir =>],
          [$name => $args],
          ['Meta::Contributors',
              {
                 contributor => ["$fname $lname <$email>"],
              }
          ],
        )
      }
    }
  );

  $zilla->build;
  my $build_dir = $zilla->tempdir->subdir('build');
  my $file = path($build_dir, 'xt', 'author', 'pod-spell.t');
  return $file->slurp_utf8;
}

my $content = get_content({});

like   $content, qr/$fname /xms, 'includes first name';
like   $content, qr/$lname/xms, 'includes last name';
unlike $content, qr/$email/xms, 'includes email';

done_testing;
