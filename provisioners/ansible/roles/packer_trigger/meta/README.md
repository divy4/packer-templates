# packer_trigger

## Mapping

This role uses MAC addresses to map machines to their respective roles, which is determined as follows:

```
             00:12:34:56:78:9a
      Empty_/  /  /  /  /  /
Environment___/  /  /  /  /
       Role_____/  /  /  /
    Subrole_______/  /  /
     Count1_________/  /
     Count2___________/

Empty:
Always 00

Environment:
00 - Build (bld)
01 - Development (dev)
02 - Staging (stg)
03 - Production (prd)
04 - Work (wrk)

Role:
01 - Workstation
02 - Kubernetes
03 - Cache server

Subrole:
XX:00 - Generic (when no subrole is needed)
XX:01 - Leader
XX:02 - Worker
```
