# gocryptfs

All credit for the file-system itself to rfjakob/gocryptfs.
Based on docker-gocryptfs by https://github.com/OJFord/docker-gocryptfs

## Releases

Image is available at:
```
docker.io/soluga/gocryptfs
```

*BUILD/IMAGE currently not available. Need to fix Dockerfile somehow...*


In addition to `latest`, tags are available as both:
```
<gocryptfs_version>
<gocryptfs_version>-<docker_gcfs_release_number>
```

So that, for example, `gocryptfs` version `1.7.1` has:
```
1.7.1
1.7.1-1
```
and any update to the packaging in this repository will result in updating:
```
1.7.1
1.7.1-2
```
but leave `1.7.1-1` untouched. 

## Usage

Passphrase should be specified in:
```
$GOCRYPTFS_PSWD
```

Can be used to encrypt or decrypt your files.
```
/encrypt/decrypted/<some dir> will be encrypted to /encrypt/encrypted/<some dir>
/decrypt/encrypted/<some dir> will be decrypted to /decrypt/decrypted/<some dir>
```

Initialization of gocryptfs-config-file is automatically done if you provide
```
$AUTOINIT=true
```
Please be sure to check the logs upon first start (initialization) because the master-key will be printed there and should be writen down!

## Docker compose
```
version: '3.8'
services:
  gocryptfs:
    image: soluga/gocryptfs:latest
    container_name: gocryptfs
    privileged: true
    stdin_open: true
    tty: true
    environment:
      - GOCRYPTFS_PSWD=YourSecretPasswordGoesHere!
      - AUTOINIT=true
    
    volumes:
    - /docker_dev/gocryptfs:/new_dev
    - type: bind
      source: /gocryptfs/encrypt/decrypted/
      target: /encrypt/decrypted/
      bind:
          propagation: rshared
    - type: bind
      source: /gocryptfs/encrypt/encrypted/
      target: /encrypt/encrypted/
      bind:
          propagation: rshared

    - type: bind
      source: /gocryptfs/decrypt/encrypted/
      target: /decrypt/encrypted/
      bind:
          propagation: rshared
    - type: bind
      source: /gocryptfs/decrypt/decrypted/
      target: /decrypt/decrypted/
      bind:
          propagation: rshared
```

## Licence

MIT.
