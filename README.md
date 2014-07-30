`$Id: dotfiles/README.textile, 2014/07/22 18:11:51 -tclover Exp $`

---

another _dotfiles_ repository

# using this repository

* clone the repository or repositories: 
`% git clone git://github.com/tokiclover/dotfiles.git ~/`
* zsh users may clone my fork of [my-zsh][] of [oh-my-zsh][]: 
`% git clone --recurse-submodules git://github.com/tokiclover/oh-my-zsh.git .oh-my-zsh`
`% cd ~/.oh-my-zsh && git checkout my-zsh`
* and then exec your shell with `% exec $SHELL`

# .scripts: extra info

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

[my-zsh]: https://github.com/tokiclover/oh-my-zsh
[oh-my-zsh]: https://github.com/robbyrussell/oh-my-zsh

---
`vim:fenc=utf-8:`
