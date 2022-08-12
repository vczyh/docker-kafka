#!/bin/bash -e

# Store original IFS config, so we can restore it at various stages
ORIG_IFS=$IFS

if [[ -z "$KAFKA_NODE_ID" ]]; then
    if [[ -n "$NODE_ID_COMMAND" ]]; then
        KAFKA_NODE_ID=$(eval "$NODE_ID_COMMAND")
        export KAFKA_NODE_ID
    else
        # By default auto allocate broker ID
        export KAFKA_NODE_ID=-1
    fi
fi

(
    function updateConfig() {
        key=$1
        value=$2
        file=$3

        # Omit $value here, in case there is sensitive information
        echo "[Configuring] '$key' in '$file'"

        # If config exists in file, replace it. Otherwise, append to file.
        if grep -E -q "^#?$key=" "$file"; then
#            sed -r -i "s@^#?$key=.*@$key=$value@g" "$file" #note that no config values may contain an '@' char
            sed -r -i "s/^#?$key=.*/$key=$value/g" "$file" #note that no config values may contain an '@' char
        else
            echo "$key=$value" >> "$file"
        fi
    }


    # Read in env as a new-line separated array. This handles the case of env variables have spaces and/or carriage returns. See #313
    IFS=$'\n'
    for VAR in $(env)
    do
        env_var=$(echo "$VAR" | cut -d= -f1)
        if [[ "$EXCLUSIONS" = *"|$env_var|"* ]]; then
            echo "Excluding $env_var from broker config"
            continue
        fi

        if [[ $env_var =~ ^KAFKA_ ]]; then
            kafka_name=$(echo "$env_var" | cut -d_ -f2- | tr '[:upper:]' '[:lower:]' | tr _ .)
            updateConfig "$kafka_name" "${!env_var}" "$HOME/config/kraft/server.properties"
        fi

        if [[ $env_var =~ ^LOG4J_ ]]; then
            log4j_name=$(echo "$env_var" | tr '[:upper:]' '[:lower:]' | tr _ .)
            updateConfig "$log4j_name" "${!env_var}" "$HOME/config/log4j.properties"
        fi
    done
)

"$HOME/bin/kafka-storage.sh" format -t "$CLUSTER_ID" -c "$HOME/config/kraft/server.properties"

"$HOME/bin/kafka-server-start.sh" "$HOME/config/kraft/server.properties"

