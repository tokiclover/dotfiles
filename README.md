`$Id: dotfiles/README.textile, 2014/08/31 18:11:51 -tclover Exp $`

---

another _dotfiles_ repository

# COPYING:

2-clause (*simplified* or *new*) BSD or MIT at your *name* preference

(if not explicitly stated otherwise in particular files)

# Using this repository:

* clone the repository or repositories: 
`% git clone git://github.com/tokiclover/dotfiles.git ~/`
* zsh users may clone my [fork][] of [oh-my-zsh][]: 
`% git clone --recurse-submodules git://github.com/tokiclover/oh-my-zsh.git .oh-my-zsh`
* and then exec your shell with `% exec $SHELL`
* another alternative is to clone this repository with *--recurse-submodules* passed to *git*
* your HOME dir is not empty? just back up your dot files, clone to another directory like *dotfiles* and then move everything manualy to your $HOME dir

# Scripts extra info (/scr):

* cbu: is a simple script to back up/restore cfg files or directories;
* fhp: is a simple script which put firefox profile into tmpfs/zram backed FS (dep: functions.$shell);
* functions: functions for bash and zsh, almost only die() helper;
* hdu: is a simple script which ease updating '$Header:...$' or '$Id:...$' update;
* ips: is a script which can be used to retrieve IP block lists to be added to iptables rules;
* ipr: is script to generate ip[6]tables net rules;
* kvm: is a script to ease kvm loadind with a few default option;
* lbd: is a script to add/remove loop back devices;
* mkstage4: a stage4 maker scripts with squashed (system and/or local) directories support;
* soundon.user: an oss4 user soundon script;
* term'*': terminal colors display scripts;
* zram.initd: a init service to initialize zram devices.
* zramdir.initd: an init svc which can put several directories (var/{log,run,lock}..) into zram backed fs.
* xtr: stand for eXtract TaRball, just run with a list of tarball to extract;
* bfd-plugins: switch ld plugin beetwen LLVMgold.so and GCC liblto_plugin.so,
    beware to switch to bfd or gold beforehand (using: binutils-config --linker bfd).

[fork]: https://github.com/tokiclover/oh-my-zsh
[oh-my-zsh]: https://github.com/robbyrussell/oh-my-zsh

---
`vim:fenc=utf-8:`
