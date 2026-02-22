[INFO] MODO BASE DE DATOS: PostgreSQL (Docker)

CREATE TABLE property_media (
	id SERIAL NOT NULL, 
	property_id INTEGER NOT NULL, 
	media_type mediatype NOT NULL, 
	file_path VARCHAR NOT NULL, 
	is_main BOOLEAN, 
	"order" INTEGER, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(property_id) REFERENCES properties (id)
)


;
