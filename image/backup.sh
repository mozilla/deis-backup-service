#!/bin/bash
# Based on https://github.com/glogiotatidis/audiometric-services/blob/master/runner/backup.sh from Ian Blenke
# License: Apache License, Version 2.0

set -eo pipefail

[ -n "$AWS_ACCESS_KEY" ] || (
  echo "Need actual AWS S3 environment variable defined: AWS_ACCESS_KEY"
  false
)
[ -n "$AWS_SECRET_KEY" ] || (
  echo "Need actual AWS S3 environment variable defined: AWS_SECRET_KEY"
  false
)
[ -n "$AWS_BACKUP_BUCKET" ] || {
  echo "Need AWS_BACKUP_BUCKET defined"
  false
}
[ -n "$DEIS_DOMAIN" ] || {
  echo "Need DEIS_DOMAIN defined that you are using for your wildcard DNS for DEIS"
  false
}
[ -n "$HOST" ] || {
  echo "Need HOST of container defined"
  false
}

# configure etcd
ETCD_PORT=${ETCD_PORT:-4001}
ETCD="$HOST:$ETCD_PORT"
ETCD_TTL=${ETCD_TTL:-10}

# wait for etcd to be available
until etcdctl --no-sync -C $ETCD ls >/dev/null 2>&1; do
  echo "runner: waiting for etcd at $ETCD..."
  sleep $(($ETCD_TTL/2))  # sleep for half the TTL
done

DEIS_CONFIG_FILE=${DEIS_CONFIG_FILE:-~/.s3cfg.deis}
AWS_CONFIG_FILE=${AWS_CONFIG_FILE:-~/.s3cfg.aws}

CEPH_ACCESS_KEY="$(etcdctl -C ${ETCD} get deis/store/gateway/accessKey)"
CEPH_SECRET_KEY="$(etcdctl -C ${ETCD} get deis/store/gateway/secretKey)"
DATABASE_BUCKET_NAME="$(etcdctl -C ${ETCD} get /deis/database/bucketName)"
REGISTRY_BUCKET_NAME="$(etcdctl -C ${ETCD} get /deis/registry/bucketName)"
DATABASE_BUCKET_NAME="${DATABASE_BUCKET_NAME:-db_wal}"
REGISTRY_BUCKET_NAME="${REGISTRY_BUCKET_NAME:-registry}"
if [ -n "${PASSPHRASE:+x}" ]
then
    ENCRYPT="True"
else
    ENCRYPT="False"
fi

BACKUP_DIR="./`date +%Y-%m-%d-%H:%M`"


cat s3cfg | ACCESS_KEY=${AWS_ACCESS_KEY} SECRET_KEY=${AWS_SECRET_KEY} HOST_BASE=s3.amazonawscom HOST_BUCKET=%\(bucket\)s.s3.amazonaws.com ENCRYPT=${ENCRYPT} PASSPHRASE=${PASSPHRASE} envsubst > ${AWS_CONFIG_FILE}

cat s3cfg | ACCESS_KEY=${CEPH_ACCESS_KEY} SECRET_KEY=${CEPH_SECRET_KEY} HOST_BASE=deis-store.${DEIS_DOMAIN} HOST_BUCKET=deis-store.${DEIS_DOMAIN} ENCRYPT=False PASSPHRASE=${PASSPHRASE} envsubst > ${DEIS_CONFIG_FILE}

set -x

# Copy the deis
mkdir -p "${BACKUP_DIR}/${DATABASE_BUCKET_NAME}/"
s3cmd -c "${DEIS_CONFIG_FILE}" get -r "s3://${DATABASE_BUCKET_NAME}/" "${BACKUP_DIR}/${DATABASE_BUCKET_NAME}"
mkdir -p "${BACKUP_DIR}/${REGISTRY_BUCKET_NAME}/"
s3cmd -c "${DEIS_CONFIG_FILE}" get -r "s3://${REGISTRY_BUCKET_NAME}/" "${BACKUP_DIR}/${REGISTRY_BUCKET_NAME}"

# Copy the local db_wal bucket to AWS
s3cmd -c "${AWS_CONFIG_FILE}" put -r "${BACKUP_DIR}" "s3://${AWS_BACKUP_BUCKET}/"
