package migrations

import (
	"encoding/json"

	"github.com/pocketbase/pocketbase/core"
	m "github.com/pocketbase/pocketbase/migrations"
)

func init() {
	m.Register(func(app core.App) error {
		collection, err := app.FindCollectionByNameOrId("pbc_2854881890")
		if err != nil {
			return err
		}

		// update collection data
		if err := json.Unmarshal([]byte(`{
			"viewQuery": "SELECT es.id, es.user, es.event, es.waitlist, es.created, es.updated, u.name as username, u.elo FROM event_signups es\nLEFT OUTER JOIN users u\nON u.id = es.user"
		}`), &collection); err != nil {
			return err
		}

		// remove field
		collection.Fields.RemoveById("_clone_IHVs")

		// remove field
		collection.Fields.RemoveById("_clone_WiAP")

		// remove field
		collection.Fields.RemoveById("_clone_74DS")

		// remove field
		collection.Fields.RemoveById("_clone_33UM")

		// remove field
		collection.Fields.RemoveById("_clone_6kOQ")

		// remove field
		collection.Fields.RemoveById("_clone_LpvB")

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(1, []byte(`{
			"cascadeDelete": false,
			"collectionId": "_pb_users_auth_",
			"hidden": false,
			"id": "_clone_pzXK",
			"maxSelect": 1,
			"minSelect": 0,
			"name": "user",
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
			"collectionId": "pbc_1687431684",
			"hidden": false,
			"id": "_clone_puij",
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
		if err := collection.Fields.AddMarshaledJSONAt(3, []byte(`{
			"hidden": false,
			"id": "_clone_C3Us",
			"name": "waitlist",
			"presentable": false,
			"required": false,
			"system": false,
			"type": "bool"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(4, []byte(`{
			"hidden": false,
			"id": "_clone_gCPg",
			"name": "created",
			"onCreate": true,
			"onUpdate": false,
			"presentable": false,
			"system": false,
			"type": "autodate"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(5, []byte(`{
			"hidden": false,
			"id": "_clone_rYUR",
			"name": "updated",
			"onCreate": true,
			"onUpdate": true,
			"presentable": false,
			"system": false,
			"type": "autodate"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(6, []byte(`{
			"autogeneratePattern": "",
			"hidden": false,
			"id": "_clone_MJmU",
			"max": 255,
			"min": 0,
			"name": "username",
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
		if err := collection.Fields.AddMarshaledJSONAt(7, []byte(`{
			"hidden": false,
			"id": "_clone_Ty81",
			"max": null,
			"min": null,
			"name": "elo",
			"onlyInt": false,
			"presentable": false,
			"required": false,
			"system": false,
			"type": "number"
		}`)); err != nil {
			return err
		}

		return app.Save(collection)
	}, func(app core.App) error {
		collection, err := app.FindCollectionByNameOrId("pbc_2854881890")
		if err != nil {
			return err
		}

		// update collection data
		if err := json.Unmarshal([]byte(`{
			"viewQuery": "SELECT es.id, es.user, es.event, es.created, es.updated, u.name as username, u.elo FROM event_signups es\nLEFT OUTER JOIN users u\nON u.id = es.user"
		}`), &collection); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(1, []byte(`{
			"cascadeDelete": false,
			"collectionId": "_pb_users_auth_",
			"hidden": false,
			"id": "_clone_IHVs",
			"maxSelect": 1,
			"minSelect": 0,
			"name": "user",
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
			"collectionId": "pbc_1687431684",
			"hidden": false,
			"id": "_clone_WiAP",
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
		if err := collection.Fields.AddMarshaledJSONAt(3, []byte(`{
			"hidden": false,
			"id": "_clone_74DS",
			"name": "created",
			"onCreate": true,
			"onUpdate": false,
			"presentable": false,
			"system": false,
			"type": "autodate"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(4, []byte(`{
			"hidden": false,
			"id": "_clone_33UM",
			"name": "updated",
			"onCreate": true,
			"onUpdate": true,
			"presentable": false,
			"system": false,
			"type": "autodate"
		}`)); err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(5, []byte(`{
			"autogeneratePattern": "",
			"hidden": false,
			"id": "_clone_6kOQ",
			"max": 255,
			"min": 0,
			"name": "username",
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
			"id": "_clone_LpvB",
			"max": null,
			"min": null,
			"name": "elo",
			"onlyInt": false,
			"presentable": false,
			"required": false,
			"system": false,
			"type": "number"
		}`)); err != nil {
			return err
		}

		// remove field
		collection.Fields.RemoveById("_clone_pzXK")

		// remove field
		collection.Fields.RemoveById("_clone_puij")

		// remove field
		collection.Fields.RemoveById("_clone_C3Us")

		// remove field
		collection.Fields.RemoveById("_clone_gCPg")

		// remove field
		collection.Fields.RemoveById("_clone_rYUR")

		// remove field
		collection.Fields.RemoveById("_clone_MJmU")

		// remove field
		collection.Fields.RemoveById("_clone_Ty81")

		return app.Save(collection)
	})
}
