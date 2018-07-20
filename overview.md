nanobot:

- fission/fusion
- loads **trace**
- placed on origin of **matter subspace pad**
- constructs **trace**

trace:

- patterns for construction
- default traces are extremely energy inefficient
- generate **traces** that construct **target 3d objects** with minimal energy

matter subspace pad:
- facilities energy to matter
- generates global field that allows **matrix** of **voxels**
- field holds matter in **fixed position** in the matrix
- two modes: **low** and **high** harmonics
  - low harmonics: matter must be part of a connected component that rests on the floor: _grounded_
  - high harmonics: matter is unconstrained: _floating_

nanobots:
- focus the field for matter conversion
- can move through empty voxels in the matrix
- in high harmonics nanobots can be floating
- can build another nanobot
- can join with another nanobot

construction:
- begins and ends with a single nanobot at the origin of the matter subspace pad
- proceeds in discrete time steps

time steps:
- the pad generates a sync time-step signal
- signal coordinates nanobots
- each **active** nanobot performs a single command
- all commands take effect **simultaneously** at the end of the time step
- if the commands of different nanobots interfere at resolution then it is an **error**

nanobot commands:
- move
- swap harmonics
- create matter
- create nanobot
- join nanobot

energy:
- each time step has an **energy cost**
- energy cost depends on
  - the volume of the space
  - the global harmonics
  - nanobot commands being performed

