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

## Scripts extra info (/bin):

* fhp: is a simple script which put firefox profile into tmpfs/zram backed FS (dep: functions.$shell);
* hdu: is a simple script which ease updating '$Header:...$' or '$Id:...$' update;
* ips: is a script which can be used to retrieve IP block lists to be added to iptables rules;
* ipr: is script to generate statefull ip[6]tables net rules;
* kvm: is a script to ease kvm loadind with a few default option;
* lbd: is a script to add/remove loop back devices;
* loop2jack: a script to map loopback device to jack client (support zita-a2j/j2a or alsa_in/out);
* mkstage4: a stage4 maker scripts with squashed (system and/or local) directories support;
* soundon.user: an oss4 user soundon script;
* term256colors: terminal colors display scripts;
* xtr: stand for eXtract TaRball, just run with a list of tarball to extract;
* bfd-plugins: switch ld plugin beetwen LLVMgold.so and GCC liblto_plugin.so,
  beware to switch to bfd or gold beforehand (using: binutils-config --linker bfd).

## Functions extra info (/lib):

* functions.bash: a few helpers not fully tested...
* functions.zsh: look at .zprezto/customs/helpers those can be used with adding
  this path to fpath and then use autoload -Uz $helpers when need be.
* zram.initd: a init service to initialize zram devices.
* zramdir.initd: an init svc which can put several directories
  (var/{log,run,lock}..) into zram backed fs.

## Scripts/Functions in .zprezto/customs/customs (zsh specific):

Those helpers are availaible in /lib/functions.bash minus precompile.

* kmod-pc: list kernel module paramaters of passed args or all modules found;
* mktmp: a cheaper variant of mktemp (without the randomness of it, yes cheap);
* precompile: a litte helper to (re)compile zsh functions/scripts found in fpath
  to speed loading and execution (p-as-personal-recompile).

[1]: https://github.com/tokiclover/prezto
[2]: https://github.com/sorin-ionescu/prezto

---
vim:fenc=utf-8:
