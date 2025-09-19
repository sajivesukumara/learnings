# Variable assignments
## The colon at the start is a no-op operator and will ignore if the value (rhs) is a command 
## In the example below running below line without the first colon will execute the command helm 
## and if not found it will throw the error "helm: command not found", if command exists, then
## it assigns teh command string to variable and also executes the command.
## This assignment could also be done by excluding the ${}, how this is added so that if this variable 
## is already assigned, do not overwrite it.

: ${BINARY_NAME:="helm"}

${}

# initArch discovers the architecture for this system.
initArch() {
  ARCH=$(uname -m)
  case $ARCH in
    armv5*) ARCH="armv5";;
    armv6*) ARCH="armv6";;
    armv7*) ARCH="arm";;
    aarch64) ARCH="arm64";;
    x86) ARCH="386";;
    x86_64) ARCH="amd64";;
    i686) ARCH="386";;
    i386) ARCH="386";;
  esac
}


# runs the given command as root (detects if we are root already)
runAsRoot() {
  if [ $EUID -ne 0 -a "$USE_SUDO" = "true" ]; then
    sudo "${@}"
  else
    "${@}"
  fi
}
