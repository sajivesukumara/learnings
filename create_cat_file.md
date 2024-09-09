## Creating file using CAT and EOF

### Print to STDOUT

```
cat <<EOF
    Usage: $0 [OPTION]...
    -h, --help          Print this usage message"
    -i, --initialize    Setup pre-requisites"
EOF
```

### Write to a new file

```
cat > "$HOME/pod.json" <<-EOF
{
  "metadata": {
    "name": "busybox"
  },
  "image":{
    "image": "busybox"
  },
  "command": [
    "top"
  ],
  "log_path":"busybox.log",
  "linux": {
  }
}
EOF
```

```
cat << EOF > con-test.config
{
  "metadata": {
    "name": "busybox"
  },
  "image":{
    "image": "busybox"
  },
  "command": [
    "top"
  ],
  "log_path":"busybox.log",
  "linux": {
  }
}
EOF
```

### Append to end of existing gile

```
cat << EOF >> con-test.config
{
  "metadata": {
    "name": "busybox"
  },
  "image":{
    "image": "busybox"
  },
  "command": [
    "top"
  ],
  "log_path":"busybox.log",
  "linux": {
  }
}
EOF

```
## Redirect with TEE command
```
cat <<EOF | tee sandbox.json
{
    "metadata": {
        "name": "nginx-sandbox",
        "namespace": "default"
    }
}
EOF
```
## Bonus
### Send multiline content to any command say kubectl
```
kubectl exec -it atlas-vault-0 -- sh << EOF
vault write auth/kubernetes/role/atlas \
vault kv put storagecentral/app/atlas-onprem-backup-manager/postgres username=atlas_onprem_backup_manager  password=hpinvent
vault kv put storagecentral/app/atlas-reporting/postgres username=atlas_reporting password=hpinvent
EOF
```
