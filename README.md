Header: dotfiles/README.md

---

another _dotfiles_ repository

COPYING
-------

2-clause (*simplified* or *new*) BSD or MIT at your *name* preference

(if not explicitly stated otherwise in particular files)

USAGE
-----

* clone the repository or repositories with `--recurse-submodules` to get
everything in one shot cloning: 
```
    % git clone git://gitlab.com/tokiclover/dotfiles.git dotfiles
```
* zsh users may clone my [fork][1] of [prezto][2]: 
```
    % git clone --recurse-submodules git://gitlab.com/tokiclover/prezto.git .zprezto
```
* and then exec your shell with `% exec $SHELL`

* {BA,Z}sh Prompt Preview with Terminology virtual terminal/Fixed font
![](https://imgur.com/qWXRrc6.png)

* {BA,Z}sh Prompt Preview with Rxvt-unicode virtual terminal/Terminus font
![](https://imgur.com/FVjfmRj.png)

* [pentadactyl][4] users may merge *www-misc/dactyl* packages from [bar][3]
overlay to get current version without fetching the whole binary each time.

GIT-SUBMODULES
--------------

### zprezto

    git submodule update --init --recursive .zprezto

FILES
-----
### /bin

* bhp: is a simple script amintianing Browser-Home-Profile and cache directory to
       tmpfs (or zram backed FileSystem by specifying -t|--tmpdir [DIR]);
* ips: is a script which can be used to retrieve IP block lists to be added to iptables rules;
* ipr: is script to generate statefull ip[6]tables net rules;
* lbd: is a script to add/remove loop back devices;
* a2jloop: a script to map loopback device to jack client (support zita/alsa);
* mktmp: a simple and cheap mktemp variant to set up tmp-{dir,file}s; 
* magnet: a little script to transliterate magnet uri to torrent (file);
* mkstage4: a stage4 maker scripts with squashed (system/local) directories support;
* soundon.user: an oss4 user soundon script;
* term256colors: terminal colors display scripts;
* xtr: stand for eXtract TaRball, just run with a list of tarball to extract;
* bfd-plugins: switch ld plugin beetwen LLVMgold.so and GCC liblto_plugin.so,
  beware to switch to bfd or gold beforehand (using: binutils-config --linker bfd).

### /lib

* functions.{ba,z}sh: a very few common helpers used in other scripts;
* helpers.bash for extra bash helpers (zsh equivalent are `.zsh/functions`);

### /etc

* etc/qemu/qemu-vlan: virtual LAN, network, manager for virtualization emulators
like QEMU, UML,...;

MIRRORS
-------

* https://github.com/tokiclover/dotfiles

[1]: https://gitlab.com/tokiclover/prezto
[2]: https://github.com/sorin-ionescu/prezto
[3]: https://gitlab.com/tokiclover/bar-overlay
[4]: http://5digits.org/pentadactyl

---
vim:fenc=utf-8:
