package migrations

import (
	"encoding/json"

	"github.com/pocketbase/pocketbase/core"
	m "github.com/pocketbase/pocketbase/migrations"
)

func init() {
	m.Register(func(app core.App) error {
		collection, err := app.FindCollectionByNameOrId("pbc_2510442845")
		if err != nil {
			return err
		}

		// update collection data
		if err := json.Unmarshal([]byte(`{
			"viewQuery": "SELECT g.id, g.event, g.white, g.black, w.name AS white_name, b.name AS black_name, g.bye, w.elo AS white_elo, b.elo AS black_elo, g.result, g.round, g.finished, g.created FROM games g\nLEFT OUTER JOIN users w\nON w.id = g.white\nLEFT OUTER JOIN users b\nON b.id = g.black"
		}`), &collection); err != nil {
			return err
		}

		// remove field
		collection.Fields.RemoveById("_clone_BW6s")

		// remove field
		collection.Fields.RemoveById("_clone_6tPq")

		// remove field
		collection.Fields.RemoveById("_clone_kuyo")

		// remove field
		collection.Fields.RemoveById("_clone_kx9Y")

		// remove field
		collection.Fields.RemoveById("_clone_GzyQ")

		// remove field
		collection.Fields.RemoveById("_clone_QMrZ")

		// remove field
		collection.Fields.RemoveById("_clone_TZaV")

		// remove field
		collection.Fields.RemoveById("_clone_g9xp")

		// remove field
		collection.Fields.RemoveById("_clone_vHrF")

		// remove field
		collection.Fields.RemoveById("_clone_4ej6")

		// remove field
		collection.Fields.RemoveById("_clone_pS8g")

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(1, []byte(`{
			"cascadeDelete": false,
			"collectionId": "pbc_1687431684",
			"hidden": false,
			"id": "_clone_fzBs",
			"maxSelect": 1,
			"minSelect": 0,
			"name": "event",
			"presentable": false,
			"required": false,
			"system": false,
			"type": "relation"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(2, []byte(`{
			"cascadeDelete": false,
			"collectionId": "_pb_users_auth_",
			"hidden": false,
			"id": "_clone_ONc5",
			"maxSelect": 1,
			"minSelect": 0,
			"name": "white",
			"presentable": false,
			"required": false,
			"system": false,
			"type": "relation"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(3, []byte(`{
			"cascadeDelete": false,
			"collectionId": "_pb_users_auth_",
			"hidden": false,
			"id": "_clone_5spk",
			"maxSelect": 1,
			"minSelect": 0,
			"name": "black",
			"presentable": false,
			"required": false,
			"system": false,
			"type": "relation"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(4, []byte(`{
			"autogeneratePattern": "",
			"hidden": false,
			"id": "_clone_m38H",
			"max": 255,
			"min": 0,
			"name": "white_name",
			"pattern": "",
			"presentable": false,
			"primaryKey": false,
			"required": false,
			"system": false,
			"type": "text"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(5, []byte(`{
			"autogeneratePattern": "",
			"hidden": false,
			"id": "_clone_qD95",
			"max": 255,
			"min": 0,
			"name": "black_name",
			"pattern": "",
			"presentable": false,
			"primaryKey": false,
			"required": false,
			"system": false,
			"type": "text"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(6, []byte(`{
			"hidden": false,
			"id": "_clone_R7LW",
			"name": "bye",
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
			"id": "_clone_g9T4",
			"max": null,
			"min": null,
			"name": "white_elo",
			"onlyInt": false,
			"presentable": false,
			"required": false,
			"system": false,
			"type": "number"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(8, []byte(`{
			"hidden": false,
			"id": "_clone_XMnc",
			"max": null,
			"min": null,
			"name": "black_elo",
			"onlyInt": false,
			"presentable": false,
			"required": false,
			"system": false,
			"type": "number"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(9, []byte(`{
			"hidden": false,
			"id": "_clone_bYBc",
			"max": null,
			"min": null,
			"name": "result",
			"onlyInt": false,
			"presentable": false,
			"required": false,
			"system": false,
			"type": "number"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(10, []byte(`{
			"hidden": false,
			"id": "_clone_xRoc",
			"max": null,
			"min": null,
			"name": "round",
			"onlyInt": false,
			"presentable": false,
			"required": false,
			"system": false,
			"type": "number"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(11, []byte(`{
			"hidden": false,
			"id": "_clone_UG1y",
			"name": "finished",
			"presentable": false,
			"required": false,
			"system": false,
			"type": "bool"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(12, []byte(`{
			"hidden": false,
			"id": "_clone_Yxkn",
			"name": "created",
			"onCreate": true,
			"onUpdate": false,
			"presentable": false,
			"system": false,
			"type": "autodate"
		}`)); err != nil {
			return err
		}

		return app.Save(collection)
	}, func(app core.App) error {
		collection, err := app.FindCollectionByNameOrId("pbc_2510442845")
		if err != nil {
			return err
		}

		// update collection data
		if err := json.Unmarshal([]byte(`{
			"viewQuery": "SELECT g.id, g.event, g.white, g.black, w.name AS white_name, b.name AS black_name, g.bye, w.elo AS white_elo, b.elo AS black_elo, g.result, g.round, g.finished FROM games g\nLEFT OUTER JOIN users w\nON w.id = g.white\nLEFT OUTER JOIN users b\nON b.id = g.black"
		}`), &collection); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(1, []byte(`{
			"cascadeDelete": false,
			"collectionId": "pbc_1687431684",
			"hidden": false,
			"id": "_clone_BW6s",
			"maxSelect": 1,
			"minSelect": 0,
			"name": "event",
			"presentable": false,
			"required": false,
			"system": false,
			"type": "relation"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(2, []byte(`{
			"cascadeDelete": false,
			"collectionId": "_pb_users_auth_",
			"hidden": false,
			"id": "_clone_6tPq",
			"maxSelect": 1,
			"minSelect": 0,
			"name": "white",
			"presentable": false,
			"required": false,
			"system": false,
			"type": "relation"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(3, []byte(`{
			"cascadeDelete": false,
			"collectionId": "_pb_users_auth_",
			"hidden": false,
			"id": "_clone_kuyo",
			"maxSelect": 1,
			"minSelect": 0,
			"name": "black",
			"presentable": false,
			"required": false,
			"system": false,
			"type": "relation"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(4, []byte(`{
			"autogeneratePattern": "",
			"hidden": false,
			"id": "_clone_kx9Y",
			"max": 255,
			"min": 0,
			"name": "white_name",
			"pattern": "",
			"presentable": false,
			"primaryKey": false,
			"required": false,
			"system": false,
			"type": "text"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(5, []byte(`{
			"autogeneratePattern": "",
			"hidden": false,
			"id": "_clone_GzyQ",
			"max": 255,
			"min": 0,
			"name": "black_name",
			"pattern": "",
			"presentable": false,
			"primaryKey": false,
			"required": false,
			"system": false,
			"type": "text"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(6, []byte(`{
			"hidden": false,
			"id": "_clone_QMrZ",
			"name": "bye",
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
			"id": "_clone_TZaV",
			"max": null,
			"min": null,
			"name": "white_elo",
			"onlyInt": false,
			"presentable": false,
			"required": false,
			"system": false,
			"type": "number"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(8, []byte(`{
			"hidden": false,
			"id": "_clone_g9xp",
			"max": null,
			"min": null,
			"name": "black_elo",
			"onlyInt": false,
			"presentable": false,
			"required": false,
			"system": false,
			"type": "number"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(9, []byte(`{
			"hidden": false,
			"id": "_clone_vHrF",
			"max": null,
			"min": null,
			"name": "result",
			"onlyInt": false,
			"presentable": false,
			"required": false,
			"system": false,
			"type": "number"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(10, []byte(`{
			"hidden": false,
			"id": "_clone_4ej6",
			"max": null,
			"min": null,
			"name": "round",
			"onlyInt": false,
			"presentable": false,
			"required": false,
			"system": false,
			"type": "number"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(11, []byte(`{
			"hidden": false,
			"id": "_clone_pS8g",
			"name": "finished",
			"presentable": false,
			"required": false,
			"system": false,
			"type": "bool"
		}`)); err != nil {
			return err
		}

		// remove field
		collection.Fields.RemoveById("_clone_fzBs")

		// remove field
		collection.Fields.RemoveById("_clone_ONc5")

		// remove field
		collection.Fields.RemoveById("_clone_5spk")

		// remove field
		collection.Fields.RemoveById("_clone_m38H")

		// remove field
		collection.Fields.RemoveById("_clone_qD95")

		// remove field
		collection.Fields.RemoveById("_clone_R7LW")

		// remove field
		collection.Fields.RemoveById("_clone_g9T4")

		// remove field
		collection.Fields.RemoveById("_clone_XMnc")

		// remove field
		collection.Fields.RemoveById("_clone_bYBc")

		// remove field
		collection.Fields.RemoveById("_clone_xRoc")

		// remove field
		collection.Fields.RemoveById("_clone_UG1y")

		// remove field
		collection.Fields.RemoveById("_clone_Yxkn")

		return app.Save(collection)
	})
}
