# TBChess

A free and open source platform for modern and automated in-person chess tournament management.

It features player registration, ELO tracking, tournament management, round pairing generation with either Round Robin or FIDE Swiss Dubov system, leaderboards, administration dashboard, a mobile web app and native app support, automatic production deployment and SSL certificate generation via LetsEncrypt.

![Image](https://github.com/user-attachments/assets/bc5d6d33-8b8d-4814-89a4-a4649ac79259)

It's also super-lightweight and cross-platform (runs on Windows, macOS, Linux). You can run it on your laptop or deploy it to the cheapest VPS you can find.

## Getting Started

### Requisites

- [Flutter](https://flutter.dev/docs/get-started/install) (for the mobile `app`)
- [Go](https://go.dev/doc/install) (for the `backend`)
- [CMake](https://cmake.org/download/) and a C++ compiler (for the `swisser` C++ program)

### Running

```bash
git clone https://github.com/TBChess/TBChess
cd TBChess
./build.sh
./run.sh [--mode production] [--domain yourapp]
```

This will run everything for you. If you want to build individual components, see the `build.sh` script.

Once the app is running, you'll see a message in the terminal asking you to create a super user.

## Project Structure

- `app/` - Flutter app (web, mobile, desktop)
- `backend/` - Go backend
- `swisser/` - Tournament pairing logic program

### Useful Scripts

- `build.sh` - Build script
- `deploy.sh` - Deployment helper
- `run.sh` - Run the entire application

## Contributing

Contributions are welcome! Please open issues or pull requests. For major changes, open an issue first to discuss what you would like to change.

## License

This project is licensed under the GNU Affero General Public License v3.0 (AGPLv3). See the [LICENSE](LICENSE) file for details.
