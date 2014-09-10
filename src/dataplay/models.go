package main

import (
	"time"
)

type appError struct {
	Error   error
	Message string
	Code    int
}

type Activity struct {
	ActivityId int `primaryKey:"yes"`
	Type       string
	Created    time.Time
	Uid        int
}

func (a Activity) TableName() string {
	return "priv_activity"
}

type Comment struct {
	CommentId  int `primaryKey:"yes"`
	Comment    string
	ActivityId int
}

func (c Comment) TableName() string {
	return "priv_comments"
}

type Correlation struct {
	Tbl1          string
	Col1          string
	Tbl2          string
	Col2          string
	Tbl3          string
	Col3          string
	Method        string
	Coef          float64
	Json          []byte
	CorrelationId int `primaryKey:"yes"`
	Abscoef       float64
}

func (c Correlation) TableName() string {
	return "priv_correlation"
}

type Departments struct {
	GovDept string
	Type    string
	Id      int `primaryKey:"yes"`
}

func (c Departments) TableName() string {
	return "priv_departments"
}

type Events struct {
	Keyword string
	Event   string
	Id      int `primaryKey:"yes"`
}

func (c Events) TableName() string {
	return "priv_events"
}

type Index struct {
	Guid    string
	Name    string
	Title   string
	Notes   string
	CkanUrl string
	Owner   int
}

func (i Index) TableName() string {
	return "index"
}

type Observation struct {
	Comment       string
	ValidatedId   int
	Uid           int
	Rating        float64
	Valid         int
	Invalid       int
	ObservationId int `primaryKey:"yes"`
	Created       time.Time
	X             string
	Y             string
}

func (ob Observation) TableName() string {
	return "priv_observations"
}

type OnlineData struct {
	Guid        string
	Datasetguid string
	Tablename   string
	Defaults    string
	PrimaryDate string
}

func (od OnlineData) TableName() string {
	return "priv_onlinedata"
}

type StatsCheck struct {
	Id     int `primaryKey:"yes"`
	Table  string
	X      string
	Y      string
	P1     int
	P2     int
	P3     int
	Xstart int
	Xend   int
}

type Regions struct {
	Town   string
	County string
	Id     int `primaryKey:"yes"`
}

func (c Regions) TableName() string {
	return "priv_regions"
}

func (sc StatsCheck) TableName() string {
	return "priv_statcheck"
}

type StringSearch struct {
	Tablename string
	X         string
	Value     string
	Count     int
}

func (ss StringSearch) TableName() string {
	return "priv_stringsearch"
}

type SearchTerm struct {
	Id    int `primaryKey:"yes"`
	Term  string
	Count int
}

func (st SearchTerm) TableName() string {
	return "priv_searchterms"
}

type Tracking struct {
	Id      int `primaryKey:"yes"`
	User    int
	Guid    string
	Info    string
	Created time.Time
}

func (t Tracking) TableName() string {
	return "priv_tracking"
}

type TrackingInfo struct {
	Id   int `primaryKey:"yes"`
	Info []byte
}

func (ti TrackingInfo) TableName() string {
	return "priv_tracking"
}

type TableSchema struct {
	ColumnName string
	DataType   string
}

func (ts TableSchema) TableName() string {
	return "information_schema.columns"
}

type User struct {
	Uid        int `primaryKey:"yes"`
	Email      string
	Password   string
	Reputation int
	Avatar     string
	Username   string
}

func (u User) TableName() string {
	return "priv_users"
}

type Validated struct {
	ValidatedId   int `primaryKey:"yes"`
	Uid           int
	Created       time.Time
	Rating        float64
	Valid         int
	Invalid       int
	Json          []byte
	CorrelationId int
	RelationId    string
}

func (v Validated) TableName() string {
	return "priv_validatedcharts"
}

type Validation struct {
	ValidatedId   int
	Validator     int
	ValidationId  int `primaryKey:"yes"`
	Created       time.Time
	ObservationId int
	Valflag       bool
}

func (vn Validation) TableName() string {
	return "priv_validations"
}
