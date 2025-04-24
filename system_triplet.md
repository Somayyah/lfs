

# To track cross-compilation stages

“pc” means the commands are run on a machine using the already installed distribution. “On lfs” means the commands are run in a chrooted environment.

## 04-24-2025

| Stage | Role   | System Description    |  CC  | System Triplet   | Notes                      |
|-------|--------|-----------------------|------|------------------|----------------------------|
|   1   | Build  |  pc                   |      | x86_64-linux-gnu | Current working system     |
|   1   | Host   |  pc, Inside $LFS/tools|      | x86_64-linux-gnu | Where temporary chain runs |
|   1   | Target |  The final LFS        |      | x86_64-linux-gnu | lfs root                   |

