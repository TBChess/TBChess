# TBChess

A free and open source platform for modern and automated in-person chess tournament management.

![Image](https://github.com/user-attachments/assets/142f8036-9a7a-4293-8467-48107ec8bf84)

## Features

* Runs in your browser. No app downloads required
* Player registration
* ELO tracking
* Round pairing generation (round robin or FIDE dutch swiss)
* Built-in clock
* New round push notifications (optional)
* Leaderboards
* Event list
* Waitlist support / late registrations
* Single sign-on with Google
* Administration dashboard
* Easy deployment
* SSL certificate generation via LetsEncrypt
* Multi-platform (Linux, Windows, macOS)
* Lightweight (runs on your laptop or the cheapest VPS you can find)

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
