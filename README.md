Header: dotfiles/README.md

---

another _dotfiles_ repository

## COPYING:

2-clause (*simplified* or *new*) BSD or MIT at your *name* preference

(if not explicitly stated otherwise in particular files)

## Using this repository:

* clone the repository or repositories: 
`% git clone git://github.com/tokiclover/dotfiles.git dotfiles`
* zsh users may clone my [fork][1] of [prezto][2]: 
`% git clone --recurse-submodules git://github.com/tokiclover/prezto.git .zprezto`
* and then exec your shell with `% exec $SHELL`
* another alternative is to clone this repository with *--recurse-submodules* passed to *git*

## Scripts extra info (/scr):

* fhp: is a simple script which put firefox profile into tmpfs/zram backed FS (dep: functions.$shell);
* functions: functions for bash and zsh, almost only die() helper;
* hdu: is a simple script which ease updating '$Header:...$' or '$Id:...$' update;
* ips: is a script which can be used to retrieve IP block lists to be added to iptables rules;
* ipr: is script to generate statefull ip[6]tables net rules;
* kvm: is a script to ease kvm loadind with a few default option;
* lbd: is a script to add/remove loop back devices;
* mkstage4: a stage4 maker scripts with squashed (system and/or local) directories support;
* soundon.user: an oss4 user soundon script;
* term256colors: terminal colors display scripts;
* zram.initd: a init service to initialize zram devices.
* zramdir.initd: an init svc which can put several directories (var/{log,run,lock}..) into zram backed fs.
* xtr: stand for eXtract TaRball, just run with a list of tarball to extract;
* bfd-plugins: switch ld plugin beetwen LLVMgold.so and GCC liblto_plugin.so,
  beware to switch to bfd or gold beforehand (using: binutils-config --linker bfd).

## Scripts/Functions in .zprezto/customs (zsh specific):

* kmod-pc: list kernel module paramaters of passed args or all modules found;
* mktmp: a cheaper variant of mktemp (without the randomness of it, yes cheap);
* precompile: a litte helper to (re)compile zsh functions/scripts found in fpath
  to speed loading and execution (p-as-personal-recompile).

[1]: https://github.com/tokiclover/prezto
[2]: https://github.com/sorin-ionescu/prezto

---
vim:fenc=utf-8:
