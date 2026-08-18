package backend

import (
	"encoding/json"
	"fmt"
	"math"
	"sort"
)

// Shift is one staff member's cash handover: the float they started with, the
// sales rung during the shift, and the cash actually counted at handover.
type Shift struct {
	Staff        string  `json:"staff"`
	OpeningFloat float64 `json:"openingFloat"`
	ShiftSales   float64 `json:"shiftSales"`
	CountedCash  float64 `json:"countedCash"`
}

// Variance is counted minus expected (float + sales). Negative = short.
func (s Shift) Variance() float64 { return s.CountedCash - (s.OpeningFloat + s.ShiftSales) }

// Validate reports whether the Shift is well formed.
func (s Shift) Validate() error {
	if s.Staff == "" {
		return fmt.Errorf("staff is required")
	}
	if s.OpeningFloat < 0 || s.ShiftSales < 0 || s.CountedCash < 0 {
		return fmt.Errorf("amounts cannot be negative")
	}
	return nil
}

// StaffVariance is one staff member's accumulated variance and shift count.
type StaffVariance struct {
	Staff    string  `json:"staff"`
	Shifts   int     `json:"shifts"`
	Variance float64 `json:"variance"`
}

// Summarize accumulates variance per staff member, worst (most negative) first.
func Summarize(records []Record) []StaffVariance {
	agg := map[string]*StaffVariance{}
	for _, r := range records {
		var sh Shift
		if json.Unmarshal(r.Input, &sh) != nil {
			continue
		}
		v := agg[sh.Staff]
		if v == nil {
			v = &StaffVariance{Staff: sh.Staff}
			agg[sh.Staff] = v
		}
		v.Shifts++
		v.Variance += sh.Variance()
	}
	out := make([]StaffVariance, 0, len(agg))
	for _, v := range agg {
		out = append(out, *v)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Variance < out[j].Variance })
	return out
}

// parseEntry decodes+validates a shift; headline is its variance, label the staff.
func parseEntry(raw []byte) (float64, string, error) {
	var sh Shift
	if err := json.Unmarshal(raw, &sh); err != nil {
		return 0, "", fmt.Errorf("invalid json")
	}
	if err := sh.Validate(); err != nil {
		return 0, "", err
	}
	// round to paise to avoid float noise in stored headline
	return math.Round(sh.Variance()*100) / 100, sh.Staff, nil
}
