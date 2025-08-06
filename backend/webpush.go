package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	webpush "github.com/SherClockHolmes/webpush-go"
	"github.com/pocketbase/dbx"
	"github.com/pocketbase/pocketbase/core"
)

type WebPushNotification struct {
	Email      string `db:"email" json:"email"`
	WebPushSub string `db:"webpush_sub" json:"webpush_sub"`
}

func webPushNotifyNewRound(txApp core.App, eventId string, round int) error {
	privateKey, publicKey, err := getVAPIDKeys()
	if err != nil {
		return err
	}

	notifications := []WebPushNotification{}

	// Notify people that have web push
	err = txApp.DB().
		NewQuery(`SELECT u.email, u.webpush_sub FROM event_signups es
					LEFT OUTER JOIN users u
					ON u.id = es.user
					WHERE es.event = {:event_id} AND u.webpush_sub IS NOT NULL`).
		Bind(dbx.Params{"event_id": eventId}).
		All(&notifications)
	if err != nil {
		return err
	}

	for _, notification := range notifications {
		s := &webpush.Subscription{}

		err = json.Unmarshal([]byte(notification.WebPushSub), s)
		if err != nil {
			txApp.Logger().Warn(fmt.Sprintf("Cannot unmarshal webpush subscription for %s: %s", notification.Email, err))
			continue
		}

		// Validate that subscription has required fields
		if s.Endpoint == "" || s.Keys.P256dh == "" || s.Keys.Auth == "" {
			txApp.Logger().Warn(fmt.Sprintf("Invalid webpush subscription for %s: missing required fields", notification.Email))
			continue
		}

		// Send Notification

		payload := map[string]string{
			"title":   fmt.Sprintf("Round %d", round),
			"message": fmt.Sprintf("Round %d has started", round),
			"path":    fmt.Sprintf("event/%s", eventId),
		}

		payloadBytes, err := json.Marshal(payload)
		if err != nil {
			return fmt.Errorf("cannot encode notification payload %s", err)
		}

		resp, err := webpush.SendNotification(payloadBytes, s, &webpush.Options{
			Subscriber:      notification.Email,
			VAPIDPublicKey:  publicKey,
			VAPIDPrivateKey: privateKey,
			TTL:             30,
		})
		if err != nil {
			txApp.Logger().Warn(fmt.Sprintf("Cannot send notification: %s", err))
		}
		defer resp.Body.Close()
	}

	return nil
}

func getVAPIDKeys() (string, string, error) {
	dataDir := "pb_data"
	keysFile := filepath.Join(dataDir, "vapid_keys.json")

	if err := os.MkdirAll(dataDir, 0755); err != nil {
		return "", "", err
	}

	if _, err := os.Stat(keysFile); err == nil {
		// File exists, read keys from JSON
		data, err := os.ReadFile(keysFile)
		if err != nil {
			return "", "", err
		}

		var keys struct {
			PrivateKey string `json:"privateKey"`
			PublicKey  string `json:"publicKey"`
		}

		if err := json.Unmarshal(data, &keys); err != nil {
			return "", "", err
		}

		return keys.PrivateKey, keys.PublicKey, nil
	}

	// File doesn't exist, generate new keys
	privateKey, publicKey, err := webpush.GenerateVAPIDKeys()
	if err != nil {
		return "", "", err
	}

	keys := struct {
		PrivateKey string `json:"privateKey"`
		PublicKey  string `json:"publicKey"`
	}{
		PrivateKey: privateKey,
		PublicKey:  publicKey,
	}

	data, err := json.MarshalIndent(keys, "", "  ")
	if err != nil {
		return "", "", err
	}

	if err := os.WriteFile(keysFile, data, 0644); err != nil {
		return "", "", err
	}

	return privateKey, publicKey, nil
}
