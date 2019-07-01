# lococlu
Low Coupling Cluster, based on Bash Scripts, designed for Raw Image over NFS structure

## Getting Started
Basic structure as below
```
/receptionist/                 # Lococlu runtime folder, NFS mounted by all heads/nodes
├── lococlu                    # Main functions folder
│   ├── backstage.conf         # LCC bypass white list
│   ├── lcc.conf               # Main config file (ignored by git, a sample was provided instead)
│   ├── lccmain.sh             # Main function
│   ├── noderep.sh             # Node deamon, run as cronjobs on nodes
│   └── tools                  # Extra tools folder
│       ├── autoballast.sh     # Burn cpu tool, make cpu workloads for debug
│       ├── deploynode.sh      # Node deployment script, currently blank
│       ├── dskbill.sh         # User team disk quota usage calculator
│       ├── dskusg.sh          # NFS volume quota usage percentage calculator
│       ├── imgdel.sh          # User code image delete tool
│       ├── execbdcst.sh       # Execute Broadcaster, batch send commands to all live nodes
│       └── mgrlist            # User team manager list for dskbill.sh
└── opstmp                     # Operation temp folder, set as 777, for node sitreps and session lock files
└── dbgtmp                     # Debug temp folder (optional), set as 777, for geoexec tickets trace

/images/                       # ImgON volumes mount point nest
├── vol00                      # ImgON volume 00, NFS mounted by all heads/nodes, code image template volume
├── vol01                      # ImgON volume 01, NFS mounted by all heads/nodes, user root image volume
├── vol02                      # ImgON volume 02, NFS mounted by all heads/nodes, user root image volume
└── vol..                      # ImgON volumesXX, NFS mounted by all heads/nodes, vol+`2 digits numeral name`, user root image volume
```

