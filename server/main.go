package main

import (
	"log"
	"net/http"
	"os"
	"time"

	"github.com/IamFreak10/Gonotify"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// 1. Initialize Gonotify engine
	notifier := gonotify.New(gonotify.Config{
		PingPeriod: 25 * time.Second,
		OnConnect: func(client *gonotify.Client) {
			log.Printf("[Notify Server] Client connected: %s", client.ID)
		},
		OnDisconnect: func(client *gonotify.Client) {
			log.Printf("[Notify Server] Client disconnected: %s", client.ID)
		},
	})
	defer notifier.Close()

	// 2. WebSocket endpoint for Notify Mobile App
	http.HandleFunc("/ws", notifier.Handler())

	// 3. HTTP REST Webhook endpoint for Bornomala backend
	// Bornomala sends: POST /publish {"topic":"orders", "event":"NEW_ORDER", ...}
	http.HandleFunc("/publish", notifier.PublishHandler())

	// 4. Health check endpoint (for Render / UptimeRobot)
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"status":"ok","clients":` + string(rune(notifier.ClientCount()+'0')) + `}`))
	})

	log.Printf("[Notify Server] Listening on :%s", port)
	log.Printf("[Notify Server] WS Route: /ws | Publish Route: /publish")
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
