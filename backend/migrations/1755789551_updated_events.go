package migrations

import (
	"github.com/pocketbase/pocketbase/core"
	m "github.com/pocketbase/pocketbase/migrations"
)

func init() {
	m.Register(func(app core.App) error {
		collection, err := app.FindCollectionByNameOrId("pbc_1687431684")
		if err != nil {
			return err
		}

		// add field
		if err := collection.Fields.AddMarshaledJSONAt(12, []byte(`{
			"hidden": false,
			"id": "select3736761055",
			"maxSelect": 1,
			"name": "format",
			"presentable": false,
			"required": true,
			"system": false,
			"type": "select",
			"values": [
				"auto",
				"swiss",
				"roundrobin"
			]
		}`)); err != nil {
			return err
		}

		return app.Save(collection)
	}, func(app core.App) error {
		collection, err := app.FindCollectionByNameOrId("pbc_1687431684")
		if err != nil {
			return err
		}

		// remove field
		collection.Fields.RemoveById("select3736761055")

		return app.Save(collection)
	})
}
