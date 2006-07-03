use strict;
use warnings;
use inc::Module::Install;

name 'Data-Hive';
author 'Hans Dieter Pearcey <hdp@cpan.org>';
all_from;

build_requires 'Test::More'       => 0;
build_requires 'Test::use::ok'    => 0;
build_requires 'Test::MockObject' => 0;

requires 'Carp::Clan' => 0;

auto_install;
WriteAll;