## Built With
* [GNU Linux](https://www.kernel.org/) - The /proc system used
* [Bash](https://www.gnu.org/software/bash/) - Fully depends on bash logic

## Authors
* **Sayoung Han** - *Initial work* - [China-SW-EC, Qualcomm Inc.](sayoungh@qti.qualcomm.com)
* **Joey Jiang** - *GV duty & Jenkins developments* - [China-SW-EC, Qualcomm Inc.](ziyij@qti.qualcomm.com)

## License
This project is licensed under the GNU General Public License version 3 (GPL-3.0) - see the [LICENSE.md](LICENSE.md) file for details

## Missing parts
* Change sitrep exchange from text files over NFS volume to rsyslog system
* Auto-scanner of "Ghost loop mount" issue, sometimes the user images are loop mounted without mount point, mostly when unmounting stuck.
* Head and Node deploy scripts.
* Join domain script.

## Known issue
* L1 issue: Potentially "Ghost loop mount" issue. ( Should be highly improved in v0.6.1 )
* L2 issue: launchlock file accumulation issue.
* L3 issue: Half disconnected lccmain.sh session burning head CPU.

## Current Version
## v0.6.5a
* Minor bugfix on geoexec(), mountcmd() and usereject main function.
## v0.6.5
* Renewed secrtsend_execbd() to avoid user conflict.
* Fully functioning user eject tool.
* Disabled loop device deletion operations, this might be the reason of loop device number used up issue.
* Suggest regularly reboot nodes to avoid loop device number used up issue, before this problem is radically fixed.
## v0.6.4
* Added loop device quantity patch to mountcmd()
* Added user eject tool: usereject.sh
* Renewed geoexec ticket name rules for secrtsend() and geoexec() modules on lccmain.sh, noderep.sh, imgdel.sh and execbdcst.sh to avoid user ticket conflict.
## v0.6.3
* Improved noderep output under heavy load and high NFS latency.
* Added experimental tee bypass output debug method for unirep() of noderep.
* Added noderep sitrep output line count debug tool DBG_RepLengthCheck.
* More accurate text transform process for mountcmd() of lccmain.sh
* Better performance for image list process of lccmain.sh
## v0.6.2b
* bugfix terminator() suicide issue fixed.
## v0.6.2a
* bugfix on geoexec(), no time check needed on this module.
* Added multiple tickets concurrent execution funciton to geoexec()
* bugfix on lccmain draft ticket conflict, add $LOGNAME behind drafts.
## v0.6.2
* noderep.sh high performance revision block 2, with execute sequence structure renewed and dedicated performance debug module added.
## v0.6.1
* Secured mount logic now covering all mount conditions, including new user, full mount, image add, switch nodes and auto abort image multiple mount ( single node and cross nodes ) .
* Reliability update for terminator() kill actions.
## v0.6.0
* Added full mount integrity check for lccmain.sh to prevent user images been mounted in wrong way when login.
* Renewed terminator() module for lccmain.sh, terminator now works with multiple node kill, more secured image unmount, and with active loop device remove been added.
* Renewed mountcmd() module for lccmain.sh, with simpler text conversion logic
* Minor display update on module secpatch() of lccmain.sh.
* lccmain.sh now using standrad issued secrtsend_execbd to send tickets.
* secrtsend_execbd and secrtsend is now using RAM disk /tmp for better performance.
* Added experimental user root image move tool vol2to5.sh and vol2to5_neat.sh.
* noderep.sh is outputing performance debug info into /tmp/nodereplag.log on each node.
## v0.5.3c
* High performance revision block 1 for noderep.sh, reduced the sitrep refresh latency.
## v0.5.3b
* Added loop device delete when unmount image, reliability patch.
## v0.5.3a
* Added Jenkins image delete tool
## v0.5.3
* Added image delete tool: imgdel.sh
* More robust image unmount operations.
## v0.5.2a
* Most details provided by dskusg.sh
* Input module of image dump tool
## v0.5.2
* Realtime PerfIndex is now SRSS of CPU and IO load indexes.
## v0.5.1
* Added Sub-function "darwinawards" to noderep.sh to kill users not connecting via cluster head out per-loop.
## v0.5.0
* Changed the realtime sitrep system into universal single sitrep file, with line data type declarations. To lower the NFS exchange frequency, and as preparation to move from text log system to rsyslog system.
## v0.4.1
* Added admin lccmain bypass whitelist function (/receptionist/lococlu/backstage.conf). No SSH2 needed now.
## v0.4.0
* Added compatibility with premade code template image management system over Jenkins. (AFBF phase II function)
* Bypass code template image NFS volume (/images/vol00) when creating user root workspace images.  (AFBF phase II function)
* Added a user image mount integrity check to make sure all user images are mounted, including the new images just created.  (AFBF phase II function)
## v0.3.3
* Changed NFS volume usage balance calculation logic from by real used space percentage to by quota usage percentage.
* Added quota assign percentage calculation tool script "/receptionist/lococlu/tools/dskusg.sh"
## v0.3.2
* Fixed he issue "When next mount level image existing, root workspace image creating will be skipped".
## v0.3.1b
* Removed /var/adm/gv/user sync since the permission sync function is taken over by GV duty afbf-login
## v0.3.1a
* Roll back from 0.3.2 as the "root image mount" bugfix needs further tests
### v0.3.1
* Added IO status sensor into noderep and lccmain "switch node" mechanism
### v0.3
* Added PerfScore mechanism to noderep, lococlu now fully support asymmetrical nodes. Yet, still recommend to add nodes with similar hardware spec into cluster
* New lccmain running logic, image mount check before image existence check, for quicker daily response and evolution of mkuserimg
* Unified mkuserimg into geoexec framework, foundation of premade code template call
* Improved geoexec response time and noderep loop cleanups

### v0.2.1
noderep loop design improvements

### v0.2
workspace auto-balance function now ready in mkuserimg_v2 of noderep.sh, waiting for periphery checks to enable for Qualcomm Cluster

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
