# backup script
backup-script /home and mysql databases

This is a backup script to send websites to S3 buckets. I made it with the purpose to backup CyberPanel non-wordpress websites and its databases to a S3 Bucket.

What the scripts do is very simple:

- It check for /home/anything/public_html directories and it TAR such directories. It is possible to put subdirectories in exclusion lists
- After this it connect in mysql to show all databases and then backup these DBs each one in it own .sql file. Again, it is possible to create exceptions
- For last it lists the backup directory and calls s3cmd sendind each file found to the S3 repository, and excluding each file after successfully upload it. 
