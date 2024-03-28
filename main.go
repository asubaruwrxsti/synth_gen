package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
)

func main() {
	db, err := sqlx.Connect("postgres", "user=admin dbname=postgres sslmode=disable password=password host=localhost")
	if err != nil {
		log.Fatalln(err)
	}

	defer db.Close()

	schemas, err := db.Query(`SELECT DISTINCT table_schema FROM information_schema.tables`)
	if err != nil {
		log.Fatal(err)
	}
	defer schemas.Close()

	// Read the SQL query from the file
	sqlQuery, err := os.ReadFile("json.sql")
	if err != nil {
		log.Fatal(err)
	}

	// Define the array of names to ignore
	ignoreNames := []string{"information_schema", "pg_catalog"}

	for schemas.Next() {
		var schemaName string
		if err := schemas.Scan(&schemaName); err != nil {
			log.Fatal(err)
		}

		// Skip if the schema name is in the ignore list
		if contains(ignoreNames, schemaName) {
			continue
		}

		rows, err := db.Query(`SELECT table_name FROM information_schema.tables WHERE table_schema=$1`, schemaName)
		if err != nil {
			log.Fatal(err)
		}
		defer rows.Close()

		for rows.Next() {
			var tableName string
			if err := rows.Scan(&tableName); err != nil {
				log.Fatal(err)
			}

			// Skip if the table name is in the ignore list
			if contains(ignoreNames, tableName) {
				continue
			}

			// Create a directory for the table
			err = os.MkdirAll(filepath.Join("./"+schemaName, tableName), os.ModePerm)
			if err != nil {
				log.Fatal(err)
			}

			// Run the SQL query for the table
			formattedQuery := fmt.Sprintf(string(sqlQuery), schemaName, tableName, tableName)
			row := db.QueryRowx(formattedQuery)

			var resultBytes []byte
			err = row.Scan(&resultBytes)
			if err != nil {
				log.Fatal(err)
			}

			var result map[string]interface{}
			err = json.Unmarshal(resultBytes, &result)
			if err != nil {
				log.Fatal(err)
			}

			// Save the output of the query as a JSON file in the directory
			file, err := os.Create(filepath.Join("./"+schemaName, tableName, tableName+".json"))
			if err != nil {
				log.Fatal(err)
			}
			defer file.Close()

			encoder := json.NewEncoder(file)
			err = encoder.Encode(&result)
			if err != nil {
				log.Fatal(err)
			}
		}

		if err := rows.Err(); err != nil {
			log.Fatal(err)
		}
	}

	if err := schemas.Err(); err != nil {
		log.Fatal(err)
	}
}

// Helper function to check if a string is in a slice
func contains(slice []string, item string) bool {
	for _, a := range slice {
		if a == item {
			return true
		}
	}
	return false
}
