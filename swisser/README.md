# Swisser

A simple pairing engine server that generates pairings via the FIDE swiss dutch or round robin system.

## Build

```bash
mkdir build && cd build
cmake ..
make -j4
./swisser
```

Then you can invoke:

```bash
curl -X POST http://localhost:8080/round -d @example.json
```

## License

Swisser is originally based on bbpPairings which is licensed under Apache 2.0 and is Copyright 2016-2022 Jeremy Bierema. (see Apache-2.0.txt file).

The swisser program and all modifications in this repository are instead licensed under the AGPLv3.
