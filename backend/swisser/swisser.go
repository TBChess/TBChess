package swisser

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
)

type SwisserClient struct {
	BaseURL string
	Client  *http.Client
}

// NewSwisserClient creates a new Swisser API client
func NewSwisserClient(baseURL string) *SwisserClient {
	return &SwisserClient{
		BaseURL: baseURL,
		Client:  &http.Client{},
	}
}

// Ping checks if the Swisser API server is responding
func (c *SwisserClient) Ping() error {
	resp, err := c.Client.Get(c.BaseURL + "/ping")
	if err != nil {
		return fmt.Errorf("ping request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("ping failed with status: %d", resp.StatusCode)
	}

	// Check if response is valid JSON
	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return fmt.Errorf("invalid JSON response: %w", err)
	}

	if _, exists := result["swisser"]; !exists {
		return fmt.Errorf("swisser key not found in ping response")
	}

	return nil
}

// RoundRequest represents the request payload for the round endpoint
type Player struct {
	Name string `json:"name"`
	Elo  int    `json:"elo"`
}

type Game struct {
	White  string  `json:"white,omitempty"`
	Black  string  `json:"black,omitempty"`
	Result float64 `json:"result,omitempty"`
	Bye    bool    `json:"bye,omitempty"`
}

type Pairing struct {
	White string `json:"white,omitempty"`
	Black string `json:"black,omitempty"`
	Bye   bool   `json:"bye,omitempty"`
}

type RoundRequest struct {
	Rounds  int      `json:"rounds"`
	Players []Player `json:"players"`
	Games   [][]Game `json:"games"`
}

// Round sends a POST request to the /round endpoint
func (c *SwisserClient) Round(request RoundRequest) ([]Pairing, error) {
	jsonData, err := json.Marshal(request)

	if err != nil {
		return nil, fmt.Errorf("Failed to marshal request: %w", err)
	}

	data := url.Values{}
	data.Add("data", string(jsonData))

	resp, err := c.Client.PostForm(c.BaseURL+"/round", data)
	if err != nil {
		return nil, fmt.Errorf("Round request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("Round request failed with status: %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("Failed to read response body: %w", err)
	}

	var result []Pairing
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("Failed to unmarshal response: %w", err)
	}

	return result, nil
}
