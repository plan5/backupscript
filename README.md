backupscript
============

Notes for Version 0.1:
----------------------

A script that allows to run rsnapshot manually and run the next backup level once the previous level has reached its retention limit.

Possibly an unnecessary solution but I did not find it within rsnapshot. Maybe this could also be solved more easily using rsync an cp alone.

A good practice anyhow. If this ever gets popular (more than 3 users, I suppose) the project will be renamed to something more unique.

Version 0.1 was designed to run on bash 4.3+.

For testing mode, run:
test=1 ./backupscript.sh

For less verbosity unset debug in backupscript.sh.
