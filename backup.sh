#!/bin/bash

# Backup Dir Location 
BACKUP_DIR="/backup"

# S3 Bucket Name
S3_BUCKET=backups-rifa-01

# Excluded subdirs from backup (separated by spaces)
EXCLUDE_DIRS=("cyberpanel" "exclude2") # Substitua "exclude1", "exclude2", etc., pelos nomes dos diretórios que você deseja excluir

# Create backup dir
mkdir -p "$BACKUP_DIR"

# set the timestamp format YYYYMMDD_HHMM
CURRENT_DATETIME=$(date +%Y-%m-%d_%H%M)

# Function to check if directory is on exclusion list
is_excluded() {
    for item in "${EXCLUDE_DIRS[@]}"; do
        if [ "$item" == "$1" ]; then
            return 0 # 0 means 'true' in shell script context
        fi
    done
    return 1 # 1 means  'false' in  shell script context
}

# Loop to list  /home subdirs and do backup from its  public_html
for dir in /home/*/public_html/; do
    # Obtain the parent dir of public_html
    parent_dir=$(basename "$(dirname "$dir")")

    # Check if parent dir is on the exclusion list
    if is_excluded "$parent_dir"; then
        echo "Pulando o diretório public_html de $parent_dir"
        continue
    fi

    # Make the backup
    tar -czf "$BACKUP_DIR/${parent_dir}_${CURRENT_DATETIME}.tgz" -C "/home/$parent_dir" "public_html"
    echo "Backing up public_html of $parent_dir concluded"
done


echo "All of public_html backups are concluded."

echo "Starting databases backup."
# Obtaining databases list
databases=$(mysql -e "SHOW DATABASES;" | tr -d "| " | grep -v Database)

# Iterating databases list and doing backup of each one
for db in $databases; do
    # Ignore  'information_schema' and others databases, if necessary
    if [[ "$db" != "information_schema" ]] && [[ "$db" != _* ]] && [[ "$db" != mysql ]] && [[ "$db" != performance_schema ]] && [[ "$db" != sys ]] ; then
        echo "Backing up database '$db'"
        mysqldump --databases $db > "$BACKUP_DIR/${db}_${CURRENT_DATETIME}.sql"
    fi
done

echo "All databases backup concluded."

# Loop to list files and upload them to S3
for backup_file in "$BACKUP_DIR"/*; do
    echo "Uploading file $backup_file to S3"

    # Uploading do S3
    s3cmd put "$backup_file" s3://backups-rifa-01/

    # Checking if sucessfully uploaded
    if [ $? -eq 0 ]; then
        echo " $backup_file sucessfully uploaded."

        # Deleting the file
        rm "$backup_file"
        echo "$backup_file deleted from local folder."
    else
        echo "Fail to upload $backup_file to S3. It will not be excluded. Next backup job a new try to upload it"
    fi
done

echo "Backup Process Concluded"
