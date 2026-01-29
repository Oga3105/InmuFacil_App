-- Enums
DO $$ BEGIN
    CREATE TYPE propertytype AS ENUM ('piso', 'chalet', 'local', 'oficina', 'terreno', 'edificio');
    EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE operationtype AS ENUM ('venta', 'alquiler', 'btr', 'inversion');
    EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE orientation AS ENUM ('norte', 'sur', 'este', 'oeste', 'noreste', 'noroeste', 'sureste', 'suroeste');
    EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE heatingtype AS ENUM ('gas_natural', 'electrica', 'central', 'aerotermia', 'otro');
    EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE conservationstate AS ENUM ('a_estrenar', 'buen_estado', 'a_reformar');
    EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE energycertification AS ENUM ('A', 'B', 'C', 'D', 'E', 'F', 'G', 'exento', 'en_tramite');
    EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE itestatus AS ENUM ('pasada', 'pendiente', 'desfavorable', 'no_obligado');
    EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE notasimplestatus AS ENUM ('pending', 'verified', 'rejected');
    EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE crimerate AS ENUM ('bajo', 'medio', 'alto');
    EXCEPTION
    WHEN duplicate_object THEN null;
END $$;


-- Core Table
CREATE TABLE properties (
	id SERIAL NOT NULL, 
	title VARCHAR NOT NULL, 
	description VARCHAR, 
	price FLOAT NOT NULL, 
	location VARCHAR NOT NULL, 
	surface_area FLOAT NOT NULL, 
	property_type propertytype NOT NULL, 
	operation_type operationtype NOT NULL, 
	owner_id INTEGER, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now(), 
	updated_at TIMESTAMP WITH TIME ZONE, 
	PRIMARY KEY (id), 
	FOREIGN KEY(owner_id) REFERENCES users (id)
);

-- Satellite Tables
CREATE TABLE property_features (
	id SERIAL NOT NULL, 
	property_id INTEGER NOT NULL, 
	bedrooms INTEGER, 
	bathrooms INTEGER, 
	construction_year INTEGER, 
	orientation orientation, 
	heating_type heatingtype, 
	has_lift BOOLEAN, 
	has_ac BOOLEAN, 
	has_heating BOOLEAN, 
	has_terrace BOOLEAN, 
	has_pool BOOLEAN, 
	has_garden BOOLEAN, 
	conservation_state conservationstate, 
	PRIMARY KEY (id), 
	UNIQUE (property_id), 
	FOREIGN KEY(property_id) REFERENCES properties (id) ON DELETE CASCADE
);

CREATE TABLE property_legal (
	id SERIAL NOT NULL, 
	property_id INTEGER NOT NULL, 
	energy_certification energycertification, 
	energy_consumption_kwh_m2 FLOAT, 
	emissions_kg_co2_m2 FLOAT, 
	ite_status itestatus, 
	ite_year INTEGER, 
	cadastral_reference VARCHAR, 
	nota_simple_status notasimplestatus, 
	PRIMARY KEY (id), 
	UNIQUE (property_id), 
	FOREIGN KEY(property_id) REFERENCES properties (id) ON DELETE CASCADE
);

CREATE TABLE property_financial (
	id SERIAL NOT NULL, 
	property_id INTEGER NOT NULL, 
	ibi_yearly_tax FLOAT, 
	community_fees_monthly FLOAT, 
	estimated_rent_monthly FLOAT, 
	gross_yield FLOAT, 
	price_m2 FLOAT, 
	PRIMARY KEY (id), 
	UNIQUE (property_id), 
	FOREIGN KEY(property_id) REFERENCES properties (id) ON DELETE CASCADE
);

CREATE TABLE property_environment (
	id SERIAL NOT NULL, 
	property_id INTEGER NOT NULL, 
	noise_level_day_db FLOAT, 
	noise_level_night_db FLOAT, 
	crime_rate_level crimerate, 
	proximity_subway_min INTEGER, 
	proximity_school_min INTEGER, 
	healthcare_quality_index FLOAT, 
	PRIMARY KEY (id), 
	UNIQUE (property_id), 
	FOREIGN KEY(property_id) REFERENCES properties (id) ON DELETE CASCADE
);
