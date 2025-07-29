set -e
go build .
./tbchess serve --dev --automigrate --http 0.0.0.0:4090
