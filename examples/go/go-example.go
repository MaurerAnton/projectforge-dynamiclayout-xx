// Go example: Generate DynamicLayout JSON from Go code
// Build: go run go-example.go
// Output: JSON printed to stdout — pipe to playground for visual verification

package main

import (
	"fmt"

	dl "github.com/MaurerAnton/projectforge-dynamiclayout/dynamiclayout"
)

func main() {
	// === 1. Static about page ===
	fmt.Println("=== About Page ===")
	b := dl.Begin("About (from Go)")
	b.Section("Info", "DynamicLayout Engine v1.0")
	b.Section("License", "MIT — single-file Go library")
	b.Button("ok", "OK", dl.ColorPrimary, true)
	b.Button("cancel", "Cancel", dl.ColorSecondary, false)
	fmt.Println(b.End())

	// === 2. Feedback form ===
	fmt.Println("\n=== Feedback Form ===")
	b2 := dl.Begin("Feedback (from Go)")
	b2.Fieldset("Your Message")
	b2.Input("name", "Your Name", dl.Required())
	b2.Input("email", "Email", dl.Required(), dl.DataTypeInput(dl.DataTypeString))
	b2.Input("subject", "Subject")
	b2.EndFieldset()
	b2.FeedbackForm() // includes send/cancel buttons
	fmt.Println(b2.End())

	// === 3. Registration form with grid layout ===
	fmt.Println("\n=== Registration Form ===")
	b3 := dl.Begin("Registration (from Go)")
	b3.Row()
	b3.Col(12, 6)
	b3.Fieldset("Personal Info")
	b3.Input("firstName", "First Name", dl.Required())
	b3.Input("lastName", "Last Name", dl.Required())
	b3.Input("email", "Email", dl.Required())
	b3.EndFieldset()
	b3.EndCol()
	b3.Col(12, 6)
	b3.Fieldset("Preferences")
	b3.SelectStrings("country", "Country",
		[2]string{"us", "United States"},
		[2]string{"de", "Germany"},
		[2]string{"jp", "Japan"},
	)
	b3.Checkbox("newsletter", "Subscribe to newsletter")
	b3.EndFieldset()
	b3.EndCol()
	b3.EndRow()
	b3.Button("register", "Register", dl.ColorPrimary, true)
	b3.Button("cancel", "Cancel", dl.ColorSecondary, false)
	fmt.Println(b3.End())

	// === 4. Device diagnostics (embedded use case) ===
	fmt.Println("\n=== Device Diagnostics ===")
	b4 := dl.Begin("Device Diagnostics (from Go)")
	b4.Fieldset("System")
	b4.Label("CPU: ARM Cortex-M4 @ 180 MHz")
	b4.Label("Memory: 512 KB free / 1 MB total")
	b4.Alert("Overheating detected!", dl.ColorDanger)
	b4.EndFieldset()
	b4.Fieldset("Network")
	b4.Input("hostname", "Hostname", dl.Required())
	b4.Input("mqtt_broker", "MQTT Broker")
	b4.SelectStrings("log_level", "Log Level",
		[2]string{"debug", "Debug"},
		[2]string{"info", "Info"},
		[2]string{"warn", "Warning"},
		[2]string{"error", "Error"},
	)
	b4.EndFieldset()
	b4.Button("reboot", "Reboot", dl.ColorDanger, false)
	b4.Button("save", "Save Config", dl.ColorPrimary, true)
	fmt.Println(b4.End())

	// === 5. AgGrid table ===
	fmt.Println("\n=== User List (AgGrid) ===")
	b5 := dl.Begin("Users (from Go)")
	b5.AgGrid("users", []dl.Element{
		b5.AgGridColumn("id", "ID"),
		b5.AgGridColumn("name", "Name"),
		b5.AgGridColumn("email", "Email"),
		b5.AgGridColumn("role", "Role"),
	})
	fmt.Println(b5.End())

	fmt.Println("\n=== All examples generated successfully ===")
}
