KEY="alice"
CHAINID="brc_12123-1"
MONIKER="node1"
KEYRING="os"
LOGLEVEL="info"
HOMEDIR="$HOME/.brc"
# to trace evm
TRACE="--trace"

# validate dependencies are installed
#command -v jq > /dev/null 2>&1 || { echo >&2 "jq not installed. More info: https://stedolan.github.io/jq/download/"; exit 1; }

# Reinstall daemon
rm -rf $HOMEDIR/data/
rm -rf $HOMEDIR/config/

# Set client config
ethermintd config keyring-backend $KEYRING --home $HOMEDIR
ethermintd config chain-id $CHAINID --home $HOMEDIR

# if $KEY exists it should be deleted
ethermintd keys add $KEY --keyring-backend $KEYRING --home $HOMEDIR

# Set moniker and chain-id for cosmos (Moniker can be anything, chain-id must be an integer)
ethermintd init $MONIKER --chain-id $CHAINID --home $HOMEDIR

cp $HOMEDIR/config/genesis.json $HOMEDIR/config/tmp_genesis.json

# Change parameter abrc denominations to abrc
cat $HOMEDIR/config/genesis.json | jq '.app_state["staking"]["params"]["bond_denom"]="abrc"' > $HOMEDIR/config/tmp_genesis.json && mv $HOMEDIR/config/tmp_genesis.json $HOMEDIR/config/genesis.json
cat $HOMEDIR/config/genesis.json | jq '.app_state["slashing"]["params"]["signed_blocks_window"]="5000"' > $HOMEDIR/config/tmp_genesis.json && mv $HOMEDIR/config/tmp_genesis.json $HOMEDIR/config/genesis.json
cat $HOMEDIR/config/genesis.json | jq '.app_state["crisis"]["constant_fee"]["denom"]="abrc"' > $HOMEDIR/config/tmp_genesis.json && mv $HOMEDIR/config/tmp_genesis.json $HOMEDIR/config/genesis.json
cat $HOMEDIR/config/genesis.json | jq '.app_state["gov"]["deposit_params"]["min_deposit"][0]["denom"]="abrc"' > $HOMEDIR/config/tmp_genesis.json && mv $HOMEDIR/config/tmp_genesis.json $HOMEDIR/config/genesis.json
cat $HOMEDIR/config/genesis.json | jq '.app_state["gov"]["deposit_params"]["min_deposit"][0]["amount"]="64"' > $HOMEDIR/config/tmp_genesis.json && mv $HOMEDIR/config/tmp_genesis.json $HOMEDIR/config/genesis.json
cat $HOMEDIR/config/genesis.json | jq '.app_state["gov"]["deposit_params"]["max_deposit_period"]="259200s"' > $HOMEDIR/config/tmp_genesis.json && mv $HOMEDIR/config/tmp_genesis.json $HOMEDIR/config/genesis.json
cat $HOMEDIR/config/genesis.json | jq '.app_state["gov"]["voting_params"]["voting_period"]="259200s"' > $HOMEDIR/config/tmp_genesis.json && mv $HOMEDIR/config/tmp_genesis.json $HOMEDIR/config/genesis.json

cat $HOMEDIR/config/genesis.json | jq '.app_state["evm"]["params"]["evm_denom"]="abrc"' > $HOMEDIR/config/tmp_genesis.json && mv $HOMEDIR/config/tmp_genesis.json $HOMEDIR/config/genesis.json
cat $HOMEDIR/config/genesis.json | jq '.app_state["inflation"]["params"]["mint_denom"]="abrc"' > $HOMEDIR/config/tmp_genesis.json && mv $HOMEDIR/config/tmp_genesis.json $HOMEDIR/config/genesis.json
cat $HOMEDIR/config/genesis.json | jq '.app_state["mint"]["params"]["mint_denom"]="abrc"' > $HOMEDIR/config/tmp_genesis.json && mv $HOMEDIR/config/tmp_genesis.json $HOMEDIR/config/genesis.json

