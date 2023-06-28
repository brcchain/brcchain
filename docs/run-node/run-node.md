# run a node

## download code

```
git clone https://github.com/brcchain/brcchain.git
cd brcchain
```

## build

```
make install
```

## init

```
./init.sh
```

## change config
```
cd ~/.brc/config
vim config.toml
```
find [p2p] and change persistent_peers content
11
```
#persistent_peers = ""
persistent_peers = "acdcc063a7cec116ac89b062d595381f1a4b46f4@18.219.47.60:26656"
```

## run node

```
brcd start --pruning=nothing --log_level info --json-rpc.api eth,txpool,net,web3 --home ~/.brc
```
