-- Enum
DO $$ BEGIN
    CREATE TYPE visitstatus AS ENUM ('requested', 'approved', 'rejected');
    EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Tables
CREATE TABLE visit_windows (
	id SERIAL NOT NULL, 
	property_id INTEGER NOT NULL, 
	start_time TIMESTAMP WITH TIME ZONE NOT NULL, 
	end_time TIMESTAMP WITH TIME ZONE NOT NULL, 
	slot_duration_minutes INTEGER NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(property_id) REFERENCES properties (id) ON DELETE CASCADE
);

CREATE TABLE visit_appointments (
	id SERIAL NOT NULL, 
	window_id INTEGER NOT NULL, 
	buyer_id INTEGER NOT NULL, 
	start_time TIMESTAMP WITH TIME ZONE NOT NULL, 
	status visitstatus NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(window_id) REFERENCES visit_windows (id) ON DELETE CASCADE, 
	FOREIGN KEY(buyer_id) REFERENCES users (id) ON DELETE CASCADE
);
