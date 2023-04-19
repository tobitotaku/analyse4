#!/usr/bin/bash
# Naam: Tobias Roessingh; Student ID: 1042623
# Naam: Marchano Gopal; Student ID: 1038165
# Declare global variables
errorLog() {
  read IN
  if [ -n "$IN" ]; then
    echo "${0/\.\//} gave an error. find out more in log.txt"
    current=$(date +'%m/%d/%Y %H:%M:%S')
    echo "$current : $IN" >> log.txt
    echo "$(tail -n -10 log.txt)" > log.txt
    exit 0
  fi
}
# Error messages
errorNoDir() {
    echo "Invalid: No destination directory given for parameter -d"
    exit 0
}
errorNoPw() {
    echo "Invalid: No passwords given for parameter -p"
    exit 0
}
errorOption() {
    echo "Invalid parameter '$1' given for '$2'"
    exit 0
}

(
  BaseDest=''
  BaseOrigin=''
  OverWrite=false
  HasPw=false
  Passwords=()
  InLength=0


  # When -o is first param
  if [ "$1" == '-o' ]; then
    OverWrite=true
    let ++InLength
    if [ "$2" == '-d' ]; then
      let ++InLength
      if [ -z "$3" ]; then
        errorNoDir
      elif [ -d "$3" ]; then
        BaseDest=$3
        let ++InLength
      else
        errorOption $3 $2
      fi
      if [ "$4" == '-p' ]; then
      let ++InLength
      if [ -z "$5" ]; then
        errorNoPw
      fi
      HasPw=true
    fi
    elif [ "$2" == '-p' ]; then
      let ++InLength
      if [ -z "$3" ]; then
        errorNoPw
      fi
      HasPw=true
    fi
  # When -d is first param
  elif [ "$1" == '-d' ]; then
    let ++InLength
    if [ -z "$2" ]; then
      errorNoDir
    elif [ "$2" == '-o' ]; then
      errorOption $2 $1
    elif [ -d "$2" ]; then
      BaseDest=$2
      let ++InLength
    else
      errorOption $2 $1
    fi
    if [ "$3" == '-o' ]; then
      errorOption $3 $2
    elif [ "$3" == '-p' ]; then
      let ++InLength
      if [ -z "$4" ]; then
        errorNoPw
      fi
      HasPw==true
    fi
  # When -p is first param
  elif [ "$1" == '-p' ]; then
    if [ -z "$2" ]; then
      errorNoPw
    elif [ "$2" == '-o' ]; then
      errorOption $2 $1
    elif [ "$2" == '-d' ]; then
      errorOption $2 $1
    elif [ "$3" == '-o' ]; then
      errorOption $3 $1
    elif [ "$3" == '-d' ]; then
      errorOption $3 $1
    fi
    HasPw==true
    let ++InLength
  fi

  # Set Default Destination folder
  if [ -z "$BaseDest" ]; then
      BaseDest="archive"
      if [[ -d $BaseDest || -L $BaseDest ]] ; then
          i=1
          while [[ -d "$BaseDest$i" || -L "$BaseDest$i" ]] ; do
              let i++
          done
          BaseDest="$BaseDest$i"
      fi
  fi

  Params=( "$@" )
  LenParams="${#Params[@]}"
  # Set Passwords from Params
  if [ $HasPw==true ]; then
    while [ $InLength -le $LenParams ]; do
      Passwords=(${Passwords[@]} "${Params[$InLength]}")
      let ++InLength
    done
  fi

  FileExts=$(find $BaseOrigin ! -name "${0/\.\//}" ! -name log\.txt  ! -path "*archive*" -type f | sed -e 's/.*\././' | sort -n | uniq -c -i | tr -d ' ')
  for FileExt in $FileExts; do
    echo "${FileExt/\./ file\(s\) with extension\: \.}"
  done

  # iterate through files, skip current bash script and archive dir's
  for FileToMv in $(find $BaseOrigin ! -name "${0/\.\//}" ! -name log\.txt ! -path "*archive*" -type f);do
    # echo $FileToMv
    TargetDateFolder=$(find $FileToMv -type f -printf %TF)
    $(mkdir -p "$BaseDest/$TargetDateFolder")
    IsOverWrite=''
    BaseFile=$(basename -- "$FileToMv")
    if [ $OverWrite == true ];then
      IsOverWrite=' -f '
    else
      # Check file exists
      if [[ -f "$BaseDest/$TargetDateFolder/$BaseFile" ]]; then
        i=1
        # Increment filename
        while [[ -f "$BaseDest/$TargetDateFolder/${BaseFile/\./\.$i\.}" ]]; do
          let ++i
        done
        BaseFile="${BaseFile/\./\.$i\.}"
      fi
    fi
    # copy preserve
    $(cp -p$IsOverWrite $FileToMv "$BaseDest/$TargetDateFolder/$BaseFile" && rm -rf $FileToMv)
    # clean up origin
    if [[ "$BaseDest/$TargetDateFolder/$BaseFile" =~ \.zip$ ]];then
      for pw in ${Passwords[@]}; do
        $(unzip -q -j -o -d "$BaseDest/$TargetDateFolder" -P "$pw" "$BaseDest/$TargetDateFolder/$BaseFile" )
      done
    fi
  done

  # clean up origin
) 2> >(errorLog)