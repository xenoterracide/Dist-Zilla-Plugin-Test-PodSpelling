use strict;
use warnings;
use Test::More;
use Test::DZil;
use Test::Fatal;
use Test::Deep;

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
					[ ExtraTests => ],
					['Test::PodSpelling']
				)
			}
		},
	);

is(
	exception { $tzil->build },
	undef,
	'no exceptions during dzil build',
);

cmp_deeply(
	$tzil->log_messages,
	supersetof(
		'[ExtraTests] rewriting author test xt/author/pod-spell.t',
		'[Test::PodSpelling] failed to find xt/author/pod-spell.t - did something rename or remove it?'
	),
	'warning is given when file is renamed before it can be munged',
);

done_testing;
