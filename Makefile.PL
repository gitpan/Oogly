
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Oogly',
                       'DISTNAME' => 'Oogly',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Al Newkirk <awncorp@cpan.org>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Oogly - A Data validation idea that just might be ideal!',
                       'EXE_FILES' => [],
                       'VERSION' => '0.02',
                       'PREREQ_PM' => {},
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{BUILD_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.56) };

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



