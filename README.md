# microNMR

This is a repo for microNMR project, a miniaturized NMR sensor assembly that can perform high-quality relaxation measurements under extreme conditions. 

Currently, it includes both firmware (in C) and software (in Matlab) that work for Rev aa board.

The sensor performs the following experiments:

- power-up diagnosis,
- FID,
- LF search,
- nutation experiments,
- spin echo, shape recording,
- CPMG (window-sum optional),
- IRCPMG.

It is the codebase that used to generate data in the following paper:

https://www.nature.com/articles/s41598-019-47634-2
