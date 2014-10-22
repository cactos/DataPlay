package main

import (
	"fmt"
	"github.com/gocql/gocql"
	"os"
	"strconv"
	"time"
)

func main() {
	DataTransfer()
}

func DataTransfer() {
	session1, err1 := GetCassandraConnection("dp")
	session2, err2 := GetCassandraConnection("dp2")

	if err1 != nil {
		fmt.Println("ERROR CASSANDRA 1!")
	}
	defer session1.Close()

	if err2 != nil {
		fmt.Println("ERROR CASSANDRA 2 !")
	}
	defer session2.Close()

	var FromDate = time.Date(2010, 1, 1, 0, 0, 0, 0, time.UTC)
	var ToDate = FromDate.AddDate(0, 1, 0)

	for i := 0; i < 58; i++ {
		var id []byte
		var pic_index int
		var date time.Time
		var description, url, title, name, pic_url, related_url string

		iter1 := session1.Query(`SELECT id, date, description, url, title FROM response WHERE date >= ? AND date < ? ALLOW FILTERING`, FromDate, ToDate).Iter()

		for iter1.Scan(&id, &date, &description, &url, &title) {
			session2.Query(`INSERT INTO response2 (date, dummy, description, url, title) VALUES (?, ?, ?, ?, ?)`, date, 1, description, url, title).Exec()

			iter2 := session1.Query(`SELECT url, pic_index FROM image WHERE id = ? ALLOW FILTERING`, id).Iter()

			for iter2.Scan(&pic_url, &pic_index) {
				if pic_index == 0 {
					session2.Query(`INSERT INTO image2 (date, dummy, pic_url, url) VALUES (?, ?, ?, ?)`, date, 1, pic_url, url).Exec()
				}
			}

			err := iter2.Close()
			if err != nil {
				fmt.Println("ERROR LOOP image")
			}

			iter3 := session1.Query(`SELECT description, title, url FROM related WHERE id = ? ALLOW FILTERING`, id).Iter()

			for iter3.Scan(&description, &title, &related_url) {
				session2.Query(`INSERT INTO related2 (date, dummy, description, title, related_url, url) VALUES (?, ?, ?, ?, ?, ?)`, date, 1, description, title, related_url, url).Exec()
			}

			err = iter3.Close()
			if err != nil {
				fmt.Println("ERROR LOOP related")
			}

		}

		err := iter1.Close()
		if err != nil {
			fmt.Println("ERROR LOOP image, related, response")
		}

		fmt.Println("SUCCESS LOOP image, related, response ", i)

		iter4 := session1.Query(`SELECT date, name, url, FROM keyword WHERE date >= ? AND date < ? ALLOW FILTERING`, FromDate, ToDate).Iter()

		for iter4.Scan(&date, &name, &url) {
			session2.Query(`INSERT INTO keyword2 (date, dummy, name, url) VALUES (?, ?, ?, ?)`, date, 1, name, url).Exec()
		}

		err = iter4.Close()

		if err != nil {
			fmt.Println("ERROR LOOP keyword")
		}

		fmt.Println("SUCCESS LOOP keyword", i)

		iter5 := session1.Query(`SELECT date, name, url, FROM entity WHERE date >= ? AND date < ? ALLOW FILTERING`, FromDate, ToDate).Iter()

		for iter5.Scan(&date, &name, &url) {
			session2.Query(`INSERT INTO entity2 (date, dummy, name, url) VALUES (?, ?, ?, ?)`, date, 1, name, url).Exec()
		}

		err = iter5.Close()
		if err != nil {
			fmt.Println("ERROR LOOP entity")
		}

		fmt.Println("SUCCESS LOOP entity", i)

		ToDate = ToDate.AddDate(0, 1, 0)
		FromDate = FromDate.AddDate(0, 1, 0)
		fmt.Println("TOTAL LOOP ", i, " COMPLETE ", 58-i, " MORE TO GO")
	}
}

func GetCassandraConnection(keyspace string) (*gocql.Session, error) {
	cassandraHost := "109.231.121.129"
	cassandraPort := 9042

	if os.Getenv("DP_CASSANDRA_HOST") != "" {
		cassandraHost = os.Getenv("DP_CASSANDRA_HOST")
	}

	if os.Getenv("DP_CASSANDRA_PORT") != "" {
		cassandraPort, _ = strconv.Atoi(os.Getenv("DP_CASSANDRA_PORT"))
	}

	cluster := gocql.NewCluster(cassandraHost)
	cluster.Timeout = 2 * time.Minute
	cluster.Port = cassandraPort
	cluster.Keyspace = keyspace
	cluster.Consistency = gocql.Quorum
	cluster.Compressor = gocql.SnappyCompressor{}
	cluster.RetryPolicy = &gocql.SimpleRetryPolicy{NumRetries: 5}
	session, err := cluster.CreateSession()

	if err != nil {
		fmt.Println("Could not connect to the Cassandara server.")
		return nil, err
	}

	return session, nil
}
