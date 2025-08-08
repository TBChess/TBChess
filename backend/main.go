package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	_ "tbchess/migrations"
	"tbchess/swisser"

	"github.com/pocketbase/dbx"
	"github.com/pocketbase/pocketbase"
	"github.com/pocketbase/pocketbase/apis"
	"github.com/pocketbase/pocketbase/core"
	"github.com/pocketbase/pocketbase/plugins/jsvm"
	"github.com/pocketbase/pocketbase/plugins/migratecmd"
	"github.com/pocketbase/pocketbase/tools/hook"

	glicko "github.com/zelenin/go-glicko2"
)

func main() {
	app := pocketbase.New()

	// ---------------------------------------------------------------
	// Optional plugin flags:
	// ---------------------------------------------------------------

	var hooksDir string
	app.RootCmd.PersistentFlags().StringVar(
		&hooksDir,
		"hooksDir",
		"",
		"the directory with the JS app hooks",
	)

	var hooksWatch bool
	app.RootCmd.PersistentFlags().BoolVar(
		&hooksWatch,
		"hooksWatch",
		true,
		"auto restart the app on pb_hooks file change; it has no effect on Windows",
	)

	var hooksPool int
	app.RootCmd.PersistentFlags().IntVar(
		&hooksPool,
		"hooksPool",
		15,
		"the total prewarm goja.Runtime instances for the JS app hooks execution",
	)

	var migrationsDir string
	app.RootCmd.PersistentFlags().StringVar(
		&migrationsDir,
		"migrationsDir",
		"./migrations",
		"the directory with the user defined migrations",
	)

	var swisserUrl string
	app.RootCmd.PersistentFlags().StringVar(
		&swisserUrl,
		"swisserUrl",
		"http://localhost:8080",
		"The URL of the swisser tournament making service",
	)

	var automigrate bool
	app.RootCmd.PersistentFlags().BoolVar(
		&automigrate,
		"automigrate",
		true,
		"enable/disable auto migrations",
	)

	var publicDir string
	app.RootCmd.PersistentFlags().StringVar(
		&publicDir,
		"publicDir",
		defaultPublicDir(),
		"the directory to serve static files",
	)

	var indexFallback bool
	app.RootCmd.PersistentFlags().BoolVar(
		&indexFallback,
		"indexFallback",
		true,
		"fallback the request to index.html on missing static path, e.g. when pretty urls are used with SPA",
	)

	app.RootCmd.ParseFlags(os.Args[1:])

	// ---------------------------------------------------------------
	// Plugins and hooks:
	// ---------------------------------------------------------------

	// load jsvm (pb_hooks and pb_migrations)
	jsvm.MustRegister(app, jsvm.Config{
		MigrationsDir: migrationsDir,
		HooksDir:      hooksDir,
		HooksWatch:    hooksWatch,
		HooksPoolSize: hooksPool,
	})

	// migrate command (with js templates)
	migratecmd.MustRegister(app, app.RootCmd, migratecmd.Config{
		TemplateLang: migratecmd.TemplateLangGo,
		Automigrate:  automigrate,
		Dir:          migrationsDir,
	})

	// GitHub selfupdate
	// ghupdate.MustRegister(app, app.RootCmd, ghupdate.Config{})

	_, vapidPublicKey, err := getVAPIDKeys()
	if err != nil {
		log.Fatal("Cannot generate vapid keys")
	}

	// Initialize swisser
	swisserClient := swisser.NewSwisserClient(swisserUrl)
	err = swisserClient.Ping()
	if err != nil {
		log.Fatal("Failed to connect to swisser service: ", err)
	}

	// static route to serves files from the provided public dir
	// (if publicDir exists and the route path is not already defined)
	app.OnServe().Bind(&hook.Handler[*core.ServeEvent]{
		Func: func(e *core.ServeEvent) error {
			if !e.Router.HasRoute(http.MethodGet, "/{path...}") {
				e.Router.GET("/{path...}", apis.Static(os.DirFS(publicDir), indexFallback))
			}

			return e.Next()
		},
		Priority: 999, // execute as latest as possible to allow users to provide their own route
	})

	// Default users name
	app.OnRecordCreateRequest("users").BindFunc(func(e *core.RecordRequestEvent) error {
		e.Record.Set("name", strings.Split(e.Record.Email(), "@")[0])
		e.Record.Set("elo", 1200)

		return e.Next()
	})

	app.OnRecordUpdateRequest("users").BindFunc(func(e *core.RecordRequestEvent) error {
		// ignore for superusers
		if e.HasSuperuserAuth() {
			return e.Next()
		}

		if e.Auth.GetFloat("elo") != e.Record.GetFloat("elo") && e.Auth.GetBool("starter_elo") {
			return e.BadRequestError("Cannot update ELO", nil)
		}

		if e.Auth.GetBool("verified") != e.Record.GetBool("verified") {
			return e.BadRequestError("Cannot update verified", nil)
		}

		return e.Next()
	})

	// Signups checks
	app.OnRecordCreateRequest("event_signups").BindFunc(func(e *core.RecordRequestEvent) error {
		if e.Auth == nil {
			return e.ForbiddenError("Not authenticated", nil)
		}

		// Check duplicate registration
		signup, _ := app.FindFirstRecordByFilter(
			"event_signups",
			"user_id = {:user_id} && event = {:event_id}",
			dbx.Params{"user_id": e.Auth.Id, "event_id": e.Record.GetString("event")},
		)

		if signup != nil {
			return e.BadRequestError("You're already registered!", nil)
		}

		// Don't allow signups for events that are started
		event, _ := app.FindRecordById(
			"events",
			e.Record.GetString("event"),
		)

		if event == nil {
			return e.BadRequestError("Cannot find event", nil)
		}

		if event.GetBool("started") {
			return e.BadRequestError("Registration for this event is closed", nil)
		}

		return e.Next()
	})

	finalizeEvent := func(txApp core.App, e *core.RequestEvent, event *core.Record) error {
		if !event.GetBool("finished") {
			return e.BadRequestError("This event is not finished and cannot be finalized", nil)
		}

		// Update ELO points
		allGames, _ := txApp.FindRecordsByFilter("games_list",
			"event = {:event_id} && finished = {:finished}",
			"round",
			0,
			0,
			dbx.Params{"event_id": event.Id, "finished": true})

		playerMap := make(map[string]*glicko.Player)
		period := glicko.NewRatingPeriod()

		for _, game := range allGames {
			white := game.GetString("white")
			whiteElo := game.GetFloat("white_elo")
			black := game.GetString("black")
			blackElo := game.GetFloat("black_elo")
			result := game.GetFloat("result")

			bye := game.GetBool("bye")

			var whitePlayer *glicko.Player
			if player, exists := playerMap[white]; exists {
				whitePlayer = player
			} else if white != "" {
				whitePlayer = glicko.NewPlayer(glicko.NewRating(whiteElo, 80, 0.06))
				playerMap[white] = whitePlayer
			}

			var blackPlayer *glicko.Player

			if player, exists := playerMap[black]; exists {
				blackPlayer = player
			} else if black != "" {
				blackPlayer = glicko.NewPlayer(glicko.NewRating(blackElo, 80, 0.06))
				playerMap[black] = blackPlayer
			}

			if !bye && whitePlayer != nil && blackPlayer != nil {
				switch result {
				case 1.0:
					period.AddMatch(whitePlayer, blackPlayer, glicko.MATCH_RESULT_WIN)
				case 0.5:
					period.AddMatch(whitePlayer, blackPlayer, glicko.MATCH_RESULT_DRAW)
				case 0.0:
					period.AddMatch(whitePlayer, blackPlayer, glicko.MATCH_RESULT_LOSS)
				}
			}
		}

		period.Calculate()

		for playerId, player := range playerMap {
			user, err := txApp.FindRecordById("users", playerId)
			if err != nil {
				return e.BadRequestError("Cannot update user ELO", err)
			}

			user.Set("elo", player.Rating().R())

			err = txApp.Save(user)
			if err != nil {
				return e.BadRequestError("Cannot update user ELO", err)
			}
		}

		return nil
	}

	nextRound := func(txApp core.App, e *core.RequestEvent, event *core.Record) error {
		// Check signups
		minPlayers := event.GetInt("min_players")
		signups, err := txApp.FindRecordsByFilter("event_signups_list",
			"event = {:event_id}",
			"created",
			0,
			0,
			dbx.Params{"event_id": event.Id})

		if err != nil {
			return e.BadRequestError("Not enough players signed up", nil)
		}

		if len(signups) < minPlayers {
			return e.BadRequestError(fmt.Sprintf("Need at least %d players to start the next round", minPlayers), nil)
		}

		curGames, err := txApp.FindAllRecords("games",
			dbx.NewExp("event = {:event_id}", dbx.Params{"event_id": event.Id}),
		)
		if err != nil {
			return e.BadRequestError("Cannot find past games", nil)
		}

		// Create rounds
		rr := swisser.RoundRequest{}
		rr.Rounds = event.GetInt("rounds")

		// Find next round, populate game history
		maxRound := 0
		for _, game := range curGames {
			maxRound = max(maxRound, game.GetInt("round"))
		}
		rr.Games = make([][]swisser.Game, maxRound)
		for _, game := range curGames {
			rId := min(maxRound-1, max(0, game.GetInt("round")-1))
			rr.Games[rId] = append(rr.Games[rId], swisser.Game{
				White:  game.GetString("white"),
				Black:  game.GetString("black"),
				Result: game.GetFloat("result"),
				Bye:    game.GetBool("bye"),
			})
		}

		for _, signup := range signups {
			rr.Players = append(rr.Players, swisser.Player{
				Name: signup.GetString("user"),
				Elo:  signup.GetInt("elo"),
			})
		}

		pairings, err := swisserClient.Round(rr)
		if err != nil {
			return e.BadRequestError("Cannot create round pairings", nil)
		}

		games, err := txApp.FindCollectionByNameOrId("games")
		if err != nil {
			return e.BadRequestError("Cannot create round pairings (no games collection)", nil)
		}

		for _, p := range pairings {
			game := core.NewRecord(games)
			game.Set("white", p.White)
			game.Set("black", p.Black)
			if p.Bye {
				game.Set("bye", true)
			}
			game.Set("event", event.Id)
			game.Set("round", maxRound+1)
			err = txApp.Save(game)
			if err != nil {
				return e.BadRequestError("Cannot create game", nil)
			}
		}

		event.Set("current_round", maxRound+1)
		err = txApp.Save(event)
		if err != nil {
			return e.BadRequestError("Cannot save event", nil)
		}

		err = webPushNotifyNewRound(txApp, event.Id, maxRound+1)
		if err != nil {
			txApp.Logger().Warn(fmt.Sprintf("Cannot push web notifications: %s", err))
		}

		return nil
	}

	app.OnServe().BindFunc(func(se *core.ServeEvent) error {

		// Start an event
		se.Router.POST("/api/tbchess/event/{event_id}/start", func(e *core.RequestEvent) error {
			eventId := e.Request.PathValue("event_id")
			if eventId == "" {
				return e.BadRequestError("Empty event ID", nil)
			}

			event, _ := app.FindRecordById(
				"events",
				eventId,
			)

			if event == nil {
				return e.BadRequestError("Cannot find event", nil)
			}

			authRecord := e.Auth

			if !authRecord.IsSuperuser() && event.GetString("owner") != authRecord.Id {
				return e.ForbiddenError("You don't have permission to start this event", nil)
			}

			if event.GetBool("started") {
				return e.BadRequestError("Event already started", nil)
			}

			err = app.RunInTransaction(func(txApp core.App) error {
				err := nextRound(txApp, e, event)
				if err != nil {
					return err
				}

				event.Set("started", true)

				err = txApp.Save(event)
				if err != nil {
					return e.BadRequestError("Cannot update event", nil)
				}

				return nil
			})

			if err != nil {
				return err
			}

			return e.JSON(http.StatusOK, map[string]bool{"success": true})
		}).Bind(apis.RequireAuth())

		se.Router.POST("/api/tbchess/game/{game_id}/finish", func(e *core.RequestEvent) error {
			gameId := e.Request.PathValue("game_id")
			if gameId == "" {
				return e.BadRequestError("Empty game ID", nil)
			}

			data := struct {
				Result float64 `json:"result" form:"result"`
			}{}
			if err := e.BindBody(&data); err != nil {
				return e.BadRequestError("Failed to read request data", err)
			}

			if data.Result != 0 && data.Result != 0.5 && data.Result != 1.0 {
				return e.BadRequestError("Invalid result format", nil)
			}

			game, _ := app.FindRecordById(
				"games",
				gameId,
			)

			if game == nil {
				return e.BadRequestError("Cannot find event", nil)
			}

			authRecord := e.Auth

			eventId := game.GetString("event")
			event, err := app.FindRecordById(
				"events",
				eventId,
			)
			if err != nil {
				return e.BadRequestError("Cannot find event associated with this game", nil)
			}

			isOwner := event.GetString("owner") == authRecord.Id

			if !authRecord.IsSuperuser() &&
				game.GetString("white") != authRecord.Id &&
				game.GetString("black") != authRecord.Id &&
				!isOwner {
				return e.ForbiddenError("You don't have permission to finish this game", nil)
			}

			// Don't allow players to submit score twice
			// (but allow owners to adjust scores)
			if !authRecord.IsSuperuser() && !isOwner && game.GetBool("finished") {
				return e.BadRequestError("Game already finished", nil)
			}

			if !event.GetBool("started") {
				return e.BadRequestError("Event not started", nil)
			}

			if event.GetBool("finished") {
				return e.BadRequestError("Event already finished", nil)
			}

			currentRound := event.GetInt("current_round")
			rounds := event.GetInt("rounds")

			if err != nil {
				return e.BadRequestError("Cannot find event for game", nil)
			}

			err = app.RunInTransaction(func(txApp core.App) error {
				game.Set("finished", true)
				game.Set("result", data.Result)

				err = txApp.Save(game)
				if err != nil {
					return e.BadRequestError("Cannot update game", nil)
				}

				// Check if all games in this event's round have finished
				allGames, _ := txApp.FindAllRecords("games",
					dbx.NewExp("event = {:event_id} AND round = {:round}", dbx.Params{"event_id": eventId, "round": currentRound}),
				)

				// Also set any bye game to finished
				countFinish := 0

				for _, g := range allGames {
					finished := g.GetBool("finished")
					if g.GetBool("bye") && !finished {
						g.Set("finished", true)
						g.Set("result", 1.0)

						err = txApp.Save(g)
						if err != nil {
							return e.BadRequestError("Cannot update bye game", nil)
						}

						countFinish++
					} else if finished {
						countFinish++
					}
				}

				// All games have finished?
				if countFinish == len(allGames) {

					// Done?
					if currentRound >= rounds {
						event.Set("finished", true)
						err = txApp.Save(event)
						if err != nil {
							return e.BadRequestError("Cannot set event to finished", nil)
						}

						// TODO: we should probably have some sort of
						// finalization step to correct possible scoring mistakes
						// before committing, or a cronjob that executes after
						// X many hours to give time to fix these problems

						err = finalizeEvent(txApp, e, event)
						if err != nil {
							return err
						}

					} else {
						// Generate next round
						err := nextRound(txApp, e, event)
						if err != nil {
							return err
						}
					}
				}

				return nil
			})

			if err != nil {
				return err
			}

			return e.JSON(http.StatusOK, map[string]bool{"success": true})
		}).Bind(apis.RequireAuth())

		se.Router.GET("/api/tbchess/vapid", func(e *core.RequestEvent) error {
			return e.JSON(http.StatusOK, map[string]string{"publicKey": vapidPublicKey})
		})

		// se.Router.GET("/api/tbchess/test/{event_id}", func(e *core.RequestEvent) error {
		// 	eventId := e.Request.PathValue("event_id")

		// 	err := webPushNotifyNewRound(app, eventId, 3)
		// 	if err != nil {
		// 		app.Logger().Debug(err.Error())
		// 	}

		// 	return e.JSON(http.StatusOK, map[string]bool{"ok": true})
		// })

		return se.Next()
	})

	if err := app.Start(); err != nil {
		log.Fatal(err)
	}
}

// the default pb_public dir location is relative to the executable
func defaultPublicDir() string {
	if strings.HasPrefix(os.Args[0], os.TempDir()) {
		// most likely ran with go run
		return "./pb_public"
	}

	return filepath.Join(os.Args[0], "../pb_public")
}
