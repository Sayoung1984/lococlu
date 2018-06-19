# lococlu
Low Coupling Cluster, based on Bash Scripts, designed for Raw Image over NFS structure

## Getting Started
Basic structure as below
```
/receptionist/                 # Lococlu runtime folder, NFS mounted by all heads/nodes
├── lococlu                    # Lococlu main functions folder
│   ├── lcc.conf               # Lococlu config file
│   ├── lccmain.sh             # Lococlu main function
│   ├── noderep.sh             # Lococlu node deamon, run as cronjobs on nodes
│   └── tools                  # Lococlu extra tools folder
│       ├── autoballast.sh     # Burn cpu tool, make cpu workloads for debug
│       ├── deploynode.sh      # node deployment script, currently blank
│       └── execbdcst.sh       # Execute Broadcaster, batch send commands to all live nodes
└── opstmp                     # Lococlu operation temp folder, set as 777, for node sitreps and session lock files


/images/                       # ImgON volumes folder
├── vol01                      # ImgON volume 01, NFS mounted by all heads/nodes
└── vol02                      # ImgON volume 02, NFS mounted by all heads/nodes
└── vol..                      # ImgON volumes, NFS mounts, vol+`2 digits numeral name`
```

## Built With
* [GNU Linux](https://www.kernel.org/) - The /proc system used
* [Bash](https://www.gnu.org/software/bash/) - Fully depends on bash logic

## Authors
* **Sayoung Han** - *Initial work* - [China-SW-EC, Qualcomm Inc.](sayoungh@qti.qualcomm.com)

## License
This project is licensed under the GNU General Public License version 3 (GPL-3.0) - see the [LICENSE.md](LICENSE.md) file for details

## Current Version
### v0.2.1
noderep loop design improvements

### v0.2
workspace auto-balance function now ready in mkuserimg_v2 of noderep.sh, waiting for periphery checks to enable for Qualcomm Cluster

Missing parts:
More robust security designs.
Head and Node deploy scripts missing.
Join domain script missing.


### v0.1.3
Added global basic config file lcc.conf

Forked loop works of noderep deamon out to minimize performance impact from workloads.

### v0.1.2
Added Execute Broadcaster in tools/execbdcst.sh, to send multi-line commands to all live nodes.  


### v0.1.1
Added image seed auto generate to all NFS volumes, in noderep.sh


### v0.1
First working version with limited function.
Still need some tests to make sure everything works as expected.

Missing parts:
Security designs.
Head and Node deploy scripts missing.
Join domain script missing.
Missing user image create auto balance, currently only create user images in /images/vol01
Also maybe missing some other function on cross NFS filer structure

Anyway, too later, too tired, let's call this v0.1


### v0.0
Function not complete yet.