#cat $HOMEDIR/config/genesis.json | jq '.app_state["evm"]["accounts"][0]["address"]="0x4200000000000000000000000000000000000042"' > $HOMEDIR/config/tmp_genesis.json && mv $HOMEDIR/config/tmp_genesis.json $HOMEDIR/config/genesis.json
#cat $HOMEDIR/config/genesis.json | jq -r --arg CODE "$CODE" '.app_state["evm"]["accounts"][0]["code"]=$CODE' > $HOMEDIR/config/tmp_genesis.json && mv $HOMEDIR/config/tmp_genesis.json $HOMEDIR/config/genesis.json


# Set gas limit in genesis
cat $HOMEDIR/config/genesis.json | jq '.consensus_params["block"]["max_gas"]="40000000"' > $HOMEDIR/config/tmp_genesis.json && mv $HOMEDIR/config/tmp_genesis.json $HOMEDIR/config/genesis.json

# Set claims start time
node_address=$(ethermintd keys list --home $HOMEDIR | grep  "address: " | cut -c12-)
current_date=$(date -u +"%Y-%m-%dT%TZ")
cat $HOMEDIR/config/genesis.json | jq -r --arg current_date "$current_date" '.app_state["claims"]["params"]["airdrop_start_time"]=$current_date' > $HOMEDIR/config/tmp_genesis.json && mv $HOMEDIR/config/tmp_genesis.json $HOMEDIR/config/genesis.json

# Set claims records for validator account
amount_to_claim=10000
cat $HOMEDIR/config/genesis.json | jq -r --arg node_address "$node_address" --arg amount_to_claim "$amount_to_claim" '.app_state["claims"]["claims_records"]=[{"initial_claimable_amount":$amount_to_claim, "actions_completed":[false, false, false, false],"address":$node_address}]' > $HOMEDIR/config/tmp_genesis.json && mv $HOMEDIR/config/tmp_genesis.json $HOMEDIR/config/genesis.json

# Set claims decay
cat $HOMEDIR/config/genesis.json | jq -r --arg current_date "$current_date" '.app_state["claims"]["params"]["duration_of_decay"]="1000000s"' > $HOMEDIR/config/tmp_genesis.json && mv $HOMEDIR/config/tmp_genesis.json $HOMEDIR/config/genesis.json
cat $HOMEDIR/config/genesis.json | jq -r --arg current_date "$current_date" '.app_state["claims"]["params"]["duration_until_decay"]="100000s"' > $HOMEDIR/config/tmp_genesis.json && mv $HOMEDIR/config/tmp_genesis.json $HOMEDIR/config/genesis.json

# disable produce empty block
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's/127.0.0.1:26657/0.0.0.0:26657/g' $HOMEDIR/config/config.toml
    sed -i '' 's/create_empty_blocks = true/create_empty_blocks = false/g' $HOMEDIR/config/config.toml
    sed -i '' '$H;x;1,/enable = false/s/enable = false/enable = true/;1d' $HOMEDIR/config/app.toml
    sed -i '' ' s/swagger = false/swagger = true/g' $HOMEDIR/config/app.toml
    sed -i '' 's/enabled-unsafe-cors = false/enabled-unsafe-cors = true/g' $HOMEDIR/config/app.toml
  else
    sed -i 's/127.0.0.1:26657/0.0.0.0:26657/g' $HOMEDIR/config/config.toml
    sed -i 's/create_empty_blocks = true/create_empty_blocks = false/g' $HOMEDIR/config/config.toml
    sed -i '$H;x;1,/enable = false/s/enable = false/enable = true/;1d' $HOMEDIR/config/app.toml
    sed -i ' s/swagger = false/swagger = true/g' $HOMEDIR/config/app.toml
    sed -i 's/enabled-unsafe-cors = false/enabled-unsafe-cors = true/g' $HOMEDIR/config/app.toml
fi


