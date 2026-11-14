Applies Devel::PatchPerl and my additional patches to older Perl sources.

# Install

```
cpm install -g https://github.com/skaji/perl-Devel-PatchPerl-SKAJI.git
```

# Usage

```
curl -fsSL -O https://cpan.metacpan.org/authors/id/S/SH/SHAY/perl-5.24.4.tar.gz
tar xf perl-5.24.4.tar.gz
cd perl-5.24.4
perl -MDevel::PatchPerl::SKAJI -E 'Devel::PatchPerl::SKAJI->patchperl("5.24.4", ".")'
```
