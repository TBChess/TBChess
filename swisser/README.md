# Swisser

A simple pairing engine server that generates pairings via the FIDE Swiss Dubov system.

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

Swisser is based on CPPDubovSystem which is licensed under Apache 2.0 (see LICENSE file).

The swisser program is instead licensed under the AGPLv3.
