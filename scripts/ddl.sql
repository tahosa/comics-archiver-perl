CREATE TABLE comics (
	cName VARCHAR(100) PRIMARY KEY,
	number INT DEFAULT 0,
	folder VARCHAR(255) UNIQUE NOT NULL,
	updated DATETIME,
	lastPage TEXT NOT NULL,
	firstPage TEXT NOT NULL,
	nextSearch TEXT NOT NULL,
	comicSearch TEXT NOT NULL,
	baseURL TEXT NOT NULL,
	description TEXT NOT NULL,
	finished TINYINT DEFAULT 0);

CREATE TABLE files (
	cName VARCHAR(100),
	number INT,
	filename VARCHAR(255) NOT NULL,
	altText TEXT,
	annotation TEXT,
	PRIMARY KEY(cName, number),
	CONSTRAINT FOREIGN KEY(cName) REFERENCES comics(cName)
	);
	
CREATE INDEX filesIndex ON files(cName, number);
	