## Overview

Mozc UT Jawiki Dictionary is a dictionary generated from the [Japanese Wikipedia](https://ja.wikipedia.org/) for Mozc.

Thanks to the Japanese Wikipedia team.

## License

mozcdic-ut-jawiki.txt: [CC BY-SA 3.0](https://ja.wikipedia.org/wiki/Wikipedia:ウィキペディアを二次利用する)

Source code: Apache License, Version 2.0

## Usage

Add mozcdic-ut-*.txt to dictionary00.txt and build Mozc as usual.

```
tar xf mozcdic-ut-*.txt.tar.bz2
cat mozcdic-ut-*.txt >> ../mozc-master/src/data/dictionary_oss/dictionary00.txt
```

To modify the costs for words or merge multiple UT dictionaries into one, use this tool:

[merge-ut-dictionaries](https://github.com/utuhiro78/merge-ut-dictionaries)

## Update this dictionary with the latest stuff

Requirement(s): ruby, rsync

```
gem install bzip2-ffi parallel

cd src/
sh make.sh
```

[HOME](http://linuxplayers.g1.xrea.com/mozc-ut.html)
