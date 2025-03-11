# Learning from Shell Scripting

<details>
  <summary><b>🛠️&nbsp;&nbsp;Languages&nbsp;and&nbsp;Tools</b></summary>
  <br/>
  <p align="left"> Lot more details about the script in the repo
</details>
  

### Shell: Send all output to the logfile as well as stdout.
```
exec 3< thisfile          # open "thisfile" for reading on file descriptor 3
exec 4> thatfile          # open "thatfile" for writing on file descriptor 4
exec 8<> tother           # open "tother" for reading and writing on fd 8
exec 6>> other            # open "other" for appending on file descriptor 6
exec 5<&0                 # copy read file descriptor 0 onto file descriptor 5
exec 7>&4                 # copy write file descriptor 4 onto 7
exec 3<&-                 # close the read file descriptor 3
exec 6>&-                 # close the write file descriptor 6
```

### Shell: Prompt Statement (PS)

- PS1: Default interaction prompt
- PS2 – Continuation interactive prompt
- PS3 – Prompt used by “select” inside shell script
- PS4 – Used by “set -x” to prefix tracing output

<pre>
PS3="Select a day (1-4): "
select i in mon tue wed exit
# Shows 
1) mon
2) tue
3) wed
4) exit
Select a day (1-4): 1
</pre>

<pre>
export OLD_PS4=$PS4
export PS4='+($(date +"%b %d %H:%M:%S") ${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

</pre>



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

## Case modification
These expansion operators modify the case of the letters in the expanded text.
```
${PARAMETER^}   - Change first character to uppercase
${PARAMETER^^}  - Change all characters to uppercase
${PARAMETER,}   - Change firt characters to lowercase
${PARAMETER,,}  - Change all characters to lowercase
${PARAMETER~}   - Reverses the case of first letter of words in the variable 
${PARAMETER~~}  -  ~~ reverses case for all.
```
The ^ operator modifies the first character to uppercase, 
the , operator to lowercase. 
When using the double-form (^^ and ,,), all characters are converted.

**Example** rename all .dat files to uppercase
```
for file in *.dat; do
  mv "$file" "${file^^}"
done
```

```
array=(This is some Text)

echo "${array[@],}"
⇒ this is some text
echo "${array[@],,}"
⇒ this is some text
echo "${array[@]^}"
⇒ This Is Some Text
echo "${array[@]^^}"
⇒ THIS IS SOME TEXT
echo "${array[2]^^}"
⇒ SOME
```


## Default value use and assignment

```
If the parameter PARAMETER is unset (never was defined) or null (empty), this one expands to WORD, 
otherwise it expands to the value of PARAMETER, as if it just was ${PARAMETER}. 
If you omit the : (colon), like shown in the second form, the default value is only used when the 
parameter was unset, not when it was empty.

${PARAMETER:-WORD}

${PARAMETER-WORD}
```


```
${PARAMETER:=WORD}

${PARAMETER=WORD}
```













# Reference List 

[]([http://web.archive.org/web/20230404084543/https://wiki.bash-hackers.org/syntax/pe#use_a_default_value](http://web.archive.org/web/20230404084543/https://wiki.bash-hackers.org/syntax/pe))
