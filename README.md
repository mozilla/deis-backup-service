## Setup daily Deis backups

0. SSH into a Deis instance
1. `git clone https://github.com/glogiotatidis/deis-backup-service`
2. Edit `units/deis-backup.service`
  - `AWS_ACCESS_KEY`: AWS S3 Access Key
  - `AWS_SECRET_KEY`: AWS S3 Secret Key
  - `AWS_BACKUP_BUCKET`: AWS S3 Backup Bucket. Example `masterfirefoxos-backup/deis`
  - `DEIS_DOMAIN`: Deis Domain. Example `masterfirefoxos.com`
  - `PASSPHRASE`: Passphrase for gpg encryption of data uploaded to S3. Optional.
  - `AWS_HTTPS`: Use HTTPS to connect to S3. `True` or `False`. Optional defaults to `True`.
  - `AWS_REDUCED_REDUNDANCY`: Use AWS Reduced Redundancy. `True` or `False`. Optional defaults to `False`.
3. `fleetctl load deis-backup.service`
4. `fleetctl load deis-backup.timer`
5. `fleetctl start deis-backup.timer`

You don't need to start `deis-backup.service`, timer service will take care of that when it's time.

`fleectl list-units` should list both services like this

 - deis-backup.service		5277b5e9.../10.21.2.84	inactive	dead
 - deis-backup.timer		5277b5e9.../10.21.2.84	inactive	waiting


If you want to change the frequency of the backups, edit [deis-backup.timer](units/deis-backup.timer) unit and adjust `OnCalendar` entry to your needs. You can read more about the `Timer` format on [systemd.timer](http://www.freedesktop.org/software/systemd/man/systemd.timer.html) documenation.
