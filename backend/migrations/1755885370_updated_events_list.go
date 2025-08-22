package migrations

import (
	"encoding/json"

	"github.com/pocketbase/pocketbase/core"
	m "github.com/pocketbase/pocketbase/migrations"
)

func init() {
	m.Register(func(app core.App) error {
		collection, err := app.FindCollectionByNameOrId("pbc_3522113896")
		if err != nil {
			return err
		}

		// update collection data
		if err := json.Unmarshal([]byte(`{
			"viewQuery": "SELECT e.id, e.event_date, e.min_players, e.max_players, e.current_round, e.rounds, e.started, e.finished, e.time_control, COUNT(es.id) as players_count, json_group_array(es.user) as user_signups, v.name as venue_name, v.logo as venue_logo, v.byob as venue_byob FROM events e\nLEFT OUTER JOIN event_signups es\nON es.event = e.id\nINNER JOIN venues v\nON e.venue = v.id\nGROUP BY e.id"
		}`), &collection); err != nil {
			return err
		}

		// remove field
		collection.Fields.RemoveById("_clone_M6VV")

		// remove field
		collection.Fields.RemoveById("_clone_sd35")

		// remove field
		collection.Fields.RemoveById("_clone_dsX8")

		// remove field
		collection.Fields.RemoveById("_clone_lwP6")

		// remove field
		collection.Fields.RemoveById("_clone_e4kC")

		// remove field
		collection.Fields.RemoveById("_clone_TsSH")

		// remove field
		collection.Fields.RemoveById("_clone_4WTg")

		// remove field
		collection.Fields.RemoveById("_clone_jXLA")

		// remove field
		collection.Fields.RemoveById("_clone_Vesp")

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(1, []byte(`{
			"hidden": false,
			"id": "_clone_k201",
			"max": "",
			"min": "",
			"name": "event_date",
			"presentable": false,
			"required": true,
			"system": false,
			"type": "date"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(2, []byte(`{
			"hidden": false,
			"id": "_clone_hfrs",
			"max": null,
			"min": null,
			"name": "min_players",
			"onlyInt": true,
			"presentable": false,
			"required": true,
			"system": false,
			"type": "number"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(3, []byte(`{
			"hidden": false,
			"id": "_clone_TUiG",
			"max": null,
			"min": null,
			"name": "max_players",
			"onlyInt": true,
			"presentable": false,
			"required": true,
			"system": false,
			"type": "number"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(4, []byte(`{
			"hidden": false,
			"id": "_clone_WOKN",
			"max": null,
			"min": null,
			"name": "current_round",
			"onlyInt": false,
			"presentable": false,
			"required": false,
			"system": false,
			"type": "number"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(5, []byte(`{
			"hidden": false,
			"id": "_clone_5uF4",
			"max": null,
			"min": null,
			"name": "rounds",
			"onlyInt": false,
			"presentable": false,
			"required": true,
			"system": false,
			"type": "number"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(6, []byte(`{
			"hidden": false,
			"id": "_clone_fWnz",
			"name": "started",
			"presentable": false,
			"required": false,
			"system": false,
			"type": "bool"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(7, []byte(`{
			"hidden": false,
			"id": "_clone_Ut54",
			"name": "finished",
			"presentable": false,
			"required": false,
			"system": false,
			"type": "bool"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(8, []byte(`{
			"hidden": false,
			"id": "_clone_DBDo",
			"maxSelect": 0,
			"name": "time_control",
			"presentable": false,
			"required": true,
			"system": false,
			"type": "select",
			"values": [
				"5+0",
				"5+3",
				"10+0",
				"10+5",
				"15+0",
				"15+10"
			]
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(11, []byte(`{
			"autogeneratePattern": "",
			"hidden": false,
			"id": "_clone_RuRA",
			"max": 255,
			"min": 0,
			"name": "venue_name",
			"pattern": "",
			"presentable": false,
			"primaryKey": false,
			"required": true,
			"system": false,
			"type": "text"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(12, []byte(`{
			"hidden": false,
			"id": "_clone_ijgG",
			"maxSelect": 0,
			"maxSize": 0,
			"mimeTypes": null,
			"name": "venue_logo",
			"presentable": false,
			"protected": false,
			"required": false,
			"system": false,
			"thumbs": [
				"128x128"
			],
			"type": "file"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(13, []byte(`{
			"hidden": false,
			"id": "_clone_MGCI",
			"name": "venue_byob",
			"presentable": false,
			"required": true,
			"system": false,
			"type": "bool"
		}`)); err != nil {
			return err
		}

		return app.Save(collection)
	}, func(app core.App) error {
		collection, err := app.FindCollectionByNameOrId("pbc_3522113896")
		if err != nil {
			return err
		}

		// update collection data
		if err := json.Unmarshal([]byte(`{
			"viewQuery": "SELECT e.id, e.event_date, e.min_players, e.max_players, e.started, e.finished, e.time_control, COUNT(es.id) as players_count, json_group_array(es.user) as user_signups, v.name as venue_name, v.logo as venue_logo, v.byob as venue_byob FROM events e\nLEFT OUTER JOIN event_signups es\nON es.event = e.id\nINNER JOIN venues v\nON e.venue = v.id\nGROUP BY e.id"
		}`), &collection); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(1, []byte(`{
			"hidden": false,
			"id": "_clone_M6VV",
			"max": "",
			"min": "",
			"name": "event_date",
			"presentable": false,
			"required": true,
			"system": false,
			"type": "date"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(2, []byte(`{
			"hidden": false,
			"id": "_clone_sd35",
			"max": null,
			"min": null,
			"name": "min_players",
			"onlyInt": true,
			"presentable": false,
			"required": true,
			"system": false,
			"type": "number"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(3, []byte(`{
			"hidden": false,
			"id": "_clone_dsX8",
			"max": null,
			"min": null,
			"name": "max_players",
			"onlyInt": true,
			"presentable": false,
			"required": true,
			"system": false,
			"type": "number"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(4, []byte(`{
			"hidden": false,
			"id": "_clone_lwP6",
			"name": "started",
			"presentable": false,
			"required": false,
			"system": false,
			"type": "bool"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(5, []byte(`{
			"hidden": false,
			"id": "_clone_e4kC",
			"name": "finished",
			"presentable": false,
			"required": false,
			"system": false,
			"type": "bool"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(6, []byte(`{
			"hidden": false,
			"id": "_clone_TsSH",
			"maxSelect": 0,
			"name": "time_control",
			"presentable": false,
			"required": true,
			"system": false,
			"type": "select",
			"values": [
				"5+0",
				"5+3",
				"10+0",
				"10+5",
				"15+0",
				"15+10"
			]
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(9, []byte(`{
			"autogeneratePattern": "",
			"hidden": false,
			"id": "_clone_4WTg",
			"max": 255,
			"min": 0,
			"name": "venue_name",
			"pattern": "",
			"presentable": false,
			"primaryKey": false,
			"required": true,
			"system": false,
			"type": "text"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(10, []byte(`{
			"hidden": false,
			"id": "_clone_jXLA",
			"maxSelect": 0,
			"maxSize": 0,
			"mimeTypes": null,
			"name": "venue_logo",
			"presentable": false,
			"protected": false,
			"required": false,
			"system": false,
			"thumbs": [
				"128x128"
			],
			"type": "file"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(11, []byte(`{
			"hidden": false,
			"id": "_clone_Vesp",
			"name": "venue_byob",
			"presentable": false,
			"required": true,
			"system": false,
			"type": "bool"
		}`)); err != nil {
			return err
		}

		// remove field
		collection.Fields.RemoveById("_clone_k201")

		// remove field
		collection.Fields.RemoveById("_clone_hfrs")

		// remove field
		collection.Fields.RemoveById("_clone_TUiG")

		// remove field
		collection.Fields.RemoveById("_clone_WOKN")

		// remove field
		collection.Fields.RemoveById("_clone_5uF4")

		// remove field
		collection.Fields.RemoveById("_clone_fWnz")

		// remove field
		collection.Fields.RemoveById("_clone_Ut54")

		// remove field
		collection.Fields.RemoveById("_clone_DBDo")

		// remove field
		collection.Fields.RemoveById("_clone_RuRA")

		// remove field
		collection.Fields.RemoveById("_clone_ijgG")

		// remove field
		collection.Fields.RemoveById("_clone_MGCI")

		return app.Save(collection)
	})
}
