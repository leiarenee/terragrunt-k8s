#!/bin/bash
set -e

trap 'catch $? $LINENO' EXIT ERR

# Source env
source ".envrc"

export TG_COMMAND=${1:-$TG_COMMAND}

function catch() {

  if [ $1 -ne 0 ]
  then
    bash_error=true
    echo "Error occured in $BASH_SOURCE"
    echo "Exitcode $1 from Line $2"
  else
    echo "$BASH_SOURCE exited with 0 Exitcode"
  fi

}

function find_modules(){
  echo Getting Modules List...
  #tg_modules=$(python3 -m runtask json-modules)
  set +e
  tg_groups=$(python3 -m runtask json-groups)
  [ $? -ne 0 ] && echo "$tg_groups" && exit 
  set -e
  export TG_MODULES_LIST=$(echo $tg_groups | jq 'values[][]' | jq . --slurp -c)
  echo "Terragrunt will run the modules in the following order."
  echo $tg_groups | jq .
  export TG_MODULES_COMPLETED=[]
  export TG_MODULES_COUNT=$(echo $TG_MODULES_LIST | jq length)
  echo
  echo Total number of modules to be processed: $TG_MODULES_COUNT
  echo
  sleep 1
  
}

# Run Terragrunt
function run_terragrunt(){

  # Prepare command line arguments

  if [[ $INTERACTIVE != true ]]
  then
    tg_non_interactive="--terragrunt-non-interactive"
    if [[ $TG_COMMAND == "apply" ]] || [[ $TG_COMMAND == "destroy" ]] && [[ $RUN_ALL != "true" ]] 
    then
      tg_non_interactive="$tg_non_interactive -auto-approve"
    fi
  fi

  if [[ $RUN_ALL == "true" ]] 
  then
    tg_run_all=run-all
  fi

  if [[ $TG_COMMAND == plan ]]
  then
    TG_ARGUMENTS="$TG_ARGUMENTS -out=plan-state-file"
  fi

  if [[ $COMPACT_WARNINGS == true ]]
  then
    tf_compact_warnings="-compact-warnings"
  fi

  working_dir=$WORK_FOLDER/$STACK_FOLDER/$RUN_MODULE

  # Escape / Character
  escaped_stack_path=$(echo "$WORK_FOLDER" | sed s/\\//\\\\\\//g)
  
  if [[ $COMPACT_STDOUT == true ]]
  then
    stderr_output=/dev/null
  else
    stderr_output=1
  fi


  
  # Prepare command line arguments for interactive or non-interactive usage
  if [[ $INTERACTIVE == "true" ]]
  then
    echo Interavtive Session Activated
  else
    export TG_DISABLE_CONFIRM=true
  fi
  
  set +e

  [[ -z $LOG_LEVEL ]] && export LOG_LEVEL=info

  # Run terragrunt init
  if  [[ $TG_COMMAND == apply ]] || [[ $TG_COMMAND == destroy ]] || [[ $TG_COMMAND == plan ]] 
  then
    if [[ $FORCE_INIT == true ]]
    then
      echo ---------- Initializing Modules ----------------------
      terragrunt $tg_run_all init \
        --terragrunt-working-dir $working_dir  \
        $tg_non_interactive --terragrunt-log-level $LOG_LEVEL $no_color $tf_compact_warnings \
        > >(tee $WORK_FOLDER/stdout.log) \
        2> >(tee $WORK_FOLDER/stderr.log >&$stderr_output) 
    fi
  fi

  # Run terragrunt command
  echo ------------- Running Terragrunt ----------------------
  terragrunt $tg_run_all $TG_COMMAND \
    --terragrunt-debug --terragrunt-working-dir $working_dir  \
    $tg_non_interactive --terragrunt-log-level $LOG_LEVEL $no_color $tf_compact_warnings \
    $TG_ARGUMENTS \
    > >(tee $WORK_FOLDER/stdout.log) \
    2> >(tee $WORK_FOLDER/stderr.log >&$stderr_output) 

  # Get Exit Code
  export tg_err=$?

  [ $tg_err -eq 137 ] && [ ! -z "$(cat $WORK_FOLDER/stderr.log | grep "cancelled" )" ] && echo Runner Process cancelled && exit 999

  [ $tg_err -ne 0 ] && echo Terragrunt Exitcode: $tg_err

  # Prepare a consise error log
  cat $WORK_FOLDER/stderr.log | grep -vE 'level=debug|locals|msg=run_cmd|msg=Detected|msg=Included|msg=\[Partial\]|msg=Executing|msg=WARN|msg=Setting|^$|msg=Generated|msg=Downloading|msg=The|msg=Are|msg=Reading|msg=Copying|msg=Debug|must wait|msg=Variables|msg=Dependency|msg=[0-9] error occurred|Cannot process|=>|msg=Stack|msg=Unable|errors occurred|sensitive|BEGIN RSA|\[0m|You may now|any changes|should now|If you ever|If you forget|- Reusing previous| \* exit status|Include this file|Terraform can guarantee|^\t\* |^ prefix' \
    | sed s/$escaped_stack_path//g > $WORK_FOLDER/stderr_filtered.log
  
  # If error occurs write filtered error into terminal (stdout)
  if [ $tg_err -ne 0 ] && [[ $COMPACT_STDOUT == true ]]
  then
    echo -e "${RED}------- ALL STDERR  ----------${NC}"
    cat $WORK_FOLDER/stderr.log
  fi

  if [ $tg_err -ne 0 ] && [[ $SHOW_FILTERED_ERRORS == true ]]
  then
    echo -e "${RED}--------Filtered TERRAGRUNT STDERR--------------${NC}"
    cat $WORK_FOLDER/stderr_filtered.log
    echo -e "\n${RED}--------Filtered TERRAGRUNT Error--------------${NC}"
    echo -e "${WHITE}"
    cat $WORK_FOLDER/stderr_filtered.log | grep 'level=error'
    echo -e "${NC}"
    if [ ! -z "$(cat $WORK_FOLDER/stderr.log | grep '│')" ]
    then
      echo -e "\n${RED}--------Filtered TERRAFORM Errors--------------${NC}"
      cat $WORK_FOLDER/stderr.log | grep '│'
    fi

  fi

  [ $tg_err -ne 0 ] && echo -e "\n${RED}-----------------------------------------------${NC}"
  
  set -e

}

# Check for python virtual env
if [ ! -d venv ]
then
  echo virtual env not found
  exit 1
else
  source venv/bin/activate
fi

find_modules
run_terragrunt
exit $tg_err
