# lococlu
Low Coupling Cluster, based on Bash Scripts, designed for Raw Image over NFS structure

v0.2

workspace auto-balance function now ready in mkuserimg_v2 of noderep.sh, waiting for periphery checks to enable for Qualcomm Cluster

Missing parts:
More robust security designs.
Head and Node deploy scripts missing.
Join domain script missing.


v0.1.3

Added global basic config file lcc.conf

Forked loop works of noderep deamon out to minimize performance impact from workloads.

v0.1.2

Added Execute Broadcaster in tools/execbdcst.sh, to send multi-line commands to all live nodes.  


v0.1.1

Added image seed auto generate to all NFS volumes, in noderep.sh


v0.1

First working version with limited function.
Still need some tests to make sure everything works as expected.

Missing parts:
Security designs.
Head and Node deploy scripts missing.
Join domain script missing.
Missing user image create auto balance, currently only create user images in /images/vol01
Also maybe missing some other function on cross NFS filer structure

Anyway, too later, too tired, let's call this v0.1


v0.0

Function not complete yet.
