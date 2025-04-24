

# To track cross-compilation stages

## 04-24-2025

| Stage | Role   | System Description | System Triplet   | Notes                      |
|-------|--------|--------------------|------------------|----------------------------|
|   1   | Build  |  Ubuntu Machine    | x86_64-linux-gnu | Current working system     |
|   1   | Host   |  Inside $LFS/tools | x86_64-linux-gnu | Where temporary chain runs |
|   1   | Target |  The final LFS     | x86_64-linux-gnu | lfs root                   |
