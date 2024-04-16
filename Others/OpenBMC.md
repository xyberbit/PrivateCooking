meta-manufacturer/
├── conf
│   └── layer.conf
├── meta-machine/
│   ├── conf
│   │   ├── bblayers.conf.sample
│   │   ├── conf-notes.txt
│   │   ├── layer.conf
│   │   ├── local.conf.sample
│   │   └── machine
│   │       └── machine-name-2.conf
│   ├── recipes-kernel
│   │   └── linux
│   │       ├── linux-obmc
│   │       │   └── machine-name-2.cfg  # Machine specific kernel configs
│   │       └── linux-obmc_%.bbappend
│   └── recipes-phosphor
│       ...
│       ├── images
│       │   └── obmc-phosphor-image.bbappend  # Machine specfic apps/services to include
│       └── workbook
│           ├── machine-name-2-config
│           │   └── Machine-name-2.py  # Machine specific workbook (see below)
│           └── machine-name-2-config.bb
└── poky
