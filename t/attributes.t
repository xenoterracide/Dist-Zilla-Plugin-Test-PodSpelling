#!/usr/bin/perl
use strict;
use warnings;
use Test::More 0.88;
use Test::DZil;

# test the file content generated when various attributes are set

my $author = 'Fooer';

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
  like $content, qr/use Pod::Wordlist::hanekomu/, q[use default wordlist];
unlike $content, qr/set_spell_cmd/,               q[by default don't set spell command];
  like $content, qr/add_stopwords/,               q[by default we add stopwords];
  like $content, qr/__DATA__\s$author/,           q[DATA handle includes author];

$content = get_content({wordlist => 'Foo::Bar'});
unlike $content, qr/use Pod::Wordlist::hanekomu/, q[custom word list];
  like $content, qr/use Foo::Bar/,                q[custom word list];

$content = get_content({spell_cmd => 'all_wrong'});
  like $content, qr/set_spell_cmd.+all_wrong/,    q[custom spell checker];

$content = get_content({stopwords => 'foohoo'});
  like $content, qr/__DATA__\s(.*\s)*foohoo\b/,   q[add stopwords];

done_testing;
