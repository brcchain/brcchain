# run a node

## download code

```
git clone https://github.com/brcchain/brcchain.gitx
```

## build

```
make install
```

## download brc.tar

```
cd ~
tar -xvf brc.tar .brc 
```

## run node
```
brcd start --pruning=nothing --log_level info --json-rpc.api eth,txpool,net,web3 --home ~/.brc
```
