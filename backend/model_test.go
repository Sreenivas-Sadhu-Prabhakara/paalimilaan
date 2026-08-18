package backend

import (
	"encoding/json"
	"math"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

type memStore struct{ items []Record }

func (m *memStore) Save(r Record) (Record, error) {
	r.ID = int64(len(m.items) + 1)
	m.items = append([]Record{r}, m.items...)
	return r, nil
}
func (m *memStore) List(limit int) ([]Record, error) { return m.items, nil }

func mk(staff string, fl, sales, counted float64) Record {
	sh := Shift{Staff: staff, OpeningFloat: fl, ShiftSales: sales, CountedCash: counted}
	in, _ := json.Marshal(sh)
	return Record{Input: in, Headline: sh.Variance(), Label: staff}
}

func TestVariance(t *testing.T) {
	// float 1000 + sales 4000 = 5000 expected, counted 4950 => -50.
	if v := (Shift{OpeningFloat: 1000, ShiftSales: 4000, CountedCash: 4950}).Variance(); math.Abs(v+50) > 1e-9 {
		t.Fatalf("variance=%v want -50", v)
	}
}

func TestSummarize_WorstFirstPerStaff(t *testing.T) {
	out := Summarize([]Record{mk("Ravi", 1000, 4000, 4950), mk("Ravi", 1000, 3000, 3990), mk("Sita", 1000, 2000, 3005)})
	if out[0].Staff != "Ravi" { // Ravi -60 total, worse than Sita +5
		t.Fatalf("worst-first wrong: %+v", out)
	}
	if math.Abs(out[0].Variance+60) > 1e-9 || out[0].Shifts != 2 {
		t.Fatalf("Ravi agg wrong: %+v", out[0])
	}
}

func TestLogEndpoint(t *testing.T) {
	srv := NewServer(&memStore{})
	rec := httptest.NewRecorder()
	srv.ServeHTTP(rec, httptest.NewRequest(http.MethodPost, "/log",
		strings.NewReader(`{"staff":"Ravi","openingFloat":1000,"shiftSales":4000,"countedCash":4950}`)))
	if rec.Code != http.StatusCreated {
		t.Fatalf("log %d", rec.Code)
	}
}