if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' 's/create_empty_blocks_interval = "0s"/create_empty_blocks_interval = "30s"/g' $HOMEDIR/config/config.toml
      sed -i '' 's/timeout_propose = "3s"/timeout_propose = "2s"/g' $HOMEDIR/config/config.toml
      sed -i '' 's/timeout_propose_delta = "500ms"/timeout_propose_delta = "500ms"/g' $HOMEDIR/config/config.toml
      sed -i '' 's/timeout_prevote = "1s"/timeout_prevote = "1s"/g' $HOMEDIR/config/config.toml
      sed -i '' 's/timeout_prevote_delta = "500ms"/timeout_prevote_delta = "500ms"/g' $HOMEDIR/config/config.toml
      sed -i '' 's/timeout_precommit = "1s"/timeout_precommit = "1s"/g' $HOMEDIR/config/config.toml
      sed -i '' 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "500ms"/g' $HOMEDIR/config/config.toml
      sed -i '' 's/timeout_commit = "5s"/timeout_commit = "2s"/g' $HOMEDIR/config/config.toml
      sed -i '' 's/timeout_broadcast_tx_commit = "2m30s"/timeout_broadcast_tx_commit = "10s"/g' $HOMEDIR/config/config.toml
  else
      sed -i 's/create_empty_blocks_interval = "0s"/create_empty_blocks_interval = "30s"/g' $HOMEDIR/config/config.toml
      sed -i 's/timeout_propose = "3s"/timeout_propose = "2s"/g' $HOMEDIR/config/config.toml
      sed -i 's/timeout_propose_delta = "500ms"/timeout_propose_delta = "500ms"/g' $HOMEDIR/config/config.toml
      sed -i 's/timeout_prevote = "1s"/timeout_prevote = "1s"/g' $HOMEDIR/config/config.toml
      sed -i 's/timeout_prevote_delta = "500ms"/timeout_prevote_delta = "500ms"/g' $HOMEDIR/config/config.toml
      sed -i 's/timeout_precommit = "1s"/timeout_precommit = "1s"/g' $HOMEDIR/config/config.toml
      sed -i 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "500ms"/g' $HOMEDIR/config/config.toml
      sed -i 's/timeout_commit = "5s"/timeout_commit = "2s"/g' $HOMEDIR/config/config.toml
      sed -i 's/timeout_broadcast_tx_commit = "2m30s"/timeout_broadcast_tx_commit = "10s"/g' $HOMEDIR/config/config.toml
fi

# Allocate genesis accounts (cosmos formatted addresses)
ethermintd add-genesis-account $KEY 1000000000000000000000000000abrc --keyring-backend $KEYRING --home $HOMEDIR

# Update total supply with claim values
validators_supply=$(cat $HOMEDIR/config/genesis.json | jq -r '.app_state["bank"]["supply"][0]["amount"]')
## brc is required to add this big numbers
## total_supply=$(brc <<< "$amount_to_claim+$validators_supply")
total_supply=1000000000000000000000000000
cat $HOMEDIR/config/genesis.json | jq -r '.app_state["bank"]["supply"][0]["denom"]="abrc"' > $HOMEDIR/config/tmp_genesis.json && mv $HOMEDIR/config/tmp_genesis.json $HOMEDIR/config/genesis.json
cat $HOMEDIR/config/genesis.json | jq -r --arg total_supply "$total_supply" '.app_state["bank"]["supply"][0]["amount"]=$total_supply' > $HOMEDIR/config/tmp_genesis.json && mv $HOMEDIR/config/tmp_genesis.json $HOMEDIR/config/genesis.json

# Sign genesis transaction
ethermintd gentx $KEY 1000brc --keyring-backend $KEYRING --chain-id $CHAINID --home $HOMEDIR

# Collect genesis tx
ethermintd collect-gentxs --home $HOMEDIR

# Run this to ensure everything worked and that the genesis file is setup correctly
ethermintd validate-genesis --home $HOMEDIR

#Start the node
echo ethermintd start --pruning=nothing --log_level $LOGLEVEL --json-rpc.api eth,txpool,net,web3 --home $HOMEDIR
