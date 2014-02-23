use strict;
use warnings;
use Test::More;
use Test::DZil;
use Test::Script 1.05;

my $tzil
	= Builder->from_config(
		{
			dist_root    => 'corpus/a',
		},
		{
			add_files => {
				'source/lib/Foo.pm' => "package Foo;\n1;\n",
				'source/dist.ini' => simple_ini(
					[ GatherDir => ],
					['Test::PodSpelling']
				)
			}
		},
	);

$tzil->build;

my $fn
	= $tzil
	->tempdir
	->subdir('build')
	->subdir('xt')
	->subdir('author')
	->file('pod-spell.t')
	;

ok ( -e $fn, 'test file exists');

script_compiles( '' . $fn->relative, 'check test compiles' );

done_testing;
