Applies Devel::PatchPerl and my additional patches to older Perl sources.

Additional patches:

- Fix the Devel::PatchPerl 2.14 DB_File patch for Perl 5.10.0 with Apple's patch utility.
- Restore `PERL_USE_SAFE_PUTENV` on macOS for Perl 5.23.6 through 5.37.0.
- Suppress incompatible function pointer warnings in DB_File on macOS before Perl 5.10.1.
- Avoid compound tokens split across macros by using `do { ... } while (0)` for statement macros.
- Include `signal.h` without conditional guards on macOS for Perl 5.8.1 and 5.8.2.
- Fix Configure's `malloc` and `free` type detection with C23 compilers.
- Fix Storable function declarations for Perl 5.8.1 through 5.8.7.
- Fix the POSIX signal handler type for Perl 5.8.8.

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
